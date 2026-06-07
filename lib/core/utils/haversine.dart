import 'dart:math' as math;

/// Mean Earth radius in metres, per the assignment spec (FR-2).
const double earthRadiusMeters = 6371000;

/// Returns the great-circle distance, in metres, between two WGS84 coordinates
/// using the Haversine formula.
///
/// Implemented by hand (deliberately **not** `Geolocator.distanceBetween`) as the
/// core problem-solving requirement of the assignment. The geolocator value is
/// only used as a sanity check in tests.
double haversineMeters(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);

  final lat1Rad = _toRadians(lat1);
  final lat2Rad = _toRadians(lat2);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1Rad) *
          math.cos(lat2Rad) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusMeters * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
