import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/pattern_data.dart';
import 'package:plinkyhub/state/midi_notifier.dart';
import 'package:plinkyhub/state/pattern_playback_state.dart';
import 'package:plinkyhub/utils/pitch.dart';

final patternPlaybackProvider =
    NotifierProvider<PatternPlaybackNotifier, PatternPlaybackState>(
      PatternPlaybackNotifier.new,
    );

/// Drives a step sequencer that sends MIDI note on/off messages for each
/// active cell in the pattern grid, one column at a time, to the currently
/// selected MIDI output.
class PatternPlaybackNotifier extends Notifier<PatternPlaybackState> {
  Timer? _timer;
  final _activeNotes = <int>{};
  PatternData? _currentPattern;
  int _currentChannel = 0;

  @override
  PatternPlaybackState build() {
    ref.onDispose(_stopInternal);
    return const PatternPlaybackState();
  }

  /// Update the playback tempo. Takes effect immediately if a pattern
  /// is currently playing.
  void setBeatsPerMinute(double beatsPerMinute) {
    state = state.copyWith(beatsPerMinute: beatsPerMinute);
    if (state.isPlaying && _currentPattern != null) {
      _restartTimer();
    }
  }

  /// Replace the live pattern data driving playback. Used by editors so
  /// that grid edits made while a pattern is playing take effect on the
  /// next step rather than requiring a stop/start.
  void updatePattern(String patternId, PatternData pattern) {
    if (!state.isPlaying || state.currentPatternId != patternId) {
      return;
    }
    _currentPattern = pattern;
  }

  /// Start playing [pattern]. Sends a program change first if
  /// [presetSlot] is non-null (0..31).
  void play({
    required String patternId,
    required PatternData pattern,
    int? presetSlot,
    double beatsPerMinute = 80,
    int channel = 0,
  }) {
    _stopInternal();

    final midiNotifier = ref.read(midiProvider.notifier);
    if (presetSlot != null) {
      midiNotifier.sendProgramChange(presetSlot, channel: channel);
    }

    if (pattern.grid.isEmpty) {
      return;
    }

    _currentPattern = pattern;
    _currentChannel = channel;

    state = state.copyWith(
      isPlaying: true,
      currentPatternId: patternId,
      currentStep: 0,
      presetSlot: presetSlot,
      beatsPerMinute: beatsPerMinute,
    );

    // Fire the first step immediately so audio starts on click.
    _advance(initial: true);
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    // Plinky patterns use 16 sixteenth-note steps; one beat = 4 steps.
    final stepDurationMilliseconds = (60000 / (state.beatsPerMinute * 4))
        .round()
        .clamp(20, 2000);
    _timer = Timer.periodic(
      Duration(milliseconds: stepDurationMilliseconds),
      (_) => _advance(),
    );
  }

  void stop() {
    _stopInternal();
    _currentPattern = null;
    state = state.copyWith(
      isPlaying: false,
      currentPatternId: null,
      currentStep: 0,
    );
  }

  void _advance({bool initial = false}) {
    final pattern = _currentPattern;
    if (pattern == null) {
      return;
    }
    final stepCount = pattern.grid.length;
    if (stepCount == 0) {
      return;
    }

    final nextStep = initial ? 0 : (state.currentStep + 1) % stepCount;

    // Update the visual playhead first so the rebuild is scheduled
    // before we send any MIDI. Otherwise audio (USB latency ~5 ms)
    // reaches the user before the next frame paints (~16 ms), and the
    // playhead appears to lag behind what's playing by one step.
    state = state.copyWith(currentStep: nextStep);

    // Defer the MIDI off/on burst until just after the current frame
    // is painted. This trades ~16 ms of audio latency for accurate
    // playhead-vs-audio sync. Re-read `_currentPattern` at fire time
    // so live edits made before the frame painted are picked up.
    final channel = _currentChannel;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _sendStepMidi(nextStep: nextStep, channel: channel);
    });
  }

  void _sendStepMidi({
    required int nextStep,
    required int channel,
  }) {
    if (!state.isPlaying) {
      return;
    }
    final pattern = _currentPattern;
    if (pattern == null) {
      return;
    }
    final midiNotifier = ref.read(midiProvider.notifier);

    // Release notes from the previous step.
    for (final note in _activeNotes) {
      midiNotifier.sendNoteOff(note, channel: channel);
    }
    _activeNotes.clear();

    if (nextStep >= pattern.grid.length) {
      return;
    }
    final scale = _scaleFromIndex(pattern.scaleIndex);
    final rowValues = pattern.grid[nextStep];
    for (var row = 0; row < rowValues.length; row++) {
      final value = rowValues[row];
      if (value == 0) {
        continue;
      }
      // Cell values 1..8 encode the touch-strip column (0..7); legacy
      // patterns (always 0/1) effectively play column 0.
      final column = (value - 1).clamp(0, 7);
      final midiNote = midiNoteForPad(
        row: row,
        col: column,
        scale: scale,
      );
      midiNotifier.sendNoteOn(midiNote, channel: channel);
      _activeNotes.add(midiNote);
    }
  }

  PlinkyScale _scaleFromIndex(int scaleIndex) {
    if (scaleIndex < 0 || scaleIndex >= PlinkyScale.values.length) {
      return PlinkyScale.major;
    }
    return PlinkyScale.values[scaleIndex];
  }

  void _stopInternal() {
    _timer?.cancel();
    _timer = null;

    if (_activeNotes.isNotEmpty) {
      try {
        final midiNotifier = ref.read(midiProvider.notifier);
        for (final note in _activeNotes) {
          midiNotifier.sendNoteOff(note);
        }
      } on Object catch (error) {
        debugPrint('Failed to send note off during stop: $error');
      }
      _activeNotes.clear();
    }
  }
}
