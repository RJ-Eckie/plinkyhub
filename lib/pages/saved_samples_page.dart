import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';
import 'package:plinkyhub/utils/wav.dart';
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

class _SampleList extends ConsumerStatefulWidget {
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
  ConsumerState<_SampleList> createState() => _SampleListState();
}

class _SampleListState extends ConsumerState<_SampleList> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedSample> get _filteredSamples {
    final samples = widget.samples;
    if (_query.isEmpty) {
      return samples;
    }
    final lower = _query.toLowerCase();
    final filtered = samples
        .where(
          (sample) =>
              sample.name.toLowerCase().contains(lower) ||
              sample.username.toLowerCase().contains(lower) ||
              sample.description.toLowerCase().contains(lower),
        )
        .toList();
    filtered.sort((a, b) {
      final aExact = a.name.toLowerCase() == lower ? 0 : 1;
      final bExact = b.name.toLowerCase() == lower ? 0 : 1;
      return aExact.compareTo(bExact);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.samples.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.samples.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isOwned
                  ? 'No saved samples yet'
                  : 'No community samples yet',
            ),
            const SizedBox(height: 8),
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isOwned) ...[
                    PlinkyButton(
                      onPressed: () => _showUploadDialog(context),
                      icon: Icons.upload_file,
                      label: 'Upload sample',
                    ),
                    const SizedBox(height: 8),
                  ],
                  PlinkyButton(
                    onPressed: widget.onRefresh,
                    icon: Icons.refresh,
                    label: 'Refresh',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredSamples;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search samples...',
              prefixIcon: Icon(Icons.search, size: 20),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          '${filtered.length} '
                          'sample${filtered.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        if (widget.isOwned)
                          IconButton(
                            icon: const Icon(Icons.upload_file, size: 20),
                            onPressed: () => _showUploadDialog(context),
                            tooltip: 'Upload sample',
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: widget.onRefresh,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  );
                }

                final sample = filtered[index - 1];
                return _SampleCard(
                  sample: sample,
                  isOwned: widget.isOwned,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _UploadSampleDialog(),
    );
  }
}

class _SampleCard extends ConsumerStatefulWidget {
  const _SampleCard({
    required this.sample,
    required this.isOwned,
  });

  final SavedSample sample;
  final bool isOwned;

  @override
  ConsumerState<_SampleCard> createState() => _SampleCardState();
}

class _SampleCardState extends ConsumerState<_SampleCard> {
  bool _expanded = false;
  Uint8List? _wavBytes;
  bool _loadingWav = false;
  late List<double> _slicePoints;
  late bool _pitched;
  late List<int> _sliceNotes;

  @override
  void initState() {
    super.initState();
    _slicePoints = List.of(widget.sample.slicePoints);
    _pitched = widget.sample.pitched;
    _sliceNotes = List.of(widget.sample.sliceNotes);
  }

