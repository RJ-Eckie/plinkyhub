import 'dart:math';

import 'package:flutter/material.dart';

class PlayPad extends StatefulWidget {
  const PlayPad({
    required this.iconAsset,
    required this.isActive,
    required this.onPressStart,
    required this.onPressEnd,
    super.key,
  });

  final String iconAsset;
  final bool isActive;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  State<PlayPad> createState() => _PlayPadState();
}

class _PlayPadState extends State<PlayPad> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.isActive;
    final primaryColor = theme.colorScheme.primary;
    final arcColor = isActive
        ? primaryColor
        : _hovering
            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
            : theme.colorScheme.onSurface.withValues(alpha: 0.25);
    final iconColor = isActive
        ? primaryColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => widget.onPressStart(),
        onTapUp: (_) => widget.onPressEnd(),
        onTapCancel: widget.onPressEnd,
        child: CustomPaint(
          painter: _ArcPadPainter(
            color: arcColor,
            isActive: isActive,
            activeColor: primaryColor,
          ),
          child: FractionallySizedBox(
            widthFactor: 0.55,
            heightFactor: 0.55,
            child: Image.asset(
              'assets/icons/${widget.iconAsset}',
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPadPainter extends CustomPainter {
  _ArcPadPainter({
    required this.color,
    required this.isActive,
    required this.activeColor,
  });

  final Color color;
  final bool isActive;
  final Color activeColor;

  static const _gapAngle = 0.8;
  static const _strokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );

    final fullSweep = pi - _gapAngle;
    final sweepAngle = fullSweep * 0.85;
    final offset = (fullSweep - sweepAngle) / 2;

    // Left arc
    canvas.drawArc(
      rect,
      pi / 2 + _gapAngle / 2 + offset,
      sweepAngle,
      false,
      paint,
    );

    // Right arc
    canvas.drawArc(
      rect,
      -pi / 2 + _gapAngle / 2 + offset,
      sweepAngle,
      false,
      paint,
    );

    if (isActive) {
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - _strokeWidth,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPadPainter oldDelegate) =>
      color != oldDelegate.color ||
      isActive != oldDelegate.isActive ||
      activeColor != oldDelegate.activeColor;
}
