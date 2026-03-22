import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';
import 'package:plinkyhub/widgets/authentication_button.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

class SavedSamplesPage extends ConsumerStatefulWidget {
  const SavedSamplesPage({super.key});

  @override
  ConsumerState<SavedSamplesPage> createState() => _SavedSamplesPageState();
}

class _SavedSamplesPageState extends ConsumerState<SavedSamplesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        ref.read(savedSamplesProvider.notifier).fetchPublicSamples();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticationState = ref.watch(authenticationProvider);
    final savedSamplesState = ref.watch(savedSamplesProvider);
    final isSignedIn = authenticationState.user != null;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Samples'),
            Tab(text: 'Community Samples'),
          ],
        ),
        if (savedSamplesState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              savedSamplesState.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              if (isSignedIn)
                _SampleList(
                  samples: savedSamplesState.userSamples,
                  isLoading: savedSamplesState.isLoading,
                  isOwned: true,
                  onRefresh: () => ref
                      .read(savedSamplesProvider.notifier)
                      .fetchUserSamples(),
                )
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Sign in to upload and manage your samples',
                      ),
                      const SizedBox(height: 16),
                      PlinkyButton(
                        onPressed: () => showSignInDialog(context),
                        icon: Icons.login,
                        label: 'Sign in',
                      ),
                    ],
                  ),
                ),
              _SampleList(
                samples: savedSamplesState.publicSamples,
                isLoading: savedSamplesState.isLoading,
                isOwned: false,
                onRefresh: () => ref
                    .read(savedSamplesProvider.notifier)
                    .fetchPublicSamples(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SampleList extends ConsumerWidget {
  const _SampleList({
    required this.samples,
    required this.isLoading,
    required this.isOwned,
    required this.onRefresh,
  });

  final List<SavedSample> samples;
  final bool isLoading;
  final bool isOwned;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && samples.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (samples.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isOwned ? 'No saved samples yet' : 'No community samples yet',
            ),
            const SizedBox(height: 8),
            if (isOwned) ...[
              PlinkyButton(
                onPressed: () => _showUploadDialog(context),
                icon: Icons.upload_file,
                label: 'Upload sample',
              ),
              const SizedBox(height: 8),
            ],
            PlinkyButton(
              onPressed: onRefresh,
              icon: Icons.refresh,
              label: 'Refresh',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: samples.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${samples.length} sample${samples.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (isOwned)
                    IconButton(
                      icon: const Icon(Icons.upload_file, size: 20),
                      onPressed: () => _showUploadDialog(context),
                      tooltip: 'Upload sample',
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            );
          }

          final sample = samples[index - 1];
          return _SampleCard(
            sample: sample,
            isOwned: isOwned,
          );
        },
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _UploadSampleDialog(),
    );
  }
}

class _SampleCard extends ConsumerWidget {
  const _SampleCard({
    required this.sample,
    required this.isOwned,
  });

