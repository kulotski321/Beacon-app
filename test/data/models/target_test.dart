import 'package:beacon_app/data/models/target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Target.fromJson', () {
    test('parses the mock backend payload', () {
      final target = Target.fromJson({
        'id': '001',
        'target_lat': 1.265,
        'target_lng': 103.695,
      });
      expect(target.id, '001');
      expect(target.latitude, 1.265);
      expect(target.longitude, 103.695);
    });

    test('accepts integer coordinates and widens to double', () {
      final target = Target.fromJson({
        'id': '002',
        'target_lat': 1,
        'target_lng': 103,
      });
      expect(target.latitude, 1.0);
      expect(target.longitude, 103.0);
    });

    test('throws FormatException on a malformed payload', () {
      expect(
        () => Target.fromJson({'id': '001', 'target_lat': 'oops'}),
        throwsFormatException,
      );
      expect(
        () => Target.fromJson({'target_lat': 1.265, 'target_lng': 103.695}),
        throwsFormatException,
      );
    });
  });

  test('round-trips through toJson/fromJson', () {
    const target = Target(id: '001', latitude: 1.265, longitude: 103.695);
    expect(Target.fromJson(target.toJson()), target);
  });

  test('value equality', () {
    const a = Target(id: '001', latitude: 1.265, longitude: 103.695);
    const b = Target(id: '001', latitude: 1.265, longitude: 103.695);
    const c = Target(id: '002', latitude: 1.265, longitude: 103.695);
    expect(a, b);
    expect(a, isNot(c));
  });
}
