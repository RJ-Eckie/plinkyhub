import 'package:flutter/material.dart';
import 'package:plinkyhub/widgets/plinky_loading_animation.dart';

class TunnelOfLightsInstructions extends StatelessWidget {
  const TunnelOfLightsInstructions({
    required this.itemType,
    this.isLoading = false,
    super.key,
  });

  final String itemType;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final action = isLoading
        ? 'To load a $itemType from your Plinky, put it'
        : 'To save this $itemType to your Plinky, put it';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$action into Tunnel of Lights mode:'),
        const SizedBox(height: 12),
        const Text('1. Turn off your Plinky'),
        const SizedBox(height: 4),
        const Text(
          '2. Hold the rotary encoder while turning '
          'the Plinky on',
        ),
        const SizedBox(height: 4),
        const Text(
          '3. The Plinky will appear as a USB drive '
          'on your computer',
        ),
        const SizedBox(height: 12),
        const Text(
          'Then click the button below to select the '
          'Plinky drive.',
        ),
      ],
    );
  }
}

class SaveProgressView extends StatelessWidget {
  const SaveProgressView({
    required this.statusMessage,
    this.progress,
    super.key,
  });

  final String statusMessage;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PlinkyLoadingAnimation(),
        const SizedBox(height: 16),
        Text(statusMessage),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class SaveDoneView extends StatelessWidget {
  const SaveDoneView({
    required this.itemType,
    this.usedWebUsb = false,
    super.key,
  });

  final String itemType;
  final bool usedWebUsb;

  @override
  Widget build(BuildContext context) {
    final label = '${itemType[0].toUpperCase()}${itemType.substring(1)}';
    if (usedWebUsb) {
      return Text('$label sent to Plinky successfully!');
    }
    return Text(
      '$label saved to Plinky successfully! '
      'Eject the drive and restart your Plinky.',
    );
  }
}

class SaveErrorView extends StatelessWidget {
  const SaveErrorView({
    this.errorMessage,
    super.key,
  });

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(errorMessage ?? 'An unknown error occurred.'),
      ],
    );
  }
}
