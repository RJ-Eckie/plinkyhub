import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/preset.dart';
import 'package:plinkyhub/models/saved_pattern.dart';
import 'package:plinkyhub/models/saved_preset.dart';
import 'package:plinkyhub/models/saved_wavetable.dart';
import 'package:plinkyhub/pages/packs/pattern_picker_dialog.dart';
import 'package:plinkyhub/pages/packs/preset_picker_dialog.dart';
import 'package:plinkyhub/pages/packs/samples_section.dart';
import 'package:plinkyhub/pages/packs/wavetable_picker_dialog.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_patterns_notifier.dart';
import 'package:plinkyhub/state/saved_presets_notifier.dart';
import 'package:plinkyhub/state/saved_wavetables_notifier.dart';
import 'package:plinkyhub/utils/content_hash.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _PageState { connect, loading, loaded, error }

class MyPlinkyPage extends ConsumerStatefulWidget {
  const MyPlinkyPage({super.key});

  @override
  ConsumerState<MyPlinkyPage> createState() => _MyPlinkyPageState();
}

class _MyPlinkyPageState extends ConsumerState<MyPlinkyPage> {
  _PageState _state = _PageState.connect;
  String _statusMessage = '';
  String? _errorMessage;

  // Device data: preset name/category from PRESETS.UF2 per slot.
  final _devicePresets = <int, Preset>{};

  // Device sample slot indices that have audio data.
  final _deviceSampleSlots = <int>{};

  // Linked saved entry IDs (null = not linked).
  final List<({String? presetId, String? sampleId, String? patternId})>
      _slots = List.generate(
        32,
        (_) => (presetId: null, sampleId: null, patternId: null),
      );
  String? _wavetableId;
  String? _patternId;

