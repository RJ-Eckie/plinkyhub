import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/state/midi_notifier.dart';
import 'package:plinkyhub/utils/pitch.dart';

/// Per-pad state for the WebMIDI play page. Tracks which pads are
/// currently held down and what MIDI note each one sent, so we know
/// what to release on note-off (the scale or octave can change while
/// a pad is still pressed).
class MidiPlayState {
  const MidiPlayState({this.activeNotesByPad = const {}});

  final Map<int, int> activeNotesByPad;

  Set<int> get activePadIndices => activeNotesByPad.keys.toSet();

  MidiPlayState copyWith({Map<int, int>? activeNotesByPad}) {
    return MidiPlayState(
      activeNotesByPad: activeNotesByPad ?? this.activeNotesByPad,
    );
  }
}

final midiPlayProvider = NotifierProvider<MidiPlayNotifier, MidiPlayState>(
  MidiPlayNotifier.new,
);

class MidiPlayNotifier extends Notifier<MidiPlayState> {
  @override
  MidiPlayState build() {
    ref.onDispose(_releaseAll);
    return const MidiPlayState();
  }

  /// Sends a MIDI note-on for the pad at [row], [col] using the given
  /// [scale] / [stride] / [octaveOffset] mapping, and tracks the
  /// note so we can release it later.
  void pressPad({
    required int row,
    required int col,
    required PlinkyScale scale,
    int stride = 7,
    int octaveOffset = 0,
    int channel = 0,
    int velocity = 100,
  }) {
    final padIndex = row * 8 + col;
    if (state.activeNotesByPad.containsKey(padIndex)) {
      return;
    }
    final note = midiNoteForPad(
      row: row,
      col: col,
      scale: scale,
      stride: stride,
      octaveOffset: octaveOffset,
    );
    ref
        .read(midiProvider.notifier)
        .sendNoteOn(note, channel: channel, velocity: velocity);
    state = state.copyWith(
      activeNotesByPad: {...state.activeNotesByPad, padIndex: note},
    );
  }

  /// Sends a MIDI note-off for the previously-pressed pad and clears
  /// it from the active set.
  void releasePad(int row, int col, {int channel = 0}) {
    final padIndex = row * 8 + col;
    final note = state.activeNotesByPad[padIndex];
    if (note == null) {
      return;
    }
    ref.read(midiProvider.notifier).sendNoteOff(note, channel: channel);
    final updated = {...state.activeNotesByPad}..remove(padIndex);
    state = state.copyWith(activeNotesByPad: updated);
  }

  void _releaseAll() {
    if (state.activeNotesByPad.isEmpty) {
      return;
    }
    final midiNotifier = ref.read(midiProvider.notifier);
    for (final note in state.activeNotesByPad.values) {
      midiNotifier.sendNoteOff(note);
    }
    state = const MidiPlayState();
  }
}
