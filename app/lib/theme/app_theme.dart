import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData _make(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF69278A),
      brightness: brightness,
      primary: dark ? const Color(0xFFE1B4FF) : const Color(0xFF662583),
      surface: dark ? const Color(0xFF211C29) : const Color(0xFFFFFAF6),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF17131D)
          : const Color(0xFFFFFAF6),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: const NavigationBarThemeData(height: 76),
    );
  }

  static final ThemeData light = _make(Brightness.light);
  static final ThemeData dark = _make(Brightness.dark);
}

class OrbitColors {
  static Color peach(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFF3B2A31)
      : const Color(0xFFFFE7D6);
  static Color aqua(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFF19383F)
      : const Color(0xFFDDF4F4);
  static Color lavender(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFF342644)
      : const Color(0xFFEEE0F7);
}
