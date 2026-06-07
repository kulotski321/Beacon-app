import '../data/models/location_reading.dart';
import '../data/models/target.dart';
import '../data/sources/location_service.dart';

/// The phases of the tracking lifecycle (FR-1).
enum TrackingStatus { idle, fetchingTarget, tracking, error }

/// Immutable snapshot of the tracking feature — the single source of truth the
/// UI renders. Storage always holds every reading; [filter] is a view concern.
class TrackingState {
  const TrackingState({
    this.status = TrackingStatus.idle,
    this.target,
    this.readings = const [],
    this.filter,
    this.errorMessage,
    this.failure,
  });

  final TrackingStatus status;
  final Target? target;

  /// All readings, oldest-first (storage order).
  final List<LocationReading> readings;

  /// Number of most-recent readings to show, or null for "All".
  final int? filter;

  final String? errorMessage;

  /// The specific location failure, when [status] is `error` due to permissions.
  /// Lets the UI offer "open settings" for the permanently-denied case.
  final LocationFailure? failure;

  bool get isTracking => status == TrackingStatus.tracking;
  bool get isFetchingTarget => status == TrackingStatus.fetchingTarget;
  bool get hasError => status == TrackingStatus.error;

  /// Readings for display: newest-first, limited to the most recent [filter].
  List<LocationReading> get visibleReadings {
    final newestFirst = readings.reversed.toList(growable: false);
    final n = filter;
    if (n == null || n >= newestFirst.length) return newestFirst;
    return newestFirst.sublist(0, n);
  }

  // Sentinel lets copyWith distinguish "leave unchanged" from "set to null".
  static const Object _unset = Object();

  TrackingState copyWith({
    TrackingStatus? status,
    Object? target = _unset,
    List<LocationReading>? readings,
    Object? filter = _unset,
    Object? errorMessage = _unset,
    Object? failure = _unset,
  }) {
    return TrackingState(
      status: status ?? this.status,
      target: identical(target, _unset) ? this.target : target as Target?,
      readings: readings ?? this.readings,
      filter: identical(filter, _unset) ? this.filter : filter as int?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      failure: identical(failure, _unset)
          ? this.failure
          : failure as LocationFailure?,
    );
  }
}
