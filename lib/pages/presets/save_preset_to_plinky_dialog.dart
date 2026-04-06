import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_preset.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/services/webusb_service.dart';
import 'package:plinkyhub/state/plinky_notifier.dart';
import 'package:plinkyhub/state/plinky_state.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _DialogStep {
  methodSelection,
  slotSelection,
  sampleSlotSelection,
  instructions,
  progress,
  done,
  error,
}

enum _SaveMethod {
  webUsb,
  tunnelOfLights,
}

class SavePresetToPlinkyDialog extends ConsumerStatefulWidget {
  const SavePresetToPlinkyDialog({required this.preset, super.key});

  final SavedPreset preset;

  @override
  ConsumerState<SavePresetToPlinkyDialog> createState() =>
      _SavePresetToPlinkyDialogState();
}

class _SavePresetToPlinkyDialogState
    extends ConsumerState<SavePresetToPlinkyDialog> {
  _DialogStep _step = _DialogStep.methodSelection;
  _SaveMethod _method = _SaveMethod.webUsb;
  int _selectedSlot = 0;
  int _selectedSampleSlot = 0;
  String _statusMessage = '';
  String? _errorMessage;
  double? _progress;

  /// Preset slot → sample slot mapping read from PRESETS.UF2 (Tunnel of Lights
  /// only). Null until the file is read.
  Map<int, int>? _devicePresetSampleSlots;

  SupabaseClient get _supabase => Supabase.instance.client;

  bool get _hasSample => widget.preset.sampleId != null;

  SavedSample? _findSample() {
    if (widget.preset.sampleId == null) {
      return null;
    }
    final samplesState = ref.read(savedSamplesProvider);
    return samplesState.userSamples
            .where((s) => s.id == widget.preset.sampleId)
            .firstOrNull ??
        samplesState.publicSamples
            .where((s) => s.id == widget.preset.sampleId)
            .firstOrNull;
  }

  void _advanceFromPresetSlot() {
    if (_hasSample) {
      setState(() => _step = _DialogStep.sampleSlotSelection);
    } else if (_method == _SaveMethod.webUsb) {
      _startWebUsbSave();
    } else {
      setState(() => _step = _DialogStep.instructions);
    }
  }

  void _advanceFromSampleSlot() {
    if (_method == _SaveMethod.webUsb) {
      _startWebUsbSave();
    } else {
      setState(() => _step = _DialogStep.instructions);
    }
  }

  Future<void> _startWebUsbSave() async {
    setState(() {
      _step = _DialogStep.progress;
      _statusMessage = 'Connecting to Plinky...';
      _progress = null;
    });

    try {
      final notifier = ref.read(plinkyProvider.notifier);
      final currentState = ref.read(plinkyProvider);

      if (currentState.connectionState == PlinkyConnectionState.disconnected ||
          currentState.connectionState == PlinkyConnectionState.error) {
        await notifier.connect();
        final afterConnect = ref.read(plinkyProvider);
        if (afterConnect.connectionState != PlinkyConnectionState.connected) {
          setState(() {
            _step = _DialogStep.error;
            _errorMessage =
                afterConnect.errorMessage ?? 'Failed to connect to Plinky.';
          });
          return;
        }
      }

      // Upload sample first if linked.
      final sample = _findSample();
      if (sample != null) {
        setState(() => _statusMessage = 'Downloading sample data...');
        final pcmBytes = await _supabase.storage
            .from('samples')
            .download(sample.pcmFilePath);

        setState(() => _statusMessage = 'Building sample metadata...');
        final sampleInfo = buildSampleInfo(
          pcmData: pcmBytes,
          slicePoints: sample.slicePoints,
          sliceNotes: sample.sliceNotes,
          pitched: sample.pitched,
        );

        setState(() => _statusMessage = 'Sending sample to Plinky...');
        await notifier.sendSample(
          slotIndex: _selectedSampleSlot,
          pcmData: pcmBytes,
          sampleInfo: sampleInfo,
          onProgress: (value) {
            if (mounted) {
              setState(() {
                _progress = value * 0.9; // Reserve 10% for preset.
                final percent = (value * 90).toInt();
                _statusMessage = 'Sending sample data... $percent%';
              });
            }
          },
        );
      }

      setState(() {
        _statusMessage = 'Sending preset to Plinky...';
        _progress = sample != null ? 0.9 : null;
      });

      final presetData = Uint8List.fromList(
        base64Decode(widget.preset.presetData),
      );

      // Update the preset's P_SAMPLE to point to the chosen sample slot.
      if (sample != null) {
        setPresetSampleSlot(presetData, _selectedSampleSlot);
      }

      notifier.presetNumber = _selectedSlot;
      notifier.loadPresetFromBytes(presetData);
      await notifier.savePreset();

      if (mounted) {
        setState(() => _step = _DialogStep.done);
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _step = _DialogStep.error;
          _errorMessage = error.toString();
        });
      }
    }
  }

  Future<void> _startTunnelOfLightsSave() async {
    final directory = await showDirectoryPicker(readwrite: true);
    if (directory == null) {
      return;
    }

    setState(() {
      _step = _DialogStep.progress;
      _statusMessage = 'Reading existing PRESETS.UF2...';
      _progress = null;
    });

    try {
      await _generateAndWriteFiles(directory);
      setState(() => _step = _DialogStep.done);
    } on Exception catch (error) {
      setState(() {
        _step = _DialogStep.error;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _generateAndWriteFiles(
    FileSystemDirectoryHandle directory,
  ) async {
    final existingUf2 = await readFileFromDirectory(directory, 'PRESETS.UF2');

    List<Uint8List?> presets;
    List<Uint8List?> sampleInfos;
    List<Uint8List?>? patternQuarters;

    if (existingUf2 != null) {
      final flashImage = uf2ToData(existingUf2);
      final parsed = parseFlashImage(flashImage);
      presets = parsed.presets;
      sampleInfos = parsed.rawSampleInfos;
      patternQuarters = parsed.patternQuarters;
    } else {
      presets = List<Uint8List?>.filled(presetCount, null);
      sampleInfos = List<Uint8List?>.filled(sampleCount, null);
    }

    final presetData = Uint8List.fromList(
      base64Decode(widget.preset.presetData),
    );

    // Upload sample if linked.
    final sample = _findSample();
    if (sample != null) {
      setState(() => _statusMessage = 'Downloading sample data...');
      final pcmBytes = await _supabase.storage
          .from('samples')
          .download(sample.pcmFilePath);

      setState(
        () => _statusMessage = 'Generating SAMPLE$_selectedSampleSlot.UF2...',
      );
      final sampleUf2Bytes = sampleToUf2(
        pcmBytes,
        slotIndex: _selectedSampleSlot,
      );

      setState(
        () => _statusMessage = 'Writing SAMPLE$_selectedSampleSlot.UF2...',
      );
      await writeFileToDirectory(
        directory,
        'SAMPLE$_selectedSampleSlot.UF2',
        sampleUf2Bytes,
      );

      sampleInfos[_selectedSampleSlot] = buildSampleInfo(
        pcmData: pcmBytes,
        slicePoints: sample.slicePoints,
        sliceNotes: sample.sliceNotes,
        pitched: sample.pitched,
      );

      // Update the preset's P_SAMPLE to point to the chosen sample slot.
      setPresetSampleSlot(presetData, _selectedSampleSlot);
    }

    presets[_selectedSlot] = presetData;

    setState(() => _statusMessage = 'Generating PRESETS.UF2...');
    final presetsUf2 = generatePresetsUf2(
      presets: presets,
      sampleInfos: sampleInfos,
      patternQuarters: patternQuarters,
    );

    setState(() => _statusMessage = 'Writing PRESETS.UF2...');
    await writeFileToDirectory(directory, 'PRESETS.UF2', presetsUf2);
  }

  /// Returns a map of sample slot (0-7) → list of preset numbers (1-32)
  /// that reference it, based on [_devicePresetSampleSlots].
  Map<int, List<int>> _sampleSlotUsage() {
    final usage = <int, List<int>>{};
    final slots = _devicePresetSampleSlots;
    if (slots == null) {
      return usage;
    }
    for (final entry in slots.entries) {
      usage.putIfAbsent(entry.value, () => []).add(entry.key + 1);
    }
    return usage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: switch (_step) {
        _DialogStep.methodSelection ||
        _DialogStep.slotSelection ||
        _DialogStep.sampleSlotSelection ||
        _DialogStep.instructions => const Text('Save preset to Plinky'),
        _DialogStep.progress => const Text('Uploading to Plinky...'),
        _DialogStep.done => Row(
          children: [
            const Text('Done'),
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        _DialogStep.error => const Text('Error'),
      },
      content: SizedBox(
        width: 400,
        child: switch (_step) {
          _DialogStep.methodSelection => const TransferMethodSelection(
            itemType: 'preset',
          ),
          _DialogStep.slotSelection => SlotSelectionGrid(
            itemType: 'preset',
            slotCount: presetCount,
            selectedSlot: _selectedSlot,
            onSlotChanged: (slot) => setState(() => _selectedSlot = slot),
          ),
          _DialogStep.sampleSlotSelection => _SampleSlotSelectionView(
            selectedSlot: _selectedSampleSlot,
            onSlotChanged: (slot) => setState(() => _selectedSampleSlot = slot),
            sampleSlotUsage: _sampleSlotUsage(),
          ),
          _DialogStep.instructions => const TunnelOfLightsInstructions(
            itemType: 'preset',
          ),
          _DialogStep.progress => SaveProgressView(
            statusMessage: _statusMessage,
            progress: _progress,
          ),
          _DialogStep.done => SaveDoneView(
            itemType: 'preset',
            usedWebUsb: _method == _SaveMethod.webUsb,
          ),
          _DialogStep.error => SaveErrorView(errorMessage: _errorMessage),
        },
      ),
      actions: switch (_step) {
        _DialogStep.methodSelection => [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Cancel',
          ),
          if (WebUsbService.isSupported)
            PlinkyButton(
              onPressed: () {
                _method = _SaveMethod.webUsb;
                setState(() => _step = _DialogStep.slotSelection);
              },
              icon: Icons.usb,
              label: 'Send via USB',
            ),
          PlinkyButton(
            onPressed: () {
              _method = _SaveMethod.tunnelOfLights;
              setState(() => _step = _DialogStep.slotSelection);
            },
            icon: Icons.folder_open,
            label: 'Tunnel of Lights',
          ),
        ],
        _DialogStep.slotSelection => [
          PlinkyButton(
            onPressed: () =>
                setState(() => _step = _DialogStep.methodSelection),
            label: 'Back',
          ),
          PlinkyButton(
            onPressed: _advanceFromPresetSlot,
            label: _hasSample
                ? 'Next'
                : (_method == _SaveMethod.webUsb ? 'Send' : 'Next'),
          ),
        ],
        _DialogStep.sampleSlotSelection => [
          PlinkyButton(
            onPressed: () => setState(() => _step = _DialogStep.slotSelection),
            label: 'Back',
          ),
          PlinkyButton(
            onPressed: _advanceFromSampleSlot,
            label: _method == _SaveMethod.webUsb ? 'Send' : 'Next',
          ),
        ],
        _DialogStep.instructions => [
          PlinkyButton(
            onPressed: () => setState(() {
              _step = _hasSample
                  ? _DialogStep.sampleSlotSelection
                  : _DialogStep.slotSelection;
            }),
            label: 'Back',
          ),
          PlinkyButton(
            onPressed: _startTunnelOfLightsSave,
            icon: Icons.folder_open,
            label: 'Select Plinky drive',
          ),
        ],
        _DialogStep.progress => [],
        _DialogStep.done || _DialogStep.error => [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Close',
          ),
        ],
      },
    );
  }
}

class _SampleSlotSelectionView extends StatelessWidget {
  const _SampleSlotSelectionView({
    required this.selectedSlot,
    required this.onSlotChanged,
    required this.sampleSlotUsage,
  });

  final int selectedSlot;
  final ValueChanged<int> onSlotChanged;

  /// Map of sample slot (0-7) → list of preset numbers (1-based) using it.
  final Map<int, List<int>> sampleSlotUsage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usingSlot = sampleSlotUsage[selectedSlot];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This preset uses a sample. Select the sample slot on your Plinky:',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < sampleCount; i++)
              ChoiceChip(
                label: Text('Slot ${i + 1}'),
                selected: selectedSlot == i,
                showCheckmark: false,
                onSelected: (_) => onSlotChanged(i),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (usingSlot != null && usingSlot.isNotEmpty)
          Text(
            'Warning: Preset${usingSlot.length > 1 ? 's' : ''} '
            '${usingSlot.join(', ')} currently '
            '${usingSlot.length > 1 ? 'use' : 'uses'} sample slot '
            '${selectedSlot + 1}. They will use the new sample after saving.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else
          Text(
            'The existing sample in slot ${selectedSlot + 1} will be '
            'overwritten.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
