import 'dart:async';

import 'package:flutter/foundation.dart';
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
      _restartTimer(_currentPattern!, channel: _currentChannel);
    }
  }

  /// Start playing [pattern]. Sends a program change first if
  /// [presetSlot] is non-null (0..31).
  void play({
    required String patternId,
    required PatternData pattern,
    int? presetSlot,
    double beatsPerMinute = 120,
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
    _advance(pattern, channel: channel, initial: true);
    _restartTimer(pattern, channel: channel);
  }

  void _restartTimer(PatternData pattern, {required int channel}) {
    _timer?.cancel();
    // Plinky patterns use 16 sixteenth-note steps; one beat = 4 steps.
    final stepDurationMilliseconds = (60000 / (state.beatsPerMinute * 4))
        .round()
        .clamp(20, 2000);
    _timer = Timer.periodic(
      Duration(milliseconds: stepDurationMilliseconds),
      (_) => _advance(pattern, channel: channel),
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

  void _advance(
    PatternData pattern, {
    required int channel,
    bool initial = false,
  }) {
    final midiNotifier = ref.read(midiProvider.notifier);
    final stepCount = pattern.grid.length;
    if (stepCount == 0) {
      return;
    }

    // Release notes from the previous step.
    for (final note in _activeNotes) {
      midiNotifier.sendNoteOff(note, channel: channel);
    }
    _activeNotes.clear();

    final nextStep = initial ? 0 : (state.currentStep + 1) % stepCount;
    final scale = _scaleFromIndex(pattern.scaleIndex);
    final rowValues = pattern.grid[nextStep];

    for (var row = 0; row < rowValues.length; row++) {
      if (rowValues[row] != 0) {
        final midiNote = midiNoteForPad(
          row: row,
          col: 0,
          scale: scale,
        );
        midiNotifier.sendNoteOn(midiNote, channel: channel);
        _activeNotes.add(midiNote);
      }
    }

    state = state.copyWith(currentStep: nextStep);
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
