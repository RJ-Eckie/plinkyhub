import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';

class SamplesSection extends ConsumerWidget {
  const SamplesSection({
    required this.slots,
    this.deviceSampleSlots = const {},
    super.key,
  });

  final List<({String? presetId, String? sampleId, String? patternId})> slots;
  final Set<int> deviceSampleSlots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final samples = ref.watch(
      savedSamplesProvider.select((state) => state.userSamples),
    );

    final uniqueSampleIds = slots
        .map((slot) => slot.sampleId)
        .whereType<String>()
        .toSet()
        .toList();
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
                          if (hasDeviceSample && sampleId != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Icon(
                                Icons.link,
                                size: 12,
                                color: theme.colorScheme.primary,
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
