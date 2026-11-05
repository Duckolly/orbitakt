import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dvizh/screens/reports_screen.dart';
import 'package:dvizh/screens/toilet_screen.dart';
import 'package:dvizh/widgets/toilet_summary.dart';
import 'package:dvizh/services/progress_reports.dart';
import 'package:dvizh/services/storage_service.dart';

Future<void> advance(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pumpAndSettle();
}

Future<void> until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 30 && !ready(); i++) {
    await advance(tester);
  }
  expect(ready(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dir = await Directory.systemTemp.createTemp('orbitakt-audit-fixes-');
    await databaseFactory.setDatabasesPath(dir.path);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.database;
  });
  tearDown(() async {
    await StorageService.deleteAllData();
  });
  tearDownAll(() async {
    await dir.delete(recursive: true);
  });

  testWidgets(
    'selected year survives deletion of its final records and report reload',
    (tester) async {
      final old = DateTime.now().year - 1;
      var rows = <Object>[
        {'day': '$old-12-31', 'steps': 10000, 'estimated': false},
      ];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            ProgressReports.channel,
            (call) async => {'steps': rows, 'water': <Object>[]},
          );
      await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
      await until(tester, () => find.text('0 стаканов').evaluate().isNotEmpty);
      await tester.tap(find.text('${DateTime.now().year} год'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('$old год').last);
      await tester.pumpAndSettle();
      rows = <Object>[];
      await tester.tap(find.byTooltip('Обновить отчёт'));
      await advance(tester);
      await until(tester, () => find.text('0 стаканов').evaluate().isNotEmpty);
      expect(find.text('$old год'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'journal loading and read failure show no fabricated zero or null; retry recovers',
    (tester) async {
      await tester.runAsync(() async {
        final db = await StorageService.database;
        await db.execute(
          'ALTER TABLE toilet_visits RENAME TO visits_unavailable',
        );
      });
      await tester.pumpWidget(const MaterialApp(home: ToiletScreen()));
      expect(find.text('Загрузка журнала…'), findsOneWidget);
      expect(find.text('Сегодня: 0 · Всего: 0'), findsNothing);
      await until(
        tester,
        () => find.text('Не удалось прочитать журнал').evaluate().isNotEmpty,
      );
      expect(find.text('Сегодня: 0 · Всего: 0'), findsNothing);
      expect(
        find.text('Пока нет записей. Нажми «Добавить посещение».'),
        findsNothing,
      );
      expect(find.textContaining('null'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byWidgetPredicate((w) => w is FilledButton).first,
            )
            .onPressed,
        isNull,
      );
      await tester.runAsync(() async {
        final db = await StorageService.database;
        await db.execute(
          'ALTER TABLE visits_unavailable RENAME TO toilet_visits',
        );
      });
      await tester.tap(find.text('Повторить'));
      await advance(tester);
      await until(
        tester,
        () => find.text('Сегодня: 0 · Всего: 0').evaluate().isNotEmpty,
      );
      expect(find.textContaining('null'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'home toilet card reports loading and read error without zero totals',
    (tester) async {
      await tester.runAsync(() async {
        final db = await StorageService.database;
        await db.execute(
          'ALTER TABLE toilet_visits RENAME TO visits_unavailable',
        );
      });
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ToiletSummary())),
      );
      expect(find.textContaining('Сегодня:'), findsNothing);
      await until(
        tester,
        () => find.text('Не удалось прочитать посещения').evaluate().isNotEmpty,
      );
      expect(find.textContaining('За месяц: 0'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byWidgetPredicate((w) => w is FilledButton).first,
            )
            .onPressed,
        isNull,
      );
      await tester.runAsync(() async {
        final db = await StorageService.database;
        await db.execute(
          'ALTER TABLE visits_unavailable RENAME TO toilet_visits',
        );
      });
      await tester.tap(find.text('Повторить загрузку'));
      await advance(tester);
      await until(
        tester,
        () => find.textContaining('За месяц: 0').evaluate().isNotEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
