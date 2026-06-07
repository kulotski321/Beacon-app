import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tracking_controller.dart';
import '../../application/tracking_state.dart';
import '../../core/utils/formatters.dart';
import '../../data/sources/location_service.dart';
import '../widgets/filter_selector.dart';
import '../widgets/reading_tile.dart';
import '../widgets/tracking_toggle.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surface errors as they occur: a dialog for permanently-denied permission
    // (which only Settings can fix), a snackbar for everything else.
    ref.listen<TrackingState>(trackingControllerProvider, (previous, next) {
      final isNewError = next.hasError &&
          next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage;
      if (!isNewError) return;
      if (next.failure == LocationFailure.permissionDeniedForever) {
        _showPermissionDialog(context, ref, next.errorMessage!);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final state = ref.watch(trackingControllerProvider);
    final readings = state.visibleReadings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon'),
        actions: [
          if (state.isTracking)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: _LiveIndicator()),
            ),
        ],
      ),
      body: Column(
        children: [
          _StatusBanner(state: state),
          if (readings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FilterSelector(
                filter: state.filter,
                onChanged:
                    ref.read(trackingControllerProvider.notifier).setFilter,
              ),
            ),
          Expanded(
            child: readings.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: readings.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) =>
                        ReadingTile(reading: readings[index]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: const TrackingToggle(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionDialog(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location permission needed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref
                  .read(trackingControllerProvider.notifier)
                  .openLocationSettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}

/// Navy header showing tracking status and the latest distance to the target.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latest =
        state.visibleReadings.isNotEmpty ? state.visibleReadings.first : null;

    final label = switch (state.status) {
      TrackingStatus.idle => 'Idle',
      TrackingStatus.fetchingTarget => 'Fetching target…',
      TrackingStatus.tracking => 'Tracking',
      TrackingStatus.error => 'Stopped — error',
    };

    return Container(
      width: double.infinity,
      color: scheme.primary,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            latest != null ? formatDistance(latest.distanceMeters) : '—',
            style: TextStyle(
              color: scheme.secondary,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            latest != null ? 'to target' : 'Know your distance.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.my_location_outlined,
              size: 64,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('No readings yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Start tracking to record your distance to the target every '
              '5 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing amber "LIVE" badge shown in the app bar while tracking.
class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amber = Theme.of(context).colorScheme.secondary;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_controller),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: amber, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
