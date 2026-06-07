import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/location_reading.dart';
import '../data/models/target.dart';
import '../data/repositories/tracking_repository.dart';
import '../data/sources/location_service.dart';
import '../data/sources/target_api.dart';
import 'providers.dart';
import 'tracking_state.dart';

/// Foreground polling interval for location readings (FR-1).
const Duration trackingInterval = Duration(seconds: 5);

final trackingControllerProvider =
    NotifierProvider<TrackingController, TrackingState>(TrackingController.new);

/// Owns the tracking lifecycle and is the single source of truth for the UI.
///
/// State machine: `idle → fetchingTarget → tracking → idle`, with an `error`
/// branch. The timer lives here (not in any widget), so tracking survives widget
/// rebuilds and is cancelled deterministically on [stop] and on dispose.
class TrackingController extends Notifier<TrackingState> {
  Timer? _timer;
  bool _capturing = false;

  TrackingRepository get _repository => ref.read(trackingRepositoryProvider);

  @override
  TrackingState build() {
    ref.onDispose(_cancelTimer);
    // Surface any readings persisted in a previous session.
    return TrackingState(readings: _persistedReadings());
  }

  List<LocationReading> _persistedReadings() {
    try {
      return _repository.readings();
    } catch (_) {
      return const [];
    }
  }

  /// Fetches the target, takes an immediate reading (which also verifies
  /// location permission), then polls every [trackingInterval] while tracking.
  Future<void> start() async {
    if (state.isTracking || state.isFetchingTarget) return;

    state = state.copyWith(
      status: TrackingStatus.fetchingTarget,
      errorMessage: null,
      failure: null,
    );

    final Target target;
    try {
      target = await _repository.fetchTarget();
    } catch (e) {
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: _describe(e),
      );
      return;
    }

    state = state.copyWith(status: TrackingStatus.tracking, target: target);

    // First reading now; only arm the periodic timer if it succeeds.
    await _capture();
    if (state.isTracking) {
      _timer = Timer.periodic(trackingInterval, (_) => _capture());
    }
  }

  /// Stops tracking immediately — cancels the timer so no further readings land.
  void stop() {
    _cancelTimer();
    if (state.isTracking) {
      state = state.copyWith(status: TrackingStatus.idle);
    }
  }

  /// View-layer filter: show the most recent [mostRecent] readings, or all when
  /// null. Storage is untouched.
  void setFilter(int? mostRecent) {
    state = state.copyWith(filter: mostRecent);
  }

  Future<void> clearReadings() async {
    await _repository.clearReadings();
    state = state.copyWith(readings: const []);
  }

  /// Opens the OS location settings (to recover from a permanently-denied
  /// permission).
  Future<void> openLocationSettings() => _repository.openLocationSettings();

  Future<void> _capture() async {
    final target = state.target;
    if (target == null || _capturing) return; // skip overlapping ticks
    _capturing = true;
    try {
      await _repository.captureReading(target);
      state = state.copyWith(readings: _repository.readings());
    } on LocationServiceException catch (e) {
      _fail(e.message, failure: e.failure);
    } catch (e) {
      _fail('Failed to read location: $e');
    } finally {
      _capturing = false;
    }
  }

  void _fail(String message, {LocationFailure? failure}) {
    _cancelTimer();
    state = state.copyWith(
      status: TrackingStatus.error,
      errorMessage: message,
      failure: failure,
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _describe(Object error) {
    if (error is TargetApiException) return error.message;
    return error.toString();
  }
}
