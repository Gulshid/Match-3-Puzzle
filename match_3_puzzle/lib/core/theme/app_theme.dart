import 'package:flutter/material.dart';

/// App-wide theming. Kept intentionally minimal in Phase 1 — visual
/// polish for the board itself comes in Phase 6.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF3B2F63);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F1FA),
        fontFamily: 'Roboto',
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1B1730),
        fontFamily: 'Roboto',
      );
}
