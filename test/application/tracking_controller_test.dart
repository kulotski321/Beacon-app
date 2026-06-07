import 'package:beacon_app/application/providers.dart';
import 'package:beacon_app/application/tracking_controller.dart';
import 'package:beacon_app/application/tracking_state.dart';
import 'package:beacon_app/data/models/location_reading.dart';
import 'package:beacon_app/data/models/target.dart';
import 'package:beacon_app/data/repositories/tracking_repository.dart';
import 'package:beacon_app/data/sources/location_service.dart';
import 'package:beacon_app/data/sources/target_api.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository repo;
  late ProviderContainer container;

  const target = Target(id: '001', latitude: 1.265, longitude: 103.695);
  final reading = LocationReading(
    timestamp: DateTime.utc(2026, 6, 7),
    latitude: 1.30,
    longitude: 103.70,
    distanceMeters: 742,
  );

  setUpAll(() => registerFallbackValue(target));

  setUp(() {
    repo = MockTrackingRepository();
    when(() => repo.readings()).thenReturn(<LocationReading>[]);
    container = ProviderContainer(
      overrides: [trackingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  TrackingController controller() =>
      container.read(trackingControllerProvider.notifier);
  TrackingState currentState() => container.read(trackingControllerProvider);

  test('loads persisted readings when first built', () {
    when(() => repo.readings()).thenReturn([reading]);
    expect(currentState().readings, [reading]);
  });

  test('start fetches the target, takes a first reading, and tracks', () async {
    when(() => repo.fetchTarget()).thenAnswer((_) async => target);
    when(() => repo.captureReading(any())).thenAnswer((_) async => reading);
    when(() => repo.readings()).thenReturn([reading]);

    await controller().start();

    final state = currentState();
    expect(state.status, TrackingStatus.tracking);
    expect(state.target, target);
    expect(state.readings, [reading]);
    verify(() => repo.captureReading(target)).called(1);
  });

  test('start enters error and does not track when the fetch fails', () async {
    when(() => repo.fetchTarget()).thenThrow(const TargetApiException('down'));

    await controller().start();

    expect(currentState().status, TrackingStatus.error);
    expect(currentState().errorMessage, 'down');
    verifyNever(() => repo.captureReading(any()));
  });

  test('start enters error when the first reading is denied', () async {
    when(() => repo.fetchTarget()).thenAnswer((_) async => target);
    when(() => repo.captureReading(any())).thenThrow(
      const LocationServiceException(LocationFailure.permissionDeniedForever),
    );

    await controller().start();

    expect(currentState().status, TrackingStatus.error);
    expect(currentState().errorMessage, contains('permanently denied'));
  });

  test('captures every interval, and stop() halts further readings', () {
    fakeAsync((async) {
      when(() => repo.fetchTarget()).thenAnswer((_) async => target);
      when(() => repo.captureReading(any())).thenAnswer((_) async => reading);
      when(() => repo.readings()).thenReturn([reading]);

      final c = controller();
      c.start();
      async.flushMicrotasks(); // resolve fetch + immediate reading
      expect(currentState().isTracking, isTrue);

      async.elapse(trackingInterval); // 2nd reading
      async.elapse(trackingInterval); // 3rd reading

      c.stop();
      expect(currentState().status, TrackingStatus.idle);

      async.elapse(trackingInterval * 5); // nothing more after stop

      verify(() => repo.captureReading(any())).called(3);
    });
  });

  test('setFilter changes the view only, leaving storage intact', () async {
    when(() => repo.fetchTarget()).thenAnswer((_) async => target);
    when(() => repo.captureReading(any())).thenAnswer((_) async => reading);
    when(() => repo.readings()).thenReturn([reading]);
    await controller().start();

    controller().setFilter(5);
    expect(currentState().filter, 5);

    controller().setFilter(null);
    expect(currentState().filter, isNull);

    verifyNever(() => repo.clearReadings());
  });
}
