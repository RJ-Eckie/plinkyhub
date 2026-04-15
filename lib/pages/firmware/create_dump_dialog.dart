import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/state/dumps_notifier.dart';
import 'package:plinkyhub/state/plinky_notifier.dart';
import 'package:plinkyhub/state/plinky_state.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

enum _CreateDumpStep {
  form,
  reading,
  uploading,
  done,
  error,
}

class CreateDumpDialog extends ConsumerStatefulWidget {
  const CreateDumpDialog({super.key});

  @override
  ConsumerState<CreateDumpDialog> createState() => _CreateDumpDialogState();
}

class _CreateDumpDialogState extends ConsumerState<CreateDumpDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  _CreateDumpStep _step = _CreateDumpStep.form;
  String _statusMessage = '';
  double _progress = 0;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _startDump() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    setState(() {
      _step = _CreateDumpStep.reading;
      _statusMessage = 'Connecting to Plinky...';
      _progress = 0;
      _errorMessage = null;
    });

    final plinkyNotifier = ref.read(plinkyProvider.notifier);
    final plinkyState = ref.read(plinkyProvider);

    try {
      if (plinkyState.connectionState == PlinkyConnectionState.disconnected ||
          plinkyState.connectionState == PlinkyConnectionState.error) {
        await plinkyNotifier.connect();
      }
      final afterConnect = ref.read(plinkyProvider);
      if (afterConnect.connectionState != PlinkyConnectionState.connected) {
        throw Exception(
          afterConnect.errorMessage ?? 'Failed to connect to Plinky',
        );
      }

      setState(() {
        _statusMessage = 'Reading internal flash (1 MB)...';
        _progress = 0;
      });
      final internalBytes = await plinkyNotifier.readFlashDump(
        flashIndex: flashDumpInternalIndex,
        onProgress: (value) {
          if (!mounted) {
            return;
          }
          // Internal flash counts for roughly 1/33 of total work.
          setState(() {
            _progress = value * (1 / 33);
          });
        },
      );

      setState(() {
        _statusMessage = 'Reading external flash (32 MB)...';
        _progress = 1 / 33;
      });
      final externalBytes = await plinkyNotifier.readFlashDump(
        flashIndex: flashDumpExternalIndex,
        onProgress: (value) {
          if (!mounted) {
            return;
          }
          setState(() {
            _progress = (1 / 33) + value * (32 / 33);
          });
        },
      );

      setState(() {
        _step = _CreateDumpStep.uploading;
        _statusMessage = 'Uploading dump to your account...';
        _progress = 0;
      });

      await ref
          .read(dumpsProvider.notifier)
          .uploadDump(
            title: title,
            description: _descriptionController.text.trim(),
            internalFlashBytes: internalBytes,
            externalFlashBytes: externalBytes,
          );

      if (!mounted) {
        return;
      }
      setState(() {
        _step = _CreateDumpStep.done;
      });
    } on Object catch (error) {
      debugPrint('Dump failed: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _step = _CreateDumpStep.error;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(switch (_step) {
        _CreateDumpStep.form => 'Create flash dump',
        _CreateDumpStep.reading => 'Reading flash...',
        _CreateDumpStep.uploading => 'Uploading dump...',
        _CreateDumpStep.done => 'Dump saved',
        _CreateDumpStep.error => 'Error',
      }),
      content: SizedBox(
        width: 460,
        child: switch (_step) {
          _CreateDumpStep.form => _DumpFormView(
            titleController: _titleController,
            descriptionController: _descriptionController,
            onChanged: () => setState(() {}),
          ),
          _CreateDumpStep.reading => _DumpProgressView(
            statusMessage: _statusMessage,
            progress: _progress,
          ),
          _CreateDumpStep.uploading => _DumpProgressView(
            statusMessage: _statusMessage,
            progress: null,
          ),
          _CreateDumpStep.done => const Text(
            'Your flash dump has been saved. '
            'You can download the binaries any time from the Dump tab.',
          ),
          _CreateDumpStep.error => Text(
            _errorMessage ?? 'An unknown error occurred.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        },
      ),
      actions: switch (_step) {
        _CreateDumpStep.form => [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Cancel',
          ),
          PlinkyButton(
            onPressed: _titleController.text.trim().isEmpty ? null : _startDump,
            icon: Icons.usb,
            label: 'Connect & dump',
          ),
        ],
        _CreateDumpStep.reading || _CreateDumpStep.uploading => const [],
        _CreateDumpStep.done || _CreateDumpStep.error => [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Close',
          ),
        ],
      },
    );
  }
}

class _DumpFormView extends StatelessWidget {
  const _DumpFormView({
    required this.titleController,
    required this.descriptionController,
    required this.onChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Give this dump a title so you can find it later. '
          "We'll read both the internal and external flash from your "
          'Plinky. The external flash is 32 MB and can take a '
          'few minutes to transfer.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            border: OutlineInputBorder(),
          ),
          minLines: 3,
          maxLines: null,
        ),
      ],
    );
  }
}

class _DumpProgressView extends StatelessWidget {
  const _DumpProgressView({
    required this.statusMessage,
    required this.progress,
  });

  final String statusMessage;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final percentText = progress == null
        ? ''
        : ' (${(progress! * 100).toStringAsFixed(0)}%)';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$statusMessage$percentText'),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}
