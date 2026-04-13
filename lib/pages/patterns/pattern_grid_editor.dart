import 'package:flutter/material.dart';
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

/// Returns a human-readable note name for a MIDI note number (e.g. "C4").
String _midiNoteName(int midi) {
  final octave = (midi ~/ 12) - 1;
  return '${_noteNames[midi % 12]}$octave';
}

/// A piano-roll-style step-sequencer grid for Plinky patterns.
///
/// Each row is one of the 64 Plinky pads (8 strings × 8 columns) sorted
/// from highest to lowest pitch. Each column is one step. Tapping a
/// cell places a note at that pitch and step; clicking again clears it.
/// Per-string monophony is enforced — placing a note on a string at a
/// step automatically clears any other column the same string had at
/// the same step.
///
/// Cell values in [grid] use the firmware-friendly encoding:
///   0     = inactive
///   1..8  = active at touch-strip column 0..7
class PatternGridEditor extends StatefulWidget {
  const PatternGridEditor({
    required this.grid,
    required this.scale,
    required this.onGridChanged,
    this.enabled = true,
    this.readOnly = false,
    this.currentPlaybackStep,
    super.key,
  });

  /// 2D grid indexed by step then string. Cell value: 0 = inactive,
  /// 1..8 = active at touch-strip column 0..7.
  final List<List<int>> grid;
  final PlinkyScale scale;
  final ValueChanged<List<List<int>>> onGridChanged;
  final bool enabled;

  /// When true, cells cannot be toggled and hover effects are disabled.
  final bool readOnly;

  /// When non-null, draws a vertical playback bar over the given step
  /// index to indicate the currently-playing column.
  final int? currentPlaybackStep;

  @override
  State<PatternGridEditor> createState() => _PatternGridEditorState();
}

class _PatternGridEditorState extends State<PatternGridEditor> {
  /// Cell width including the 1px margin on each side.
  static const _cellWithMargin = 26.0;

  /// Cell height including the 1px margin on each side.
  static const _rowHeight = 22.0;

  /// Width reserved for the pitch label column.
  static const _labelWidth = 56.0;

  /// Height of the step-numbers header row.
  static const _headerHeight = 20.0;

  /// Default viewport when the parent doesn't constrain our height
  /// (e.g. when nested in a SingleChildScrollView).
  static const _fallbackViewportHeight = 520.0;

  final _horizontalScrollController = ScrollController();
  final _verticalScrollController = ScrollController();

  /// The cell value the current drag gesture is painting (0 to clear,
  /// or `column + 1` to paint).
  int? _dragPaintValue;

  late List<PlinkyPad> _pads;

  @override
  void initState() {
    super.initState();
    _pads = plinkyPadsByPitch(widget.scale);
  }

