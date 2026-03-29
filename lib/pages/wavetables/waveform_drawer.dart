import 'dart:math';

import 'package:flutter/material.dart';

/// Interactive widget for drawing a single-cycle waveform.
///
/// Displays a canvas where the user can click and drag to draw a waveform.
/// The horizontal axis represents one full cycle and
/// the vertical axis represents amplitude from −1.0 to 1.0.
class WaveformDrawer extends StatefulWidget {
  const WaveformDrawer({
    required this.samples,
    required this.onSamplesChanged,
    this.height = 180,
    super.key,
  });

  /// The current waveform samples, each in the range −1.0 to 1.0.
  final List<double> samples;

  /// Called whenever the user modifies the waveform by drawing.
  final ValueChanged<List<double>> onSamplesChanged;

  /// Height of the drawing canvas.
  final double height;

  @override
  State<WaveformDrawer> createState() => _WaveformDrawerState();
}

class _WaveformDrawerState extends State<WaveformDrawer> {
  /// The last sample index touched during a drag, used for interpolation.
  int? _lastDragIndex;

  List<double> _cloneSamples() => List<double>.from(widget.samples);

  void _applyDrawAt(Offset localPosition, Size canvasSize) {
    final sampleCount = widget.samples.length;
    final sampleIndex = (localPosition.dx / canvasSize.width * sampleCount)
        .floor()
        .clamp(0, sampleCount - 1);
    final amplitude = (1.0 - 2.0 * localPosition.dy / canvasSize.height).clamp(
      -1.0,
      1.0,
    );

    final updatedSamples = _cloneSamples();

    // Interpolate between the last drag position and the current one to
    // avoid gaps when the pointer moves quickly.
    if (_lastDragIndex != null && _lastDragIndex != sampleIndex) {
      final startIndex = _lastDragIndex!;
      final startAmplitude = updatedSamples[startIndex];
      final steps = (sampleIndex - startIndex).abs();
      final direction = sampleIndex > startIndex ? 1 : -1;
      for (var step = 1; step <= steps; step++) {
        final interpolatedIndex = startIndex + step * direction;
        final fraction = step / steps;
        updatedSamples[interpolatedIndex.clamp(0, sampleCount - 1)] =
            startAmplitude + (amplitude - startAmplitude) * fraction;
      }
    } else {
      updatedSamples[sampleIndex] = amplitude;
    }

    _lastDragIndex = sampleIndex;
    widget.onSamplesChanged(updatedSamples);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, widget.height);
        return GestureDetector(
          onPanStart: (details) {
            _lastDragIndex = null;
            _applyDrawAt(details.localPosition, canvasSize);
          },
          onPanUpdate: (details) {
            _applyDrawAt(details.localPosition, canvasSize);
          },
          onPanEnd: (_) => _lastDragIndex = null,
          onTapDown: (details) {
            _lastDragIndex = null;
            _applyDrawAt(details.localPosition, canvasSize);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.precise,
            child: CustomPaint(
              size: canvasSize,
              painter: _WaveformPainter(
                samples: widget.samples,
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

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.samples,
    required this.waveformColor,
    required this.gridColor,
    required this.backgroundColor,
  });

  final List<double> samples;
  final Color waveformColor;
  final Color gridColor;
  final Color backgroundColor;

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

    // Grid lines.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Center line (zero amplitude).
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      gridPaint,
    );

    // Quarter lines (±0.5 amplitude).
    final quarterY = size.height / 4;
    canvas.drawLine(
      Offset(0, quarterY),
      Offset(size.width, quarterY),
      gridPaint..color = gridColor.withValues(alpha: 0.3),
    );
    canvas.drawLine(
      Offset(0, size.height - quarterY),
      Offset(size.width, size.height - quarterY),
      gridPaint,
    );

    // Waveform path.
    if (samples.isEmpty) {
      return;
    }

    final path = Path();
    final sampleCount = samples.length;

    for (var i = 0; i < sampleCount; i++) {
      final x = i * size.width / (sampleCount - 1);
      final y = (1.0 - samples[i]) / 2.0 * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Glow effect.
    canvas.drawPath(
      path,
      Paint()
        ..color = waveformColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Main waveform line.
    canvas.drawPath(
      path,
      Paint()
        ..color = waveformColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return !_listEquals(samples, oldDelegate.samples) ||
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

/// Generates a flat (silent) waveform.
List<double> generateFlatPreset() {
  return List<double>.filled(waveformDrawerSampleCount, 0);
}
