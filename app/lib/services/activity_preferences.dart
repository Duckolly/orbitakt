import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local display preferences. Never alters recorded sensor steps.
class ActivityPreferences {
  const ActivityPreferences({
    this.stepLengthCm = 70,
    this.stepGoal = 8000,
    this.waterGoalMl = 2000,
  });
  final double stepLengthCm;
  final int stepGoal;
  final int waterGoalMl;
  static const storageKey = 'activityPreferencesV1';

  double kilometres(int steps) =>
      (steps < 0 ? 0 : steps) * stepLengthCm / 100000;
  String distanceLabel(int steps) =>
      '≈ ${kilometres(steps).toStringAsFixed(2).replaceAll('.', ',')} км';

  static Future<ActivityPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(storageKey);
      if (raw == null) return const ActivityPreferences();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final value = ActivityPreferences(
        stepLengthCm: (data['stepLengthCm'] as num).toDouble(),
        stepGoal: (data['stepGoal'] as num).toInt(),
        waterGoalMl: (data['waterGoalMl'] as num).toInt(),
      );
      return value.valid ? value : const ActivityPreferences();
    } catch (_) {
      return const ActivityPreferences();
    }
  }

  bool get valid =>
      stepLengthCm.isFinite &&
      stepLengthCm >= 20 &&
      stepLengthCm <= 150 &&
      stepGoal >= 500 &&
      stepGoal <= 50000 &&
      waterGoalMl >= 200 &&
      waterGoalMl <= 6000 &&
      waterGoalMl % 200 == 0;

  Future<void> save() async {
    if (!valid) throw ArgumentError('Недопустимые параметры активности');
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKey,
      jsonEncode({
        'stepLengthCm': stepLengthCm,
        'stepGoal': stepGoal,
        'waterGoalMl': waterGoalMl,
      }),
    );
    if (!saved) throw StateError('Не удалось сохранить настройки');
  }
}
