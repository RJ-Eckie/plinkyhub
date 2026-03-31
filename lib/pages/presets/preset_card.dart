import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plinkyhub/models/saved_preset.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/pages/presets/save_preset_to_plinky_dialog.dart';
import 'package:plinkyhub/pages/presets/star_button.dart';
import 'package:plinkyhub/state/saved_presets_notifier.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';
import 'package:plinkyhub/widgets/pack_usage_check.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/share_link_button.dart';
import 'package:plinkyhub/widgets/username_date_line.dart';

class PresetCard extends ConsumerWidget {
  const PresetCard({
    required this.preset,
    required this.isOwned,
    super.key,
  });

  final SavedPreset preset;
  final bool isOwned;

  SavedSample? _findSample(WidgetRef ref) {
    if (preset.sampleId == null) {
      return null;
    }
    final samplesState = ref.watch(savedSamplesProvider);
    return samplesState.userSamples
            .where((s) => s.id == preset.sampleId)
            .firstOrNull ??
        samplesState.publicSamples
            .where((s) => s.id == preset.sampleId)
            .firstOrNull;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sample = _findSample(ref);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: preset.username.isNotEmpty
            ? () => context.go(
                '/${preset.username}/preset/'
                '${Uri.encodeComponent(preset.name)}',
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.name.isEmpty ? '(unnamed)' : preset.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (preset.category.isNotEmpty)
                    Chip(
                      label: Text(
                        preset.category,
                        style: theme.textTheme.bodySmall,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (preset.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preset.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 4),
              UsernameDateLine(
                userId: preset.userId,
                username: preset.username,
                updatedAt: preset.updatedAt,
              ),
              if (sample != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: sample.username.isNotEmpty
                      ? () => context.go(
                          '/${sample.username}/sample/'
                          '${Uri.encodeComponent(sample.name)}',
                        )
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.audio_file,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sample.name.isEmpty ? '(unnamed)' : sample.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: sample.username.isNotEmpty
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  PlinkyButton(
                    onPressed: () {
                      ref
                          .read(savedPresetsProvider.notifier)
                          .loadPresetIntoEditor(preset);
                    },
                    icon: Icons.download,
                    label: 'Load into editor',
                  ),
                  const SizedBox(width: 8),
                  PresetStarButton(preset: preset),
                  if (preset.username.isNotEmpty)
                    ShareLinkButton(
                      username: preset.username,
                      itemType: 'preset',
                      itemName: preset.name,
                    ),
                  IconButton(
                    icon: const Icon(Icons.usb, size: 20),
                    tooltip: 'Save to Plinky',
                    onPressed: () => _saveToPlinky(context),
                  ),
                  const Spacer(),
                  if (isOwned) ...[
                    IconButton(
                      icon: Icon(
                        preset.isPublic ? Icons.public : Icons.public_off,
                        size: 20,
                      ),
                      tooltip: preset.isPublic ? 'Make private' : 'Make public',
                      onPressed: () {
                        ref
                            .read(savedPresetsProvider.notifier)
                            .updatePreset(
                              preset.id,
                              isPublic: !preset.isPublic,
                            );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Delete preset',
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

  void _saveToPlinky(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SavePresetToPlinkyDialog(preset: preset),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final referencingPacks = findPacksUsingPreset(ref, preset.id);
    if (referencingPacks.isNotEmpty) {
      showPackUsageDialog(
        context,
        itemType: 'preset',
        packs: referencingPacks,
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete preset?'),
        content: Text(
          'Are you sure you want to delete '
          '"${preset.name.isEmpty ? '(unnamed)' : preset.name}"?',
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
              ref.read(savedPresetsProvider.notifier).deletePreset(preset.id);
              Navigator.of(context).maybePop();
            },
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
    );
  }
}
