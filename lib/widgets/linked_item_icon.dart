import 'package:flutter/material.dart';

/// A clickable link icon that shows a pointer cursor on hover.
/// Used to indicate an item is linked to a saved entry and can be
/// viewed by tapping.
class LinkedItemIcon extends StatelessWidget {
  const LinkedItemIcon({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          Icons.link,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
