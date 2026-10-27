import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Bundled locally so web and Android do not depend on platform font defaults.
  static const fontFamily = 'UniConnectSans';
  static const _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );

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
  static const Color engineeringBackground = Color(0xFF12070E);
  static const Color engineeringCanvas = Color(0xFF230812);
  static const Color engineeringSurface = Color(0xFF2A0918);
  static const Color engineeringRaised = Color(0xFF370D21);
  static const Color engineeringAccent = Color(0xFFEF326E);
  static const Color engineeringSoftPink = Color(0xFFFF6B9D);
  static const Color engineeringText = Color(0xFFFFF1F7);

  static ThemeData light() {
    return ThemeData(
      colorScheme:
          ColorScheme.fromSeed(
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
      fontFamily: fontFamily,
      textTheme: _typography(Brightness.light),
      scaffoldBackgroundColor: _lightStage,
      cardTheme: const CardThemeData(
        shape: _cardShape,
        color: Color(0xFFFFFDFC),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _inputs(Colors.white, _lightSeed),
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
      colorScheme:
          ColorScheme.fromSeed(
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
      fontFamily: fontFamily,
      textTheme: _typography(Brightness.dark),
      scaffoldBackgroundColor: _darkStage,
      cardTheme: const CardThemeData(
        shape: _cardShape,
        color: _darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _inputs(_darkInput, _gold),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: _darkCanvas,
        foregroundColor: _darkText,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData engineering() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: engineeringAccent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: engineeringAccent,
          onPrimary: Colors.white,
          secondary: engineeringSoftPink,
          onSecondary: const Color(0xFF260710),
          surface: engineeringSurface,
          onSurface: engineeringText,
          surfaceContainerHighest: engineeringRaised,
          onSurfaceVariant: const Color(0xFFD9A9BF),
          outline: const Color(0xFF8E2449),
          outlineVariant: const Color(0xFF572233),
          error: const Color(0xFFFF8A9E),
        );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: _typography(Brightness.dark),
      scaffoldBackgroundColor: engineeringBackground,
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: engineeringAccent, width: .8),
        ),
        color: engineeringSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: _engineeringInputs(),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: engineeringCanvas,
        foregroundColor: engineeringText,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFF713047),
      listTileTheme: const ListTileThemeData(
        iconColor: engineeringText,
        textColor: engineeringText,
        selectedColor: Colors.white,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: engineeringText,
          side: const BorderSide(color: engineeringAccent),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      extensions: const [EngineeringTheme()],
    );
  }

  static TextTheme _typography(Brightness brightness) {
    final base =
        (brightness == Brightness.dark
                ? Typography.material2021().white
                : Typography.material2021().black)
            .apply(fontFamily: fontFamily);
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  static InputDecorationTheme _inputs(Color fill, Color primary) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorMaxLines: 3,
    );
  }

  static InputDecorationTheme _engineeringInputs() {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFFB84C70)),
    );
    return const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF290B1B),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: engineeringSoftPink, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      errorMaxLines: 3,
    );
  }
}

@immutable
class EngineeringTheme extends ThemeExtension<EngineeringTheme> {
  const EngineeringTheme();

  static bool active(BuildContext context) =>
      Theme.of(context).extension<EngineeringTheme>() != null;

  @override
  EngineeringTheme copyWith() => const EngineeringTheme();

  @override
  EngineeringTheme lerp(covariant EngineeringTheme? other, double t) =>
      const EngineeringTheme();
}