  @override
  void didUpdateWidget(covariant PatternGridEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scale != oldWidget.scale) {
      _pads = plinkyPadsByPitch(widget.scale);
    }
    if (widget.currentPlaybackStep != oldWidget.currentPlaybackStep) {
      _scrollToPlaybackStep();
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  /// Keeps the currently-playing column horizontally centred in the
  /// viewport. Clamped at both ends so we don't scroll past the start
  /// or end of the grid.
  void _scrollToPlaybackStep() {
    final step = widget.currentPlaybackStep;
    if (step == null || !_horizontalScrollController.hasClients) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_horizontalScrollController.hasClients) {
        return;
      }
      final position = _horizontalScrollController.position;
      final viewportWidth = position.viewportDimension;
      final cellCenterOffset = step * _cellWithMargin + _cellWithMargin / 2;
      final target = (cellCenterOffset - viewportWidth / 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _horizontalScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  /// Returns true when the cell at (step, pad) should appear active —
  /// i.e. the grid records this string playing this column at this step.
  bool _isCellActive(int step, PlinkyPad pad) {
    return widget.grid[step][pad.string] == pad.column + 1;
  }

  /// Computes the value to write to (step, pad) when the user taps it:
  /// clear if it was already at this column, otherwise paint with this
  /// pad's column. Per-string monophony is implicit because the grid
  /// only stores one column per (step, string).
  int _nextValueOnTap(int step, PlinkyPad pad) {
    return _isCellActive(step, pad) ? 0 : pad.column + 1;
  }

  void _setCellValue(int step, int stringIndex, int value) {
    if (!widget.enabled || widget.readOnly) {
      return;
    }
    if (widget.grid[step][stringIndex] == value) {
      return;
    }
    final newGrid = [
      for (var s = 0; s < widget.grid.length; s++)
        [for (var r = 0; r < 8; r++) widget.grid[s][r]],
    ];
    newGrid[step][stringIndex] = value;
    widget.onGridChanged(newGrid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stepCount = widget.grid.length;
    final fullHeight = _headerHeight + _pads.length * _rowHeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pattern Grid', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : _fallbackViewportHeight;
              return SizedBox(
                height: viewportHeight,
                child: _PianoRollScroller(
                  pads: _pads,
                  stepCount: stepCount,
                  fullHeight: fullHeight,
                  cellWithMargin: _cellWithMargin,
                  rowHeight: _rowHeight,
                  labelWidth: _labelWidth,
                  headerHeight: _headerHeight,
                  colorScheme: colorScheme,
                  textTheme: theme.textTheme,
                  readOnly: widget.readOnly,
                  enabled: widget.enabled,
                  currentPlaybackStep: widget.currentPlaybackStep,
                  horizontalScrollController: _horizontalScrollController,
                  verticalScrollController: _verticalScrollController,
                  isCellActive: _isCellActive,
                  onTap: (step, padIndex) {
                    final pad = _pads[padIndex];
                    _setCellValue(
                      step,
                      pad.string,
                      _nextValueOnTap(step, pad),
                    );
                  },
                  onDragStart: (step, padIndex) {
                    final pad = _pads[padIndex];
                    final next = _nextValueOnTap(step, pad);
                    _dragPaintValue = next;
                    _setCellValue(step, pad.string, next);
                  },
                  onDragEnter: (step, padIndex) {
                    final value = _dragPaintValue;
                    if (value == null) {
                      return;
                    }
                    final pad = _pads[padIndex];
                    // Only paint cells whose current state matches the
                    // value we'd paint, to avoid accidentally clearing
                    // unrelated columns.
                    if (value == 0 || widget.grid[step][pad.string] == 0) {
                      _setCellValue(step, pad.string, value);
                    }
                  },
                  onDragEnd: () => _dragPaintValue = null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PianoRollScroller extends StatelessWidget {
  const _PianoRollScroller({
    required this.pads,
    required this.stepCount,
    required this.fullHeight,
    required this.cellWithMargin,
    required this.rowHeight,
    required this.labelWidth,
    required this.headerHeight,
    required this.colorScheme,
    required this.textTheme,
    required this.readOnly,
    required this.enabled,
    required this.currentPlaybackStep,
    required this.horizontalScrollController,
    required this.verticalScrollController,
    required this.isCellActive,
    required this.onTap,
    required this.onDragStart,
    required this.onDragEnter,
    required this.onDragEnd,
  });

  final List<PlinkyPad> pads;
  final int stepCount;
  final double fullHeight;
  final double cellWithMargin;
  final double rowHeight;
  final double labelWidth;
  final double headerHeight;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool readOnly;
  final bool enabled;
  final int? currentPlaybackStep;
  final ScrollController horizontalScrollController;
  final ScrollController verticalScrollController;
  final bool Function(int step, PlinkyPad pad) isCellActive;
  final void Function(int step, int padIndex) onTap;
  final void Function(int step, int padIndex) onDragStart;
  final void Function(int step, int padIndex) onDragEnter;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: verticalScrollController,
        child: SizedBox(
          height: fullHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: _PitchLabels(
                  pads: pads,
                  rowHeight: rowHeight,
                  headerHeight: headerHeight,
                  textStyle: textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: horizontalScrollController,
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.depth == 0,
                  child: SingleChildScrollView(
                    controller: horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: stepCount * cellWithMargin,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StepHeader(
                                stepCount: stepCount,
                                cellWidth: cellWithMargin,
                                headerHeight: headerHeight,
                                textStyle: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              for (
                                var padIndex = 0;
                                padIndex < pads.length;
                                padIndex++
                              )
                                _PadRow(
                                  pad: pads[padIndex],
                                  padIndex: padIndex,
                                  stepCount: stepCount,
                                  cellWithMargin: cellWithMargin,
                                  rowHeight: rowHeight,
                                  colorScheme: colorScheme,
                                  readOnly: readOnly || !enabled,
                                  isActive: isCellActive,
                                  onTap: onTap,
                                  onDragStart: onDragStart,
                                  onDragEnter: onDragEnter,
                                  onDragEnd: onDragEnd,
                                ),
                            ],
                          ),
                          if (currentPlaybackStep != null)
                            Positioned(
                              left: currentPlaybackStep! * cellWithMargin,
                              top: headerHeight,
                              width: cellWithMargin,
                              height: pads.length * rowHeight,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    border: Border(
                                      left: BorderSide(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                      right: BorderSide(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Left column of pitch labels, one per pad.
class _PitchLabels extends StatelessWidget {
  const _PitchLabels({
    required this.pads,
    required this.rowHeight,
    required this.headerHeight,
    required this.textStyle,
  });

  final List<PlinkyPad> pads;
  final double rowHeight;
  final double headerHeight;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: headerHeight),
        for (final pad in pads)
          SizedBox(
            height: rowHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _midiNoteName(pad.midiNote),
                  style: textStyle?.copyWith(fontSize: 11),
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Step-numbers header row (1, 2, 3, ...).
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.stepCount,
    required this.cellWidth,
    required this.headerHeight,
    required this.textStyle,
  });

  final int stepCount;
  final double cellWidth;
  final double headerHeight;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var step = 0; step < stepCount; step++)
          SizedBox(
            width: cellWidth,
            height: headerHeight,
            child: Center(
              child: Text('${step + 1}', style: textStyle),
            ),
          ),
      ],
    );
  }
}

/// One row of step cells for a single pad.
class _PadRow extends StatelessWidget {
  const _PadRow({
    required this.pad,
    required this.padIndex,
    required this.stepCount,
    required this.cellWithMargin,
    required this.rowHeight,
    required this.colorScheme,
    required this.readOnly,
    required this.isActive,
    required this.onTap,
    required this.onDragStart,
    required this.onDragEnter,
    required this.onDragEnd,
  });

  final PlinkyPad pad;
  final int padIndex;
  final int stepCount;
  final double cellWithMargin;
  final double rowHeight;
  final ColorScheme colorScheme;
  final bool readOnly;
  final bool Function(int step, PlinkyPad pad) isActive;
  final void Function(int step, int padIndex) onTap;
  final void Function(int step, int padIndex) onDragStart;
  final void Function(int step, int padIndex) onDragEnter;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var step = 0; step < stepCount; step++)
          _GridCell(
            isActive: isActive(step, pad),
            isDownbeat: step % 4 == 0,
            cellSize: cellWithMargin - 2,
            rowHeight: rowHeight,
            colorScheme: colorScheme,
            readOnly: readOnly,
            onTap: () => onTap(step, padIndex),
            onDragStart: () => onDragStart(step, padIndex),
            onDragEnter: () => onDragEnter(step, padIndex),
            onDragEnd: onDragEnd,
          ),
      ],
    );
  }
}

class _GridCell extends StatefulWidget {
  const _GridCell({
    required this.isActive,
    required this.isDownbeat,
    required this.cellSize,
    required this.rowHeight,
    required this.colorScheme,
    required this.onTap,
    required this.onDragStart,
    required this.onDragEnter,
    required this.onDragEnd,
    this.readOnly = false,
  });

  final bool isActive;
  final bool isDownbeat;
  final double cellSize;
  final double rowHeight;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnter;
  final VoidCallback onDragEnd;
  final bool readOnly;

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isActive
        ? widget.colorScheme.primary
        : widget.isDownbeat
        ? widget.colorScheme.surfaceContainerHighest
        : widget.colorScheme.surfaceContainerLow;
    final fillColor = _isHovered && !widget.readOnly
        ? Color.lerp(baseColor, widget.colorScheme.onSurface, 0.15)!
        : baseColor;
    final borderColor = _isHovered && !widget.readOnly
        ? widget.colorScheme.outline
        : widget.colorScheme.outlineVariant;

    final cell = Container(
      width: widget.cellSize,
      height: widget.rowHeight - 2,
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      margin: const EdgeInsets.all(1),
    );

    if (widget.readOnly) {
      return cell;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (_) => widget.onDragStart(),
        onPanEnd: (_) => widget.onDragEnd(),
        onPanCancel: widget.onDragEnd,
        child: DragTarget<Object>(
          onWillAcceptWithDetails: (_) {
            widget.onDragEnter();
            return false;
          },
          builder: (context, _, __) => cell,
        ),
      ),
    );
  }
}
