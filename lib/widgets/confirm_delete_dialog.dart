import 'package:flutter/material.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

/// Shows a confirmation dialog for deleting an item.
///
/// Returns `true` if the user confirmed the deletion.
Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String itemType,
  required String itemName,
}) async {
  final displayName = itemName.isEmpty ? '(unnamed)' : itemName;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete $itemType?'),
      content: Text(
        'Are you sure you want to delete "$displayName"?',
      ),
      actions: [
        PlinkyButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          icon: Icons.close,
          label: 'Cancel',
        ),
        PlinkyButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: Icons.delete,
          label: 'Delete',
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
