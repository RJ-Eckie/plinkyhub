import 'package:flutter/material.dart';
import 'package:plinkyhub/models/saved_wavetable.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

class WavetablePickerDialog extends StatelessWidget {
  const WavetablePickerDialog({
    required this.wavetables,
    super.key,
  });

  final List<SavedWavetable> wavetables;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a wavetable'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: wavetables.isEmpty
            ? const Center(child: Text('No saved wavetables'))
            : ListView.builder(
                itemCount: wavetables.length,
                itemBuilder: (context, index) {
                  final wavetable = wavetables[index];
                  return ListTile(
                    title: Text(
                      wavetable.name.isEmpty ? '(unnamed)' : wavetable.name,
                    ),
                    subtitle: wavetable.description.isNotEmpty
                        ? Text(wavetable.description)
                        : null,
                    onTap: () => Navigator.of(context).pop(wavetable.id),
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
