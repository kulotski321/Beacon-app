import 'package:beacon_app/app.dart';
import 'package:beacon_app/application/providers.dart';
import 'package:beacon_app/data/models/location_reading.dart';
import 'package:beacon_app/data/repositories/tracking_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  testWidgets('renders the empty state and a start control on launch',
      (tester) async {
    final repo = MockTrackingRepository();
    when(() => repo.readings()).thenReturn(<LocationReading>[]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [trackingRepositoryProvider.overrideWithValue(repo)],
        child: const BeaconApp(),
      ),
    );

    expect(find.text('Beacon'), findsOneWidget);
    expect(find.text('Start tracking'), findsOneWidget);
    expect(find.textContaining('No readings'), findsOneWidget);
  });
}
