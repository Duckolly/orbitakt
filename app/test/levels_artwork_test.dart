import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/models/progress_report.dart';
import 'package:dvizh/services/monthly_animals.dart';
import 'package:dvizh/widgets/rank_animal.dart';
import 'package:dvizh/widgets/metric_levels_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'every exact boundary has the requested animal and a bundled asset',
    () async {
      final steps = ['Лиса', 'Волк', 'Лев', 'Пантера', 'Дракон'];
      final water = ['Выдра', 'Дельфин', 'Акула', 'Косатка', 'Синий кит'];
      for (final metric in ['steps', 'water', 'toilet']) {
        final levels = RankProgressCard.levels(metric);
        for (var i = 0; i < levels.length; i++) {
          final item = levels[i];
          if (metric == 'steps') expect(item.animal, steps[i]);
          if (metric == 'water') expect(item.animal, water[i]);
          if (item.animal == null) continue;
          final bytes = await rootBundle.load(
            'assets/ranks/${RankAnimal.assets[item.animal]}.webp',
          );
          expect(bytes.lengthInBytes, greaterThan(1000));
        }
      }
      expect(RankAnimal.assets.length, 14);
    },
  );
  test(
    'old cached art is normalized without changing earned level or cache bytes',
    () async {
      final old = jsonEncode({
        'level': 2,
        'name': 'Гладиатор',
        'min': 10000,
        'max': 12000,
        'animal': 'Заяц',
        'icon': '🐇',
      });
      const key = 'monthlyAnimalsV1.2026-11.steps';
      SharedPreferences.setMockInitialValues({key: old});
      final rank = await MonthlyAnimals.get(
        'steps',
        ProgressRanks.steps(25000),
        now: DateTime(2026, 11),
      );
      expect(rank?.level, 2);
      expect(rank?.animal, 'Волк');
      expect((await SharedPreferences.getInstance()).getString(key), old);
    },
  );
  testWidgets(
    'long ranks wrap on narrow screens with enlarged type in both themes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final brightness in Brightness.values) {
        for (final metric in ['steps', 'water', 'toilet']) {
          final rank = RankProgressCard.levels(metric)[3];
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
                child: Scaffold(
                  body: ListView(
                    children: [
                      RankProgressCard(
                        metric: metric,
                        rank: rank,
                        monthly: rank,
                        date: DateTime(2026, 11),
                        valueLabel: '15000 шагов/день',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Все уровни'));
        await tester.tap(find.text('Все уровни'));
        expect(tester.widget<ExpansionTile>(find.byType(ExpansionTile)).title, isA<Text>());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
