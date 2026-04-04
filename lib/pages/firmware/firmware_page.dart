import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/pages/firmware/firmware_card.dart';
import 'package:plinkyhub/pages/firmware/upload_firmware_dialog.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/firmwares_notifier.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

const _firmwareAdminIds = {
  '1fc66f06-5180-48d6-814d-9cbcdd0980d8',
  'a1248a67-da78-4b23-856f-02fc2c23d4bc',
  '3e60fdc3-fd09-44e1-a211-8c790f69899b',
};

class FirmwarePage extends ConsumerWidget {
  const FirmwarePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firmwaresState = ref.watch(firmwaresProvider);
    final currentUserId = ref.watch(authenticationProvider).user?.id;
    final isAdmin =
        currentUserId != null && _firmwareAdminIds.contains(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Firmware',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              if (isAdmin)
                PlinkyButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => const UploadFirmwareDialog(),
                  ),
                  icon: Icons.upload,
                  label: 'Upload firmware',
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (firmwaresState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (firmwaresState.errorMessage != null)
            Text(
              firmwaresState.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (firmwaresState.firmwares.isEmpty)
            const Text('No firmware versions available yet.')
          else
            ...firmwaresState.firmwares.map(
              (firmware) => FirmwareCard(
                firmware: firmware,
                isAdmin: isAdmin,
              ),
            ),
        ],
      ),
    );
  }
}
