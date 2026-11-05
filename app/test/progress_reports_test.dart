import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/models/progress_report.dart';
import 'package:dvizh/models/toilet_visit.dart';
import 'package:dvizh/services/activity_preferences.dart';
import 'package:dvizh/services/daily_tracker.dart';
import 'package:dvizh/services/water_tracker.dart';
import 'package:dvizh/services/progress_reports.dart';
import 'package:dvizh/services/monthly_animals.dart';

void main() {
  test('all step thresholds are inclusive and below minimum has no level', () {
    final boundaries = [6000.0, 10000.0, 12000.0, 15000.0, 25000.0];
    for (var i = 0; i < boundaries.length; i++) {
      expect(ProgressRanks.steps(boundaries[i])?.level, i + 1);
      expect(ProgressRanks.steps(boundaries[i] - .1)?.level, i == 0 ? null : i);
    }
    expect(ProgressRanks.steps(double.nan), isNull);
  });
  test('water thresholds use daily average', () {
    for (var i = 0; i < 5; i++) {
      expect(ProgressRanks.water(4.0 + i * 2)?.level, i + 1);
    }
    expect(ProgressRanks.water(3.99), isNull);
    expect(ProgressRanks.water(100)?.level, 5);
  });
  test('toilet monthly thresholds and animals match specification', () {
    expect(ProgressRanks.toilet(0).animal, isNull);
    final values = [14, 15, 19, 20, 24, 25, 34, 35];
    final levels = [1, 2, 2, 3, 3, 4, 4, 5];
    for (var i = 0; i < values.length; i++) {
      expect(ProgressRanks.toilet(values[i]).level, levels[i]);
    }
    expect(ProgressRanks.toilet(15).animal, 'Заяц');
    expect(ProgressRanks.toilet(20).animal, 'Обезьяна');
    expect(ProgressRanks.toilet(25).animal, 'Эму');
    expect(ProgressRanks.toilet(35).animal, 'Динозавр');
  });
  test(
    'aggregation includes leap day, zeros, boundaries, saved calendar dates',
    () {
      final data = ProgressData(
        steps: [
          DailyDay({'day': '2024-02-01', 'steps': 10000, 'estimated': false}),
          DailyDay({'day': '2024-02-29', 'steps': 19000, 'estimated': true}),
          DailyDay({'day': '2024-03-01', 'steps': 99999, 'estimated': false}),
        ],
        water: [
          WaterDay({'day': '2024-02-29', 'glasses': 29}),
        ],
        visits: [
          ToiletVisit(timestamp: DateTime.utc(2024, 3, 1), date: '2024-02-29'),
        ],
        preferences: const ActivityPreferences(stepLengthCm: 80),
      );
      final report = data.aggregate(DateTime(2024, 2), DateTime(2024, 2, 29));
      expect(report.days, 29);
      expect(report.steps, 29000);
      expect(report.averageSteps, 1000);
      expect(report.averageGlasses, 1);
      expect(report.kilometres, 23.2);
      expect(report.visits, 1);
      expect(report.estimated, true);
      expect(report.stepDays, 2);
      expect(data.aggregate(DateTime(2024), DateTime(2024, 12, 31)).days, 366);
      expect(
        () => data.aggregate(DateTime(2025), DateTime(2024)),
        throwsArgumentError,
      );
    },
  );
  test(
    'animal stays fixed in a month and is recalculated next month',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = await MonthlyAnimals.get(
        'toilet',
        ProgressRanks.toilet(15),
        now: DateTime(2026, 11, 1),
      );
      final frozen = await MonthlyAnimals.get(
        'toilet',
        ProgressRanks.toilet(35),
        now: DateTime(2026, 11, 20),
      );
      final next = await MonthlyAnimals.get(
        'toilet',
        ProgressRanks.toilet(35),
        now: DateTime(2026, 12, 1),
      );
      expect(first?.level, 2);
      expect(frozen?.level, 2);
      expect(next?.level, 5);
      expect(
        await MonthlyAnimals.get('steps', null, now: DateTime(2026, 11)),
        isNull,
      );
      expect(
        await MonthlyAnimals.get(
          'steps',
          ProgressRanks.steps(25000),
          now: DateTime(2026, 11, 2),
        ),
        isNull,
      );
    },
  );
}
