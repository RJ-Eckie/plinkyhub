import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:plinkyhub/models/category.dart';
import 'package:plinkyhub/models/preset.dart';
import 'package:plinkyhub/state/sound_service.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/utils/wav.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

enum _LoadState { idle, loading, loaded, error }

class MyPlinkyPage extends ConsumerStatefulWidget {
  const MyPlinkyPage({super.key});

  @override
  ConsumerState<MyPlinkyPage> createState() => _MyPlinkyPageState();
}

class _MyPlinkyPageState extends ConsumerState<MyPlinkyPage> {
  _LoadState _state = _LoadState.idle;
  String _statusMessage = '';
  String? _errorMessage;

  // Parsed device data.
  List<Uint8List?> _presetDataList = [];
  List<ParsedSampleInfo?> _sampleInfos = [];

  Map<int, Uint8List> _samplePcmData = {};
  Set<int> _emptySampleSlots = {};
  Uint8List? _wavetableUf2Bytes;

  // Editable controllers and state.
  final _presetNames = <int, TextEditingController>{};
  final _presetDescriptions = <int, TextEditingController>{};
  final _presetCategories = <int, PresetCategory>{};
  final _sampleNames = <int, TextEditingController>{};
  final _sampleDescriptions = <int, TextEditingController>{};
  final _wavetableNameController = TextEditingController(text: 'Wavetable');
  final _wavetableDescriptionController = TextEditingController();
  final _patternNames = <int, TextEditingController>{};
  final _patternDescriptions = <int, TextEditingController>{};
  final _nonEmptyPatternIndices = <int>[];

  @override
  void dispose() {
    for (final controller in _presetNames.values) {
      controller.dispose();
    }
    for (final controller in _presetDescriptions.values) {
      controller.dispose();
    }
    for (final controller in _sampleNames.values) {
      controller.dispose();
    }
    for (final controller in _sampleDescriptions.values) {
      controller.dispose();
    }
    _wavetableNameController.dispose();
    _wavetableDescriptionController.dispose();
    for (final controller in _patternNames.values) {
      controller.dispose();
    }
    for (final controller in _patternDescriptions.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _presetNames.values) {
      controller.dispose();
    }
    for (final controller in _presetDescriptions.values) {
      controller.dispose();
    }
    for (final controller in _sampleNames.values) {
      controller.dispose();
    }
    for (final controller in _sampleDescriptions.values) {
      controller.dispose();
    }
    for (final controller in _patternNames.values) {
      controller.dispose();
    }
    for (final controller in _patternDescriptions.values) {
      controller.dispose();
    }
    _presetNames.clear();
    _presetDescriptions.clear();
    _presetCategories.clear();
    _sampleNames.clear();
    _sampleDescriptions.clear();
    _patternNames.clear();
    _patternDescriptions.clear();
  }

