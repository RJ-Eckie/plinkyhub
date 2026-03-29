import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_wavetable.dart';
import 'package:plinkyhub/pages/wavetables/waveform_drawer.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_wavetables_notifier.dart';
import 'package:plinkyhub/utils/wavetable.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

/// Tab for creating wavetables by drawing waveforms directly in the browser.
class DrawWavetableTab extends ConsumerStatefulWidget {
  const DrawWavetableTab({this.onCreated, super.key});

  final VoidCallback? onCreated;

  @override
  ConsumerState<DrawWavetableTab> createState() => _DrawWavetableTabState();
}

class _DrawWavetableTabState extends ConsumerState<DrawWavetableTab> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  bool _isGenerating = false;
  bool _isUploading = false;
  String? _errorMessage;

  int _selectedSlot = 0;

  /// The 15 waveform slots, each containing [waveformDrawerSampleCount]
  /// samples initialised to a sine wave.
  late final List<List<double>> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List<List<double>>.generate(
      wavetableUserShapeCount,
      (_) => generateSinePreset(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isBusy => _isGenerating || _isUploading;

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _isPublic = true;
      _isGenerating = false;
      _isUploading = false;
      _errorMessage = null;
      _selectedSlot = 0;
      for (var i = 0; i < _slots.length; i++) {
        _slots[i] = generateSinePreset();
      }
    });
  }

  void _applyPresetToSlot(List<double> Function() generator) {
    setState(() {
      _slots[_selectedSlot] = generator();
    });
  }

  void _applyPresetToAll(List<double> Function() generator) {
    setState(() {
      for (var i = 0; i < _slots.length; i++) {
        _slots[i] = generator();
      }
    });
  }

  void _copyToAllSlots() {
    final source = List<double>.from(_slots[_selectedSlot]);
    setState(() {
      for (var i = 0; i < _slots.length; i++) {
        _slots[i] = List<double>.from(source);
      }
    });
  }

  Future<void> _createAndUpload() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (userId == null) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      await Future<void>.delayed(Duration.zero);

      final uf2Bytes = generateWavetableUf2FromSamples(_slots);

      setState(() {
        _isGenerating = false;
        _isUploading = true;
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'wavetable';
      final storageName = '${name}_$timestamp.uf2';

      final wavetable = SavedWavetable(
        id: '',
        userId: userId,
        name: name,
        filePath: '$userId/$storageName',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
      );

      await ref
          .read(savedWavetablesProvider.notifier)
          .saveWavetable(wavetable, uf2Bytes: uf2Bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wavetable created')),
        );
        _resetForm();
        widget.onCreated?.call();
      }
    } on FormatException catch (formatError) {
      setState(() {
        _isGenerating = false;
        _isUploading = false;
        _errorMessage = formatError.message;
      });
    } on Exception catch (error) {
      debugPrint('Failed to create wavetable: $error');
      setState(() {
        _isGenerating = false;
        _isUploading = false;
        _errorMessage = error.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DrawWavetableDescription(),
              const SizedBox(height: 16),
              _SlotSelector(
                selectedSlot: _selectedSlot,
                onSlotSelected: (index) {
                  setState(() => _selectedSlot = index);
                },
              ),
              const SizedBox(height: 12),
              WaveformDrawer(
                samples: _slots[_selectedSlot],
                onSamplesChanged: (updatedSamples) {
                  setState(() {
                    _slots[_selectedSlot] = updatedSamples;
                  });
                },
              ),
              const SizedBox(height: 12),
              _PresetButtons(
                isBusy: _isBusy,
                onSinePressed: () => _applyPresetToSlot(generateSinePreset),
                onSawPressed: () => _applyPresetToSlot(generateSawPreset),
                onTrianglePressed: () =>
                    _applyPresetToSlot(generateTrianglePreset),
                onSquarePressed: () => _applyPresetToSlot(generateSquarePreset),
                onFlatPressed: () => _applyPresetToSlot(generateFlatPreset),
              ),
              const SizedBox(height: 8),
              _BulkActions(
                isBusy: _isBusy,
                onCopyToAll: _copyToAllSlots,
                onSineAll: () => _applyPresetToAll(generateSinePreset),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Share with community'),
                value: _isPublic,
                onChanged: _isBusy
                    ? null
                    : (value) => setState(() => _isPublic = value),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                _ErrorMessageText(errorMessage: _errorMessage!),
              ],
              const SizedBox(height: 16),
              if (_isGenerating)
                const _GeneratingIndicator()
              else
                PlinkyButton(
                  onPressed: _isBusy ? null : _createAndUpload,
                  icon: _isUploading ? Icons.hourglass_empty : Icons.upload,
                  label: _isUploading ? 'Uploading...' : 'Create & Upload',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawWavetableDescription extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Draw waveforms for each of the 15 slots (c0–c14). '
      'Select a slot, then click and drag on the canvas to shape '
      'the waveform. Use the presets as starting points. '
      'A built-in saw and sine are added automatically as the '
      'first and last shapes.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SlotSelector extends StatelessWidget {
  const _SlotSelector({
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  final int selectedSlot;
  final ValueChanged<int> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(wavetableUserShapeCount, (index) {
        final isSelected = index == selectedSlot;
        return SizedBox(
          width: 40,
          height: 32,
          child: Material(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onSlotSelected(index),
              child: Center(
                child: Text(
                  'c$index',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PresetButtons extends StatelessWidget {
  const _PresetButtons({
    required this.isBusy,
    required this.onSinePressed,
    required this.onSawPressed,
    required this.onTrianglePressed,
    required this.onSquarePressed,
    required this.onFlatPressed,
  });

  final bool isBusy;
  final VoidCallback onSinePressed;
  final VoidCallback onSawPressed;
  final VoidCallback onTrianglePressed;
  final VoidCallback onSquarePressed;
  final VoidCallback onFlatPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Presets', style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _PresetChip(
              label: 'Sine',
              onPressed: isBusy ? null : onSinePressed,
            ),
            _PresetChip(
              label: 'Saw',
              onPressed: isBusy ? null : onSawPressed,
            ),
            _PresetChip(
              label: 'Triangle',
              onPressed: isBusy ? null : onTrianglePressed,
            ),
            _PresetChip(
              label: 'Square',
              onPressed: isBusy ? null : onSquarePressed,
            ),
            _PresetChip(
              label: 'Flat',
              onPressed: isBusy ? null : onFlatPressed,
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _BulkActions extends StatelessWidget {
  const _BulkActions({
    required this.isBusy,
    required this.onCopyToAll,
    required this.onSineAll,
  });

  final bool isBusy;
  final VoidCallback onCopyToAll;
  final VoidCallback onSineAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bulk actions', style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ActionChip(
              label: const Text('Copy to all slots'),
              onPressed: isBusy ? null : onCopyToAll,
            ),
            ActionChip(
              label: const Text('Reset all to sine'),
              onPressed: isBusy ? null : onSineAll,
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorMessageText extends StatelessWidget {
  const _ErrorMessageText({required this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      errorMessage,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}

class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Text('Generating wavetable...'),
      ],
    );
  }
}
