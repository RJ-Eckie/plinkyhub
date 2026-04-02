import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/preset.dart';
import 'package:plinkyhub/models/saved_preset.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/pages/packs/preset_picker_dialog.dart';
import 'package:plinkyhub/pages/packs/sample_picker_dialog.dart';
import 'package:plinkyhub/pages/presets/preset_card.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_presets_notifier.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';

class PackSlotTile extends ConsumerWidget {
  const PackSlotTile({
    required this.slotNumber,
    required this.presetId,
    required this.sampleId,
    required this.onPresetChanged,
    required this.onSampleChanged,
    this.devicePreset,
    super.key,
  });

  final int slotNumber;
  final String? presetId;
  final String? sampleId;
  final ValueChanged<String?> onPresetChanged;
  final ValueChanged<String?> onSampleChanged;
  final Preset? devicePreset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final presets = ref.watch(
      savedPresetsProvider.select((state) => state.userPresets),
    );
    final samples = ref.watch(
      savedSamplesProvider.select((state) => state.userSamples),
    );

    final hasDevicePreset = devicePreset != null;
    final isLinked = presetId != null;

    String presetName;
    if (hasDevicePreset) {
      presetName = devicePreset!.name.isNotEmpty
          ? devicePreset!.name
          : 'Preset ${slotNumber + 1}';
    } else if (isLinked) {
      presetName =
          presets.where((preset) => preset.id == presetId).firstOrNull?.name ??
          '(unknown)';
    } else {
      presetName = 'Empty';
    }

    final sampleName = sampleId != null
        ? samples.where((sample) => sample.id == sampleId).firstOrNull?.name ??
              '(unknown)'
        : null;
    final categoryLabel = devicePreset?.category.label ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPresetPicker(context, ref, presets),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${slotNumber + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasDevicePreset && isLinked)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: GestureDetector(
                          onTap: () => _showLinkedPreset(context, ref),
                          child: Icon(
                            Icons.link,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presetName,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (categoryLabel.isNotEmpty)
                      Text(
                        categoryLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (sampleName != null)
                      Text(
                        sampleName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'preset',
                    child: Text('Pick preset'),
                  ),
                  const PopupMenuItem(
                    value: 'sample',
                    child: Text('Pick sample'),
                  ),
                  if (presetId != null || sampleId != null)
                    const PopupMenuItem(
                      value: 'clear',
                      child: Text('Clear slot'),
                    ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'preset':
                      _showPresetPicker(context, ref, presets);
                    case 'sample':
                      _showSamplePicker(context, ref, samples);
                    case 'clear':
                      onPresetChanged(null);
                      onSampleChanged(null);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinkedPreset(BuildContext context, WidgetRef ref) {
    final preset = ref
        .read(savedPresetsProvider)
        .userPresets
        .where((preset) => preset.id == presetId)
        .firstOrNull;
    if (preset == null) {
      return;
    }
    final currentUserId = ref.read(authenticationProvider).user?.id;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PresetCard(
              preset: preset,
              isOwned: preset.userId == currentUserId,
            ),
          ),
        ),
      ),
    );
  }

  void _showPresetPicker(
    BuildContext context,
    WidgetRef ref,
    List<SavedPreset> presets,
  ) {
    final currentUserId = ref.read(authenticationProvider).user?.id;
    showDialog<SavedPreset>(
      context: context,
      builder: (context) => PresetPickerDialog(
        presets: presets,
        currentUserId: currentUserId,
      ),
    ).then((selected) {
      if (selected != null) {
        onPresetChanged(selected.id);
        onSampleChanged(selected.sampleId);
      }
    });
  }

  void _showSamplePicker(
    BuildContext context,
    WidgetRef ref,
    List<SavedSample> samples,
  ) {
    final currentUserId = ref.read(authenticationProvider).user?.id;
    showDialog<SavedSample>(
      context: context,
      builder: (context) => SamplePickerDialog(
        samples: samples,
        currentUserId: currentUserId,
      ),
    ).then((selected) {
      if (selected != null) {
        onSampleChanged(selected.id);
      }
    });
  }
}
