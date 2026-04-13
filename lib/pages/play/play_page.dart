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
    final activePads = ref.watch(
      midiPlayProvider.select((state) => state.activePadIndices),
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
                child: DropdownButtonFormField<int?>(
                  initialValue: _presetSlot,
                  decoration: const InputDecoration(
                    labelText: 'Preset slot (optional)',
                    helperText:
                        'Sends a program change to switch the Plinky preset',
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
                  activePads: activePads,
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

class _PadGrid extends ConsumerWidget {
  const _PadGrid({
    required this.scale,
    required this.octaveOffset,
    required this.activePads,
    required this.enabled,
    required this.latch,
  });

  final PlinkyScale scale;
  final int octaveOffset;
  final Set<int> activePads;
  final bool enabled;
  final bool latch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
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
                          scale: scale,
                          octaveOffset: octaveOffset,
                        ),
                        isActive: activePads.contains(row * 8 + col),
                        enabled: enabled,
                        onPressStart: () {
                          final notifier = ref.read(
                            midiPlayProvider.notifier,
                          );
                          // In latch mode a second press on an already
                          // playing pad releases it; otherwise pressing
                          // always starts the note.
                          if (latch && activePads.contains(row * 8 + col)) {
                            notifier.releasePad(row, col);
                          } else {
                            notifier.pressPad(
                              row: row,
                              col: col,
                              scale: scale,
                              octaveOffset: octaveOffset,
                            );
                          }
                        },
                        onPressEnd: () {
                          // Latched notes stay sounding until pressed
                          // again; only release on pointer-up otherwise.
                          if (!latch) {
                            ref
                                .read(midiPlayProvider.notifier)
                                .releasePad(row, col);
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Pad extends StatefulWidget {
  const _Pad({
    required this.midiNote,
    required this.isActive,
    required this.enabled,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final int midiNote;
  final bool isActive;
  final bool enabled;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  State<_Pad> createState() => _PadState();
}

class _PadState extends State<_Pad> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disabled = !widget.enabled;
    final fillColor = disabled
        ? colorScheme.surfaceContainerLow
        : widget.isActive
        ? colorScheme.primary
        : _hovering
        ? Color.lerp(
            colorScheme.surfaceContainerHighest,
            colorScheme.primary,
            0.15,
          )!
        : colorScheme.surfaceContainerHighest;
    final textColor = widget.isActive
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: disabled ? 0.4 : 0.85);

    final pad = Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isActive
              ? colorScheme.primary
              : colorScheme.outlineVariant,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _midiNoteName(widget.midiNote),
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (disabled) {
      return pad;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Listener(
        onPointerDown: (_) => widget.onPressStart(),
        onPointerUp: (_) => widget.onPressEnd(),
        onPointerCancel: (_) => widget.onPressEnd(),
        child: pad,
      ),
    );
  }
}
