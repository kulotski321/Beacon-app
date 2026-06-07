import 'dart:io';

import 'package:beacon_app/data/models/location_reading.dart';
import 'package:beacon_app/data/sources/reading_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;
  late ReadingStore store;

  LocationReading readingAt(double distance) => LocationReading(
        timestamp: DateTime.utc(2026, 6, 7, 9, distance.toInt() % 60),
        latitude: 1.26512,
        longitude: 103.69487,
        distanceMeters: distance,
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('beacon_hive_test');
    Hive.init(tempDir.path);
    store = ReadingStore(boxName: 'readings_test');
    await store.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('persists and retrieves readings in insertion order', () async {
    await store.add(readingAt(100));
    await store.add(readingAt(200));

    final all = store.getAll();
    expect(all, hasLength(2));
    expect(all.first.distanceMeters, 100);
    expect(all.last.distanceMeters, 200);
  });

  test('round-trips a reading through the adapter losslessly', () async {
    final original = readingAt(742.4);
    await store.add(original);
    expect(store.getAll().single, original);
  });

  test('clear empties the box', () async {
    await store.add(readingAt(100));
    await store.clear();
    expect(store.getAll(), isEmpty);
  });

  test('throws a StateError if used before init', () {
    final fresh = ReadingStore(boxName: 'never_opened');
    expect(fresh.getAll, throwsStateError);
  });
}
