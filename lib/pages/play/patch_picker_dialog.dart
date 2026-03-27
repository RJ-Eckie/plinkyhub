import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_patch.dart';
import 'package:plinkyhub/state/play_notifier.dart';
import 'package:plinkyhub/state/saved_patches_notifier.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

class PatchPickerDialog extends ConsumerStatefulWidget {
  const PatchPickerDialog({super.key});

  @override
  ConsumerState<PatchPickerDialog> createState() =>
      _PatchPickerDialogState();
}

class _PatchPickerDialogState
    extends ConsumerState<PatchPickerDialog> {
  bool _loading = false;

  Future<void> _loadPatch(SavedPatch patch) async {
    setState(() => _loading = true);

    // Load the patch into the editor state so the player can
    // read scale, stride, octave and other parameters from it.
    ref
        .read(savedPatchesProvider.notifier)
        .loadPatchIntoEditor(patch);

    // If the patch has an associated sample, load it into the
    // player automatically.
    if (patch.sampleId != null) {
      try {
        final samples =
            ref.read(savedSamplesProvider).userSamples +
            ref.read(savedSamplesProvider).publicSamples;
        final sample = samples
            .where((sample) => sample.id == patch.sampleId)
            .firstOrNull;

        if (sample != null) {
          final wavBytes = await ref
              .read(savedSamplesProvider.notifier)
              .downloadWav(sample.filePath);
          await ref.read(playProvider.notifier).loadSample(
                sample.name,
                wavBytes,
                baseMidi: sample.baseNote,
                slicePoints: sample.slicePoints,
                sliceNotes: sample.sliceNotes,
                pitched: sample.pitched,
              );
        }
      } on Exception catch (error) {
        debugPrint('Failed to load associated sample: $error');
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patchesState = ref.watch(savedPatchesProvider);
    final patches = patchesState.userPatches;

    return AlertDialog(
      title: const Text('Load Patch'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : patches.isEmpty
                ? const Center(child: Text('No saved patches'))
                : ListView.builder(
                    itemCount: patches.length,
                    itemBuilder: (context, index) {
                      final patch = patches[index];
                      return ListTile(
                        leading: const Icon(Icons.piano),
                        title: Text(
                          patch.name.isEmpty
                              ? '(unnamed)'
                              : patch.name,
                        ),
                        subtitle: patch.category.isNotEmpty
                            ? Text(patch.category)
                            : null,
                        trailing: patch.sampleId != null
                            ? const Icon(
                                Icons.audio_file,
                                size: 16,
                              )
                            : null,
                        dense: true,
                        onTap: () => _loadPatch(patch),
                      );
                    },
                  ),
      ),
      actions: [
        PlinkyButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icons.close,
          label: 'Cancel',
        ),
      ],
    );
  }
}
