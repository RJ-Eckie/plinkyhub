import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _DialogStep {
  slotSelection,
  instructions,
  progress,
  done,
  error,
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
  _DialogStep _step = _DialogStep.slotSelection;
  int _selectedSlot = 0;
  String _statusMessage = '';
  String? _errorMessage;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _startSave() async {
    final directory = await showDirectoryPicker(readwrite: true);
    if (directory == null) {
      return;
    }

    setState(() {
      _step = _DialogStep.progress;
      _statusMessage = 'Downloading sample data...';
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

    // Generate and write PRESETS.UF2 with updated SampleInfo for this slot.
    setState(() => _statusMessage = 'Generating PRESETS.UF2...');
    final sampleInfos = List<Uint8List?>.filled(sampleCount, null);
    sampleInfos[_selectedSlot] = buildSampleInfo(
      pcmData: pcmBytes,
      slicePoints: sample.slicePoints,
      sliceNotes: sample.sliceNotes,
      pitched: sample.pitched,
    );

    final presetsUf2 = generatePresetsUf2(
      presets: List<Uint8List?>.filled(presetCount, null),
      sampleInfos: sampleInfos,
    );

    setState(() => _statusMessage = 'Writing PRESETS.UF2...');
    await writeFileToDirectory(directory, 'PRESETS.UF2', presetsUf2);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        switch (_step) {
          _DialogStep.slotSelection => 'Save sample to Plinky',
          _DialogStep.instructions => 'Save sample to Plinky',
          _DialogStep.progress => 'Saving...',
          _DialogStep.done => 'Done',
          _DialogStep.error => 'Error',
        },
      ),
      content: SizedBox(
        width: 400,
        child: switch (_step) {
          _DialogStep.slotSelection => _SlotSelectionView(
              selectedSlot: _selectedSlot,
              onSlotChanged: (slot) => setState(() => _selectedSlot = slot),
            ),
          _DialogStep.instructions => const TunnelOfLightsInstructions(
              itemType: 'sample',
            ),
          _DialogStep.progress => SaveProgressView(
              statusMessage: _statusMessage,
            ),
          _DialogStep.done => const SaveDoneView(itemType: 'sample'),
          _DialogStep.error => SaveErrorView(errorMessage: _errorMessage),
        },
      ),
      actions: switch (_step) {
        _DialogStep.slotSelection => [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Cancel',
          ),
          PlinkyButton(
            onPressed: () =>
                setState(() => _step = _DialogStep.instructions),
            label: 'Next',
          ),
        ],
        _DialogStep.instructions => [
          PlinkyButton(
            onPressed: () =>
                setState(() => _step = _DialogStep.slotSelection),
            label: 'Back',
          ),
          PlinkyButton(
            onPressed: _startSave,
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

class _SlotSelectionView extends StatelessWidget {
  const _SlotSelectionView({
    required this.selectedSlot,
    required this.onSlotChanged,
  });

  final int selectedSlot;
  final ValueChanged<int> onSlotChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select the sample slot on your Plinky:'),
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
        Text(
          'Note: All presets on your Plinky that use sample slot '
          '${selectedSlot + 1} will use this sample after saving.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
