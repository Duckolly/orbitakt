import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rank_level.dart';
import '../models/progress_report.dart';

/// Freeze each metric on the first visit in a calendar month.
class MonthlyAnimals {
  static Future<RankLevel?> get(
    String metric,
    RankLevel? candidate, {
    DateTime? now,
  }) async {
    final date = now ?? DateTime.now();
    final key = 'monthlyAnimalsV1.${date.year}-${date.month}.$metric';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data == null) return null;
        return ProgressRanks.appearance(
          metric,
          RankLevel(
            level: data['level'] as int,
            name: data['name'] as String,
            minInclusive: (data['min'] as num).toDouble(),
            maxExclusive: (data['max'] as num?)?.toDouble(),
            animal: data['animal'] as String?,
            icon: data['icon'] as String?,
          ),
        );
      } catch (_) {
        /* Repair only this new derived cache, never source history. */
      }
    }
    final saved = await prefs.setString(
      key,
      jsonEncode(
        candidate == null
            ? null
            : {
                'level': candidate.level,
                'name': candidate.name,
                'min': candidate.minInclusive,
                'max': candidate.maxExclusive,
                'animal': candidate.animal,
                'icon': candidate.icon,
              },
      ),
    );
    if (!saved) throw StateError('Не удалось сохранить зверинец');
    return candidate;
  }
}
