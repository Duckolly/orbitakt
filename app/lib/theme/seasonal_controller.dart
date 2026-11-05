import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class SeasonalAppearance {
  const SeasonalAppearance({this.newYear = false, this.animate = true});
  final bool newYear;
  final bool animate;
}

class SeasonalController {
  static const storageKey = 'seasonalAppearanceV1';
  static final appearance = ValueNotifier<SeasonalAppearance>(
    const SeasonalAppearance(),
  );

  static Future<void> load() async {
    var value = const SeasonalAppearance();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        value = SeasonalAppearance(
          newYear: data['newYear'] == true,
          animate: data['animate'] != false,
        );
      }
    } catch (_) {
      /* A decorative preference must never block the app. */
    }
    appearance.value = value;
  }

  static Future<void> set(SeasonalAppearance value) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKey,
      jsonEncode({'newYear': value.newYear, 'animate': value.animate}),
    );
    if (!saved) throw StateError('Не удалось сохранить оформление');
    appearance.value = value;
  }
}
