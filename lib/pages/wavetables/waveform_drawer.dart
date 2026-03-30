import 'dart:math';

import 'package:flutter/material.dart';

/// Drawing tools available in the waveform editor, matching WaveEdit.
enum DrawingTool {
  pencil,
  brush,
  grab,
  line,
  eraser,
  smooth,
}

/// Interactive widget for drawing a single-cycle waveform.
///
/// Displays a canvas where the user can click and drag to draw a waveform.
/// The horizontal axis represents one full cycle and
/// the vertical axis represents amplitude from −1.0 to 1.0.
class WaveformDrawer extends StatefulWidget {
  const WaveformDrawer({
    required this.samples,
    required this.onSamplesChanged,
    this.postEffectSamples,
    this.tool = DrawingTool.pencil,
    this.height = 300,
    super.key,
  });

  /// The current waveform samples, each in the range −1.0 to 1.0.
  final List<double> samples;

  /// Samples after effects are applied (shown as a ghost overlay).
  final List<double>? postEffectSamples;

  /// Called whenever the user modifies the waveform by drawing.
  final ValueChanged<List<double>> onSamplesChanged;

  /// The active drawing tool.
  final DrawingTool tool;

  /// Height of the drawing canvas.
  final double height;

  @override
  State<WaveformDrawer> createState() => _WaveformDrawerState();
}

class _WaveformDrawerState extends State<WaveformDrawer> {
  int? _lastDragIndex;

  /// For the Grab tool: the X index locked at drag start.
  int? _grabLockedIndex;

  /// For the Line tool: the position where the drag started.
  Offset? _lineStartPosition;

  /// For the Line tool: a snapshot of samples at drag start.
  List<double>? _lineBaselineSamples;

  List<double> _cloneSamples() => List<double>.from(widget.samples);

  int _positionToIndex(double localX, double canvasWidth) {
    final sampleCount = widget.samples.length;
    return (localX / canvasWidth * sampleCount).floor().clamp(
      0,
      sampleCount - 1,
    );
  }

  double _positionToAmplitude(double localY, double canvasHeight) {
    return (1.0 - 2.0 * localY / canvasHeight).clamp(-1.0, 1.0);
  }

  void _onDragStart(Offset localPosition, Size canvasSize) {
    _lastDragIndex = null;

    switch (widget.tool) {
      case DrawingTool.grab:
        _grabLockedIndex = _positionToIndex(localPosition.dx, canvasSize.width);
        _applyGrab(localPosition, canvasSize);
      case DrawingTool.line:
        _lineStartPosition = localPosition;
        _lineBaselineSamples = _cloneSamples();
      case DrawingTool.pencil:
      case DrawingTool.brush:
      case DrawingTool.eraser:
      case DrawingTool.smooth:
        _applyDraw(localPosition, canvasSize);
    }
  }

  void _onDragUpdate(Offset localPosition, Size canvasSize) {
    switch (widget.tool) {
      case DrawingTool.grab:
        _applyGrab(localPosition, canvasSize);
      case DrawingTool.line:
        _applyLine(localPosition, canvasSize);
      case DrawingTool.pencil:
      case DrawingTool.brush:
      case DrawingTool.eraser:
      case DrawingTool.smooth:
        _applyDraw(localPosition, canvasSize);
    }
  }

  void _onDragEnd() {
    _lastDragIndex = null;
    _grabLockedIndex = null;
    _lineStartPosition = null;
    _lineBaselineSamples = null;
  }

  void _applyDraw(Offset localPosition, Size canvasSize) {
    final sampleCount = widget.samples.length;
    final sampleIndex = _positionToIndex(localPosition.dx, canvasSize.width);
    final amplitude = _positionToAmplitude(localPosition.dy, canvasSize.height);
    final updatedSamples = _cloneSamples();

    switch (widget.tool) {
      case DrawingTool.pencil:
        _applyPencil(
          updatedSamples,
          sampleIndex,
          amplitude,
          sampleCount,
        );
      case DrawingTool.brush:
        _applyBrush(updatedSamples, sampleIndex, amplitude, sampleCount);
      case DrawingTool.eraser:
        _applyEraser(updatedSamples, sampleIndex, sampleCount);
      case DrawingTool.smooth:
        _applySmooth(updatedSamples, sampleIndex, sampleCount);
      case DrawingTool.grab:
      case DrawingTool.line:
        break;
    }

    _lastDragIndex = sampleIndex;
    widget.onSamplesChanged(updatedSamples);
  }

  void _applyPencil(
    List<double> samples,
    int sampleIndex,
    double amplitude,
    int sampleCount,
  ) {
    if (_lastDragIndex != null && _lastDragIndex != sampleIndex) {
      final startIndex = _lastDragIndex!;
      final startAmplitude = samples[startIndex];
      final steps = (sampleIndex - startIndex).abs();
      final direction = sampleIndex > startIndex ? 1 : -1;
      for (var step = 1; step <= steps; step++) {
        final interpolatedIndex = startIndex + step * direction;
        final fraction = step / steps;
        samples[interpolatedIndex.clamp(0, sampleCount - 1)] =
            startAmplitude + (amplitude - startAmplitude) * fraction;
      }
    } else {
      samples[sampleIndex] = amplitude;
    }
  }

