import 'dart:typed_data';

import 'package:dart_midi_pro/dart_midi_pro.dart';
import 'package:plinkyhub/pages/patterns/create_pattern_tab.dart';
import 'package:plinkyhub/utils/pitch.dart';

/// Result of importing a MIDI file into the pattern grid format.
class MidiImportResult {
  MidiImportResult({
    required this.grid,
    required this.trackNames,
  });

  // 2D grid indexed by step then row, true = active.
  final List<List<bool>> grid;

  /// Names of tracks found in the MIDI file (for track selection UI).
  final List<String> trackNames;
}

/// Imports a MIDI file and converts it to a pattern grid.
///
/// [midiBytes] is the raw MIDI file content.
/// [scale] determines how MIDI note numbers map to grid rows.
/// [trackIndex] selects which track to import (null = merge all tracks).
MidiImportResult importMidiToGrid({
  required Uint8List midiBytes,
  required PlinkyScale scale,
  int? trackIndex,
}) {
  final parser = MidiParser();
  final midiFile = parser.parseMidiFromBuffer(midiBytes);
  final ticksPerBeat = midiFile.header.ticksPerBeat ?? 480;

  // Extract track names.
  final trackNames = <String>[];
  for (var i = 0; i < midiFile.tracks.length; i++) {
    String? name;
    for (final event in midiFile.tracks[i]) {
      if (event is TrackNameEvent) {
        name = event.text;
        break;
      }
    }
    trackNames.add(name ?? 'Track ${i + 1}');
  }

  // Collect note-on events from selected track(s).
  final noteOns = <({int tick, int noteNumber})>[];

  final tracksToProcess = trackIndex != null
      ? [midiFile.tracks[trackIndex]]
      : midiFile.tracks;

  for (final track in tracksToProcess) {
    var absoluteTick = 0;
    for (final event in track) {
      absoluteTick += event.deltaTime;
      if (event is NoteOnEvent && event.velocity > 0) {
        noteOns.add((tick: absoluteTick, noteNumber: event.noteNumber));
      }
    }
  }

  if (noteOns.isEmpty) {
    return MidiImportResult(
      grid: [
        for (var s = 0; s < fixedStepCount; s++)
          [for (var r = 0; r < 8; r++) false],
      ],
      trackNames: trackNames,
    );
  }

  // Determine the quantization grid: one step = one sixteenth note.
  final ticksPerStep = ticksPerBeat ~/ 4;

  // Build a reverse lookup: for each MIDI note, find the closest grid row.
  // Compute MIDI notes for each row in the current scale.
  final rowMidiNotes = <int>[
    for (var row = 0; row < 8; row++)
      midiNoteForPad(row: row, col: 0, scale: scale),
  ];

  // Create the grid (always 64 steps to match firmware storage).
  final grid = [
    for (var s = 0; s < fixedStepCount; s++)
      [for (var r = 0; r < 8; r++) false],
  ];

  for (final note in noteOns) {
    final step = (note.tick / ticksPerStep).round();
    if (step >= fixedStepCount) {
      continue;
    }

    // Find the closest row for this MIDI note.
    var bestRow = 0;
    var bestDistance = (note.noteNumber - rowMidiNotes[0]).abs();
    for (var row = 1; row < 8; row++) {
      final distance = (note.noteNumber - rowMidiNotes[row]).abs();
      if (distance < bestDistance) {
        bestRow = row;
        bestDistance = distance;
      }
    }

    grid[step][bestRow] = true;
  }

  return MidiImportResult(
    grid: grid,
    trackNames: trackNames,
  );
}
