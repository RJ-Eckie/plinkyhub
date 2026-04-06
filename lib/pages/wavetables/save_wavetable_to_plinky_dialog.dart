import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_wavetable.dart';
import 'package:plinkyhub/services/webusb_service.dart';
import 'package:plinkyhub/state/plinky_notifier.dart';
import 'package:plinkyhub/state/plinky_state.dart';
import 'package:plinkyhub/state/saved_wavetables_notifier.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';

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
  _DialogStep _step = _DialogStep.methodSelection;
  _SaveMethod _method = _SaveMethod.webUsb;
  String _statusMessage = '';
  String? _errorMessage;
  double? _progress;

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

      setState(() => _statusMessage = 'Downloading wavetable...');
      final uf2Bytes = await ref
          .read(savedWavetablesProvider.notifier)
          .downloadUf2(widget.wavetable.filePath);

      setState(() => _statusMessage = 'Extracting wavetable data...');
      final wavetableData = uf2ToData(uf2Bytes);

      setState(() => _statusMessage = 'Sending wavetable to Plinky...');
      await notifier.sendWavetable(
        wavetableData: wavetableData,
        onProgress: (value) {
          if (mounted) {
            setState(() => _progress = value);
          }
        },
      );

      if (mounted) {
        setState(() {
          _statusMessage = 'Verifying wavetable...';
          _progress = null;
        });
      }
      final verified = await notifier.verifyWavetable(wavetableData);

      if (mounted) {
        if (verified) {
          setState(() => _step = _DialogStep.done);
        } else {
          setState(() {
            _step = _DialogStep.error;
            _errorMessage =
                'Wavetable verification failed — the data on the device '
                'does not match what was sent. Check the browser console '
                'for details.';
          });
        }
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
      _statusMessage = 'Downloading wavetable...';
      _progress = null;
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
    return AlertDialog(
      title: switch (_step) {
        _DialogStep.methodSelection => const Text('Save to Plinky'),
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
          _DialogStep.methodSelection => const TransferMethodSelection(
            itemType: 'wavetable',
          ),
          _DialogStep.instructions => const TunnelOfLightsInstructions(
            itemType: 'wavetable',
          ),
          _DialogStep.progress => SaveProgressView(
            statusMessage: _statusMessage,
            progress: _progress,
          ),
          _DialogStep.done => SaveDoneView(
            itemType: 'wavetable',
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
