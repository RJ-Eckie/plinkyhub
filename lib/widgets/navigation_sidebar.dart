import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plinkyhub/widgets/arc_icon_button.dart';
import 'package:plinkyhub/widgets/authentication_button.dart';

class NavigationSidebar extends StatelessWidget {
  const NavigationSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: CustomPaint(
        painter: const _StripePainter(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(text: 'Plinky\n'),
                  TextSpan(text: 'Hub'),
                ],
              ),
              style: GoogleFonts.fingerPaint(
                textStyle: Theme.of(context).textTheme.titleLarge,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ArcIconButton(
                      icon: Icons.usb_outlined,
                      label: 'My Plinky',
                      isSelected: selectedIndex == 0,
                      onPressed: () => onDestinationSelected(0),
                    ),
                    const SizedBox(height: 8),
                    ArcIconButton(
                      icon: Icons.piano_outlined,
                      label: 'Editor',
                      isSelected: selectedIndex == 1,
                      onPressed: () => onDestinationSelected(1),
                    ),
                    const SizedBox(height: 8),
                    ArcIconButton(
                      icon: Icons.library_music_outlined,
                      label: 'Presets',
                      isSelected: selectedIndex == 2,
                      onPressed: () => onDestinationSelected(2),
                    ),
                    const SizedBox(height: 8),
                    ArcIconButton(
                      icon: Icons.folder_copy_outlined,
                      label: 'Packs',
                      isSelected: selectedIndex == 3,
                      onPressed: () => onDestinationSelected(3),
                    ),
                    const SizedBox(height: 8),
                    ArcIconButton(
                      icon: Icons.audio_file_outlined,
                      label: 'Samples',
                      isSelected: selectedIndex == 4,
                      onPressed: () => onDestinationSelected(4),
                    ),
                    const SizedBox(height: 8),
                    ArcIconButton(
                      icon: Icons.waves_outlined,
                      label: 'Wavetables',
                      isSelected: selectedIndex == 5,
                      onPressed: () => onDestinationSelected(5),
                    ),
                    const SizedBox(height: 8),
                    ArcIconButton(
                      icon: Icons.grid_view_outlined,
                      label: 'Patterns',
                      isSelected: selectedIndex == 6,
                      onPressed: () => onDestinationSelected(6),
                    ),
                    const SizedBox(height: 8),
                    ArcIconButton(
                      icon: Icons.people_outlined,
                      label: 'Users',
                      isSelected: selectedIndex == 7,
                      onPressed: () => onDestinationSelected(7),
                    ),
                    const SizedBox(height: 8),
                    ArcIconButton(
                      icon: Icons.memory_outlined,
                      label: 'Firmware',
                      isSelected: selectedIndex == 9,
                      onPressed: () => onDestinationSelected(9),
                    ),
                    const SizedBox(height: 8),
                    ArcIconButton(
                      icon: Icons.info_outlined,
                      label: 'About',
                      isSelected: selectedIndex == 10,
                      onPressed: () => onDestinationSelected(10),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: AuthenticationButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stripePositions = [0.25, 0.5, 0.75];
    for (final position in stripePositions) {
      final x = size.width * position;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(x - 4, 0, 8, size.height))
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, size.height * 0.05),
        Offset(x, size.height * 0.95),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}
