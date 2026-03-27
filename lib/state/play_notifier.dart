import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/state/play_state.dart';
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

  /// Load a WAV sample for playback with its slice configuration.
  Future<void> loadSample(
    String name,
    Uint8List wavBytes, {
    int baseMidi = 60,
    List<double> slicePoints = defaultSlicePoints,
    List<int> sliceNotes = defaultSliceNotes,
    bool pitched = false,
  }) async {
    state = state.copyWith(isLoadingSample: true);
    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) {
        debugPrint('Initializing SoLoud...');
        await soloud.init();
        debugPrint('SoLoud initialized');
      }

      // Dispose previous source if any.
      final oldSource = _audioSource;
      if (oldSource != null) {
        _stopAll();
        soloud.disposeSource(oldSource);
      }

      debugPrint('Loading sample (${wavBytes.length} bytes)...');
      _audioSource = await soloud.loadMem('sample.wav', wavBytes);
      debugPrint('Sample loaded');
      state = state.copyWith(
        sampleWavBytes: wavBytes,
        sampleName: name,
        sampleBaseMidi: baseMidi,
        slicePoints: slicePoints,
        sliceNotes: sliceNotes,
        pitched: pitched,
        isLoadingSample: false,
      );
    } on Exception catch (error) {
      debugPrint('Failed to load sample: $error');
      state = state.copyWith(isLoadingSample: false);
    }
  }

  /// Start playing the slice for the pad at [row], [col].
  ///
  /// Each row (0-7) corresponds to a slice of the sample.
  /// Row 0 (top) = slice 0, row 7 (bottom) = slice 7.
  /// Columns provide polyphony — one voice per column.
  Future<void> playPad(int row, int col) async {
    final source = _audioSource;
    if (source == null) {
      return;
    }

    final soloud = SoLoud.instance;
    final padIndex = row * 8 + col;

    // Stop existing voice in this column.
    final existing = _activeHandles.remove(col);
    if (existing != null) {
      try {
        soloud.stop(existing);
      } on Exception catch (_) {}
    }

    // Determine slice boundaries.
    final sliceIndex = row.clamp(0, 7);
    final slicePoints = state.slicePoints;
    final startFraction = slicePoints[sliceIndex];
    final endFraction =
        sliceIndex < 7 ? slicePoints[sliceIndex + 1] : 1.0;

    final totalDuration = soloud.getLength(source);
    final startTime = totalDuration * startFraction;
    final sliceDuration =
        totalDuration * (endFraction - startFraction);

    // Calculate pitch shift.
    // The slice note is the intended pitch for this slice.
    // Speed = 1.0 means play at the sample's original pitch.
    final sliceNote = state.sliceNotes.length > sliceIndex
        ? state.sliceNotes[sliceIndex]
        : 60;
    // On Plinky, slice notes are in Plinky note format (48 = C4).
    // Convert to MIDI: plinkyNote + 12 = midiNote.
    final sliceMidi = sliceNote + 12;
    final speed = playbackSpeedForMidi(sliceMidi, state.sampleBaseMidi);

    try {
      final handle = await soloud.play(source, paused: true);
      soloud.seek(handle, startTime);
      soloud.setRelativePlaySpeed(handle, speed);
      soloud.setPause(handle, false);

      // Schedule stop at the end of the slice (adjusted for speed).
      if (sliceDuration > Duration.zero) {
        final adjustedDuration = sliceDuration * (1.0 / speed);
        soloud.scheduleStop(handle, adjustedDuration);
      }

      _activeHandles[col] = handle;
      state = state.copyWith(
        activePads: {...state.activePads, padIndex},
      );

      // Clear active state when the slice finishes.
      final waitDuration = sliceDuration * (1.0 / speed);
      await Future<void>.delayed(waitDuration);
      if (state.activePads.contains(padIndex)) {
        _activeHandles.remove(col);
        state = state.copyWith(
          activePads: {...state.activePads}..remove(padIndex),
        );
      }
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
      } on Exception catch (_) {}
    }
    state = state.copyWith(
      activePads: {...state.activePads}..remove(padIndex),
    );
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
