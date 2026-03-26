import 'dart:math';

/// Scale interval tables matching Plinky firmware's 27 built-in scales.
/// Each list contains semitone offsets for one octave of the scale.
const plinkyScales = <List<int>>[
  [0, 2, 4, 5, 7, 9, 11], // Major
  [0, 2, 3, 5, 7, 8, 10], // Minor
  [0, 2, 3, 5, 7, 8, 11], // Harmonic Min
  [0, 2, 4, 7, 9], // Penta Maj
  [0, 3, 5, 7, 10], // Penta Min
  [0, 2, 3, 7, 8], // Hirajoshi
  [0, 1, 5, 7, 10], // Insen
  [0, 1, 5, 6, 10], // Iwato
  [0, 4, 5, 7, 11], // Minyo
  [0, 7], // Fifths
  [0, 4, 7], // Triad Maj
  [0, 3, 7], // Triad Min
  [0, 2, 3, 5, 7, 9, 10], // Dorian
  [0, 1, 3, 5, 7, 8, 10], // Phrygian
  [0, 2, 4, 6, 7, 9, 11], // Lydian
  [0, 2, 4, 5, 7, 9, 10], // Mixolydian
  [0, 2, 3, 5, 7, 8, 10], // Aeolian
  [0, 1, 3, 5, 6, 8, 10], // Locrian
  [0, 3, 5, 6, 7, 10], // Blues Min
  [0, 2, 3, 4, 7, 9], // Blues Maj
  [0, 2, 3, 6, 7, 9, 10], // Romanian
  [0, 2, 4, 6, 8, 10], // Wholetone
  [0, 12, 19, 24, 28, 31], // Harmonics (approx)
  [0, 3, 5, 7, 9, 11], // Hexany (approx)
  [0, 2, 4, 5, 7, 9, 11], // Just (approx, mapped to ET)
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], // Chromatic
];

/// Converts a row position (0-7, top to bottom) to a semitone offset
/// using the given scale. Wraps into higher octaves as needed.
int _scaleDegreeSemitones(int row, int scaleIndex) {
  // Row 0 is the top of the grid (highest pitch), row 7 is the bottom
  // (lowest pitch). Invert so that pressing higher rows gives higher notes.
  final degree = 7 - row;
  final scale =
      scaleIndex.clamp(0, plinkyScales.length - 1);
  final intervals = plinkyScales[scale];
  final octave = degree ~/ intervals.length;
  final step = degree % intervals.length;
  return octave * 12 + intervals[step];
}

/// Computes the MIDI note number for a pad at [row], [col] in the 8x8 grid.
///
/// [scaleIndex] selects the scale (0-26).
/// [stride] is the semitone interval between columns (typically 7 = fifth).
/// [octaveOffset] shifts the base by octaves (-4 to +4 mapped from param).
/// [pitchOffset] is a fine-tune in semitones (fractional).
int midiNoteForPad({
  required int row,
  required int col,
  int scaleIndex = 26, // chromatic
  int stride = 7,
  int octaveOffset = 0,
  double pitchOffset = 0,
}) {
  const baseMidi = 48; // C3
  final colOffset = col * stride;
  final rowOffset = _scaleDegreeSemitones(row, scaleIndex);
  return baseMidi + octaveOffset * 12 + colOffset + rowOffset +
      pitchOffset.round();
}

/// Returns the playback speed multiplier to pitch-shift from [baseMidi]
/// to [targetMidi]. Speed 1.0 = no shift, 2.0 = one octave up, etc.
double playbackSpeedForMidi(int targetMidi, int baseMidi) {
  return pow(2, (targetMidi - baseMidi) / 12).toDouble();
}
