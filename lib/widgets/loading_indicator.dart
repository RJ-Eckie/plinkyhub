import 'package:flutter/material.dart';
import 'package:plinkyhub/widgets/plinky_loading_animation.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlinkyLoadingAnimation(),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 8),
          Text(
            '(This might take a while)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
