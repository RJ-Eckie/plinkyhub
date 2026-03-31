import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_pattern.dart';
import 'package:plinkyhub/pages/packs/pattern_picker_dialog.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_patterns_notifier.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';

class PatternSection extends StatelessWidget {
  const PatternSection({
    required this.patternIds,
    required this.onPatternChanged,
    this.devicePatternIndices = const {},
    super.key,
  });

  final Map<int, String?> patternIds;
  final void Function(int patternIndex, String? patternId) onPatternChanged;
  final Set<int> devicePatternIndices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patterns',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisExtent: 64,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: patternCount,
          itemBuilder: (context, index) {
            final row = index ~/ 4;
            final column = index % 4;
            final patternIndex = column * 6 + row;
            return _PatternTile(
              patternIndex: patternIndex,
              hasDevicePattern:
                  devicePatternIndices.contains(patternIndex),
              patternId: patternIds[patternIndex],
              onChanged: (patternId) =>
                  onPatternChanged(patternIndex, patternId),
            );
          },
        ),
      ],
    );
  }
}

class _PatternTile extends ConsumerWidget {
  const _PatternTile({
    required this.patternIndex,
    required this.hasDevicePattern,
    required this.patternId,
    required this.onChanged,
  });

  final int patternIndex;
  final bool hasDevicePattern;
  final String? patternId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLinked = patternId != null;

    String displayName;
    if (isLinked) {
      final patterns = ref.watch(
        savedPatternsProvider.select((state) => state.userPatterns),
      );
      displayName = patterns
              .where((pattern) => pattern.id == patternId)
              .firstOrNull
              ?.name ??
          '(unknown)';
    } else if (hasDevicePattern) {
      displayName = 'Pattern ${patternIndex + 1}';
    } else {
      displayName = 'Empty';
    }

    return Card(
      color: hasDevicePattern || isLinked
          ? theme.colorScheme.primaryContainer
          : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPatternPicker(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${patternIndex + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasDevicePattern || isLinked
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasDevicePattern && isLinked) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.link,
                      size: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ],
                ],
              ),
              if (hasDevicePattern || isLinked)
                Text(
                  displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatternPicker(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authenticationProvider);
    final patternsState = ref.read(savedPatternsProvider);
    final allPatterns = {
      ...patternsState.userPatterns,
      ...patternsState.publicPatterns,
    }.toList();
    showDialog<SavedPattern>(
      context: context,
      builder: (context) => PatternPickerDialog(
        patterns: allPatterns,
        currentUserId: authState.user?.id,
      ),
    ).then((selected) {
      if (selected != null) {
        onChanged(selected.id);
      }
    });
  }
}
