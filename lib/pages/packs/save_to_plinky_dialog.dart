import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/preset.dart';
import 'package:plinkyhub/models/saved_pack.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/services/webusb_service.dart';
import 'package:plinkyhub/state/plinky_notifier.dart';
import 'package:plinkyhub/state/plinky_state.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _DialogStep {
  methodSelection,
  instructions,
  progress,
  done,
  error,
}

enum _SaveMethod {
  webUsb,
  tunnelOfLights,
}

class SaveToPlinkyDialog extends ConsumerStatefulWidget {
  const SaveToPlinkyDialog({required this.pack, super.key});

  final SavedPack pack;

  @override
  ConsumerState<SaveToPlinkyDialog> createState() => _SaveToPlinkyDialogState();
}

class _SaveToPlinkyDialogState extends ConsumerState<SaveToPlinkyDialog> {
  _DialogStep _step = _DialogStep.methodSelection;
  _SaveMethod _method = _SaveMethod.webUsb;
  String _statusMessage = '';
  String? _errorMessage;
  double? _progress;

  SupabaseClient get _supabase => Supabase.instance.client;

  bool get _hasPatterns => widget.pack.slots.any((s) => s.patternId != null);

  // ------------------------------------------------------------------
  // WebUSB save
  // ------------------------------------------------------------------

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

      await _sendPackOverWebUsb(notifier);

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

  Future<void> _sendPackOverWebUsb(PlinkyNotifier notifier) async {
    final slots = widget.pack.slots;

    // Collect unique IDs.
    final presetIds = <String>{};
    final sampleIds = <String>{};
    for (final slot in slots) {
      if (slot.presetId != null) {
        presetIds.add(slot.presetId!);
      }
      if (slot.sampleId != null) {
        sampleIds.add(slot.sampleId!);
      }
    }

    // Fetch preset binary data.
    setState(() => _statusMessage = 'Fetching presets...');
    final presetDataMap = <String, Uint8List>{};
    if (presetIds.isNotEmpty) {
      final response = await _supabase
          .from('presets')
          .select('id, preset_data')
          .inFilter('id', presetIds.toList());
      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        presetDataMap[map['id'] as String] = Uint8List.fromList(
          base64Decode(map['preset_data'] as String),
        );
      }
    }

