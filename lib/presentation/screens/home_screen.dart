import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tracking_controller.dart';
import '../../application/tracking_state.dart';
import '../../core/utils/formatters.dart';
import '../../data/sources/location_service.dart';
import '../widgets/empty_state.dart';
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
        _showErrorSnackBar(context, ref, next.errorMessage!);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilterSelector(
                    filter: state.filter,
                    onChanged:
                        ref.read(trackingControllerProvider.notifier).setFilter,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Showing ${readings.length} of ${state.readings.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: readings.isEmpty
                ? const EmptyState(
                    icon: Icons.my_location_outlined,
                    title: 'No readings yet',
                    message: 'Start tracking to record your distance to the '
                        'target every 5 seconds.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: readings.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) => ReadingTile(
                      reading: readings[index],
                      isLatest: index == 0,
                    ),
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

  void _showErrorSnackBar(BuildContext context, WidgetRef ref, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: ref.read(trackingControllerProvider.notifier).start,
          ),
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
    final latest = state.latest;
    final onPrimaryMuted = Colors.white.withValues(alpha: 0.7);

    final label = switch (state.status) {
      TrackingStatus.idle => 'Idle',
      TrackingStatus.fetchingTarget => 'Fetching target…',
      TrackingStatus.tracking => 'Tracking',
      TrackingStatus.error => 'Stopped — error',
    };
    final distanceText =
        latest != null ? formatDistance(latest.distanceMeters) : '—';

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
          Semantics(
            liveRegion: true,
            label: latest != null
                ? 'Distance to target: $distanceText'
                : 'No reading yet',
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              child: Text(
                distanceText,
                key: ValueKey(distanceText),
                style: TextStyle(
                  color: scheme.secondary,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Text(
            latest != null ? 'to target' : 'Know your distance.',
            style: TextStyle(color: onPrimaryMuted),
          ),
          if (latest != null || state.target != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Colors.white24),
            const SizedBox(height: 10),
          ],
          if (latest != null)
            _MetaRow(
              icon: Icons.history,
              text: '${formatReadingCount(state.readings.length)}'
                  ' · updated ${formatClock(latest.timestamp)}',
              color: onPrimaryMuted,
            ),
          if (state.target != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _MetaRow(
                icon: Icons.flag_outlined,
                text: 'Target '
                    '${formatCoordinate(state.target!.latitude)}, '
                    '${formatCoordinate(state.target!.longitude)}',
                color: onPrimaryMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// A small icon + label line used for the banner's metadata.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Pulsing amber "LIVE" badge shown in the app bar while tracking.
///
/// Honours the platform "reduce motion" accessibility setting: when motion is
/// disabled the badge stays solid instead of pulsing.
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
    value: 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    final amber = Theme.of(context).colorScheme.secondary;
    final row = Row(
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
    );

    if (reduceMotion) return row;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_controller),
      child: row,
    );
  }
}
