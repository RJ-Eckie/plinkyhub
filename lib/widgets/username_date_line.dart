import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/main.dart';
import 'package:plinkyhub/state/user_profile_notifier.dart';
import 'package:plinkyhub/utils/note_names.dart';

class UsernameDateLine extends ConsumerWidget {
  const UsernameDateLine({
    required this.userId,
    required this.username,
    required this.updatedAt,
    super.key,
  });

  final String userId;
  final String username;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (username.isEmpty) {
      return Text(formatDate(updatedAt), style: metadataStyle);
    }

    return Text.rich(
      TextSpan(
        style: metadataStyle,
        children: [
          const TextSpan(text: 'by '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                ref
                    .read(userProfileProvider.notifier)
                    .loadUserProfile(userId, username);
                ref.read(selectedPageProvider.notifier).selected = 6;
              },
                child: Text(
                  username,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          TextSpan(text: ' · ${formatDate(updatedAt)}'),
        ],
      ),
    );
  }
}
