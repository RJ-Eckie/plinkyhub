import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_wavetable.dart';
import 'package:plinkyhub/pages/packs/wavetable_picker_dialog.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_wavetables_notifier.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

class WavetableSection extends ConsumerWidget {
  const WavetableSection({
    required this.wavetableId,
    required this.onChanged,
    this.deviceHasWavetable = false,
    super.key,
  });

  final String? wavetableId;
  final bool deviceHasWavetable;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wavetablesState = ref.watch(savedWavetablesProvider);
    final wavetableName = wavetableId != null
        ? wavetablesState.userWavetables
                  .where((wavetable) => wavetable.id == wavetableId)
                  .firstOrNull
                  ?.name ??
              wavetablesState.publicWavetables
                  .where((wavetable) => wavetable.id == wavetableId)
                  .firstOrNull
                  ?.name
        : null;

    final isLinked = wavetableId != null;
    final statusText = isLinked
        ? wavetableName ?? '(unknown)'
        : deviceHasWavetable
        ? 'Present on device (not linked)'
        : 'None';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wavetable',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isLinked)
              Icon(
                Icons.link,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (wavetableId != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Remove wavetable',
                onPressed: () => onChanged(null),
              ),
            PlinkyButton(
              onPressed: () async {
                final authState = ref.read(authenticationProvider);
                final allWavetables = {
                  ...wavetablesState.userWavetables,
                  ...wavetablesState.publicWavetables,
                }.toList();
                final selected = await showDialog<SavedWavetable>(
                  context: context,
                  builder: (context) => WavetablePickerDialog(
                    wavetables: allWavetables,
                    currentUserId: authState.user?.id,
                  ),
                );
                if (selected != null) {
                  onChanged(selected.id);
                }
              },
              icon: Icons.waves,
              label: 'Choose',
            ),
          ],
        ),
      ],
    );
  }
}
