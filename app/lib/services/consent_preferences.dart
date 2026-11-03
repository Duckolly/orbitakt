import 'package:shared_preferences/shared_preferences.dart';

/// The legacy age flag covered 14+ and parental consent. It cannot confirm 16+.
class ConsentPreferences {
  static const minimumAge = 16;
  static const ageKey = 'age16Confirmed';

  static bool accepted(SharedPreferences prefs) =>
      (prefs.getBool('privacyAccepted') ?? false) &&
      (prefs.getBool(ageKey) ?? false) &&
      (prefs.getBool('offlineUnderstood') ?? false);

  static Future<bool> confirm(SharedPreferences prefs) async {
    // Write the new age acknowledgement last. Existing history is untouched.
    if (!await prefs.setBool('privacyAccepted', true)) return false;
    if (!await prefs.setBool('offlineUnderstood', true)) return false;
    return prefs.setBool(ageKey, true);
  }
}
