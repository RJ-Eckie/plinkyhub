import 'package:flutter/material.dart';
import 'package:plinkyhub/models/saved_pattern.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

class PatternPickerDialog extends StatelessWidget {
  const PatternPickerDialog({
    required this.patterns,
    super.key,
  });

  final List<SavedPattern> patterns;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a pattern'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: patterns.isEmpty
            ? const Center(child: Text('No saved patterns'))
            : ListView.builder(
                itemCount: patterns.length,
                itemBuilder: (context, index) {
                  final pattern = patterns[index];
                  return ListTile(
                    title: Text(
                      pattern.name.isEmpty ? '(unnamed)' : pattern.name,
                    ),
                    subtitle: pattern.description.isNotEmpty
                        ? Text(pattern.description)
                        : null,
                    onTap: () => Navigator.of(context).pop(pattern.id),
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
