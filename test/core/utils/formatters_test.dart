import 'package:beacon_app/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDistance', () {
    test('below 1000 m shows whole metres', () {
      expect(formatDistance(742), '742 m');
      expect(formatDistance(0), '0 m');
      expect(formatDistance(999), '999 m');
    });

    test('rounds metres to the nearest whole number', () {
      expect(formatDistance(742.6), '743 m');
      expect(formatDistance(742.4), '742 m');
    });

    test('1000 m and above shows kilometres with 2 decimals', () {
      expect(formatDistance(1000), '1.00 km');
      expect(formatDistance(12480), '12.48 km');
      expect(formatDistance(2446000), '2446.00 km');
    });
  });

  group('formatCoordinate', () {
    test('formats to 5 decimal places', () {
      expect(formatCoordinate(1.265), '1.26500');
      expect(formatCoordinate(103.6954321), '103.69543');
      expect(formatCoordinate(-7.5), '-7.50000');
    });
  });

  group('formatReadingCount', () {
    test('uses the singular noun for exactly one', () {
      expect(formatReadingCount(1), '1 reading');
    });

    test('uses the plural noun otherwise', () {
      expect(formatReadingCount(0), '0 readings');
      expect(formatReadingCount(5), '5 readings');
    });
  });

  group('formatTimestamp', () {
    test('renders a readable local timestamp', () {
      // Constructed as a local DateTime, so toLocal() is a no-op and the result
      // is independent of the test machine's time zone.
      expect(
        formatTimestamp(DateTime(2026, 6, 7, 17, 42, 13)),
        'Jun 7, 2026 5:42:13 PM',
      );
    });
  });

  group('formatClock', () {
    test('renders time only, without the date', () {
      expect(formatClock(DateTime(2026, 6, 7, 17, 42, 13)), '5:42:13 PM');
      expect(formatClock(DateTime(2026, 1, 1, 0, 0, 0)), '12:00:00 AM');
    });
  });
}
