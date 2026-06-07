import 'package:flutter/material.dart';

import 'presentation/screens/home_screen.dart';

/// Beacon brand palette (see knowledge-base PRD §1).
const Color _navy = Color(0xFF0B1F3A);
const Color _amber = Color(0xFFFFB020);
const Color _surface = Color(0xFFF7F8FA);

class BeaconApp extends StatelessWidget {
  const BeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _navy,
      brightness: Brightness.light,
    ).copyWith(primary: _navy, secondary: _amber);

    return MaterialApp(
      title: 'Beacon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
