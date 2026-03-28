import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/widgets/authentication_button.dart';

class StarButton extends ConsumerWidget {
  const StarButton({
    required this.isStarred,
    required this.starCount,
    required this.onToggle,
    super.key,
  });

  final bool isStarred;
  final int starCount;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(authenticationProvider).user != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isStarred ? Icons.star : Icons.star_border,
            size: 20,
            color: isStarred ? Colors.amber : null,
          ),
          tooltip: isStarred ? 'Remove star' : 'Star',
          onPressed: () => isSignedIn ? onToggle() : showSignInDialog(context),
        ),
        if (starCount > 0)
          Text(
            '$starCount',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
