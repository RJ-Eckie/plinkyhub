import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:plinkyhub/models/parameter.dart';
import 'package:plinkyhub/models/patch.dart';
import 'package:plinkyhub/state/play_state.dart';
import 'package:plinkyhub/state/plinky_notifier.dart';
import 'package:plinkyhub/utils/pitch.dart';

final playProvider = NotifierProvider<PlayNotifier, PlayState>(
  PlayNotifier.new,
);

class PlayNotifier extends Notifier<PlayState> {
  AudioSource? _audioSource;

  /// One voice per column (8 columns max), matching Plinky polyphony.
  final _activeHandles = <int, SoundHandle>{};

  @override
  PlayState build() => const PlayState();

  /// Load a WAV sample for playback.
  Future<void> loadSample(
    String name,
    Uint8List wavBytes, {
    int baseMidi = 60,
  }) async {
    state = state.copyWith(isLoadingSample: true);
    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) {
        await soloud.init();
      }

      // Dispose previous source if any.
      final oldSource = _audioSource;
      if (oldSource != null) {
        _stopAll();
        soloud.disposeSource(oldSource);
      }

      _audioSource = await soloud.loadMem('sample.wav', wavBytes);
      state = state.copyWith(
        sampleWavBytes: wavBytes,
        sampleName: name,
        sampleBaseMidi: baseMidi,
        isLoadingSample: false,
      );
    } on Exception catch (error) {
      debugPrint('Failed to load sample: $error');
      state = state.copyWith(isLoadingSample: false);
    }
  }

  /// Start playing the note for the pad at [row], [col].
  Future<void> playPad(int row, int col) async {
    final source = _audioSource;
    if (source == null) return;

    final soloud = SoLoud.instance;
    final padIndex = row * 8 + col;

    // Stop existing voice in this column.
    final existing = _activeHandles.remove(col);
    if (existing != null) {
      try {
        soloud.stop(existing);
      } on Exception catch (_) {
        // Handle may have already finished.
      }
    }

    // Read pitch config from current patch.
    final patch = ref.read(plinkyProvider).patch;
    int scaleIndex = 26; // chromatic default
    int stride = 7; // fifths default
    int octaveOffset = 0;
    double pitchOffset = 0;

    if (patch != null) {
      final scaleParam = _findParam(patch, 'P_SCALE');
      if (scaleParam != null) {
        // Scale value is 0-1024 mapped to enum indices.
        final options = scaleParam.getSelectOptions();
        if (options != null && options.isNotEmpty) {
          final width = 1024 / options.length;
          scaleIndex = (scaleParam.value / width)
              .floor()
              .clamp(0, options.length - 1);
        }
      }

      final strideParam = _findParam(patch, 'P_STRIDE');
      if (strideParam != null) {
        // P_STRIDE range is 0-127, representing semitones.
        stride = strideParam.value.clamp(0, 127);
      }

      final octParam = _findParam(patch, 'P_OCT');
      if (octParam != null) {
        // P_OCT range is -1024 to 1024, map to octaves (-4 to +4).
        octaveOffset = (octParam.value / 256).round();
      }

      final pitchParam = _findParam(patch, 'P_PITCH');
      if (pitchParam != null) {
        // P_PITCH range is -1024 to 1024, map to -12..+12 semitones.
        pitchOffset = pitchParam.value / 1024 * 12;
      }
    }

    final targetMidi = midiNoteForPad(
      row: row,
      col: col,
      scaleIndex: scaleIndex,
      stride: stride,
      octaveOffset: octaveOffset,
      pitchOffset: pitchOffset,
    );

    final speed = playbackSpeedForMidi(targetMidi, state.sampleBaseMidi);

    try {
      final handle = await soloud.play(source);
      soloud.setRelativePlaySpeed(handle, speed);
      _activeHandles[col] = handle;
      state = state.copyWith(
        activePads: {...state.activePads, padIndex},
      );
    } on Exception catch (error) {
      debugPrint('Failed to play pad: $error');
    }
  }

  /// Stop the note for the pad at [row], [col].
  void stopPad(int row, int col) {
    final padIndex = row * 8 + col;
    final handle = _activeHandles.remove(col);
    if (handle != null) {
      try {
        SoLoud.instance.stop(handle);
      } on Exception catch (_) {
        // May already be stopped.
      }
    }
    state = state.copyWith(
      activePads: {...state.activePads}..remove(padIndex),
    );
  }

  static Parameter? _findParam(Patch patch, String id) {
    for (final p in patch.parameters) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _stopAll() {
    final soloud = SoLoud.instance;
    for (final handle in _activeHandles.values) {
      try {
        soloud.stop(handle);
      } on Exception catch (_) {}
    }
    _activeHandles.clear();
    state = state.copyWith(activePads: {});
  }
}
