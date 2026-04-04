import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/main.dart';

const _colorOptions = <({String label, Color color})>[
  (label: 'Teal', color: Color(0xFF00897B)),
  (label: 'Blue', color: Color(0xFF1565C0)),
  (label: 'Indigo', color: Color(0xFF283593)),
  (label: 'Purple', color: Color(0xFF6A1B9A)),
  (label: 'Pink', color: Color(0xFFC2185B)),
  (label: 'Red', color: Color(0xFFC62828)),
  (label: 'Orange', color: Color(0xFFE65100)),
  (label: 'Amber', color: Color(0xFFF9A825)),
  (label: 'Green', color: Color(0xFF2E7D32)),
  (label: 'Cyan', color: Color(0xFF00838F)),
  (label: 'Brown', color: Color(0xFF4E342E)),
  (label: 'Grey', color: Color(0xFF546E7A)),
];

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(primaryColorProvider);

    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Primary color',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((option) {
                final isSelected =
                    currentColor.toARGB32() == option.color.toARGB32();
                return Tooltip(
                  message: option.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => ref
                        .read(primaryColorProvider.notifier)
                        .setColor(option.color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: option.color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
