import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/preset.dart';
import 'package:plinkyhub/pages/samples/sample_card.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';
import 'package:plinkyhub/utils/presets_uf2.dart';

class SamplesSection extends ConsumerWidget {
  const SamplesSection({
    required this.slots,
    this.deviceSampleSlots = const {},
    this.devicePresets = const {},
    super.key,
  });

  final List<({String? presetId, String? sampleId, String? patternId})> slots;
  final Set<int> deviceSampleSlots;
  final Map<int, Preset> devicePresets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final samples = ref.watch(
      savedSamplesProvider.select((state) => state.userSamples),
    );

    // Build a map from sampleId to the preset slot numbers that use it.
    final sampleToPresetSlots = <String, List<int>>{};
    for (var i = 0; i < slots.length; i++) {
      final sampleId = slots[i].sampleId;
      if (sampleId != null) {
        sampleToPresetSlots.putIfAbsent(sampleId, () => []).add(i + 1);
      }
    }

    // Build a map from device sample slot (0-7) to preset slot numbers
    // that reference it via P_SAMPLE, using the raw parameter values.
    final deviceSlotToPresetSlots = <int, List<int>>{};
    final sampleSlotRawValues = <int, int>{
      for (final slotIndex in deviceSampleSlots)
        slotIndex: sampleSlotToRaw(slotIndex),
    };
    for (final presetEntry in devicePresets.entries) {
      final preset = presetEntry.value;
      if (!preset.usesSample) {
        continue;
      }
      final presetRaw = preset.parameterById('P_SAMPLE')?.value;
      if (presetRaw == null) {
        continue;
      }
      for (final rawEntry in sampleSlotRawValues.entries) {
        if ((presetRaw - rawEntry.value).abs() < 2) {
          deviceSlotToPresetSlots
              .putIfAbsent(rawEntry.key, () => [])
              .add(presetEntry.key + 1);
          break;
        }
      }
    }

    final uniqueSampleIds = sampleToPresetSlots.keys.toList();
    final hasOverflow = uniqueSampleIds.length > 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Samples',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (hasOverflow)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'A pack can use at most 8 samples. '
              'Currently using ${uniqueSampleIds.length}.',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Row(
          children: List.generate(8, (index) {
            final sampleId = index < uniqueSampleIds.length
                ? uniqueSampleIds[index]
                : null;
            final sample = sampleId != null
                ? samples.where((sample) => sample.id == sampleId).firstOrNull
                : null;
            final hasDeviceSample = deviceSampleSlots.contains(index);

            String displayName;
            if (sample != null) {
              displayName = sample.name;
            } else if (hasDeviceSample) {
              displayName = 'On device';
            } else {
              displayName = 'Empty';
            }

            return Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index + 1}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (sample != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: GestureDetector(
                                onTap: () {
                                  final currentUserId = ref
                                      .read(authenticationProvider)
                                      .user
                                      ?.id;
                                  showDialog<void>(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 600,
                                        ),
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.all(16),
                                          child: SampleCard(
                                            sample: sample,
                                            isOwned:
                                                sample.userId == currentUserId,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.link,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (sampleId != null &&
                          sampleToPresetSlots[sampleId] != null)
                        Text(
                          'Slots: ${sampleToPresetSlots[sampleId]!.join(', ')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        )
                      else if (deviceSlotToPresetSlots.containsKey(index))
                        Text(
                          'Slots: '
                          '${deviceSlotToPresetSlots[index]!.join(', ')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
