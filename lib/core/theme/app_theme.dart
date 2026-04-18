import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, sepia }

class AppTheme {
  const AppTheme._();

  static ThemeData themeFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light;
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.sepia:
        return sepia;
    }
  }

  static final ThemeData light = _build(
    brightness: Brightness.light,
    background: const Color(0xFFFAFAFA),
    surface: Colors.white,
    onSurface: const Color(0xFF1A1A1A),
    accent: const Color(0xFF2C2C2C),
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    background: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E),
    onSurface: const Color(0xFFE6E6E6),
    accent: const Color(0xFFCFCFCF),
  );

  static final ThemeData sepia = _build(
    brightness: Brightness.light,
    background: const Color(0xFFF4ECD8),
    surface: const Color(0xFFEFE6CF),
    onSurface: const Color(0xFF3B2F2F),
    accent: const Color(0xFF5A463A),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color accent,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      surface: surface,
      onSurface: onSurface,
    );

    const headingFamily = 'Georgia';

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: headingFamily,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
          color: onSurface,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: headingFamily, color: onSurface),
        displayMedium: TextStyle(fontFamily: headingFamily, color: onSurface),
        headlineLarge: TextStyle(fontFamily: headingFamily, color: onSurface),
        headlineMedium: TextStyle(fontFamily: headingFamily, color: onSurface),
        titleLarge: TextStyle(fontFamily: headingFamily, color: onSurface),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: onSurface),
        bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: onSurface),
      ),
    );
  }
}
