import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plinkyhub/models/saved_pattern.dart';
import 'package:plinkyhub/routes.dart';
import 'package:plinkyhub/state/saved_patterns_notifier.dart';
import 'package:plinkyhub/widgets/pack_usage_check.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/share_link_button.dart';
import 'package:plinkyhub/widgets/star_button.dart';
import 'package:plinkyhub/widgets/username_date_line.dart';

class PatternCard extends ConsumerWidget {
  const PatternCard({
    required this.pattern,
    required this.isOwned,
    super.key,
  });

  final SavedPattern pattern;
  final bool isOwned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: pattern.username.isNotEmpty
            ? () => context.go(
                AppRoute.patterns.itemPage(pattern.username, pattern.name),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pattern.name.isEmpty ? '(unnamed)' : pattern.name,
                style: theme.textTheme.titleMedium,
              ),
              if (pattern.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  pattern.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 4),
              UsernameDateLine(
                userId: pattern.userId,
                username: pattern.username,
                updatedAt: pattern.updatedAt,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StarButton(
                    isStarred: pattern.isStarred,
                    starCount: pattern.starCount,
                    onToggle: () => ref
                        .read(savedPatternsProvider.notifier)
                        .toggleStar(pattern),
                  ),
                  if (pattern.username.isNotEmpty)
                    ShareLinkButton(
                      username: pattern.username,
                      itemType: 'pattern',
                      itemName: pattern.name,
                    ),
                  const Spacer(),
                  if (isOwned) ...[
                    IconButton(
                      icon: Icon(
                        pattern.isPublic ? Icons.public : Icons.public_off,
                        size: 20,
                      ),
                      tooltip: pattern.isPublic
                          ? 'Make private'
                          : 'Make public',
                      onPressed: () {
                        ref
                            .read(savedPatternsProvider.notifier)
                            .updatePattern(
                              pattern.copyWith(isPublic: !pattern.isPublic),
                            );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                      ),
                      tooltip: 'Delete pattern',
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final referencingPacks = await findPacksUsingPattern(ref, pattern.id);
    if (!context.mounted) {
      return;
    }
    if (referencingPacks.isNotEmpty) {
      showItemUsageDialog(
        context,
        itemType: 'pattern',
        packs: referencingPacks,
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete pattern?'),
        content: Text(
          'Are you sure you want to delete '
          '"${pattern.name.isEmpty ? '(unnamed)' : pattern.name}"?',
        ),
        actions: [
          PlinkyButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: Icons.close,
            label: 'Cancel',
          ),
          PlinkyButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref
                  .read(savedPatternsProvider.notifier)
                  .deletePattern(pattern.id);
              if (GoRouter.of(context).canPop()) {
                context.pop();
              }
            },
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
    );
  }
}
