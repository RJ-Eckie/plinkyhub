import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_patch.dart';
import 'package:plinkyhub/state/saved_patches_notifier.dart';
import 'package:plinkyhub/widgets/star_button.dart';

class PatchStarButton extends ConsumerWidget {
  const PatchStarButton({required this.patch, super.key});

  final SavedPatch patch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StarButton(
      isStarred: patch.isStarred,
      starCount: patch.starCount,
      onToggle: () => ref
          .read(savedPatchesProvider.notifier)
          .toggleStar(patch),
    );
  }
}
