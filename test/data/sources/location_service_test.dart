import 'package:beacon_app/data/sources/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

Position _fakePosition() => Position(
      latitude: 1.30,
      longitude: 103.70,
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
  late MockGeolocatorPlatform geo;
  late LocationService service;

  setUpAll(() => registerFallbackValue(const LocationSettings()));

  setUp(() {
    geo = MockGeolocatorPlatform();
    service = LocationService(geolocator: geo);
  });

  test('throws serviceDisabled when location services are off', () {
    when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => false);
    expect(
      service.getCurrentPosition(),
      throwsA(isA<LocationServiceException>().having(
        (e) => e.failure,
        'failure',
        LocationFailure.serviceDisabled,
      )),
    );
  });

  test('requests permission when denied, throws if still denied', () async {
    when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
    when(() => geo.checkPermission())
        .thenAnswer((_) async => LocationPermission.denied);
    when(() => geo.requestPermission())
        .thenAnswer((_) async => LocationPermission.denied);

    await expectLater(
      service.getCurrentPosition(),
      throwsA(isA<LocationServiceException>().having(
        (e) => e.failure,
        'failure',
        LocationFailure.permissionDenied,
      )),
    );
    verify(() => geo.requestPermission()).called(1);
  });

  test('throws permissionDeniedForever', () {
    when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
    when(() => geo.checkPermission())
        .thenAnswer((_) async => LocationPermission.deniedForever);

    expect(
      service.getCurrentPosition(),
      throwsA(isA<LocationServiceException>().having(
        (e) => e.failure,
        'failure',
        LocationFailure.permissionDeniedForever,
      )),
    );
  });

  test('returns the position when permission is granted', () async {
    when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
    when(() => geo.checkPermission())
        .thenAnswer((_) async => LocationPermission.whileInUse);
    when(() => geo.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        )).thenAnswer((_) async => _fakePosition());

    final position = await service.getCurrentPosition();
    expect(position.latitude, 1.30);
    expect(position.longitude, 103.70);
  });
}
