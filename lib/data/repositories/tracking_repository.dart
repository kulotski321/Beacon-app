import '../../core/utils/haversine.dart';
import '../models/location_reading.dart';
import '../models/target.dart';
import '../sources/location_service.dart';
import '../sources/reading_store.dart';
import '../sources/target_api.dart';

/// Coordinates the data sources for tracking: fetches the target, captures a
/// reading (position → distance → persist), and exposes stored readings.
///
/// This is the single seam the application layer ([TrackingController]) talks to,
/// so the controller never depends on http / geolocator / Hive directly.
class TrackingRepository {
  TrackingRepository({
    required TargetApi targetApi,
    required LocationService locationService,
    required ReadingStore readingStore,
    DateTime Function()? now,
  })  : _targetApi = targetApi,
        _locationService = locationService,
        _readingStore = readingStore,
        _now = now ?? DateTime.now;

  final TargetApi _targetApi;
  final LocationService _locationService;
  final ReadingStore _readingStore;
  final DateTime Function() _now;

  /// Fetches the tracking target from the mock backend.
  Future<Target> fetchTarget() => _targetApi.fetchTarget();

  /// Captures the current position, computes the Haversine distance to [target],
  /// persists the reading, and returns it.
  Future<LocationReading> captureReading(Target target) async {
    final position = await _locationService.getCurrentPosition();
    final distance = haversineMeters(
      position.latitude,
      position.longitude,
      target.latitude,
      target.longitude,
    );
    final reading = LocationReading(
      timestamp: _now(),
      latitude: position.latitude,
      longitude: position.longitude,
      distanceMeters: distance,
    );
    await _readingStore.add(reading);
    return reading;
  }

  /// All persisted readings, oldest first.
  List<LocationReading> readings() => _readingStore.getAll();

  Future<void> clearReadings() => _readingStore.clear();
}
