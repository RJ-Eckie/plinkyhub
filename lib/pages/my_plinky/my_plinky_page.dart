import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
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
  final _presets = <int, Preset>{};
  final _samplePcmData = <int, Uint8List>{};
  final _sampleNames = <int, String>{};
  final _emptySampleSlots = <int>{};
  bool _hasWavetable = false;
  final _nonEmptyPatternIndices = <int>[];

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

      // Parse presets.
      _presets.clear();
      for (var i = 0; i < presetCount; i++) {
        final presetBytes = parsed.presets[i];
        if (presetBytes == null) {
          continue;
        }
        final preset = Preset(presetBytes.buffer);
        if (!preset.isEmpty) {
          _presets[i] = preset;
        }
      }

      // Read samples.
      _samplePcmData.clear();
      _sampleNames.clear();
      _emptySampleSlots.clear();
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
                i < parsed.sampleInfos.length ? parsed.sampleInfos[i] : null;
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
              _sampleNames[i] = 'Sample ${i + 1}';
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
      final wavetableBytes = await readFileFromDirectory(
        directory,
        'WAVETAB.UF2',
      );
      _hasWavetable = wavetableBytes != null &&
          wavetableBytes.isNotEmpty &&
          !wavetableBytes.every((b) => b == 0) &&
          !wavetableBytes.every((b) => b == 0xFF);

      // Pattern indices.
      _nonEmptyPatternIndices
        ..clear()
        ..addAll(parsed.nonEmptyPatternIndices);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              // Column-major order: same as Create Pack tab.
              final row = index ~/ 4;
              final column = index % 4;
              final slotIndex = column * 8 + row;
              final preset = _presets[slotIndex];
              return _PresetSlotCard(
                slotNumber: slotIndex,
                preset: preset,
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Samples',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < sampleCount; i++)
            if (_samplePcmData.containsKey(i))
              _SampleRow(
                label: 'Sample ${i + 1}',
                name: _sampleNames[i] ?? '',
                pcmData: _samplePcmData[i],
              )
            else
              _EmptySlotRow(label: 'Sample ${i + 1}'),
          const SizedBox(height: 16),
          Text(
            'Wavetable',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _hasWavetable ? 'Present' : 'None',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _hasWavetable
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Patterns',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_nonEmptyPatternIndices.isEmpty)
            Text(
              'None',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final patternIndex in _nonEmptyPatternIndices)
                  Chip(label: Text('Pattern ${patternIndex + 1}')),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PresetSlotCard extends StatelessWidget {
  const _PresetSlotCard({
    required this.slotNumber,
    this.preset,
  });

  final int slotNumber;
  final Preset? preset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = preset == null;
    final categoryLabel = preset?.category.label ?? '';

    return Card(
      color: isEmpty ? null : theme.colorScheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isEmpty ? null : () => _showPresetDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${slotNumber + 1}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              if (!isEmpty) ...[
                Text(
                  preset!.name.isNotEmpty ? preset!.name : '-',
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

  void _showPresetDetails(BuildContext context) {
    if (preset == null) {
      return;
    }
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          preset!.name.isNotEmpty
              ? preset!.name
              : 'Preset ${slotNumber + 1}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preset!.category.label.isNotEmpty)
              _DetailRow(
                label: 'Category',
                value: preset!.category.label,
              ),
            _DetailRow(
              label: 'Scale',
              value: preset!.scale.displayName,
            ),
            _DetailRow(
              label: 'Octave offset',
              value: '${preset!.octaveOffset}',
            ),
            if (preset!.usesSample)
              _DetailRow(
                label: 'Sample slot',
                value: '${preset!.sampleSlot}',
              ),
            if (preset!.arp)
              Text(
                'Arpeggiator enabled',
                style: theme.textTheme.bodyMedium,
              ),
            if (preset!.latch)
              Text(
                'Latch enabled',
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
        actions: [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.close,
            label: 'Close',
          ),
        ],
      ),
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

class _SampleRow extends ConsumerStatefulWidget {
  const _SampleRow({
    required this.label,
    required this.name,
    this.pcmData,
  });

  final String label;
  final String name;
  final Uint8List? pcmData;

  @override
  ConsumerState<_SampleRow> createState() => _SampleRowState();
}

class _SampleRowState extends ConsumerState<_SampleRow> {
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              child: Text(
                widget.name,
                style: theme.textTheme.bodyMedium,
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
