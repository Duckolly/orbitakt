import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  static const String _key = 'theme_mode_index';

  static Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int index = prefs.getInt(_key) ?? 0;

    final int safeIndex = index < 0
        ? 0
        : (index >= ThemeMode.values.length
              ? ThemeMode.values.length - 1
              : index);

    themeMode.value = ThemeMode.values[safeIndex];
  }

  static Future<void> set(ThemeMode mode) async {
    themeMode.value = mode;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }
}
