import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/preset.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _DialogStep { confirm, progress, done, error }

class SaveMyPlinkyDialog extends ConsumerStatefulWidget {
  const SaveMyPlinkyDialog({
    required this.directory,
    required this.slots,
    required this.patternIds,
    required this.wavetableId,
    required this.parsedFlashImage,
    super.key,
  });

  final FileSystemDirectoryHandle directory;
  final List<({String? presetId, String? sampleId, String? patternId})> slots;
  final Map<int, String?> patternIds;
  final String? wavetableId;
  final ParsedFlashImage parsedFlashImage;

  @override
  ConsumerState<SaveMyPlinkyDialog> createState() => _SaveMyPlinkyDialogState();
}

class _SaveMyPlinkyDialogState extends ConsumerState<SaveMyPlinkyDialog> {
  _DialogStep _step = _DialogStep.confirm;
  String _statusMessage = '';
  String? _errorMessage;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _startSave() async {
    setState(() {
      _step = _DialogStep.progress;
      _statusMessage = 'Preparing...';
    });

    try {
      await _generateAndWriteFiles();
      setState(() => _step = _DialogStep.done);
    } on Exception catch (error) {
      setState(() {
        _step = _DialogStep.error;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _generateAndWriteFiles() async {
    final existing = widget.parsedFlashImage;

    // Start with existing device data.
    final presets = List<Uint8List?>.of(existing.presets);
    final sampleInfos = List<Uint8List?>.of(existing.rawSampleInfos);
    final patternQuarters = List<Uint8List?>.of(existing.patternQuarters);

    // Collect linked preset and sample IDs.
    final linkedPresetIds = <String>{};
    final linkedSampleIds = <String>{};
    for (final slot in widget.slots) {
      if (slot.presetId != null) {
        linkedPresetIds.add(slot.presetId!);
      }
      if (slot.sampleId != null) {
        linkedSampleIds.add(slot.sampleId!);
      }
    }

    // Fetch linked presets from DB.
    final presetDataMap = <String, Uint8List>{};
    if (linkedPresetIds.isNotEmpty) {
      setState(() => _statusMessage = 'Fetching presets...');
      final response = await _supabase
          .from('presets')
          .select('id, preset_data')
          .inFilter('id', linkedPresetIds.toList());
      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        presetDataMap[map['id'] as String] = Uint8List.fromList(
          base64Decode(map['preset_data'] as String),
        );
      }
    }

    // Fetch sample metadata.
    final sampleMetadataMap = <String, Map<String, dynamic>>{};
    if (linkedSampleIds.isNotEmpty) {
      setState(() => _statusMessage = 'Fetching sample metadata...');
      final response = await _supabase
          .from('samples')
          .select(
            'id, pcm_file_path, slice_points, slice_notes, '
            'pitched, base_note, fine_tune',
          )
          .inFilter('id', linkedSampleIds.toList());
      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        sampleMetadataMap[map['id'] as String] = map;
      }
    }

    // Build sample slot mapping from linked samples in preset slots.
    final sampleSlotMapping = <String, int>{};
    final seenSampleIds = <String>{};
    var nextSampleSlot = 0;
    for (var i = 0; i < 32; i++) {
      final sampleId = widget.slots[i].sampleId;
      if (sampleId != null && seenSampleIds.add(sampleId)) {
        sampleSlotMapping[sampleId] = nextSampleSlot;
        nextSampleSlot++;
      }
    }

    // Download sample PCM and build SampleInfo structs.
    final samplePcmData = <int, Uint8List>{};
    var sampleProgress = 0;
    for (final entry in sampleSlotMapping.entries) {
      final sampleId = entry.key;
      final slotIndex = entry.value;
      final metadata = sampleMetadataMap[sampleId];
      if (metadata == null) {
        continue;
      }

      sampleProgress++;
      setState(() {
        _statusMessage =
            'Downloading sample $sampleProgress/${sampleSlotMapping.length}...';
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

    // Overwrite linked preset slots with saved preset data.
    setState(() => _statusMessage = 'Generating PRESETS.UF2...');
    for (var i = 0; i < 32; i++) {
      final presetId = widget.slots[i].presetId;
      if (presetId == null) {
        continue;
      }
      final originalPresetBytes = presetDataMap[presetId];
      if (originalPresetBytes == null) {
        continue;
      }

      final presetBytes = Uint8List.fromList(originalPresetBytes);
      final preset = Preset(presetBytes.buffer);
      if (preset.usesSample) {
        final sampleId = widget.slots[i].sampleId;
        if (sampleId != null) {
          final firmwareSlot = sampleSlotMapping[sampleId];
          if (firmwareSlot != null) {
            setPresetSampleSlot(presetBytes, firmwareSlot);
          }
        }
      }

      presets[i] = presetBytes;
    }

    // Overwrite linked pattern quarters.
    final linkedPatternIds = widget.patternIds.entries
        .where((entry) => entry.value != null)
        .toList();
    if (linkedPatternIds.isNotEmpty) {
      setState(() => _statusMessage = 'Fetching patterns...');
      for (final entry in linkedPatternIds) {
        final patternIndex = entry.key;
        final patternId = entry.value!;
        final patternFilePath = await _fetchFilePath(
          'patterns',
          patternId,
        );
        final patternBlob = await _supabase.storage
            .from('patterns')
            .download(patternFilePath);
        final quarters = deserializePatternQuarters(patternBlob);
        final baseIndex = patternIndex * 4;
        for (var q = 0; q < 4; q++) {
          if (baseIndex + q < patternQuarters.length && q < quarters.length) {
            patternQuarters[baseIndex + q] = quarters[q];
          }
        }
      }
    }

    // Generate and write PRESETS.UF2.
    final presetsUf2 = generatePresetsUf2(
      presets: presets,
      sampleInfos: sampleInfos,
      patternQuarters: patternQuarters,
    );

    setState(() => _statusMessage = 'Writing PRESETS.UF2...');
    await writeFileToDirectory(
      widget.directory,
      'PRESETS.UF2',
      presetsUf2,
    );

    // Write SAMPLE*.UF2 files for all 8 slots.
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
        widget.directory,
        'SAMPLE$slotIndex.UF2',
        sampleUf2Bytes,
      );
    }

    // Write WAVETAB.UF2 if linked.
    if (widget.wavetableId != null) {
      setState(() => _statusMessage = 'Writing WAVETAB.UF2...');
      final wavetableFilePath = await _fetchFilePath(
        'wavetables',
        widget.wavetableId!,
      );
      final wavetableBytes = await _supabase.storage
          .from('wavetables')
          .download(wavetableFilePath);
      await writeFileToDirectory(
        widget.directory,
        'WAVETAB.UF2',
        wavetableBytes,
      );
    }
  }

  Future<String> _fetchFilePath(String table, String id) async {
    final response = await _supabase
        .from(table)
        .select('file_path')
        .eq('id', id)
        .single();
    return response['file_path'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        switch (_step) {
          _DialogStep.confirm => 'Save to Plinky',
          _DialogStep.progress => 'Uploading to Plinky...',
          _DialogStep.done => 'Done',
          _DialogStep.error => 'Error',
        },
      ),
      content: SizedBox(
        width: 400,
        child: switch (_step) {
          _DialogStep.confirm => const Text(
            'This will write your linked presets, samples, patterns, '
            'and wavetable to the connected Plinky. '
            'Unlinked slots will be preserved as-is.',
          ),
          _DialogStep.progress => SaveProgressView(
            statusMessage: _statusMessage,
          ),
          _DialogStep.done => const SaveDoneView(itemType: 'changes'),
          _DialogStep.error => SaveErrorView(errorMessage: _errorMessage),
        },
      ),
      actions: switch (_step) {
        _DialogStep.confirm => [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Cancel',
          ),
          PlinkyButton(
            onPressed: _startSave,
            icon: Icons.save,
            label: 'Save',
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
