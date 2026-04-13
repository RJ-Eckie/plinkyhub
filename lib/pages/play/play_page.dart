import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/state/midi_notifier.dart';
import 'package:plinkyhub/state/midi_play_notifier.dart';
import 'package:plinkyhub/state/midi_state.dart';
import 'package:plinkyhub/utils/pitch.dart';

const _noteNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

String _midiNoteName(int midi) {
  final octave = (midi ~/ 12) - 1;
  return '${_noteNames[midi % 12]}$octave';
}

const _presetSlotCount = 32;

/// 8×8 pad grid that streams MIDI to the connected Plinky over
/// WebMIDI. Tap a pad to send note-on for its pitch (computed from
/// the selected scale/stride/octave); release to send note-off. The
/// Plinky plays whichever sound its currently-loaded preset
/// produces — this page is a controller, not an emulator.
class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({super.key});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> {
  PlinkyScale _scale = PlinkyScale.major;
  int _octaveOffset = 0;
  int? _presetSlot;
  bool _latch = false;

  void _onLatchChanged(bool value) {
    setState(() => _latch = value);
    // Turning latch off should silence anything that was being held —
    // otherwise a stranded note would keep sounding.
    if (!value) {
      ref.read(midiPlayProvider.notifier).releaseAll();
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final midiState = ref.read(midiProvider);
      if (!midiState.isConnected) {
        await ref.read(midiProvider.notifier).connect();
      }
    });
  }

  void _onPresetSlotChanged(int? slot) {
    setState(() => _presetSlot = slot);
    if (slot != null) {
      ref.read(midiProvider.notifier).sendProgramChange(slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final midiState = ref.watch(midiProvider);
    final pressureByPad = ref.watch(
      midiPlayProvider.select((state) => state.pressureByPad),
    );
    final hasOutput = midiState.selectedOutputId != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PlinkyScale>(
                  initialValue: _scale,
                  decoration: const InputDecoration(
                    labelText: 'Scale',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    for (final scale in PlinkyScale.values)
                      DropdownMenuItem(
                        value: scale,
                        child: Text(scale.displayName),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _scale = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<int>(
                  initialValue: _octaveOffset,
                  decoration: const InputDecoration(
                    labelText: 'Octave',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    for (var octave = -4; octave <= 4; octave++)
                      DropdownMenuItem(
                        value: octave,
                        child: Text(octave >= 0 ? '+$octave' : '$octave'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _octaveOffset = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MidiOutputDropdown(
                  midiState: midiState,
                  onSelected: ref.read(midiProvider.notifier).selectOutput,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message:
                      'Sends a program change to switch the Plinky '
                      'preset',
                  child: DropdownButtonFormField<int?>(
                    initialValue: _presetSlot,
                    decoration: const InputDecoration(
                      labelText: 'Preset slot (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        child: Text('Use currently selected preset'),
                      ),
                      for (var slot = 0; slot < _presetSlotCount; slot++)
                        DropdownMenuItem<int?>(
                          value: slot,
                          child: Text('Preset ${slot + 1}'),
                        ),
                    ],
                    onChanged: _onPresetSlotChanged,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Tooltip(
                message: 'Hold notes until you tap the pad again',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Latch'),
                    Switch(value: _latch, onChanged: _onLatchChanged),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Press near the centre of a pad for full velocity; '
                  'pressure falls off toward the edges and the cell '
                  'brightens to match. Sliding your finger sends '
                  'polyphonic aftertouch to the Plinky.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (!hasOutput) ...[
            const SizedBox(height: 12),
            Text(
              'No MIDI output detected. Plug in your Plinky and refresh '
              'the MIDI access permission if needed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: _PadGrid(
                  scale: _scale,
                  octaveOffset: _octaveOffset,
                  pressureByPad: pressureByPad,
                  enabled: hasOutput,
                  latch: _latch,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MidiOutputDropdown extends StatelessWidget {
  const _MidiOutputDropdown({
    required this.midiState,
    required this.onSelected,
  });

  final MidiState midiState;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final outputs = midiState.outputs;
    if (outputs.isEmpty) {
      return const Text('No MIDI outputs');
    }
    return DropdownButtonFormField<String>(
      initialValue: midiState.selectedOutputId,
      decoration: const InputDecoration(
        labelText: 'MIDI output',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: [
        for (final output in outputs)
          DropdownMenuItem<String>(
            value: output.id,
            child: Text(
              output.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onSelected,
    );
  }
}

class _PadGrid extends ConsumerStatefulWidget {
  const _PadGrid({
    required this.scale,
    required this.octaveOffset,
    required this.pressureByPad,
    required this.enabled,
    required this.latch,
  });

  final PlinkyScale scale;
  final int octaveOffset;
  final Map<int, double> pressureByPad;
  final bool enabled;
  final bool latch;

  @override
  ConsumerState<_PadGrid> createState() => _PadGridState();
}

class _PadGridState extends ConsumerState<_PadGrid> {
  /// Maps each touch/pointer ID to the pad index it is currently on.
  /// We need to track this per pointer so that:
  ///   - sliding a finger off a pad releases it and presses the new
  ///     one (glissando), and
  ///   - multiple fingers on different pads don't interfere.
  final Map<int, int> _pointerToPad = {};

  /// Maps pointer IDs to whether their initial press happened on an
  /// already-active latched pad (in which case the press toggled it
  /// off, and we shouldn't immediately re-press it on slide).
  final Set<int> _pointersThatToggledOff = {};

  /// Hit-test result for [position] inside the grid: which pad was
  /// hit and what pressure that translates to (full at the centre,
  /// linearly falling off to 0 at the inscribed-circle edge).
  ({int row, int col, int padIndex, double pressure})? _hitTest(
    Offset position,
    Size size,
  ) {
    final cellWidth = size.width / 8;
    final cellHeight = size.height / 8;
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx >= size.width ||
        position.dy >= size.height) {
      return null;
    }
    final col = (position.dx / cellWidth).floor().clamp(0, 7);
    final row = (position.dy / cellHeight).floor().clamp(0, 7);

    // Position inside the pad (after the 2 px outer padding around
    // each cell from the surrounding `Padding(EdgeInsets.all(2))`).
    final padOriginX = col * cellWidth + 2;
    final padOriginY = row * cellHeight + 2;
    final innerWidth = cellWidth - 4;
    final innerHeight = cellHeight - 4;
    final localX = position.dx - padOriginX;
    final localY = position.dy - padOriginY;
    final centre = Offset(innerWidth / 2, innerHeight / 2);
    final radius = min(innerWidth, innerHeight) / 2;
    if (radius <= 0) {
      return (row: row, col: col, padIndex: row * 8 + col, pressure: 0);
    }
    final distance = (Offset(localX, localY) - centre).distance;
    final pressure = (1 - distance / radius).clamp(0.0, 1.0);
    return (
      row: row,
      col: col,
      padIndex: row * 8 + col,
      pressure: pressure,
    );
  }

  void _pressPad({
    required int row,
    required int col,
    required double pressure,
  }) {
    ref
        .read(midiPlayProvider.notifier)
        .pressPad(
          row: row,
          col: col,
          scale: widget.scale,
          octaveOffset: widget.octaveOffset,
          pressure: pressure,
        );
  }

  void _updatePressure({
    required int row,
    required int col,
    required double pressure,
  }) {
    ref
        .read(midiPlayProvider.notifier)
        .updatePadPressure(row: row, col: col, pressure: pressure);
  }

  void _releasePad(int padIndex) {
    final row = padIndex ~/ 8;
    final col = padIndex % 8;
    ref.read(midiPlayProvider.notifier).releasePad(row, col);
  }

  void _onPointerDown(PointerDownEvent event, Size gridSize) {
    final hit = _hitTest(event.localPosition, gridSize);
    if (hit == null) {
      return;
    }
    final padIndex = hit.padIndex;
    if (widget.latch) {
      if (widget.pressureByPad.containsKey(padIndex)) {
        // Tapping an already-latched pad releases it; remember that
        // this pointer toggled it off so a slide doesn't re-press
        // straight away.
        _releasePad(padIndex);
        _pointersThatToggledOff.add(event.pointer);
      } else {
        _pressPad(row: hit.row, col: hit.col, pressure: hit.pressure);
      }
    } else {
      _pressPad(row: hit.row, col: hit.col, pressure: hit.pressure);
    }
    _pointerToPad[event.pointer] = padIndex;
  }

  void _onPointerMove(PointerMoveEvent event, Size gridSize) {
    final hit = _hitTest(event.localPosition, gridSize);
    final previousPad = _pointerToPad[event.pointer];

    if (hit == null) {
      // Slid off the grid entirely.
      if (previousPad != null && !widget.latch) {
        _releasePad(previousPad);
      }
      _pointerToPad.remove(event.pointer);
      _pointersThatToggledOff.remove(event.pointer);
      return;
    }

    if (hit.padIndex == previousPad) {
      // Same pad — just update the pressure for the new finger
      // position (only meaningful for non-latched playing notes).
      if (!widget.latch && widget.pressureByPad.containsKey(hit.padIndex)) {
        _updatePressure(
          row: hit.row,
          col: hit.col,
          pressure: hit.pressure,
        );
      }
      return;
    }

    // Crossed into a different cell.
    if (widget.latch) {
      // Latch mode: don't auto-toggle as the finger drags around.
      _pointerToPad[event.pointer] = hit.padIndex;
      _pointersThatToggledOff.remove(event.pointer);
      return;
    }

    if (previousPad != null) {
      _releasePad(previousPad);
    }
    _pressPad(row: hit.row, col: hit.col, pressure: hit.pressure);
    _pointerToPad[event.pointer] = hit.padIndex;
  }

  void _onPointerUp(PointerEvent event) {
    final padIndex = _pointerToPad.remove(event.pointer);
    final toggledOff = _pointersThatToggledOff.remove(event.pointer);
    if (padIndex == null) {
      return;
    }
    // Latched notes keep sounding when the finger lifts. The
    // `toggledOff` flag means the press itself released the pad, so
    // there's nothing more to do either way.
    if (widget.latch || toggledOff) {
      return;
    }
    _releasePad(padIndex);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: disabled
              ? null
              : (event) => _onPointerDown(event, size),
          onPointerMove: disabled
              ? null
              : (event) => _onPointerMove(event, size),
          onPointerUp: disabled ? null : _onPointerUp,
          onPointerCancel: disabled ? null : _onPointerUp,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < 8; row++)
                Expanded(
                  child: Row(
                    children: [
                      for (var col = 0; col < 8; col++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: _Pad(
                              midiNote: midiNoteForPad(
                                row: row,
                                col: col,
                                scale: widget.scale,
                                octaveOffset: widget.octaveOffset,
                              ),
                              pressure:
                                  widget.pressureByPad[row * 8 + col] ?? 0,
                              isActive: widget.pressureByPad.containsKey(
                                row * 8 + col,
                              ),
                              enabled: widget.enabled,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Pad extends StatelessWidget {
  const _Pad({
    required this.midiNote,
    required this.pressure,
    required this.isActive,
    required this.enabled,
  });

  final int midiNote;

  /// Latest pressure value in [0, 1] for this pad — drives the cell
  /// brightness so the user sees a visible link between how close to
  /// the centre they touched and how loudly the note plays.
  final double pressure;
  final bool isActive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disabled = !enabled;
    // Brightness follows pressure: at p=1 the pad is the full primary
    // colour, at p=0 it's the surface container (same as inactive).
    final activeFill = Color.lerp(
      colorScheme.surfaceContainerHighest,
      colorScheme.primary,
      pressure,
    )!;
    final fillColor = disabled
        ? colorScheme.surfaceContainerLow
        : isActive
        ? activeFill
        : colorScheme.surfaceContainerHighest;
    final textColor = isActive && pressure > 0.5
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: disabled ? 0.4 : 0.85);

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _midiNoteName(midiNote),
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
