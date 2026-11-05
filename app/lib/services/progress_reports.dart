import 'package:flutter/services.dart';
import '../models/progress_report.dart';
import '../models/toilet_visit.dart';
import 'activity_preferences.dart';
import 'daily_tracker.dart';
import 'water_tracker.dart';
import 'storage_service.dart';

/// New read-only bridge: full retained history, independent of the old 90-day UI.
class ProgressReports {
  static const channel = MethodChannel('dvizh/reports');
  static Future<ProgressData> load() async {
    final native = await channel.invokeMapMethod<String, dynamic>('load');
    if (native == null) throw StateError('Нет данных отчёта');
    return ProgressData(
      steps: (native['steps'] as List).map((r) => DailyDay(r as Map)).toList(),
      water: (native['water'] as List).map((r) => WaterDay(r as Map)).toList(),
      visits: await StorageService.getAllToiletVisits(),
      preferences: await ActivityPreferences.load(),
    );
  }
}

class ProgressData {
  const ProgressData({
    required this.steps,
    required this.water,
    required this.visits,
    required this.preferences,
  });
  final List<DailyDay> steps;
  final List<WaterDay> water;
  final List<ToiletVisit> visits;
  final ActivityPreferences preferences;

  ProgressReport aggregate(DateTime start, DateTime end) {
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    if (last.isBefore(first)) {
      throw ArgumentError('Конец периода раньше начала');
    }
    bool includes(String day) {
      final d = DateTime.tryParse(day);
      return d != null && !d.isBefore(first) && !d.isAfter(last);
    }

    final s = steps.where((d) => includes(d.day)).toList();
    final w = water.where((d) => includes(d.day)).toList();
    // UTC calendar difference avoids DST introducing 23/25-hour days.
    final days =
        DateTime.utc(
          last.year,
          last.month,
          last.day,
        ).difference(DateTime.utc(first.year, first.month, first.day)).inDays +
        1;
    return ProgressReport(
      start: first,
      end: last,
      days: days,
      steps: s.fold(0, (sum, d) => sum + d.steps),
      glasses: w.fold(0, (sum, d) => sum + d.glasses),
      visits: visits.where((v) => includes(v.date)).length,
      stepDays: s.length,
      waterDays: w.length,
      estimated: s.any((d) => d.estimated),
      stepLengthCm: preferences.stepLengthCm,
    );
  }
}
