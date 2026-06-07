/// The tracking target fetched from the mock backend (FR-1).
///
/// Mock payload shape:
/// ```json
/// { "id": "001", "target_lat": 1.265, "target_lng": 103.695 }
/// ```
class Target {
  const Target({
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final double latitude;
  final double longitude;

  /// Parses the mock backend payload. Throws a [FormatException] if any field
  /// is missing or of the wrong type, so the data layer can surface a clean
  /// "bad JSON" error.
  factory Target.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final lat = json['target_lat'];
    final lng = json['target_lng'];
    if (id is! String || lat is! num || lng is! num) {
      throw FormatException('Invalid target payload', json);
    }
    return Target(
      id: id,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'target_lat': latitude,
        'target_lng': longitude,
      };

  @override
  bool operator ==(Object other) =>
      other is Target &&
      other.id == id &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(id, latitude, longitude);

  @override
  String toString() => 'Target(id: $id, lat: $latitude, lng: $longitude)';
}
