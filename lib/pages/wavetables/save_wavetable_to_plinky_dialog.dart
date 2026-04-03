import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_wavetable.dart';
import 'package:plinkyhub/state/saved_wavetables_notifier.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

enum _DialogStep {
  instructions,
  progress,
  done,
  error,
}

class SaveWavetableToPlinkyDialog extends ConsumerStatefulWidget {
  const SaveWavetableToPlinkyDialog({
    required this.wavetable,
    super.key,
  });

  final SavedWavetable wavetable;

  @override
  ConsumerState<SaveWavetableToPlinkyDialog> createState() =>
      _SaveWavetableToPlinkyDialogState();
}

class _SaveWavetableToPlinkyDialogState
    extends ConsumerState<SaveWavetableToPlinkyDialog> {
  _DialogStep _step = _DialogStep.instructions;
  String _statusMessage = '';
  String? _errorMessage;

  Future<void> _startSave() async {
    final directory = await showDirectoryPicker(readwrite: true);
    if (directory == null) {
      return;
    }

    setState(() {
      _step = _DialogStep.progress;
      _statusMessage = 'Downloading wavetable...';
    });

    try {
      final uf2Bytes = await ref
          .read(savedWavetablesProvider.notifier)
          .downloadUf2(widget.wavetable.filePath);

      setState(() {
        _statusMessage = 'Writing WAVETAB.UF2...';
      });
      await writeFileToDirectory(directory, 'WAVETAB.UF2', uf2Bytes);

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
    return PointerInterceptor(
      child: AlertDialog(
      title: switch (_step) {
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
          _DialogStep.instructions => const TunnelOfLightsInstructions(
            itemType: 'wavetable',
          ),
          _DialogStep.progress => SaveProgressView(
            statusMessage: _statusMessage,
          ),
          _DialogStep.done => const SaveDoneView(itemType: 'wavetable'),
          _DialogStep.error => SaveErrorView(errorMessage: _errorMessage),
        },
      ),
      actions: switch (_step) {
        _DialogStep.instructions => [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Cancel',
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
