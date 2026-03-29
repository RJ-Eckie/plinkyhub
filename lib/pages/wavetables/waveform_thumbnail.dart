import 'package:flutter/material.dart';
import 'package:plinkyhub/pages/wavetables/waveform_drawer.dart';

/// Small waveform preview shown in the slot selector.
class WaveformThumbnail extends StatelessWidget {
  const WaveformThumbnail({
    required this.samples,
    required this.isSelected,
    required this.slotIndex,
    required this.onTap,
    super.key,
  });

  final List<double> samples;
  final bool isSelected;
  final int slotIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CustomPaint(
                size: const Size(80, 48),
                painter: WaveformPainter(
                  samples: samples,
                  waveformColor: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  gridColor: colorScheme.outlineVariant,
                  backgroundColor: isSelected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : colorScheme.surfaceContainerLow,
                  showGrid: false,
                  strokeWidth: 1.0,
                ),
              ),
            ),
            Positioned(
              left: 3,
              top: 1,
              child: Text(
                'c$slotIndex',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
