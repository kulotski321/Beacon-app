import 'package:beacon_app/data/models/location_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final reading = LocationReading(
    timestamp: DateTime.utc(2026, 6, 7, 9, 42, 13),
    latitude: 1.26512,
    longitude: 103.69487,
    distanceMeters: 742.4,
  );

  group('LocationReading serialization', () {
    test('toJson uses an ISO 8601 timestamp and the spec field names', () {
      final json = reading.toJson();
      expect(json['timestamp'], '2026-06-07T09:42:13.000Z');
      expect(json['latitude'], 1.26512);
      expect(json['longitude'], 103.69487);
      expect(json['distance'], 742.4);
    });

    test('round-trips through toJson/fromJson', () {
      expect(LocationReading.fromJson(reading.toJson()), reading);
    });
  });

  group('LocationReading equality', () {
    test('equal when all fields match', () {
      final other = LocationReading(
        timestamp: DateTime.utc(2026, 6, 7, 9, 42, 13),
        latitude: 1.26512,
        longitude: 103.69487,
        distanceMeters: 742.4,
      );
      expect(reading, other);
      expect(reading.hashCode, other.hashCode);
    });

    test('unequal when a field differs', () {
      final other = LocationReading(
        timestamp: DateTime.utc(2026, 6, 7, 9, 42, 13),
        latitude: 1.26512,
        longitude: 103.69487,
        distanceMeters: 999.9,
      );
      expect(reading, isNot(other));
    });
  });
}
