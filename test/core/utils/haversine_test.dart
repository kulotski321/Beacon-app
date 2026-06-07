import 'package:beacon_app/core/utils/haversine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('haversineMeters', () {
    test('identical points return exactly 0', () {
      expect(haversineMeters(1.265, 103.695, 1.265, 103.695), 0);
    });

    test('one degree of longitude at the equator ≈ 111.195 km', () {
      // On the equator the Haversine distance reduces to R * Δλ, giving an
      // exact, well-known value: 6,371,000 * π/180.
      expect(haversineMeters(0, 0, 0, 1), closeTo(111194.93, 0.1));
    });

    test('Cebu → Singapore target is a sane long distance (~2,446 km)', () {
      // Cebu City -> the mock target near Singapore.
      final meters = haversineMeters(10.3157, 123.8854, 1.265, 103.695);
      expect(meters, greaterThan(2300000));
      expect(meters, lessThan(2600000));
    });

    test('is symmetric (a→b == b→a)', () {
      final ab = haversineMeters(10.3157, 123.8854, 1.265, 103.695);
      final ba = haversineMeters(1.265, 103.695, 10.3157, 123.8854);
      expect(ab, closeTo(ba, 1e-6));
    });

    test('cross-checks within 0.5% of Geolocator.distanceBetween', () {
      // Sanity check only — our value uses the mean Earth radius (6,371,000 m)
      // while geolocator uses the WGS84 equatorial radius (6,378,137 m), so the
      // two sit ~0.1% apart. distanceBetween is pure Dart, no platform channel.
      final ours = haversineMeters(10.3157, 123.8854, 1.265, 103.695);
      final reference =
          Geolocator.distanceBetween(10.3157, 123.8854, 1.265, 103.695);
      expect((ours - reference).abs() / reference, lessThan(0.005));
    });
  });
}
