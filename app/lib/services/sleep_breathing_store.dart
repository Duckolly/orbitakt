import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_breathing.dart';

class SleepBreathingStore {
  static const key = 'sleepBreathingV1';
  Future<SleepBreathing> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.get(key);
    if (raw is! String) return const SleepBreathing();
    try {
      final value = jsonDecode(raw);
      if (value is Map<String, dynamic>) return SleepBreathing.fromJson(value);
    } on FormatException {
      /* Recover the new profile without touching history. */
    }
    return const SleepBreathing();
  }

  Future<void> save(SleepBreathing value) async {
    final preferences = await SharedPreferences.getInstance();
    try {
      if (!await preferences.setString(key, jsonEncode(value.toJson()))) {
        throw StateError('Cannot save breathing profile');
      }
    } catch (_) {
      // The legacy plugin updates its cache before the platform acknowledges a
      // write. Reload after failure so a fresh screen does not see a phantom save.
      try {
        await preferences.reload();
      } catch (_) {
        /* Leave retry to the caller. */
      }
      rethrow;
    }
  }
}
