import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:plinkyhub/pages/samples/base_note_selector.dart';
import 'package:plinkyhub/pages/samples/sample_mode_selector.dart';
import 'package:plinkyhub/pages/samples/slice_points_editor.dart';

class SampleMetadataForm extends StatelessWidget {
  const SampleMetadataForm({
    required this.nameController,
    required this.descriptionController,
    required this.isPublic,
    required this.onIsPublicChanged,
    required this.pitched,
    required this.onPitchedChanged,
    required this.baseNote,
    required this.onBaseNoteChanged,
    required this.fineTune,
    required this.onFineTuneChanged,
    required this.slicePoints,
    required this.onSlicePointsChanged,
    required this.sliceNotes,
    required this.onSliceNotesChanged,
    required this.wavBytes,
    required this.pcmFrameCount,
    this.enabled = true,
    this.header,
    this.footer,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final bool isPublic;
  final ValueChanged<bool?> onIsPublicChanged;
  final bool pitched;
  final ValueChanged<bool> onPitchedChanged;
  final int baseNote;
  final ValueChanged<int> onBaseNoteChanged;
  final int fineTune;
  final ValueChanged<int> onFineTuneChanged;
  final List<double> slicePoints;
  final ValueChanged<List<double>> onSlicePointsChanged;
  final List<int> sliceNotes;
  final ValueChanged<List<int>> onSliceNotesChanged;
  final Uint8List? wavBytes;
  final int? pcmFrameCount;
  final bool enabled;
  final Widget? header;
  final Widget? footer;

  static const double _wideBreakpoint = 800;

  Widget _buildInfoSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: 16),
        ],
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Share with community'),
          value: isPublic,
          onChanged: enabled ? onIsPublicChanged : null,
        ),
        const SizedBox(height: 16),
        SampleModeSelector(
          pitched: pitched,
          enabled: enabled,
          onChanged: onPitchedChanged,
        ),
        if (!pitched) ...[
          const SizedBox(height: 16),
          BaseNoteSelector(
            baseNote: baseNote,
            fineTune: fineTune,
            enabled: enabled,
            onBaseNoteChanged: onBaseNoteChanged,
            onFineTuneChanged: onFineTuneChanged,
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: 16),
          footer!,
        ],
      ],
    );
  }

  Widget _buildSlicePointsSection() {
    return SlicePointsEditor(
      slicePoints: slicePoints,
      wavBytes: wavBytes,
      pcmFrameCount: pcmFrameCount,
      enabled: enabled,
      onChanged: onSlicePointsChanged,
      pitched: pitched,
      sliceNotes: sliceNotes,
      onSliceNotesChanged: onSliceNotesChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 340,
                child: _buildInfoSection(),
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildSlicePointsSection()),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoSection(),
            const SizedBox(height: 16),
            _buildSlicePointsSection(),
          ],
        );
      },
    );
  }
}
