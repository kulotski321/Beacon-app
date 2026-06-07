import 'package:hive_ce/hive.dart';

import 'location_reading.dart';

/// Hand-written Hive adapter for [LocationReading] — no `build_runner` codegen.
///
/// Keeping the adapter here (rather than on the model) leaves [LocationReading]
/// framework-free; the Hive dependency lives only in this file. The timestamp is
/// stored as an ISO 8601 (UTC) string so it round-trips losslessly.
class LocationReadingAdapter extends TypeAdapter<LocationReading> {
  @override
  final int typeId = 0;

  @override
  LocationReading read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return LocationReading(
      timestamp: DateTime.parse(fields[0] as String),
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      distanceMeters: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LocationReading obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp.toUtc().toIso8601String())
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.distanceMeters);
  }
}