  @override
  void didUpdateWidget(_SampleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sample.id != widget.sample.id) {
      _slicePoints = List.of(widget.sample.slicePoints);
      _pitched = widget.sample.pitched;
      _sliceNotes = List.of(widget.sample.sliceNotes);
      _wavBytes = null;
      _expanded = false;
    }
  }

  Future<void> _loadWav() async {
    if (_wavBytes != null || _loadingWav) {
      return;
    }
    setState(() => _loadingWav = true);
    try {
      final bytes = await ref
          .read(savedSamplesProvider.notifier)
          .downloadWav(widget.sample.filePath);
      if (mounted) {
        setState(() {
          _wavBytes = bytes;
          _loadingWav = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => _loadingWav = false);
      }
    }
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _loadWav();
    }
  }

  void _saveSampleSettings() {
    ref.read(savedSamplesProvider.notifier).updateSample(
      widget.sample.copyWith(
        slicePoints: _slicePoints,
        pitched: _pitched,
        sliceNotes: _sliceNotes,
      ),
    );
  }

  bool get _hasUnsavedChanges =>
      _slicePoints != widget.sample.slicePoints ||
      _pitched != widget.sample.pitched ||
      _sliceNotes != widget.sample.sliceNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sample = widget.sample;
    final isOwned = widget.isOwned;

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
                IconButton(
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                  ),
                  tooltip: _expanded ? 'Hide slices' : 'Show slices',
                  onPressed: _toggleExpanded,
                ),
                const Spacer(),
                if (isOwned) ...[
                  IconButton(
                    icon: Icon(
                      sample.isPublic ? Icons.public : Icons.public_off,
                      size: 20,
                    ),
                    tooltip:
                        sample.isPublic ? 'Make private' : 'Make public',
                    onPressed: () {
                      ref
                          .read(savedSamplesProvider.notifier)
                          .updateSample(
                            sample.copyWith(isPublic: !sample.isPublic),
                          );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete sample',
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              _SampleModeSelector(
                pitched: _pitched,
                enabled: isOwned,
                onChanged: (value) => setState(() => _pitched = value),
              ),
              const SizedBox(height: 8),
              if (_loadingWav)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _SlicePointsEditor(
                  slicePoints: _slicePoints,
                  wavBytes: _wavBytes,
                  enabled: isOwned,
                  onChanged: (points) {
                    setState(() => _slicePoints = points);
                  },
                  pitched: _pitched,
                  sliceNotes: _sliceNotes,
                  onSliceNotesChanged: (notes) {
                    setState(() => _sliceNotes = notes);
                  },
                ),
              if (isOwned && _hasUnsavedChanges)
                Align(
                  alignment: Alignment.centerRight,
                  child: PlinkyButton(
                    onPressed: _saveSampleSettings,
                    icon: Icons.save,
                    label: 'Save changes',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete sample?'),
        content: Text(
          'Are you sure you want to delete '
          '"${widget.sample.name.isEmpty ? '(unnamed)' : widget.sample.name}"?',
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
              ref
                  .read(savedSamplesProvider.notifier)
                  .deleteSample(widget.sample.id);
            },
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
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

  static String _noteNameFromMidi(int midiNote, int fineTune) {
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
  bool _isConverting = false;
  int _baseNote = 60;
  int _fineTune = 0;
  bool _pitched = false;
  List<double> _slicePoints = List.of(defaultSlicePoints);
  List<int> _sliceNotes = List.of(defaultSliceNotes);
  String? _sampleTooLongWarning;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;

      setState(() {
        _fileName = name;
        _isConverting = true;
        _sampleTooLongWarning = null;
        if (_nameController.text.isEmpty) {
          _nameController.text = name;
        }
      });

      // Run conversion off the main isolate tick to let the UI update.
      await Future<void>.delayed(Duration.zero);

      String? warning;
      try {
        final pcm = wavToPlinkyPcm(bytes);
        if (pcm.length > maxPcmBytes) {
          final durationSeconds = pcm.length ~/ 2 / plinkySampleRate;
          const maxSeconds = maxPcmBytes ~/ 2 / plinkySampleRate;
          warning = 'Sample is too long (~${durationSeconds}s). '
              'Plinky supports up to ~${maxSeconds}s per slot '
              'at 31,250 Hz.';
        }
      } on FormatException catch (e) {
        warning = e.message;
      }

      if (mounted) {
        setState(() {
          _fileBytes = bytes;
          _isConverting = false;
          _sampleTooLongWarning = warning;
        });
      }
    }
  }

  Future<void> _upload() async {
    final userId = ref.read(authenticationProvider).user?.id;
    if (_fileBytes == null || _fileName == null || userId == null) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      final pcmBytes = wavToPlinkyPcm(_fileBytes!);
      final pcmFileName =
          '${_fileName!.substring(0, _fileName!.lastIndexOf('.'))}.pcm';

      final sample = SavedSample(
        id: '',
        userId: userId,
        name: _nameController.text.trim(),
        filePath: '$userId/$_fileName',
        pcmFilePath: '$userId/$pcmFileName',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        slicePoints: _slicePoints,
        baseNote: _baseNote,
        fineTune: _fineTune,
        pitched: _pitched,
        sliceNotes: _sliceNotes,
      );

      await ref
          .read(savedSamplesProvider.notifier)
          .saveSample(
            sample,
            wavBytes: _fileBytes!,
            pcmBytes: pcmBytes,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample uploaded')),
        );
      }
    } on FormatException catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
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
                onPressed: _isUploading || _isConverting
                    ? null
                    : _pickFile,
                icon: Icons.audio_file,
                label: _fileName ?? 'Choose file',
              ),
              if (_isConverting) ...[
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Validating sample...'),
                  ],
                ),
              ],
              if (_sampleTooLongWarning != null) ...[
                const SizedBox(height: 8),
                Text(
                  _sampleTooLongWarning!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
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
              _SampleModeSelector(
                pitched: _pitched,
                enabled: !_isUploading,
                onChanged: (value) => setState(() => _pitched = value),
              ),
              const SizedBox(height: 16),
              if (!_pitched)
                _BaseNoteSelector(
                  baseNote: _baseNote,
                  fineTune: _fineTune,
                  enabled: !_isUploading,
                  onBaseNoteChanged: (value) =>
                      setState(() => _baseNote = value),
                  onFineTuneChanged: (value) =>
                      setState(() => _fineTune = value),
                ),
              if (!_pitched) const SizedBox(height: 16),
              _SlicePointsEditor(
                slicePoints: _slicePoints,
                wavBytes: _fileBytes,
                enabled: !_isUploading,
                onChanged: (points) => setState(() => _slicePoints = points),
                pitched: _pitched,
                sliceNotes: _sliceNotes,
                onSliceNotesChanged: (notes) =>
                    setState(() => _sliceNotes = notes),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Share with community'),
                value: _isPublic,
                onChanged: _isUploading
                    ? null
                    : (value) => setState(() => _isPublic = value),
              ),
              const SizedBox(height: 8),
              Text(
                'By uploading, you confirm that you own this sample or '
                'have the right to use and distribute it (e.g. under a '
                'Creative Commons licence or similar terms).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
          onPressed:
              _isUploading ||
                  _fileBytes == null ||
                  _sampleTooLongWarning != null
              ? null
              : _upload,
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

class _SlicePointsEditor extends StatefulWidget {
  const _SlicePointsEditor({
    required this.slicePoints,
    required this.wavBytes,
    required this.enabled,
    required this.onChanged,
    this.pitched = false,
    this.sliceNotes = defaultSliceNotes,
    this.onSliceNotesChanged,
  });

  final List<double> slicePoints;
  final Uint8List? wavBytes;
  final bool enabled;
  final ValueChanged<List<double>> onChanged;
  final bool pitched;
  final List<int> sliceNotes;
  final ValueChanged<List<int>>? onSliceNotesChanged;

  @override
  State<_SlicePointsEditor> createState() => _SlicePointsEditorState();
}

class _SlicePointsEditorState extends State<_SlicePointsEditor> {
  AudioSource? _audioSource;
  SoundHandle? _activeHandle;
  int _playingSlice = -1;
  bool _loadingAudio = false;

  @override
  void didUpdateWidget(_SlicePointsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wavBytes != widget.wavBytes) {
      _disposeAudio();
    }
  }

  @override
  void dispose() {
    _disposeAudio();
    super.dispose();
  }

  void _disposeAudio() {
    final source = _audioSource;
    if (source != null) {
      SoLoud.instance.disposeSource(source);
    }
    _audioSource = null;
    _activeHandle = null;
    _playingSlice = -1;
  }

  Future<void> _playSlice(int sliceIndex) async {
    final wavBytes = widget.wavBytes;
    if (wavBytes == null || _loadingAudio) {
      return;
    }

    final soloud = SoLoud.instance;

    // Stop any currently playing slice
    if (_activeHandle != null) {
      await soloud.stop(_activeHandle!);
      _activeHandle = null;
    }

    // Initialize engine and load audio if needed
    if (_audioSource == null) {
      setState(() => _loadingAudio = true);
      if (!soloud.isInitialized) {
        await soloud.init();
      }
      _audioSource = await soloud.loadMem('sample.wav', wavBytes);
      if (mounted) {
        setState(() => _loadingAudio = false);
      } else {
        return;
      }
    }

    final source = _audioSource!;
    final totalDuration = soloud.getLength(source);

    final startFraction = widget.slicePoints[sliceIndex];
    final endFraction = sliceIndex < 7
        ? widget.slicePoints[sliceIndex + 1]
        : 1.0;

    final startTime = totalDuration * startFraction;
    final sliceDuration = totalDuration * (endFraction - startFraction);

    final handle = await soloud.play(source, paused: true);
    soloud.seek(handle, startTime);
    soloud.setPause(handle, false);
    soloud.scheduleStop(handle, sliceDuration);

    setState(() {
      _activeHandle = handle;
      _playingSlice = sliceIndex;
    });

    // Reset playing state when the slice finishes
    await Future<void>.delayed(sliceDuration);
    if (mounted && _playingSlice == sliceIndex) {
      setState(() {
        _activeHandle = null;
        _playingSlice = -1;
      });
    }
  }

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
              onPressed: widget.enabled
                  ? () => widget.onChanged(List.of(defaultSlicePoints))
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
              slicePoints: widget.slicePoints,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
            size: const Size(double.infinity, 60),
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingAudio)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading audio...'),
              ],
            ),
          ),
        for (var i = 0; i < 8; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    'Slice ${i + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  icon: Icon(
                    _playingSlice == i
                        ? Icons.stop
                        : Icons.play_arrow,
                    size: 18,
                  ),
                  onPressed: widget.wavBytes != null && !_loadingAudio
                      ? () => _playSlice(i)
                      : null,
                  tooltip: 'Preview slice ${i + 1}',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: widget.slicePoints[i],
                    onChanged: widget.enabled
                        ? (value) {
                            final min = i > 0
                                ? widget.slicePoints[i - 1]
                                : 0.0;
                            final max = i < 7
                                ? widget.slicePoints[i + 1]
                                : 1.0;
                            final clamped = value.clamp(min, max);
                            final updated =
                                List<double>.from(widget.slicePoints);
                            updated[i] = double.parse(
                              clamped.toStringAsFixed(3),
                            );
                            widget.onChanged(updated);
                          }
                        : null,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(widget.slicePoints[i] * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (widget.pitched)
                  _SliceNoteDropdown(
                    note: widget.sliceNotes[i],
                    enabled: widget.enabled,
                    onChanged: (value) {
                      final updated = List<int>.from(widget.sliceNotes);
                      updated[i] = value;
                      widget.onSliceNotesChanged?.call(updated);
                    },
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

class _SampleModeSelector extends StatelessWidget {
  const _SampleModeSelector({
    required this.pitched,
    required this.enabled,
    required this.onChanged,
  });

  final bool pitched;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Mode', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Tape')),
            ButtonSegment(value: true, label: Text('Pitched')),
          ],
          selected: {pitched},
          onSelectionChanged: enabled
              ? (selection) => onChanged(selection.first)
              : null,
        ),
      ],
    );
  }
}

/// Compact note selector for a single slice in pitched mode.
///
/// Plinky uses note values 0-96 where value + 12 gives the MIDI note number.
class _SliceNoteDropdown extends StatelessWidget {
  const _SliceNoteDropdown({
    required this.note,
    required this.enabled,
    required this.onChanged,
  });

  /// Plinky note value (0-96).
  final int note;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final noteName = _noteNames[note % 12];
    final octave = (note + 12) ~/ 12 - 1;

    return SizedBox(
      width: 72,
      child: DropdownButton<int>(
        value: note,
        isExpanded: true,
        isDense: true,
        onChanged: enabled
            ? (value) {
                if (value != null) {
                  onChanged(value);
                }
              }
            : null,
        items: List.generate(97, (index) {
          final itemNoteName = _noteNames[index % 12];
          final itemOctave = (index + 12) ~/ 12 - 1;
          return DropdownMenuItem(
            value: index,
            child: Text('$itemNoteName$itemOctave'),
          );
        }),
        selectedItemBuilder: (context) {
          return List.generate(97, (_) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$noteName$octave',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          });
        },
      ),
    );
  }
}
