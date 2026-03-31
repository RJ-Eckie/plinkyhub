import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/preset.dart';
import 'package:plinkyhub/pages/my_plinky/save_my_plinky_dialog.dart';
import 'package:plinkyhub/pages/packs/pattern_section.dart';
import 'package:plinkyhub/pages/packs/preset_slots_grid.dart';
import 'package:plinkyhub/pages/packs/samples_section.dart';
import 'package:plinkyhub/pages/packs/wavetable_section.dart';
import 'package:plinkyhub/utils/file_system_access.dart';
import 'package:plinkyhub/utils/plinky_device_parser.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';
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

  // Directory handle from the initial connect.
  late FileSystemDirectoryHandle? _directory;

  // Parsed flash image from device (preserved for save-back merging).
  late ParsedFlashImage? _parsedFlashImage;

  // Device data: preset name/category from PRESETS.UF2 per slot.
  final _devicePresets = <int, Preset>{};

  // Device sample slot indices that have audio data.
  final _deviceSampleSlots = <int>{};

  // Linked saved entry IDs (null = not linked).
  final List<({String? presetId, String? sampleId, String? patternId})> _slots =
      List.generate(
        32,
        (_) => (presetId: null, sampleId: null, patternId: null),
      );
  String? _wavetableId;
  final Map<int, String?> _patternIds = {};

  // Whether the device had a wavetable / patterns.
  bool _deviceHasWavetable = false;
  final _devicePatternIndices = <int>[];

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _connectToPlinky() async {
    final directory = await showDirectoryPicker(readwrite: true);
    if (directory == null) {
      return;
    }
    _directory = directory;

    setState(() {
      _state = _PageState.loading;
      _statusMessage = 'Reading files from Plinky...';
      _errorMessage = null;
    });

    try {
      // Read all files on the main thread (File System Access API
      // requires it), then send raw bytes to an isolate for parsing.
      final presetsUf2Bytes = await readFileFromDirectory(
        directory,
        'PRESETS.UF2',
      );
      if (presetsUf2Bytes == null) {
        throw Exception(
          'PRESETS.UF2 not found on the selected drive.',
        );
      }

      final sampleUf2s = <Uint8List?>[];
      for (var i = 0; i < sampleCount; i++) {
        setState(
          () => _statusMessage = 'Reading SAMPLE$i.UF2...',
        );
        sampleUf2s.add(
          await readFileFromDirectory(directory, 'SAMPLE$i.UF2'),
        );
      }

      setState(
        () => _statusMessage = 'Reading WAVETAB.UF2...',
      );
      var wavetableBytes = await readFileFromDirectory(
        directory,
        'WAVETAB.UF2',
      );
      wavetableBytes ??= await readFileFromDirectory(
        directory,
        'wavetab.uf2',
      );

      // Phase 1: Parse presets and patterns.
      setState(() => _statusMessage = 'Parsing presets...');
      await Future<void>.delayed(Duration.zero);
      final presetsResult = parsePresetsPhase(presetsUf2Bytes);

      // Phase 2: Parse samples.
      setState(() => _statusMessage = 'Parsing samples...');
      await Future<void>.delayed(Duration.zero);
      final samplesResult = parseSamplesPhase(
        SamplesPhaseInput(
          sampleUf2s: sampleUf2s,
          sampleInfos: presetsResult.sampleInfos,
        ),
      );

      // Phase 3: Check wavetable.
      setState(() => _statusMessage = 'Checking wavetable...');
      await Future<void>.delayed(Duration.zero);
      final wavetableResult = parseWavetablePhase(wavetableBytes);

      // Store parsed flash image for save-back merging.
      _parsedFlashImage = ParsedFlashImage(
        presets: presetsResult.presets,
        sampleInfos: presetsResult.sampleInfos,
        rawSampleInfos: presetsResult.rawSampleInfos,
        patternQuarters: presetsResult.patternQuarters,
      );

      // Populate device state from parsed results.
      _devicePresets.clear();
      for (var i = 0; i < presetCount; i++) {
        final presetBytes = presetsResult.presets[i];
        if (presetBytes != null) {
          final preset = Preset(presetBytes.buffer);
          if (!preset.isEmpty) {
            _devicePresets[i] = preset;
          }
        }
      }

      _deviceSampleSlots
        ..clear()
        ..addAll(samplesResult.samplePcmData.keys);

      _deviceHasWavetable = wavetableResult.deviceHasWavetable;

      _devicePatternIndices
        ..clear()
        ..addAll(presetsResult.nonEmptyPatternIndices);

      // Match content hashes against saved entries.
      setState(() => _statusMessage = 'Matching saved content...');

      final matchedPresets = <int, _MatchedEntry>{};
      final matchedSamples = <int, _MatchedEntry>{};
      _MatchedEntry? matchedWavetable;
      final matchedPatterns = <int, _MatchedEntry>{};

      await Future.wait([
        _findMatches(
          'presets',
          presetsResult.presetHashes,
          matchedPresets,
        ),
        _findMatches(
          'samples',
          samplesResult.sampleHashes,
          matchedSamples,
        ),
        _findMatches(
          'patterns',
          presetsResult.patternHashes,
          matchedPatterns,
        ),
        if (wavetableResult.wavetableHash != null)
          _findWavetableMatch(wavetableResult.wavetableHash!).then(
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
          final presetRaw = preset.parameterById('P_SAMPLE')?.value;
          if (presetRaw != null) {
            for (final rawEntry in sampleSlotRawValues.entries) {
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
      _patternIds.clear();
      for (final patternIndex in _devicePatternIndices) {
        _patternIds[patternIndex] = matchedPatterns[patternIndex]?.id;
      }

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
              const SizedBox(width: 8),
              PlinkyButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => SaveMyPlinkyDialog(
                    directory: _directory!,
                    slots: _slots,
                    patternIds: _patternIds,
                    wavetableId: _wavetableId,
                    parsedFlashImage: _parsedFlashImage!,
                  ),
                ),
                icon: Icons.save,
                label: 'Save to Plinky',
              ),
            ],
          ),
          const SizedBox(height: 16),
          PresetSlotsGrid(
            slots: _slots,
            devicePresets: _devicePresets,
            onPresetChanged: (slotIndex, presetId) {
              setState(() {
                _slots[slotIndex] = (
                  presetId: presetId,
                  sampleId: _slots[slotIndex].sampleId,
                  patternId: _slots[slotIndex].patternId,
                );
              });
            },
            onSampleChanged: (slotIndex, sampleId) {
              setState(() {
                _slots[slotIndex] = (
                  presetId: _slots[slotIndex].presetId,
                  sampleId: sampleId,
                  patternId: _slots[slotIndex].patternId,
                );
              });
            },
          ),
          const SizedBox(height: 16),
          SamplesSection(slots: _slots),
          const SizedBox(height: 16),
          PatternSection(
            patternIds: _patternIds,
            devicePatternIndices: _devicePatternIndices.toSet(),
            onPatternChanged: (patternIndex, patternId) {
              setState(() {
                _patternIds[patternIndex] = patternId;
              });
            },
          ),
          const SizedBox(height: 16),
          WavetableSection(
            wavetableId: _wavetableId,
            deviceHasWavetable: _deviceHasWavetable,
            onChanged: (wavetableId) =>
                setState(() => _wavetableId = wavetableId),
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
