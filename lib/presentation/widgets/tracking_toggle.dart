import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tracking_controller.dart';
import '../../application/tracking_state.dart';

/// The start/stop control. Amber while tracking, navy when idle, and a spinner
/// while the target is being fetched.
class TrackingToggle extends ConsumerWidget {
  const TrackingToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the status drives this button, so select on it: a new reading every
    // 5 s must not rebuild the start/stop control.
    final status = ref.watch(
      trackingControllerProvider.select((state) => state.status),
    );
    final controller = ref.read(trackingControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    final isTracking = status == TrackingStatus.tracking;
    final isBusy = status == TrackingStatus.fetchingTarget;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: isBusy
            ? null
            : () {
                // Tactile confirmation for the primary action (no-op off-mobile).
                HapticFeedback.mediumImpact();
                isTracking ? controller.stop() : controller.start();
              },
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
