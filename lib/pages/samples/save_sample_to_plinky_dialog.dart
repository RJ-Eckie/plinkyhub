import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/services/webusb_service.dart';
import 'package:plinkyhub/state/plinky_notifier.dart';
import 'package:plinkyhub/state/plinky_state.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _DialogStep {
  methodSelection,
  slotSelection,
  instructions,
  progress,
  done,
  error,
}

enum _SaveMethod {
  webUsb,
  tunnelOfLights,
}

class SaveSampleToPlinkyDialog extends ConsumerStatefulWidget {
  const SaveSampleToPlinkyDialog({required this.sample, super.key});

  final SavedSample sample;

  @override
  ConsumerState<SaveSampleToPlinkyDialog> createState() =>
      _SaveSampleToPlinkyDialogState();
}

class _SaveSampleToPlinkyDialogState
    extends ConsumerState<SaveSampleToPlinkyDialog> {
  _DialogStep _step = _DialogStep.methodSelection;
  _SaveMethod _method = _SaveMethod.webUsb;
  int _selectedSlot = 0;
  String _statusMessage = '';
  String? _errorMessage;
  double? _progress;

  SupabaseClient get _supabase => Supabase.instance.client;

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

      setState(() => _statusMessage = 'Downloading sample data...');
      final pcmBytes = await _supabase.storage
          .from('samples')
          .download(widget.sample.pcmFilePath);

      setState(() => _statusMessage = 'Building sample metadata...');
      final sampleInfo = buildSampleInfo(
        pcmData: pcmBytes,
        slicePoints: widget.sample.slicePoints,
        sliceNotes: widget.sample.sliceNotes,
        pitched: widget.sample.pitched,
      );

      setState(() => _statusMessage = 'Sending sample to Plinky...');
      await notifier.sendSample(
        slotIndex: _selectedSlot,
        pcmData: pcmBytes,
        sampleInfo: sampleInfo,
        onProgress: (value) {
          if (mounted) {
            setState(() {
              _progress = value;
              final percent = (value * 100).toInt();
              _statusMessage = 'Sending sample data... $percent%';
            });
          }
        },
      );

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
      _statusMessage = 'Downloading sample data...';
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
    final sample = widget.sample;

    setState(() => _statusMessage = 'Downloading sample PCM data...');
    final pcmBytes = await _supabase.storage
        .from('samples')
        .download(sample.pcmFilePath);

    setState(() => _statusMessage = 'Generating SAMPLE$_selectedSlot.UF2...');
    final sampleUf2Bytes = sampleToUf2(
      pcmBytes,
      slotIndex: _selectedSlot,
    );

    setState(() => _statusMessage = 'Writing SAMPLE$_selectedSlot.UF2...');
    await writeFileToDirectory(
      directory,
      'SAMPLE$_selectedSlot.UF2',
      sampleUf2Bytes,
    );

    // Read existing PRESETS.UF2 to preserve other slots.
    setState(() => _statusMessage = 'Reading existing PRESETS.UF2...');
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

    sampleInfos[_selectedSlot] = buildSampleInfo(
      pcmData: pcmBytes,
      slicePoints: sample.slicePoints,
      sliceNotes: sample.sliceNotes,
      pitched: sample.pitched,
    );

    setState(() => _statusMessage = 'Generating PRESETS.UF2...');
    final presetsUf2 = generatePresetsUf2(
      presets: presets,
      sampleInfos: sampleInfos,
      patternQuarters: patternQuarters,
    );

    setState(() => _statusMessage = 'Writing PRESETS.UF2...');
    await writeFileToDirectory(directory, 'PRESETS.UF2', presetsUf2);
  }

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: AlertDialog(
        title: switch (_step) {
          _DialogStep.methodSelection => const Text('Save sample to Plinky'),
          _DialogStep.slotSelection => const Text('Save sample to Plinky'),
          _DialogStep.instructions => const Text('Save sample to Plinky'),
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
              itemType: 'sample',
            ),
            _DialogStep.slotSelection => SlotSelectionGrid(
              itemType: 'sample',
              slotCount: sampleCount,
              rows: 2,
              selectedSlot: _selectedSlot,
              onSlotChanged: (slot) => setState(() => _selectedSlot = slot),
            ),
            _DialogStep.instructions => const TunnelOfLightsInstructions(
              itemType: 'sample',
            ),
            _DialogStep.progress => SaveProgressView(
              statusMessage: _statusMessage,
              progress: _progress,
            ),
            _DialogStep.done => SaveDoneView(
              itemType: 'sample',
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
              onPressed: () {
                if (_method == _SaveMethod.webUsb) {
                  _startWebUsbSave();
                } else {
                  setState(() => _step = _DialogStep.instructions);
                }
              },
              label: _method == _SaveMethod.webUsb ? 'Send' : 'Next',
            ),
          ],
          _DialogStep.instructions => [
            PlinkyButton(
              onPressed: () =>
                  setState(() => _step = _DialogStep.slotSelection),
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
      ),
    );
  }
}
