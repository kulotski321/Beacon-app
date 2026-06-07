import 'package:beacon_app/application/tracking_state.dart';
import 'package:beacon_app/data/models/location_reading.dart';
import 'package:flutter_test/flutter_test.dart';

LocationReading readingAt(int minute) => LocationReading(
      timestamp: DateTime.utc(2026, 6, 7, 0, minute),
      latitude: 0,
      longitude: 0,
      distanceMeters: minute.toDouble(),
    );

void main() {
  group('visibleReadings', () {
    // Oldest-first storage order: distances 0..24.
    final readings = List.generate(25, readingAt);

    test('returns all, newest-first, when filter is null', () {
      const base = TrackingState();
      final state = base.copyWith(readings: readings);
      expect(state.visibleReadings, hasLength(25));
      expect(state.visibleReadings.first.distanceMeters, 24);
      expect(state.visibleReadings.last.distanceMeters, 0);
    });

    test('limits to the most recent N', () {
      final state = TrackingState(readings: readings, filter: 5);
      final visible = state.visibleReadings;
      expect(visible, hasLength(5));
      expect(visible.first.distanceMeters, 24);
      expect(visible.last.distanceMeters, 20);
    });

    test('returns all when filter exceeds the count', () {
      final state =
          TrackingState(readings: [readingAt(0), readingAt(1)], filter: 20);
      expect(state.visibleReadings, hasLength(2));
    });
  });

  group('latest', () {
    test('is null when there are no readings', () {
      expect(const TrackingState().latest, isNull);
    });

    test('is the newest (last stored) reading', () {
      final state = TrackingState(readings: [readingAt(0), readingAt(7)]);
      expect(state.latest, readingAt(7));
    });
  });

  group('copyWith', () {
    test('clears nullable fields when null is passed explicitly', () {
      const state = TrackingState(filter: 5, errorMessage: 'boom');
      final cleared = state.copyWith(filter: null, errorMessage: null);
      expect(cleared.filter, isNull);
      expect(cleared.errorMessage, isNull);
    });

    test('preserves fields that are not passed', () {
      const state = TrackingState(filter: 5, errorMessage: 'boom');
      final next = state.copyWith(status: TrackingStatus.tracking);
      expect(next.status, TrackingStatus.tracking);
      expect(next.filter, 5);
      expect(next.errorMessage, 'boom');
    });
  });
}
