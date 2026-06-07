import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'application/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Open the Hive box before the UI reads it, sharing one container so the
  // initialised store is the same instance the providers expose.
  final container = ProviderContainer();
  await container.read(readingStoreProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BeaconApp(),
    ),
  );
}
