import 'package:hive_ce/hive.dart';

import '../models/location_reading.dart';
import '../models/location_reading_adapter.dart';

/// Local persistence for [LocationReading]s, backed by a Hive (CE) box (FR-3).
///
/// Hive's storage directory must be initialised once at app start
/// (`Hive.initFlutter()` in `main`); [init] then registers the adapter and opens
/// the box. Tests initialise Hive with a temp directory via `Hive.init(path)`.
class ReadingStore {
  ReadingStore({this.boxName = 'readings'});

  final String boxName;
  Box<LocationReading>? _box;

  Box<LocationReading> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('ReadingStore.init() must be called before use.');
    }
    return box;
  }

  /// Registers the adapter (once) and opens the box.
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocationReadingAdapter());
    }
    _box = await Hive.openBox<LocationReading>(boxName);
  }

  Future<void> add(LocationReading reading) => _requireBox.add(reading);

  /// All stored readings, oldest first (insertion order).
  List<LocationReading> getAll() => _requireBox.values.toList(growable: false);

  Future<void> clear() => _requireBox.clear();
}
