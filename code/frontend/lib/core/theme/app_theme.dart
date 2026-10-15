import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF7E1D2E);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFEFE5E2),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFDFC),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _inputs(const Color(0xFFFFFFFF)),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFFF6C85F),
            brightness: Brightness.dark,
          ).copyWith(
            primary: const Color(0xFFF6C85F),
            surface: const Color(0xFF073525),
            onSurface: const Color(0xFFEDF7F0),
          ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF03291C),
      cardTheme: const CardThemeData(
        color: Color(0xFF073525),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _inputs(const Color(0xFF042B1D)),
    );
  }

  static InputDecorationTheme _inputs(Color fill) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorMaxLines: 3,
    );
  }
}
