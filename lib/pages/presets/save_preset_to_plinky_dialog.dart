import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_preset.dart';
import 'package:plinkyhub/services/webusb_service.dart';
import 'package:plinkyhub/state/plinky_notifier.dart';
import 'package:plinkyhub/state/plinky_state.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/plinky_save_dialog_views.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

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
  String _statusMessage = '';
  String? _errorMessage;

  Future<void> _startWebUsbSave() async {
    setState(() {
      _step = _DialogStep.progress;
      _statusMessage = 'Connecting to Plinky...';
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

      setState(() => _statusMessage = 'Sending preset to Plinky...');
      final presetData = Uint8List.fromList(
        base64Decode(widget.preset.presetData),
      );

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
          _DialogStep.methodSelection => const Text('Save preset to Plinky'),
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
            _DialogStep.methodSelection => const _MethodSelectionView(),
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

class _MethodSelectionView extends StatelessWidget {
  const _MethodSelectionView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose how to save the preset to your Plinky:'),
        const SizedBox(height: 16),
        if (WebUsbService.isSupported) ...[
          const _MethodOption(
            icon: Icons.usb,
            title: 'Send via USB',
            description:
                'Send directly over WebUSB while Plinky is running '
                'normally. No need for Tunnel of Lights mode.',
          ),
          const SizedBox(height: 12),
        ],
        const _MethodOption(
          icon: Icons.folder_open,
          title: 'Tunnel of Lights',
          description:
              'Write UF2 files to the Plinky drive. Requires putting '
              'Plinky into Tunnel of Lights mode first.',
        ),
      ],
    );
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
