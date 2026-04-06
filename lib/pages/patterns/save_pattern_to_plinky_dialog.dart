import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_pattern.dart';
import 'package:plinkyhub/state/saved_patterns_notifier.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';

enum _DialogStep {
  slotSelection,
  instructions,
  progress,
  done,
  error,
}

class SavePatternToPlinkyDialog extends ConsumerStatefulWidget {
  const SavePatternToPlinkyDialog({required this.pattern, super.key});

  final SavedPattern pattern;

  @override
  ConsumerState<SavePatternToPlinkyDialog> createState() =>
      _SavePatternToPlinkyDialogState();
}

class _SavePatternToPlinkyDialogState
    extends ConsumerState<SavePatternToPlinkyDialog> {
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
      _statusMessage = 'Downloading pattern...';
    });

    try {
      final patternBlob = await ref
          .read(savedPatternsProvider.notifier)
          .downloadFile(widget.pattern.filePath);

      setState(() => _statusMessage = 'Preparing pattern data...');
      final quarters = deserializePatternQuarters(patternBlob);

      final patternQuarters = List<Uint8List?>.filled(patternCount * 4, null);
      final baseIndex = _selectedSlot * 4;
      for (var quarter = 0; quarter < 4; quarter++) {
        if (baseIndex + quarter < patternQuarters.length &&
            baseIndex + quarter < quarters.length) {
          patternQuarters[baseIndex + quarter] = quarters[baseIndex + quarter];
        }
      }

      final presetsUf2 = generatePresetsUf2(
        presets: List<Uint8List?>.filled(presetCount, null),
        sampleInfos: List<Uint8List?>.filled(sampleCount, null),
        patternQuarters: patternQuarters,
      );

      setState(() => _statusMessage = 'Writing PRESETS.UF2...');
      await writeFileToDirectory(directory, 'PRESETS.UF2', presetsUf2);

      setState(() => _step = _DialogStep.done);
    } on Exception catch (error) {
      setState(() {
        _step = _DialogStep.error;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: switch (_step) {
        _DialogStep.slotSelection ||
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
          _DialogStep.slotSelection => SlotSelectionGrid(
            itemType: 'pattern',
            slotCount: patternCount,
            columns: 3,
            selectedSlot: _selectedSlot,
            onSlotChanged: (slot) => setState(() => _selectedSlot = slot),
            displayOffset: 33,
          ),
          _DialogStep.instructions => const TunnelOfLightsInstructions(
            itemType: 'pattern',
          ),
          _DialogStep.progress => SaveProgressView(
            statusMessage: _statusMessage,
          ),
          _DialogStep.done => const SaveDoneView(
            itemType: 'pattern',
          ),
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
            icon: Icons.arrow_forward,
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
    );
  }
}