  Future<void> _connectToPlinky() async {
    final directory = await showDirectoryPicker();
    if (directory == null) {
      return;
    }

    setState(() {
      _state = _LoadState.loading;
      _statusMessage = 'Reading PRESETS.UF2...';
      _errorMessage = null;
    });

    try {
      final presetsUf2Bytes = await readFileFromDirectory(
        directory,
        'PRESETS.UF2',
      );
      if (presetsUf2Bytes == null) {
        throw Exception('PRESETS.UF2 not found on the selected drive.');
      }

      final flashImage = uf2ToData(presetsUf2Bytes);

      setState(() => _statusMessage = 'Parsing presets...');
      final parsed = parseFlashImage(flashImage);
      _presetDataList = parsed.presets;
      _sampleInfos = parsed.sampleInfos;
      // Read samples.
      _samplePcmData = {};
      _emptySampleSlots = {};
      for (var i = 0; i < sampleCount; i++) {
        setState(() => _statusMessage = 'Reading SAMPLE$i.UF2...');
        final sampleBytes = await readFileFromDirectory(
          directory,
          'SAMPLE$i.UF2',
        );
        if (sampleBytes != null && sampleBytes.isNotEmpty) {
          try {
            var pcmData = uf2ToData(sampleBytes);
            final sampleInfo =
                i < _sampleInfos.length ? _sampleInfos[i] : null;
            if (sampleInfo != null &&
                sampleInfo.sampleLength * 2 < pcmData.length) {
              pcmData = Uint8List.sublistView(
                pcmData,
                0,
                sampleInfo.sampleLength * 2,
              );
            }
            if (pcmData.isNotEmpty && !_isSilentPcm(pcmData)) {
              _samplePcmData[i] = pcmData;
            } else {
              _emptySampleSlots.add(i);
            }
          } on FormatException {
            _emptySampleSlots.add(i);
          }
        } else {
          _emptySampleSlots.add(i);
        }
      }

      // Read wavetable.
      setState(() => _statusMessage = 'Reading WAVETAB.UF2...');
      _wavetableUf2Bytes = await readFileFromDirectory(
        directory,
        'WAVETAB.UF2',
      );
      if (_wavetableUf2Bytes != null &&
          (_wavetableUf2Bytes!.every((b) => b == 0) ||
              _wavetableUf2Bytes!.every((b) => b == 0xFF))) {
        _wavetableUf2Bytes = null;
      }

      // Build editable controllers from parsed data.
      _disposeControllers();

      for (var i = 0; i < presetCount; i++) {
        final presetBytes = _presetDataList[i];
        if (presetBytes == null) {
          continue;
        }
        final preset = Preset(presetBytes.buffer);
        if (preset.isEmpty) {
          _presetDataList[i] = null;
          continue;
        }
        _presetNames[i] = TextEditingController(
          text: preset.name.isNotEmpty ? preset.name : 'Preset ${i + 1}',
        );
        _presetDescriptions[i] = TextEditingController();
        _presetCategories[i] = preset.category;
      }

      for (final slotIndex in _samplePcmData.keys) {
        _sampleNames[slotIndex] = TextEditingController(
          text: 'Sample ${slotIndex + 1}',
        );
        _sampleDescriptions[slotIndex] = TextEditingController();
      }

      final hasWavetable =
          _wavetableUf2Bytes != null && _wavetableUf2Bytes!.isNotEmpty;
      if (hasWavetable) {
        _wavetableNameController.text = 'Wavetable';
        _wavetableDescriptionController.clear();
      }

      _nonEmptyPatternIndices
        ..clear()
        ..addAll(parsed.nonEmptyPatternIndices);
      for (final patternIndex in _nonEmptyPatternIndices) {
        _patternNames[patternIndex] = TextEditingController(
          text: 'Pattern ${patternIndex + 1}',
        );
        _patternDescriptions[patternIndex] = TextEditingController();
      }

      setState(() {
        _state = _LoadState.loaded;
        _statusMessage = '';
      });
    } on Exception catch (error) {
      debugPrint('Failed to read from Plinky: $error');
      if (mounted) {
        setState(() {
          _state = _LoadState.error;
          _errorMessage = error.toString();
        });
      }
    }
  }

  bool _isSilentPcm(Uint8List pcmData) {
    if (pcmData.every((byte) => byte == 0) ||
        pcmData.every((byte) => byte == 0xFF)) {
      return true;
    }
    if (pcmData.length >= 2) {
      final view = Int16List.view(pcmData.buffer);
      final firstSample = view[0];
      if (view.every((sample) => sample == firstSample)) {
        return true;
      }
    }
    return false;
  }

