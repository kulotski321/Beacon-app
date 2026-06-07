import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tracking_controller.dart';

/// The start/stop control. Amber while tracking, navy when idle, and a spinner
/// while the target is being fetched.
class TrackingToggle extends ConsumerWidget {
  const TrackingToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingControllerProvider);
    final controller = ref.read(trackingControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    final isTracking = state.isTracking;
    final isBusy = state.isFetchingTarget;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed:
            isBusy ? null : (isTracking ? controller.stop : controller.start),
        style: FilledButton.styleFrom(
          backgroundColor: isTracking ? scheme.secondary : scheme.primary,
          foregroundColor: isTracking ? Colors.black87 : Colors.white,
        ),
        icon: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded),
        label: Text(
          isBusy
              ? 'Starting…'
              : isTracking
                  ? 'Stop tracking'
                  : 'Start tracking',
        ),
      ),
    );
  }
}