  final SavedSample sample;
  final bool isOwned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sample.name.isEmpty ? '(unnamed)' : sample.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    _noteNameFromMidi(sample.baseNote, sample.fineTune),
                    style: theme.textTheme.bodySmall,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (sample.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                sample.description,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(sample.updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                if (isOwned) ...[
                  IconButton(
                    icon: Icon(
                      sample.isPublic ? Icons.public : Icons.public_off,
                      size: 20,
                    ),
                    tooltip: sample.isPublic ? 'Make private' : 'Make public',
                    onPressed: () {
                      ref
                          .read(savedSamplesProvider.notifier)
                          .updateSample(
                            sample.copyWith(
                              isPublic: !sample.isPublic,
                            ),
                          );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete sample',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete sample?'),
        content: Text(
          'Are you sure you want to delete '
          '"${sample.name.isEmpty ? '(unnamed)' : sample.name}"?',
        ),
        actions: [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.close,
            label: 'Cancel',
          ),
          PlinkyButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(savedSamplesProvider.notifier).deleteSample(sample.id);
            },
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static const _noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  String _noteNameFromMidi(int midiNote, int fineTune) {
    final noteName = _noteNames[midiNote % 12];
    final octave = (midiNote ~/ 12) - 1;
    if (fineTune == 0) {
      return '$noteName$octave';
    }
    final sign = fineTune > 0 ? '+' : '';
    return '$noteName$octave ($sign${fineTune}c)';
  }
}

class _UploadSampleDialog extends ConsumerStatefulWidget {
  const _UploadSampleDialog();

  @override
  ConsumerState<_UploadSampleDialog> createState() =>
      _UploadSampleDialogState();
}

class _UploadSampleDialogState extends ConsumerState<_UploadSampleDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isUploading = false;
  int _baseNote = 60;
  int _fineTune = 0;
  List<double> _slicePoints = List.of(defaultSlicePoints);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
        if (_nameController.text.isEmpty) {
          _nameController.text = result.files.single.name;
        }
      });
    }
  }

  Future<void> _upload() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (_fileBytes == null || _fileName == null || userId == null) {
      return;
    }

    setState(() => _isUploading = true);

    final sample = SavedSample(
      id: '',
      userId: userId,
      name: _nameController.text.trim(),
      filePath: '$userId/$_fileName',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      description: _descriptionController.text.trim(),
      isPublic: _isPublic,
      slicePoints: _slicePoints,
      baseNote: _baseNote,
      fineTune: _fineTune,
    );

    await ref
        .read(savedSamplesProvider.notifier)
        .saveSample(
          sample,
          _fileBytes!,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample uploaded')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Sample'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlinkyButton(
                onPressed: _isUploading ? null : _pickFile,
                icon: Icons.audio_file,
                label: _fileName ?? 'Choose file',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _BaseNoteSelector(
                baseNote: _baseNote,
                fineTune: _fineTune,
                enabled: !_isUploading,
                onBaseNoteChanged: (value) => setState(() => _baseNote = value),
                onFineTuneChanged: (value) => setState(() => _fineTune = value),
              ),
              const SizedBox(height: 16),
              _SlicePointsEditor(
                slicePoints: _slicePoints,
                enabled: !_isUploading,
                onChanged: (points) => setState(() => _slicePoints = points),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Share with community'),
                value: _isPublic,
                onChanged: _isUploading
                    ? null
                    : (value) => setState(() => _isPublic = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        PlinkyButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          icon: Icons.close,
          label: 'Cancel',
        ),
        PlinkyButton(
          onPressed: _isUploading || _fileBytes == null ? null : _upload,
          icon: _isUploading ? Icons.hourglass_empty : Icons.upload,
          label: _isUploading ? 'Uploading...' : 'Upload',
        ),
      ],
    );
  }
}

const _noteNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

class _BaseNoteSelector extends StatelessWidget {
  const _BaseNoteSelector({
    required this.baseNote,
    required this.fineTune,
    required this.enabled,
    required this.onBaseNoteChanged,
    required this.onFineTuneChanged,
  });

  final int baseNote;
  final int fineTune;
  final bool enabled;
  final ValueChanged<int> onBaseNoteChanged;
  final ValueChanged<int> onFineTuneChanged;

  @override
  Widget build(BuildContext context) {
    final noteName = _noteNames[baseNote % 12];
    final octave = (baseNote ~/ 12) - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Base note', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            DropdownButton<int>(
              value: baseNote % 12,
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        onBaseNoteChanged(
                          (baseNote ~/ 12) * 12 + value,
                        );
                      }
                    }
                  : null,
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(_noteNames[index]),
                );
              }),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: baseNote ~/ 12,
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        onBaseNoteChanged(
                          value * 12 + baseNote % 12,
                        );
                      }
                    }
                  : null,
              items: List.generate(10, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text('${index - 1}'),
                );
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Fine tune: $fineTune cents',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Slider(
                    value: fineTune.toDouble(),
                    min: -50,
                    max: 50,
                    divisions: 100,
                    label: '$fineTune c',
                    onChanged: enabled
                        ? (value) => onFineTuneChanged(value.round())
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(
          '$noteName$octave'
          '${fineTune != 0 ? ' (${fineTune > 0 ? '+' : ''}${fineTune}c)' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SlicePointsEditor extends StatelessWidget {
  const _SlicePointsEditor({
    required this.slicePoints,
    required this.enabled,
    required this.onChanged,
  });

  final List<double> slicePoints;
  final bool enabled;
  final ValueChanged<List<double>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Slice points',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton(
              onPressed: enabled
                  ? () => onChanged(List.of(defaultSlicePoints))
                  : null,
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 60,
          child: CustomPaint(
            painter: _SlicePointsPainter(
              slicePoints: slicePoints,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
            size: const Size(double.infinity, 60),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < 8; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Slice ${i + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: slicePoints[i],
                    onChanged: enabled
                        ? (value) {
                            final updated = List<double>.from(slicePoints);
                            updated[i] = double.parse(
                              value.toStringAsFixed(3),
                            );
                            onChanged(updated);
                          }
                        : null,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(slicePoints[i] * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SlicePointsPainter extends CustomPainter {
  const _SlicePointsPainter({
    required this.slicePoints,
    required this.color,
    required this.backgroundColor,
  });

  final List<double> slicePoints;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      backgroundPaint,
    );

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2;

    for (final point in slicePoints) {
      final x = point * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(_SlicePointsPainter oldDelegate) =>
      slicePoints != oldDelegate.slicePoints ||
      color != oldDelegate.color ||
      backgroundColor != oldDelegate.backgroundColor;
}
