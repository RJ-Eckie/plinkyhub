import 'dart:math';

import 'package:flutter/material.dart';

/// An 8x8 grid of pulsating semi-circle arcs, matching the arc style
/// used in the navigation sidebar. Each arc pulses with a staggered
/// delay to create a wave effect.
class PlinkyLoadingAnimation extends StatefulWidget {
  const PlinkyLoadingAnimation({super.key});

  static const double size = 160;

  @override
  State<PlinkyLoadingAnimation> createState() => _PlinkyLoadingAnimationState();
}

class _PlinkyLoadingAnimationState extends State<PlinkyLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cellSize = PlinkyLoadingAnimation.size / 8;
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: PlinkyLoadingAnimation.size,
          height: PlinkyLoadingAnimation.size,
          child: CustomPaint(
            painter: _GridArcPainter(
              progress: _controller.value,
              color: color,
              cellSize: cellSize,
            ),
          ),
        );
      },
    );
  }
}

class _GridArcPainter extends CustomPainter {
  _GridArcPainter({
    required this.progress,
    required this.color,
    required this.cellSize,
  });

  final double progress;
  final Color color;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 8;
    final arcRadius = cellSize * 0.35;
    const gapAngle = 0.8;
    final strokeWidth = cellSize * 0.12;

    for (var row = 0; row < gridSize; row++) {
      for (var column = 0; column < gridSize; column++) {
        final centerX = (column + 0.5) * cellSize;
        final centerY = (row + 0.5) * cellSize;

        // Distance from center of grid for wave effect.
        final distanceX = (column - 3.5) / 3.5;
        final distanceY = (row - 3.5) / 3.5;
        final distance = sqrt(
          distanceX * distanceX + distanceY * distanceY,
        );

        // Staggered phase based on distance from center.
        final phase = (progress - distance * 0.3) % 1.0;
        final pulse = (sin(phase * 2 * pi) + 1) / 2;
        final opacity = 0.15 + pulse * 0.85;

        final paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        final rect = Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: arcRadius,
        );

        // Left arc.
        const fullSweep = pi - gapAngle;
        const sweepAngle = fullSweep * 0.85;
        const offset = (fullSweep - sweepAngle) / 2;
        canvas.drawArc(
          rect,
          pi / 2 + gapAngle / 2 + offset,
          sweepAngle,
          false,
          paint,
        );

        // Right arc.
        canvas.drawArc(
          rect,
          -pi / 2 + gapAngle / 2 + offset,
          sweepAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GridArcPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      cellSize != oldDelegate.cellSize;
}
