import 'package:flutter/material.dart';
import 'package:plinkyhub/services/webusb_service.dart';
import 'package:plinkyhub/utils/file_system_access.dart';

/// A banner warning that the current browser does not support required APIs.
///
/// Shows nothing if all required APIs are available (Chromium browsers).
class ChromiumRequiredBanner extends StatelessWidget {
  const ChromiumRequiredBanner({
    this.requireWebUsb = false,
    this.requireFileSystemAccess = false,
    super.key,
  });

  final bool requireWebUsb;
  final bool requireFileSystemAccess;

  @override
  Widget build(BuildContext context) {
    final missingWebUsb = requireWebUsb && !WebUsbService.isSupported;
    final missingFileSystem =
        requireFileSystemAccess && !isFileSystemAccessSupported;

    if (!missingWebUsb && !missingFileSystem) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This feature requires a Chromium-based browser '
              '(Chrome, Edge, Opera). '
              'Firefox and Safari are not supported.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