  bool get _hasWavetable =>
      _wavetableUf2Bytes != null && _wavetableUf2Bytes!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _LoadState.idle => _buildConnectView(),
      _LoadState.loading => _buildLoadingView(),
      _LoadState.loaded => _buildDeviceView(),
      _LoadState.error => _buildErrorView(),
    };
  }

  Widget _buildConnectView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'My Plinky',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Connect your Plinky in Tunnel of Lights mode '
                "to see what's on it.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Text('1. Turn off your Plinky'),
              const SizedBox(height: 4),
              const Text(
                '2. Hold the rotary encoder while '
                'turning the Plinky on',
              ),
              const SizedBox(height: 4),
              const Text(
                '3. The Plinky will appear as a USB '
                'drive on your computer',
              ),
              const SizedBox(height: 16),
              PlinkyButton(
                onPressed: _connectToPlinky,
                icon: Icons.usb,
                label: 'Select Plinky drive',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_statusMessage),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'An unknown error occurred.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              PlinkyButton(
                onPressed: () => setState(() {
                  _state = _LoadState.idle;
                  _errorMessage = null;
                }),
                icon: Icons.arrow_back,
                label: 'Try again',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceView() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'My Plinky',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  PlinkyButton(
                    onPressed: _connectToPlinky,
                    icon: Icons.refresh,
                    label: 'Reload',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Found ${_presetNames.length} presets, '
                '${_sampleNames.length} samples'
                '${_nonEmptyPatternIndices.isNotEmpty ? ', '
                        '${_nonEmptyPatternIndices.length} patterns' : ''} '
                '${_hasWavetable ? 'and a wavetable ' : ''}'
                'on the Plinky.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Preset Slots',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisExtent: 64,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 32,
                itemBuilder: (context, index) {
                  final row = index ~/ 4;
                  final column = index % 4;
                  final slotIndex = column * 8 + row;
                  final hasPreset = _presetNames.containsKey(slotIndex);
                  final presetBytes = _presetDataList[slotIndex];
                  final preset = presetBytes != null
                      ? Preset(presetBytes.buffer)
                      : null;
                  return _PresetSlotCard(
                    slotNumber: slotIndex,
                    name: _presetNames[slotIndex]?.text,
                    category: _presetCategories[slotIndex],
                    hasPreset: hasPreset,
                    onTap: hasPreset
                        ? () => _showPresetEditDialog(slotIndex, preset!)
                        : null,
                  );
                },
              ),
              if (_sampleNames.isNotEmpty ||
                  _emptySampleSlots.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Samples',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final slotIndex in [
                  ..._sampleNames.keys,
                  ..._emptySampleSlots,
                ]..sort())
                  if (_sampleNames.containsKey(slotIndex))
                    _SamplePreviewRow(
                      controller: _sampleNames[slotIndex]!,
                      label: 'Sample $slotIndex',
                      pcmData: _samplePcmData[slotIndex],
                      onEdit: () => _showSampleEditDialog(slotIndex),
                    )
                  else
                    _EmptySlotRow(label: 'Sample $slotIndex'),
              ],
              if (_hasWavetable) ...[
                const SizedBox(height: 16),
                Text(
                  'Wavetable',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _NamedItemRow(
                  controller: _wavetableNameController,
                  label: 'Wavetable name',
                  onEdit: _showWavetableEditDialog,
                ),
              ],
              if (_nonEmptyPatternIndices.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Patterns',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final patternIndex
                    in _patternNames.keys.toList()..sort())
                  _NamedItemRow(
                    controller: _patternNames[patternIndex]!,
                    label: 'Pattern ${patternIndex + 1}',
                    onEdit: () => _showPatternEditDialog(patternIndex),
                  ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showPresetEditDialog(int slotIndex, Preset preset) {
    showDialog<void>(
      context: context,
      builder: (context) => _PresetEditDialog(
        nameController: _presetNames[slotIndex]!,
        descriptionController: _presetDescriptions[slotIndex]!,
        category: _presetCategories[slotIndex] ?? PresetCategory.none,
        preset: preset,
        onCategoryChanged: (value) {
          _presetCategories[slotIndex] = value;
          setState(() {});
        },
      ),
    );
  }

  void _showSampleEditDialog(int slotIndex) {
    showDialog<void>(
      context: context,
      builder: (context) => _NameDescriptionEditDialog(
        title: 'Edit Sample',
        nameController: _sampleNames[slotIndex]!,
        descriptionController: _sampleDescriptions[slotIndex]!,
      ),
    );
  }

  void _showWavetableEditDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _NameDescriptionEditDialog(
        title: 'Edit Wavetable',
        nameController: _wavetableNameController,
        descriptionController: _wavetableDescriptionController,
      ),
    );
  }

  void _showPatternEditDialog(int patternIndex) {
    showDialog<void>(
      context: context,
      builder: (context) => _NameDescriptionEditDialog(
        title: 'Edit Pattern',
        nameController: _patternNames[patternIndex]!,
        descriptionController: _patternDescriptions[patternIndex]!,
      ),
    );
  }
}