    // Fetch sample metadata.
    setState(() => _statusMessage = 'Fetching sample metadata...');
    final sampleMetadataMap = <String, Map<String, dynamic>>{};
    if (sampleIds.isNotEmpty) {
      final response = await _supabase
          .from('samples')
          .select(
            'id, pcm_file_path, slice_points, slice_notes, pitched',
          )
          .inFilter('id', sampleIds.toList());
      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        sampleMetadataMap[map['id'] as String] = map;
      }
    }

    // Build sample slot mapping (pack slots 56-63 → Plinky 0-7).
    final sampleSlotMapping = <String, int>{};
    for (final slot in slots) {
      if (slot.sampleId != null && slot.slotNumber >= sampleSlotStart) {
        sampleSlotMapping[slot.sampleId!] = slot.slotNumber - sampleSlotStart;
      }
    }

    // Count total work items for progress.
    final totalSteps = sampleSlotMapping.length + presetIds.length + 1;
    var completedSteps = 0;

    // Upload samples via WebUSB (cmd=3 for PCM, cmd=1 for SampleInfo).
    var sampleNumber = 0;
    for (final entry in sampleSlotMapping.entries) {
      final metadata = sampleMetadataMap[entry.key];
      if (metadata == null) {
        continue;
      }

      sampleNumber++;
      final slotIndex = entry.value;
      setState(() {
        _statusMessage =
            'Downloading sample $sampleNumber/${sampleSlotMapping.length}...';
      });

      final pcmBytes = await _supabase.storage
          .from('samples')
          .download(metadata['pcm_file_path'] as String);

      final slicePoints =
          (metadata['slice_points'] as List?)
              ?.map((v) => (v as num).toDouble())
              .toList() ??
          List.of(defaultSlicePoints);
      final sliceNotes =
          (metadata['slice_notes'] as List?)
              ?.map((v) => (v as num).toInt())
              .toList() ??
          List.of(defaultSliceNotes);
      final pitched = metadata['pitched'] as bool? ?? false;

      final sampleInfo = buildSampleInfo(
        pcmData: pcmBytes,
        slicePoints: slicePoints,
        sliceNotes: sliceNotes,
        pitched: pitched,
      );

      setState(() {
        _statusMessage =
            'Sending sample $sampleNumber/${sampleSlotMapping.length}...';
      });

      await notifier.sendSample(
        slotIndex: slotIndex,
        pcmData: pcmBytes,
        sampleInfo: sampleInfo,
        onProgress: (value) {
          if (mounted) {
            setState(() {
              _progress = (completedSteps + value) / totalSteps;
            });
          }
        },
      );

      completedSteps++;
    }

    // Upload wavetable via WebUSB (cmd=5).
    if (widget.pack.wavetableId != null) {
      setState(() => _statusMessage = 'Sending wavetable...');

      final wavetableFilePath = await _fetchFilePath(
        'wavetables',
        widget.pack.wavetableId!,
      );
      final uf2Bytes = await _supabase.storage
          .from('wavetables')
          .download(wavetableFilePath);
      final wavetableData = uf2ToData(uf2Bytes);

      await notifier.sendWavetable(wavetableData: wavetableData);
    }

    // Upload presets via WebUSB (cmd=1 for each preset slot).
    for (final slot in slots) {
      if (slot.slotNumber < presetSlotStart ||
          slot.slotNumber >= patternSlotStart) {
        continue;
      }
      if (slot.presetId == null) {
        continue;
      }
      final originalBytes = presetDataMap[slot.presetId];
      if (originalBytes == null) {
        continue;
      }

      final presetBytes = Uint8List.fromList(originalBytes);

      // Remap P_SAMPLE to the device slot.
      final preset = Preset(presetBytes.buffer);
      if (preset.usesSample) {
        final presetRaw = preset.parameterById('P_SAMPLE')?.value;
        if (presetRaw != null && presetRaw != 0) {
          final originalSlot = rawToSampleSlot(presetRaw);
          for (final entry in sampleSlotMapping.entries) {
            if (entry.value == originalSlot) {
              setPresetSampleSlot(presetBytes, entry.value);
              break;
            }
          }
        }
      }

      final presetIndex = slot.slotNumber - presetSlotStart;
      setState(() {
        _statusMessage = 'Sending preset ${presetIndex + 1}...';
      });

      notifier.presetNumber = presetIndex;
      notifier.loadPresetFromBytes(presetBytes);
      await notifier.savePreset();

      completedSteps++;
      setState(() => _progress = completedSteps / totalSteps);
    }
  }

  // ------------------------------------------------------------------
  // Tunnel of Lights save
  // ------------------------------------------------------------------

  Future<void> _startTunnelOfLightsSave() async {
    final directory = await showDirectoryPicker(readwrite: true);
    if (directory == null) {
      return;
    }

    setState(() {
      _step = _DialogStep.progress;
      _statusMessage = 'Fetching preset data...';
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
    final slots = widget.pack.slots;

    // Collect unique IDs from the pack slots by range.
    final presetIds = <String>{};
    final sampleIds = <String>{};
    for (final slot in slots) {
      if (slot.presetId != null) {
        presetIds.add(slot.presetId!);
      }
      if (slot.sampleId != null) {
        sampleIds.add(slot.sampleId!);
      }
    }

    // Fetch presets from the database.
    setState(() => _statusMessage = 'Fetching presets...');
    final presetDataMap = <String, Uint8List>{};
    if (presetIds.isNotEmpty) {
      final response = await _supabase
          .from('presets')
          .select('id, preset_data')
          .inFilter('id', presetIds.toList());
      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        final id = map['id'] as String;
        final presetData = map['preset_data'] as String;
        presetDataMap[id] = Uint8List.fromList(base64Decode(presetData));
      }
    }

    // Fetch sample metadata from the database.
    setState(() => _statusMessage = 'Fetching sample metadata...');
    final sampleMetadataMap = <String, Map<String, dynamic>>{};
    if (sampleIds.isNotEmpty) {
      final response = await _supabase
          .from('samples')
          .select(
            'id, pcm_file_path, slice_points, slice_notes, '
            'pitched, base_note, fine_tune',
          )
          .inFilter('id', sampleIds.toList());
      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        sampleMetadataMap[map['id'] as String] = map;
      }
    }

    // Build sample slot mapping from pack slots (56-63 → Plinky 0-7).
    final sampleSlotMapping = <String, int>{};
    for (final slot in slots) {
      if (slot.sampleId != null && slot.slotNumber >= sampleSlotStart) {
        final plinkySlot = slot.slotNumber - sampleSlotStart;
        sampleSlotMapping[slot.sampleId!] = plinkySlot;
      }
    }
    if (sampleSlotMapping.length > sampleCount) {
      throw Exception(
        'Pack has ${sampleSlotMapping.length} samples, '
        'but Plinky only supports $sampleCount.',
      );
    }

    // Download sample PCM files and build SampleInfo structs.
    final sampleInfos = List<Uint8List?>.filled(sampleCount, null);
    final samplePcmData = <int, Uint8List>{};
    var tunnelSampleNumber = 0;
    for (final entry in sampleSlotMapping.entries) {
      final sampleId = entry.key;
      final slotIndex = entry.value;
      final metadata = sampleMetadataMap[sampleId];
      if (metadata == null) {
        continue;
      }

      tunnelSampleNumber++;
      setState(() {
        _statusMessage =
            'Downloading sample $tunnelSampleNumber/${sampleSlotMapping.length}...';
      });

      final pcmFilePath = metadata['pcm_file_path'] as String;
      final pcmBytes = await _supabase.storage
          .from('samples')
          .download(pcmFilePath);

      samplePcmData[slotIndex] = pcmBytes;

      final slicePoints =
          (metadata['slice_points'] as List?)
              ?.map((value) => (value as num).toDouble())
              .toList() ??
          List.of(defaultSlicePoints);
      final sliceNotes =
          (metadata['slice_notes'] as List?)
              ?.map((value) => (value as num).toInt())
              .toList() ??
          List.of(defaultSliceNotes);
      final pitched = metadata['pitched'] as bool? ?? false;

      sampleInfos[slotIndex] = buildSampleInfo(
        pcmData: pcmBytes,
        slicePoints: slicePoints,
        sliceNotes: sliceNotes,
        pitched: pitched,
      );
    }

    // Build the 32 preset entries, remapping P_SAMPLE for each.
    setState(() => _statusMessage = 'Generating PRESETS.UF2...');
    final presets = List<Uint8List?>.filled(presetCount, null);
    for (final slot in slots) {
      if (slot.slotNumber < presetSlotStart ||
          slot.slotNumber >= patternSlotStart) {
        continue;
      }
      if (slot.presetId == null) {
        continue;
      }
      final originalPresetBytes = presetDataMap[slot.presetId];
      if (originalPresetBytes == null) {
        continue;
      }

      // Clone the preset bytes so we can modify P_SAMPLE.
      final presetBytes = Uint8List.fromList(originalPresetBytes);

      // Remap P_SAMPLE to the target slot for this device.
      final preset = Preset(presetBytes.buffer);
      if (preset.usesSample) {
        final presetRaw = preset.parameterById('P_SAMPLE')?.value;
        if (presetRaw != null && presetRaw != 0) {
          final originalSlot = rawToSampleSlot(presetRaw);
          for (final entry in sampleSlotMapping.entries) {
            if (entry.value == originalSlot) {
              setPresetSampleSlot(presetBytes, entry.value);
              break;
            }
          }
        }
      }

      presets[slot.slotNumber - presetSlotStart] = presetBytes;
    }

    // Fetch pattern quarter data from slots (32-55).
    List<Uint8List?>? patternQuarters;
    final patternSlots = slots
        .where(
          (slot) =>
              slot.patternId != null &&
              slot.slotNumber >= patternSlotStart &&
              slot.slotNumber < sampleSlotStart,
        )
        .toList();
    if (patternSlots.isNotEmpty) {
      setState(() => _statusMessage = 'Fetching patterns...');
      patternQuarters = List<Uint8List?>.filled(
        patternCount * 4,
        null,
      );
      for (final slot in patternSlots) {
        final patternFilePath = await _fetchFilePath(
          'patterns',
          slot.patternId!,
        );
        final patternBlob = await _supabase.storage
            .from('patterns')
            .download(patternFilePath);
        final quarters = deserializePatternQuarters(patternBlob);
        // Place this pattern's quarters at its Plinky index.
        final patternIndex = slot.slotNumber - patternSlotStart;
        final baseIndex = patternIndex * 4;
        for (var q = 0; q < 4; q++) {
          if (baseIndex + q < patternQuarters.length &&
              baseIndex + q < quarters.length) {
            patternQuarters[baseIndex + q] = quarters[baseIndex + q];
          }
        }
      }
    }

    // Generate PRESETS.UF2 (includes presets, samples, and patterns).
    final presetsUf2 = generatePresetsUf2(
      presets: presets,
      sampleInfos: sampleInfos,
      patternQuarters: patternQuarters,
    );

    // Write PRESETS.UF2 to the selected directory.
    setState(() => _statusMessage = 'Writing PRESETS.UF2...');
    await writeFileToDirectory(directory, 'PRESETS.UF2', presetsUf2);

    // Generate and write SAMPLE*.UF2 files for all 8 slots.
    for (var slotIndex = 0; slotIndex < sampleCount; slotIndex++) {
      setState(() {
        _statusMessage = 'Writing SAMPLE$slotIndex.UF2...';
      });

      final pcmBytes = samplePcmData[slotIndex] ?? Uint8List(0);
      final sampleUf2Bytes = sampleToUf2(
        pcmBytes,
        slotIndex: slotIndex,
      );
      await writeFileToDirectory(
        directory,
        'SAMPLE$slotIndex.UF2',
        sampleUf2Bytes,
      );
    }

    // Write WAVETAB.UF2 if the pack has one.
    if (widget.pack.wavetableId != null) {
      setState(() {
        _statusMessage = 'Writing WAVETAB.UF2...';
      });

      final wavetableFilePath = await _fetchFilePath(
        'wavetables',
        widget.pack.wavetableId!,
      );
      final wavetableBytes = await _supabase.storage
          .from('wavetables')
          .download(wavetableFilePath);
      await writeFileToDirectory(
        directory,
        'WAVETAB.UF2',
        wavetableBytes,
      );
    }
  }

  Future<String> _fetchFilePath(
    String table,
    String id,
  ) async {
    final response = await _supabase
        .from(table)
        .select('file_path')
        .eq('id', id)
        .single();
    return response['file_path'] as String;
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: switch (_step) {
        _DialogStep.methodSelection ||
        _DialogStep.instructions => const Text('Save to Plinky'),
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
          _DialogStep.methodSelection => TransferMethodSelection(
            itemType: 'pack',
            webUsbNote: _hasPatterns
                ? 'Note: Patterns cannot be transferred over WebUSB '
                      'and will be skipped.'
                : null,
          ),
          _DialogStep.instructions => const TunnelOfLightsInstructions(
            itemType: 'pack',
          ),
          _DialogStep.progress => SaveProgressView(
            statusMessage: _statusMessage,
            progress: _progress,
          ),
          _DialogStep.done => SaveDoneView(
            itemType: 'pack',
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
                _startWebUsbSave();
              },
              icon: Icons.usb,
              label: 'Send via USB',
            ),
          PlinkyButton(
            onPressed: () {
              _method = _SaveMethod.tunnelOfLights;
              setState(() => _step = _DialogStep.instructions);
            },
            icon: Icons.folder_open,
            label: 'Tunnel of Lights',
          ),
        ],
        _DialogStep.instructions => [
          PlinkyButton(
            onPressed: () =>
                setState(() => _step = _DialogStep.methodSelection),
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
