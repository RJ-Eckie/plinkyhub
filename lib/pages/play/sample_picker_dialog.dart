import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/state/play_notifier.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

class SamplePickerDialog extends ConsumerStatefulWidget {
  const SamplePickerDialog({super.key});

  @override
  ConsumerState<SamplePickerDialog> createState() =>
      _SamplePickerDialogState();
}

class _SamplePickerDialogState
    extends ConsumerState<SamplePickerDialog> {
  bool _loading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() => _loading = true);
      await ref.read(playProvider.notifier).loadSample(
            result.files.single.name,
            result.files.single.bytes!,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadSaved(SavedSample sample) async {
    setState(() => _loading = true);
    try {
      debugPrint('Downloading WAV: ${sample.filePath}');
      final bytes = await ref
          .read(savedSamplesProvider.notifier)
          .downloadWav(sample.filePath);
      debugPrint('Downloaded ${bytes.length} bytes, loading into player...');
      await ref.read(playProvider.notifier).loadSample(
            sample.name,
            bytes,
            baseMidi: sample.baseNote,
            slicePoints: sample.slicePoints,
            sliceNotes: sample.sliceNotes,
            pitched: sample.pitched,
          );
      debugPrint('Sample loaded into player');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Exception catch (e) {
      debugPrint('Failed to load saved sample: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sample: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final samplesState = ref.watch(savedSamplesProvider);
    final samples = samplesState.userSamples;

    return AlertDialog(
      title: const Text('Load Sample'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlinkyButton(
              onPressed: _loading ? null : _pickFile,
              icon: Icons.file_open,
              label: 'Upload WAV file',
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Saved Samples',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (samples.isEmpty)
              const Center(
                child: Text('No saved samples'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: samples.length,
                  itemBuilder: (context, index) {
                    final sample = samples[index];
                    return ListTile(
                      leading: const Icon(Icons.audio_file),
                      title: Text(
                        sample.name.isEmpty
                            ? '(unnamed)'
                            : sample.name,
                      ),
                      dense: true,
                      onTap: () => _loadSaved(sample),
                    );
                  },
                ),
              ),
          ],
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