  void _applyBrush(
    List<double> samples,
    int sampleIndex,
    double amplitude,
    int sampleCount,
  ) {
    const sigma = 10.0;
    const radius = 30;
    final start = (sampleIndex - radius).clamp(0, sampleCount - 1);
    final end = (sampleIndex + radius).clamp(0, sampleCount - 1);
    for (var i = start; i <= end; i++) {
      final distance = (i - sampleIndex).toDouble();
      final weight = exp(-0.5 * (distance / sigma) * (distance / sigma));
      samples[i] = samples[i] * (1.0 - weight) + amplitude * weight;
    }
  }

  void _applyEraser(
    List<double> samples,
    int sampleIndex,
    int sampleCount,
  ) {
    if (_lastDragIndex != null && _lastDragIndex != sampleIndex) {
      final startIndex = _lastDragIndex!;
      final steps = (sampleIndex - startIndex).abs();
      final direction = sampleIndex > startIndex ? 1 : -1;
      for (var step = 0; step <= steps; step++) {
        final index = (startIndex + step * direction).clamp(0, sampleCount - 1);
        samples[index] = 0;
      }
    } else {
      samples[sampleIndex] = 0;
    }
  }

  void _applySmooth(
    List<double> samples,
    int sampleIndex,
    int sampleCount,
  ) {
    const radius = 20;
    final start = (sampleIndex - radius).clamp(0, sampleCount - 1);
    final end = (sampleIndex + radius).clamp(0, sampleCount - 1);
    final original = List<double>.from(samples);
    for (var i = start; i <= end; i++) {
      final distance = (i - sampleIndex).toDouble();
      final weight = exp(-0.05 * distance * distance);
      // Weighted average with neighbours.
      final left = (i > 0) ? original[i - 1] : original[i];
      final right = (i < sampleCount - 1) ? original[i + 1] : original[i];
      final smoothed = (left + original[i] + right) / 3.0;
      samples[i] = original[i] * (1.0 - weight * 0.3) + smoothed * weight * 0.3;
    }
  }

  void _applyGrab(Offset localPosition, Size canvasSize) {
    if (_grabLockedIndex == null) {
      return;
    }
    final amplitude = _positionToAmplitude(localPosition.dy, canvasSize.height);
    final updatedSamples = _cloneSamples();
    updatedSamples[_grabLockedIndex!] = amplitude;
    widget.onSamplesChanged(updatedSamples);
  }

  void _applyLine(Offset localPosition, Size canvasSize) {
    if (_lineStartPosition == null || _lineBaselineSamples == null) {
      return;
    }
    final sampleCount = widget.samples.length;
    final startIndex = _positionToIndex(
      _lineStartPosition!.dx,
      canvasSize.width,
    );
    final startAmplitude = _positionToAmplitude(
      _lineStartPosition!.dy,
      canvasSize.height,
    );
    final endIndex = _positionToIndex(localPosition.dx, canvasSize.width);
    final endAmplitude = _positionToAmplitude(
      localPosition.dy,
      canvasSize.height,
    );

    final updatedSamples = List<double>.from(_lineBaselineSamples!);
    final minIndex = min(startIndex, endIndex);
    final maxIndex = max(startIndex, endIndex);
    final steps = maxIndex - minIndex;

    for (var i = minIndex; i <= maxIndex; i++) {
      final fraction = steps > 0 ? (i - minIndex) / steps : 0.5;
      final amplitude = startIndex <= endIndex
          ? startAmplitude + (endAmplitude - startAmplitude) * fraction
          : endAmplitude + (startAmplitude - endAmplitude) * (1.0 - fraction);
      updatedSamples[i.clamp(0, sampleCount - 1)] = amplitude;
    }

    widget.onSamplesChanged(updatedSamples);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, widget.height);
        return GestureDetector(
          onPanStart: (details) =>
              _onDragStart(details.localPosition, canvasSize),
          onPanUpdate: (details) =>
              _onDragUpdate(details.localPosition, canvasSize),
          onPanEnd: (_) => _onDragEnd(),
          onTapDown: (details) {
            _onDragStart(details.localPosition, canvasSize);
            _onDragEnd();
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.precise,
            child: CustomPaint(
              size: canvasSize,
              painter: WaveformPainter(
                samples: widget.samples,
                postEffectSamples: widget.postEffectSamples,
                waveformColor: Theme.of(context).colorScheme.primary,
                gridColor: Theme.of(context).colorScheme.outlineVariant,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLow,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints a waveform with optional post-effect ghost overlay.
///
/// Made public so it can be reused for thumbnails.
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.samples,
    required this.waveformColor,
    required this.gridColor,
    required this.backgroundColor,
    this.postEffectSamples,
    this.showGrid = true,
    this.strokeWidth = 2.0,
  });

  final List<double> samples;
  final List<double>? postEffectSamples;
  final Color waveformColor;
  final Color gridColor;
  final Color backgroundColor;
  final bool showGrid;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(8),
      ),
      Paint()..color = backgroundColor,
    );

