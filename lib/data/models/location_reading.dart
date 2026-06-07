/// A single location reading captured during tracking (FR-3).
///
/// Stores the four required fields: timestamp, latitude, longitude, and the
/// computed distance to the target (metres).
class LocationReading {
  const LocationReading({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  /// When the reading was captured.
  final DateTime timestamp;

  /// Device latitude at capture time.
  final double latitude;

  /// Device longitude at capture time.
  final double longitude;

  /// Great-circle distance to the target, in metres.
  final double distanceMeters;

  /// Serializes to a JSON-safe map with an ISO 8601 (UTC) timestamp.
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'distance': distanceMeters,
      };

  factory LocationReading.fromJson(Map<String, dynamic> json) {
    return LocationReading(
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceMeters: (json['distance'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LocationReading &&
      other.timestamp == timestamp &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.distanceMeters == distanceMeters;

  @override
  int get hashCode =>
      Object.hash(timestamp, latitude, longitude, distanceMeters);

  @override
  String toString() =>
      'LocationReading(timestamp: ${timestamp.toIso8601String()}, '
      'lat: $latitude, lng: $longitude, distance: ${distanceMeters}m)';
}
