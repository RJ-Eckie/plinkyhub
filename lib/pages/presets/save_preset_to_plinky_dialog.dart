import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_preset.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

enum _DialogStep {
  slotSelection,
  instructions,
  progress,
  done,
  error,
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
  _DialogStep _step = _DialogStep.slotSelection;
  int _selectedSlot = 0;
  String _statusMessage = '';
  String? _errorMessage;

  Future<void> _startSave() async {
    final directory = await showDirectoryPicker(readwrite: true);
    if (directory == null) {
      return;
    }

    setState(() {
      _step = _DialogStep.progress;
      _statusMessage = 'Generating PRESETS.UF2...';
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

    presets[_selectedSlot] = Uint8List.fromList(
      base64Decode(widget.preset.presetData),
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
        _DialogStep.slotSelection => const Text('Save preset to Plinky'),
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
          _DialogStep.slotSelection => _SlotSelectionView(
            selectedSlot: _selectedSlot,
            onSlotChanged: (slot) => setState(() => _selectedSlot = slot),
          ),
          _DialogStep.instructions => const TunnelOfLightsInstructions(
            itemType: 'preset',
          ),
          _DialogStep.progress => SaveProgressView(
            statusMessage: _statusMessage,
          ),
          _DialogStep.done => const SaveDoneView(itemType: 'preset'),
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
            onPressed: () => setState(() => _step = _DialogStep.instructions),
            label: 'Next',
          ),
        ],
        _DialogStep.instructions => [
          PlinkyButton(
            onPressed: () => setState(() => _step = _DialogStep.slotSelection),
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
    ),
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
        const Text('Select the preset slot on your Plinky:'),
        const SizedBox(height: 12),
        for (var row = 0; row < 8; row++)
          Row(
            children: [
              for (var col = 0; col < 4; col++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: col < 3 ? 8 : 0,
                      bottom: row < 7 ? 8 : 0,
                    ),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          '${row * 4 + col + 1}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      selected: selectedSlot == row * 4 + col,
                      showCheckmark: false,
                      onSelected: (_) => onSlotChanged(row * 4 + col),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        Text(
          'Note: This will overwrite the existing preset in slot '
          '${selectedSlot + 1} on your Plinky.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
