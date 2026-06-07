import 'package:intl/intl.dart';

/// Formats a distance in metres for display (FR-2):
/// `< 1000 m` → whole metres (e.g. `742 m`);
/// `>= 1000 m` → kilometres with 2 decimals (e.g. `12.48 km`).
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  final km = meters / 1000;
  return '${km.toStringAsFixed(2)} km';
}

/// Formats a timestamp for the readings list, e.g. `Jun 7, 2026 5:42:13 PM`.
///
/// Renders in the device's local time zone.
String formatTimestamp(DateTime time) {
  return DateFormat('MMM d, y h:mm:ss a').format(time.toLocal());
}

/// Formats a single coordinate component to 5 decimal places (FR-4),
/// e.g. `1.26500`.
String formatCoordinate(double value) => value.toStringAsFixed(5);