    if (showGrid) {
      _paintGrid(canvas, size);
    }

    // Post-effect ghost overlay (drawn first, behind main waveform).
    if (postEffectSamples != null && postEffectSamples!.isNotEmpty) {
      _paintWaveform(
        canvas,
        size,
        postEffectSamples!,
        waveformColor.withValues(alpha: 0.25),
        strokeWidth,
        showGlow: false,
      );
    }

    // Main waveform.
    if (samples.isNotEmpty) {
      _paintWaveform(
        canvas,
        size,
        samples,
        waveformColor,
        strokeWidth,
        showGlow: true,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      gridPaint,
    );

    final quarterY = size.height / 4;
    gridPaint.color = gridColor.withValues(alpha: 0.3);
    canvas.drawLine(
      Offset(0, quarterY),
      Offset(size.width, quarterY),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height - quarterY),
      Offset(size.width, size.height - quarterY),
      gridPaint,
    );
  }

  void _paintWaveform(
    Canvas canvas,
    Size size,
    List<double> waveformSamples,
    Color color,
    double width, {
    required bool showGlow,
  }) {
    final path = Path();
    final sampleCount = waveformSamples.length;

    for (var i = 0; i < sampleCount; i++) {
      final x = i * size.width / (sampleCount - 1);
      final y = (1.0 - waveformSamples[i]) / 2.0 * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (showGlow) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return !_listEquals(samples, oldDelegate.samples) ||
        !_listEquals(
          postEffectSamples ?? const [],
          oldDelegate.postEffectSamples ?? const [],
        ) ||
        waveformColor != oldDelegate.waveformColor;
  }

  static bool _listEquals(List<double> a, List<double> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// Waveform preset generators
// ---------------------------------------------------------------------------

/// Number of samples per drawn waveform cycle.
const waveformDrawerSampleCount = 512;

/// Generates a sine wave.
List<double> generateSinePreset() {
  return List<double>.generate(
    waveformDrawerSampleCount,
    (i) => sin(2.0 * pi * i / waveformDrawerSampleCount),
  );
}

/// Generates a sawtooth wave (rising ramp).
List<double> generateSawPreset() {
  return List<double>.generate(
    waveformDrawerSampleCount,
    (i) => 2.0 * i / waveformDrawerSampleCount - 1.0,
  );
}

/// Generates a triangle wave.
List<double> generateTrianglePreset() {
  return List<double>.generate(waveformDrawerSampleCount, (i) {
    final phase = i / waveformDrawerSampleCount;
    if (phase < 0.25) {
      return 4.0 * phase;
    } else if (phase < 0.75) {
      return 2.0 - 4.0 * phase;
    } else {
      return -4.0 + 4.0 * phase;
    }
  });
}

/// Generates a square wave.
List<double> generateSquarePreset() {
  return List<double>.generate(
    waveformDrawerSampleCount,
    (i) => i < waveformDrawerSampleCount ~/ 2 ? 1.0 : -1.0,
  );
}

/// Generates a rectangle / pulse wave with a given duty cycle.
List<double> generateRectanglePreset({double dutyCycle = 0.25}) {
  final threshold = (waveformDrawerSampleCount * dutyCycle).round();
  return List<double>.generate(
    waveformDrawerSampleCount,
    (i) => i < threshold ? 1.0 : -1.0,
  );
}

/// Generates a half-rectified sine wave.
List<double> generateRectifiedSinePreset() {
  return List<double>.generate(waveformDrawerSampleCount, (i) {
    final value = sin(2.0 * pi * i / waveformDrawerSampleCount);
    return value > 0 ? value : 0;
  });
}

/// Generates white noise (random waveform).
List<double> generateNoisePreset() {
  final random = Random();
  return List<double>.generate(
    waveformDrawerSampleCount,
    (_) => random.nextDouble() * 2.0 - 1.0,
  );
}

/// Generates a flat (silent) waveform.
List<double> generateFlatPreset() {
  return List<double>.filled(waveformDrawerSampleCount, 0);
}

/// Generates a chirp waveform with the given number of cycles.
List<double> generateChirpPreset({int cycles = 16}) {
  return List<double>.generate(waveformDrawerSampleCount, (i) {
    final phase = i / waveformDrawerSampleCount;
    // Quadratic frequency sweep.
    return sin(2.0 * pi * cycles * phase * phase);
  });
}
