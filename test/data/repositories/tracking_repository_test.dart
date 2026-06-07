import 'package:beacon_app/core/utils/haversine.dart';
import 'package:beacon_app/data/models/location_reading.dart';
import 'package:beacon_app/data/models/target.dart';
import 'package:beacon_app/data/repositories/tracking_repository.dart';
import 'package:beacon_app/data/sources/location_service.dart';
import 'package:beacon_app/data/sources/reading_store.dart';
import 'package:beacon_app/data/sources/target_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockTargetApi extends Mock implements TargetApi {}

class MockLocationService extends Mock implements LocationService {}

class MockReadingStore extends Mock implements ReadingStore {}

Position _position(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.utc(2026, 6, 7),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  late MockTargetApi targetApi;
  late MockLocationService locationService;
  late MockReadingStore readingStore;
  late TrackingRepository repository;

  final fixedNow = DateTime.utc(2026, 6, 7, 12);
  const target = Target(id: '001', latitude: 1.265, longitude: 103.695);

  setUpAll(() {
    registerFallbackValue(
      LocationReading(
        timestamp: DateTime.utc(2026),
        latitude: 0,
        longitude: 0,
        distanceMeters: 0,
      ),
    );
  });

  setUp(() {
    targetApi = MockTargetApi();
    locationService = MockLocationService();
    readingStore = MockReadingStore();
    repository = TrackingRepository(
      targetApi: targetApi,
      locationService: locationService,
      readingStore: readingStore,
      now: () => fixedNow,
    );
  });

  test('fetchTarget delegates to the API', () async {
    when(() => targetApi.fetchTarget()).thenAnswer((_) async => target);
    expect(await repository.fetchTarget(), target);
  });

  test('captureReading computes distance, persists, and returns the reading',
      () async {
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => _position(1.30, 103.70));
    when(() => readingStore.add(any())).thenAnswer((_) async {});

    final reading = await repository.captureReading(target);

    final expectedDistance = haversineMeters(1.30, 103.70, 1.265, 103.695);
    expect(reading.latitude, 1.30);
    expect(reading.longitude, 103.70);
    expect(reading.distanceMeters, expectedDistance);
    expect(reading.timestamp, fixedNow);
    verify(() => readingStore.add(reading)).called(1);
  });

  test('readings delegates to the store', () {
    final stored = [
      LocationReading(
        timestamp: fixedNow,
        latitude: 1,
        longitude: 2,
        distanceMeters: 3,
      ),
    ];
    when(() => readingStore.getAll()).thenReturn(stored);
    expect(repository.readings(), stored);
  });
}
