import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _lightSeed = Color(0xFF7E1D2E);
  static const Color _lightStage = Color(0xFFE4D6D4);
  static const Color _lightCanvas = Color(0xFFF8F3F2);
  static const Color _lightPanel = Color(0xFFEFE5E2);
  static const Color _lightText = Color(0xFF2B1317);
  static const Color _lightMuted = Color(0xFF7A6065);
  static const Color _darkStage = Color(0xFF00180F);
  static const Color _darkCanvas = Color(0xFF022318);
  static const Color _darkSurface = Color(0xFF073525);
  static const Color _darkRaised = Color(0xFF0B4230);
  static const Color _darkInput = Color(0xFF042B1D);
  static const Color _darkText = Color(0xFFEDF7F0);
  static const Color _darkMuted = Color(0xFFA4C0AF);
  static const Color _gold = Color(0xFFF6C85F);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightSeed,
        brightness: Brightness.light,
      ).copyWith(
        primary: _lightSeed,
        onPrimary: Colors.white,
        secondary: const Color(0xFFB8862F),
        surface: Colors.white,
        onSurface: _lightText,
        surfaceContainerHighest: _lightPanel,
        onSurfaceVariant: _lightMuted,
        outline: const Color(0xFFB99FA3),
        error: const Color(0xFFB3261E),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: _lightStage,
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFDFC),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _inputs(Colors.white),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: _lightCanvas,
        foregroundColor: _lightText,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _gold,
        brightness: Brightness.dark,
      ).copyWith(
        primary: _gold,
        onPrimary: const Color(0xFF013220),
        secondary: const Color(0xFF6FD8A8),
        onSecondary: const Color(0xFF013220),
        surface: _darkSurface,
        onSurface: _darkText,
        surfaceContainerHighest: _darkRaised,
        onSurfaceVariant: _darkMuted,
        outline: const Color(0xFF456958),
        error: const Color(0xFFFF8F84),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: _darkStage,
      cardTheme: const CardThemeData(
        color: _darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _inputs(_darkInput),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: _darkCanvas,
        foregroundColor: _darkText,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static InputDecorationTheme _inputs(Color fill) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorMaxLines: 3,
    );
  }
}
