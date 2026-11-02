import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A3BFF),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A3BFF),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}