class _PresetSlotCard extends StatelessWidget {
  const _PresetSlotCard({
    required this.slotNumber,
    required this.hasPreset, this.name,
    this.category,
    this.onTap,
  });

  final int slotNumber;
  final String? name;
  final PresetCategory? category;
  final bool hasPreset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryLabel = category?.label ?? '';

    return Card(
      color: hasPreset ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${slotNumber + 1}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasPreset
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasPreset) ...[
                Text(
                  name?.isNotEmpty == true ? name! : '-',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (categoryLabel.isNotEmpty)
                  Text(
                    categoryLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetEditDialog extends StatelessWidget {
  const _PresetEditDialog({
    required this.nameController,
    required this.descriptionController,
    required this.category,
    required this.preset,
    required this.onCategoryChanged,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final PresetCategory category;
  final Preset preset;
  final ValueChanged<PresetCategory> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Preset'),
      content: SizedBox(
        width: 400,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            var currentCategory = category;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PresetCategory>(
                  initialValue: currentCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: PresetCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category.label.isEmpty ? 'None' : category.label,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      currentCategory = value;
                      onCategoryChanged(value);
                      setDialogState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),
                _PresetInfoSection(preset: preset),
              ],
            );
          },
        ),
      ),
      actions: [
        PlinkyButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icons.check,
          label: 'Done',
        ),
      ],
    );
  }
}

class _PresetInfoSection extends StatelessWidget {
  const _PresetInfoSection({required this.preset});

  final Preset preset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _DetailRow(label: 'Scale', value: preset.scale.displayName),
        _DetailRow(label: 'Octave offset', value: '${preset.octaveOffset}'),
        if (preset.usesSample)
          _DetailRow(label: 'Sample slot', value: '${preset.sampleSlot}'),
        if (preset.arp)
          Text(
            'Arpeggiator enabled',
            style: theme.textTheme.bodyMedium,
          ),
        if (preset.latch)
          Text(
            'Latch enabled',
            style: theme.textTheme.bodyMedium,
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _SamplePreviewRow extends ConsumerStatefulWidget {
  const _SamplePreviewRow({
    required this.controller,
    required this.label,
    this.pcmData,
    this.onEdit,
  });

  final TextEditingController controller;
  final String label;
  final Uint8List? pcmData;
  final VoidCallback? onEdit;

  @override
  ConsumerState<_SamplePreviewRow> createState() => _SamplePreviewRowState();
}

class _SamplePreviewRowState extends ConsumerState<_SamplePreviewRow> {
  AudioSource? _audioSource;
  bool _isPlaying = false;

  Future<void> _togglePlayback() async {
    final soundService = ref.read(soundServiceProvider);

    if (_isPlaying) {
      await soundService.stopPreview();
      setState(() => _isPlaying = false);
      return;
    }

    final pcmData = widget.pcmData;
    if (pcmData == null) {
      return;
    }

    if (_audioSource == null) {
      final wavBytes = plinkyPcmToWav(pcmData);
      _audioSource = await soundService.loadSource(
        '${widget.label}.wav',
        wavBytes,
      );
    }

    await soundService.play(_audioSource!);
    setState(() => _isPlaying = true);

    final duration = soundService.getLength(_audioSource!);
    await Future<void>.delayed(duration);
    if (mounted && _isPlaying) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          if (widget.pcmData != null)
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.stop : Icons.play_arrow,
                size: 20,
              ),
              tooltip: _isPlaying ? 'Stop' : 'Play',
              onPressed: _togglePlayback,
            ),
          if (widget.onEdit != null)
            Tooltip(
              message: 'Edit details',
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: widget.onEdit,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySlotRow extends StatelessWidget {
  const _EmptySlotRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          'EMPTY',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _NamedItemRow extends StatelessWidget {
  const _NamedItemRow({
    required this.controller,
    required this.label,
    this.onEdit,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          if (onEdit != null)
            Tooltip(
              message: 'Edit details',
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
            ),
        ],
      ),
    );
  }
}

class _NameDescriptionEditDialog extends StatelessWidget {
  const _NameDescriptionEditDialog({
    required this.title,
    required this.nameController,
    required this.descriptionController,
  });

  final String title;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        PlinkyButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icons.check,
          label: 'Done',
        ),
      ],
    );
  }
}
