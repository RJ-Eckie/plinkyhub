import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plinkyhub/models/saved_pack.dart';
import 'package:plinkyhub/state/saved_packs_notifier.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

/// Returns packs that reference the given preset ID.
List<SavedPack> findPacksUsingPreset(WidgetRef ref, String presetId) {
  return ref
      .read(savedPacksProvider)
      .userPacks
      .where(
        (pack) => pack.slots.any((slot) => slot.presetId == presetId),
      )
      .toList();
}

/// Returns packs that reference the given sample ID.
List<SavedPack> findPacksUsingSample(WidgetRef ref, String sampleId) {
  return ref
      .read(savedPacksProvider)
      .userPacks
      .where(
        (pack) => pack.slots.any((slot) => slot.sampleId == sampleId),
      )
      .toList();
}

/// Returns packs that reference the given wavetable ID.
List<SavedPack> findPacksUsingWavetable(
  WidgetRef ref,
  String wavetableId,
) {
  return ref
      .read(savedPacksProvider)
      .userPacks
      .where((pack) => pack.wavetableId == wavetableId)
      .toList();
}

/// Returns packs that reference the given pattern ID.
List<SavedPack> findPacksUsingPattern(WidgetRef ref, String patternId) {
  return ref
      .read(savedPacksProvider)
      .userPacks
      .where((pack) => pack.patternId == patternId)
      .toList();
}

/// Shows a dialog informing the user that the item is used in packs
/// and must be removed from those packs before it can be deleted.
/// Each pack name is a clickable link to its detail page.
void showPackUsageDialog(
  BuildContext context, {
  required String itemType,
  required List<SavedPack> packs,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Cannot delete $itemType'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This $itemType is used in the following '
            '${packs.length == 1 ? 'pack' : 'packs'}. '
            'Remove it from '
            '${packs.length == 1 ? 'the pack' : 'these packs'}'
            ' first before deleting.',
          ),
          const SizedBox(height: 12),
          for (final pack in packs)
            _PackLink(pack: pack, dialogContext: dialogContext),
        ],
      ),
      actions: [
        PlinkyButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          icon: Icons.close,
          label: 'OK',
        ),
      ],
    ),
  );
}

class _PackLink extends StatelessWidget {
  const _PackLink({
    required this.pack,
    required this.dialogContext,
  });

  final SavedPack pack;
  final BuildContext dialogContext;

  @override
  Widget build(BuildContext context) {
    final name = pack.name.isEmpty ? '(unnamed)' : pack.name;
    final hasLink = pack.username.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: hasLink
            ? () {
                Navigator.of(dialogContext).pop();
                context.go(
                  '/${pack.username}/pack/'
                  '${Uri.encodeComponent(pack.name)}',
                );
              }
            : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 4,
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasLink
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    decoration: hasLink ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
