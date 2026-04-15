import 'package:flutter/material.dart';

/// Notice explaining that the flash dump feature only works with the
/// experimental LPE firmware, which exposes the WebUSB flash dump
/// commands (`IDX_DUMP_INT_FLASH` / `IDX_DUMP_EXT_FLASH`). Stock
/// Plinky firmware does not implement those commands.
class LpeFirmwareRequiredNotice extends StatelessWidget {
  const LpeFirmwareRequiredNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.memory,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Flash dumps require the experimental LPE firmware '
              '(ember-labs-io/Plinky_LPE). '
              'Stock Plinky firmware does not expose the WebUSB flash '
              'dump commands needed for this feature.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
