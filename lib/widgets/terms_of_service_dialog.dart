import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const _storageKey = 'tos_accepted';

bool hasAcceptedTermsOfService() {
  return web.window.localStorage.getItem(_storageKey) == 'true';
}

void showTermsOfServiceDialog(
  BuildContext context, {
  bool requireAcceptance = true,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: !requireAcceptance,
    builder: (context) => TermsOfServiceDialog(
      requireAcceptance: requireAcceptance,
    ),
  );
}

class TermsOfServiceDialog extends StatelessWidget {
  const TermsOfServiceDialog({
    this.requireAcceptance = true,
    super.key,
  });

  final bool requireAcceptance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Terms of Service',
        style: theme.textTheme.headlineSmall,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to PlinkyHub!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'By using PlinkyHub, you agree to the following terms:',
              ),
              const SizedBox(height: 12),
              const Text(
                '1. User Content\n'
                'You retain ownership of presets, samples, wavetables, and '
                'other content you upload. By sharing content publicly, you '
                'grant other users a non-exclusive license to use and download '
                'that content.\n\n'
                '2. Acceptable Use\n'
                'You agree not to upload content that infringes on the '
                'intellectual property rights of others, or that is '
                'unlawful, harmful, or offensive.\n\n'
                '3. No Warranty\n'
                'PlinkyHub is provided "as is" without warranties of any '
                'kind. We are not responsible for data loss or damage to '
                'your Plinky device.\n\n'
                '4. Privacy\n'
                'We collect only the data necessary to provide the service. '
                'Your email is used for authentication purposes only.\n\n'
                '5. Changes\n'
                'We may update these terms from time to time. Continued use '
                'of the service constitutes acceptance of any changes.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (requireAcceptance)
          FilledButton(
            onPressed: () {
              web.window.localStorage.setItem(_storageKey, 'true');
              Navigator.of(context).pop();
            },
            child: const Text('I Accept'),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
