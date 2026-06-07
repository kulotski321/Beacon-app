import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/tracking_repository.dart';
import '../data/sources/location_service.dart';
import '../data/sources/reading_store.dart';
import '../data/sources/target_api.dart';

/// Data-source + repository providers. The controller depends only on
/// [trackingRepositoryProvider]; tests override that single provider.
final targetApiProvider = Provider<TargetApi>((ref) {
  // Point at a different mock at launch with
  // `--dart-define=TARGET_ENDPOINT=<url>` (e.g. a local server); otherwise the
  // hosted mock JSON is used.
  const endpoint = String.fromEnvironment(
    'TARGET_ENDPOINT',
    defaultValue: defaultTargetEndpoint,
  );
  return TargetApi(endpoint: Uri.parse(endpoint));
});

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

/// The Hive-backed store. Its box is opened once at app start (`main` calls
/// `ReadingStore.init()` after `Hive.initFlutter()`), before the UI reads it.
final readingStoreProvider = Provider<ReadingStore>((ref) => ReadingStore());

final trackingRepositoryProvider = Provider<TrackingRepository>(
  (ref) => TrackingRepository(
    targetApi: ref.read(targetApiProvider),
    locationService: ref.read(locationServiceProvider),
    readingStore: ref.read(readingStoreProvider),
  ),
);