  // Whether the device had a wavetable / patterns.
  bool _deviceHasWavetable = false;
  final _devicePatternIndices = <int>[];

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _connectToPlinky() async {
    final directory = await showDirectoryPicker();
    if (directory == null) {
      return;
    }

    setState(() {
      _state = _PageState.loading;
      _statusMessage = 'Reading PRESETS.UF2...';
      _errorMessage = null;
    });

    try {
      final presetsUf2Bytes = await readFileFromDirectory(
        directory,
        'PRESETS.UF2',
      );
      if (presetsUf2Bytes == null) {
        throw Exception(
          'PRESETS.UF2 not found on the selected drive.',
        );
      }

      final flashImage = uf2ToData(presetsUf2Bytes);

      setState(() => _statusMessage = 'Parsing presets...');
      final parsed = parseFlashImage(flashImage);

      // Parse device presets and compute hashes.
      _devicePresets.clear();
      final presetHashes = <int, String>{};
      for (var i = 0; i < presetCount; i++) {
        final presetBytes = parsed.presets[i];
        if (presetBytes == null) {
          continue;
        }
        final preset = Preset(presetBytes.buffer);
        if (!preset.isEmpty) {
          _devicePresets[i] = preset;
          presetHashes[i] = computeContentHash(presetBytes);
        }
      }

      // Read and hash samples.
      _deviceSampleSlots.clear();
      final sampleHashes = <int, String>{};
      for (var i = 0; i < sampleCount; i++) {
        setState(() => _statusMessage = 'Reading SAMPLE$i.UF2...');
        final sampleBytes = await readFileFromDirectory(
          directory,
          'SAMPLE$i.UF2',
        );
        if (sampleBytes != null && sampleBytes.isNotEmpty) {
          try {
            var pcmData = uf2ToData(sampleBytes);
            final sampleInfo = i < parsed.sampleInfos.length
                ? parsed.sampleInfos[i]
                : null;
            if (sampleInfo != null &&
                sampleInfo.sampleLength * 2 < pcmData.length) {
              pcmData = Uint8List.sublistView(
                pcmData,
                0,
                sampleInfo.sampleLength * 2,
              );
            }
            if (pcmData.isNotEmpty && !_isSilentPcm(pcmData)) {
              _deviceSampleSlots.add(i);
              sampleHashes[i] = computeContentHash(pcmData);
            }
          } on FormatException {
            // Skip corrupt sample.
          }
        }
      }

      // Read wavetable.
      setState(() => _statusMessage = 'Reading WAVETAB.UF2...');
      final wavetableBytes = await readFileFromDirectory(
        directory,
        'WAVETAB.UF2',
      );
      String? wavetableHash;
      _deviceHasWavetable = wavetableBytes != null &&
          !wavetableBytes.every((b) => b == 0) &&
          !wavetableBytes.every((b) => b == 0xFF);
      if (_deviceHasWavetable) {
        wavetableHash = computeContentHash(wavetableBytes!);
      }

      // Compute pattern hashes.
      _devicePatternIndices
        ..clear()
        ..addAll(parsed.nonEmptyPatternIndices);
      final patternHashes = <int, String>{};
      for (final patternIndex in _devicePatternIndices) {
        final quarterStart = patternIndex * 4;
        final quarters = List<Uint8List?>.filled(
          parsed.patternQuarters.length,
          null,
        );
        for (var q = 0; q < 4; q++) {
          final index = quarterStart + q;
          if (index < parsed.patternQuarters.length) {
            quarters[index] = parsed.patternQuarters[index];
          }
        }
        final patternBlob = serializePatternQuarters(quarters);
        patternHashes[patternIndex] =
            computeContentHash(patternBlob);
      }

      // Match content hashes against saved entries.
      setState(() => _statusMessage = 'Matching saved content...');

      final matchedPresets = <int, _MatchedEntry>{};
      final matchedSamples = <int, _MatchedEntry>{};
      _MatchedEntry? matchedWavetable;
      final matchedPatterns = <int, _MatchedEntry>{};

      await Future.wait([
        _findMatches('presets', presetHashes, matchedPresets),
        _findMatches('samples', sampleHashes, matchedSamples),
        _findMatches('patterns', patternHashes, matchedPatterns),
        if (wavetableHash != null)
          _findWavetableMatch(wavetableHash).then(
            (entry) => matchedWavetable = entry,
          ),
      ]);

      // Pre-compute raw P_SAMPLE values for sample slot matching.
      final sampleSlotRawValues = <int, int>{
        for (final slotIndex in _deviceSampleSlots)
          slotIndex: sampleSlotToRaw(slotIndex),
      };

      // Populate slots with matched IDs.
      for (var i = 0; i < 32; i++) {
        _slots[i] = (
          presetId: null,
          sampleId: null,
          patternId: null,
        );
      }

      for (final entry in matchedPresets.entries) {
        final slotIndex = entry.key;
        String? sampleId;

        // Find matched sample for this preset's sample slot.
        final preset = _devicePresets[slotIndex];
        if (preset != null && preset.usesSample) {
          final presetRaw =
              preset.parameterById('P_SAMPLE')?.value;
          if (presetRaw != null) {
            for (final rawEntry
                in sampleSlotRawValues.entries) {
              if ((presetRaw - rawEntry.value).abs() < 2) {
                sampleId = matchedSamples[rawEntry.key]?.id;
                break;
              }
            }
          }
        }

        _slots[slotIndex] = (
          presetId: entry.value.id,
          sampleId: sampleId,
          patternId: null,
        );
      }

      _wavetableId = matchedWavetable?.id;
      _patternId = matchedPatterns.values.firstOrNull?.id;

      setState(() {
        _state = _PageState.loaded;
        _statusMessage = '';
      });
    } on Exception catch (error) {
      debugPrint('Failed to read from Plinky: $error');
      if (mounted) {
        setState(() {
          _state = _PageState.error;
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

  Future<void> _findMatches(
    String table,
    Map<int, String> hashes,
    Map<int, _MatchedEntry> matches,
  ) async {
    if (hashes.isEmpty) {
      return;
    }

    final uniqueHashes = hashes.values.toSet().toList();
    final results = await _supabase
        .from(table)
        .select('id, name, content_hash')
        .inFilter('content_hash', uniqueHashes);

    final hashToEntry = <String, _MatchedEntry>{};
    for (final row in results) {
      final hash = row['content_hash'] as String?;
      if (hash != null) {
        hashToEntry[hash] = _MatchedEntry(
          id: row['id'] as String,
          name: row['name'] as String,
        );
      }
    }

    for (final entry in hashes.entries) {
      final matched = hashToEntry[entry.value];
      if (matched != null) {
        matches[entry.key] = matched;
      }
    }
  }

  Future<_MatchedEntry?> _findWavetableMatch(String hash) async {
    final results = await _supabase
        .from('wavetables')
        .select('id, name, content_hash')
        .eq('content_hash', hash)
        .limit(1);

    if (results.isNotEmpty) {
      return _MatchedEntry(
        id: results.first['id'] as String,
        name: results.first['name'] as String,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _PageState.connect => _buildConnectView(),
      _PageState.loading => _buildLoadingView(),
      _PageState.loaded => _buildDeviceView(),
      _PageState.error => _buildErrorView(),
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
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
              const Icon(
                Icons.error,
                size: 48,
                color: Colors.red,
              ),
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
                  _state = _PageState.connect;
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
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
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
              return _PlinkySlotTile(
                slotNumber: slotIndex,
                devicePreset: _devicePresets[slotIndex],
                presetId: _slots[slotIndex].presetId,
                sampleId: _slots[slotIndex].sampleId,
                onPresetChanged: (presetId) {
                  setState(() {
                    _slots[slotIndex] = (
                      presetId: presetId,
                      sampleId: _slots[slotIndex].sampleId,
                      patternId: _slots[slotIndex].patternId,
                    );
                  });
                },
                onSampleChanged: (sampleId) {
                  setState(() {
                    _slots[slotIndex] = (
                      presetId: _slots[slotIndex].presetId,
                      sampleId: sampleId,
                      patternId: _slots[slotIndex].patternId,
                    );
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          SamplesSection(slots: _slots),
          const SizedBox(height: 16),
          _WavetableSection(
            wavetableId: _wavetableId,
            deviceHasWavetable: _deviceHasWavetable,
            onChanged: (wavetableId) =>
                setState(() => _wavetableId = wavetableId),
          ),
          const SizedBox(height: 16),
          _PatternSection(
            patternId: _patternId,
            devicePatternCount: _devicePatternIndices.length,
            onChanged: (patternId) =>
                setState(() => _patternId = patternId),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MatchedEntry {
  const _MatchedEntry({required this.id, required this.name});

  final String id;
  final String name;
}

/// A slot tile that shows the device preset name from PRESETS.UF2
/// as the primary label, with a link icon when matched to a saved
/// entry, and a popup menu to pick or clear presets/samples.
class _PlinkySlotTile extends ConsumerWidget {
  const _PlinkySlotTile({
    required this.slotNumber,
    required this.devicePreset,
    required this.presetId,
    required this.sampleId,
    required this.onPresetChanged,
    required this.onSampleChanged,
  });

  final int slotNumber;
  final Preset? devicePreset;
  final String? presetId;
  final String? sampleId;
  final ValueChanged<String?> onPresetChanged;
  final ValueChanged<String?> onSampleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasDevicePreset = devicePreset != null;
    final isLinked = presetId != null;

    // Show device name as primary, or linked name if no device
    // preset but a saved one is picked.
    String displayName;
    if (hasDevicePreset) {
      displayName = devicePreset!.name.isNotEmpty
          ? devicePreset!.name
          : 'Preset ${slotNumber + 1}';
    } else if (isLinked) {
      final presets = ref.watch(
        savedPresetsProvider
            .select((state) => state.userPresets),
      );
      displayName = presets
              .where((preset) => preset.id == presetId)
              .firstOrNull
              ?.name ??
          '(unknown)';
    } else {
      displayName = 'Empty';
    }

    final categoryLabel = devicePreset?.category.label ?? '';

    return Card(
      color: hasDevicePreset || isLinked
          ? theme.colorScheme.primaryContainer
          : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPresetPicker(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${slotNumber + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasDevicePreset || isLinked
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isLinked) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.link,
                      size: 12,
                      color:
                          theme.colorScheme.onPrimaryContainer,
                    ),
                  ],
                ],
              ),
              if (hasDevicePreset || isLinked) ...[
                Text(
                  displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (categoryLabel.isNotEmpty)
                  Text(
                    categoryLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme
                          .colorScheme.onPrimaryContainer
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

  void _showPresetPicker(BuildContext context, WidgetRef ref) {
    final presets = ref.read(
      savedPresetsProvider.select((state) => state.userPresets),
    );
    final currentUserId =
        ref.read(authenticationProvider).user?.id;
    showDialog<SavedPreset>(
      context: context,
      builder: (context) => PresetPickerDialog(
        presets: presets,
        currentUserId: currentUserId,
      ),
    ).then((selected) {
      if (selected != null) {
        onPresetChanged(selected.id);
        if (selected.sampleId != null) {
          onSampleChanged(selected.sampleId);
        }
      }
    });
  }
}

class _WavetableSection extends ConsumerWidget {
  const _WavetableSection({
    required this.wavetableId,
    required this.deviceHasWavetable,
    required this.onChanged,
  });

  final String? wavetableId;
  final bool deviceHasWavetable;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wavetablesState = ref.watch(savedWavetablesProvider);
    final wavetableName = wavetableId != null
        ? wavetablesState.userWavetables
                  .where(
                    (wavetable) => wavetable.id == wavetableId,
                  )
                  .firstOrNull
                  ?.name ??
              wavetablesState.publicWavetables
                  .where(
                    (wavetable) => wavetable.id == wavetableId,
                  )
                  .firstOrNull
                  ?.name
        : null;

    final isLinked = wavetableId != null;
    final statusText = isLinked
        ? wavetableName ?? '(unknown)'
        : deviceHasWavetable
            ? 'Present on device (not linked)'
            : 'None';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wavetable',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (isLinked)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.link,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Expanded(
              child: Text(
                statusText,
                style:
                    Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (wavetableId != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Remove wavetable',
                onPressed: () => onChanged(null),
              ),
            PlinkyButton(
              onPressed: () async {
                final authState =
                    ref.read(authenticationProvider);
                final allWavetables = {
                  ...wavetablesState.userWavetables,
                  ...wavetablesState.publicWavetables,
                }.toList();
                final selected =
                    await showDialog<SavedWavetable>(
                  context: context,
                  builder: (context) =>
                      WavetablePickerDialog(
                    wavetables: allWavetables,
                    currentUserId: authState.user?.id,
                  ),
                );
                if (selected != null) {
                  onChanged(selected.id);
                }
              },
              icon: Icons.waves,
              label: 'Choose',
            ),
          ],
        ),
      ],
    );
  }
}

class _PatternSection extends ConsumerWidget {
  const _PatternSection({
    required this.patternId,
    required this.devicePatternCount,
    required this.onChanged,
  });

  final String? patternId;
  final int devicePatternCount;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsState = ref.watch(savedPatternsProvider);
    final patternName = patternId != null
        ? patternsState.userPatterns
                  .where(
                    (pattern) => pattern.id == patternId,
                  )
                  .firstOrNull
                  ?.name ??
              patternsState.publicPatterns
                  .where(
                    (pattern) => pattern.id == patternId,
                  )
                  .firstOrNull
                  ?.name
        : null;

    final isLinked = patternId != null;
    final statusText = isLinked
        ? patternName ?? '(unknown)'
        : devicePatternCount > 0
            ? '$devicePatternCount on device (not linked)'
            : 'None';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patterns',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (isLinked)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.link,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Expanded(
              child: Text(
                statusText,
                style:
                    Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (patternId != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Remove patterns',
                onPressed: () => onChanged(null),
              ),
            PlinkyButton(
              onPressed: () async {
                final authState =
                    ref.read(authenticationProvider);
                final allPatterns = {
                  ...patternsState.userPatterns,
                  ...patternsState.publicPatterns,
                }.toList();
                final selected =
                    await showDialog<SavedPattern>(
                  context: context,
                  builder: (context) => PatternPickerDialog(
                    patterns: allPatterns,
                    currentUserId: authState.user?.id,
                  ),
                );
                if (selected != null) {
                  onChanged(selected.id);
                }
              },
              icon: Icons.grid_view,
              label: 'Choose',
            ),
          ],
        ),
      ],
    );
  }
}
