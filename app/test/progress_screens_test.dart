import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dvizh/services/storage_service.dart';
import 'package:dvizh/services/progress_reports.dart';
import 'package:dvizh/screens/toilet_screen.dart';
import 'package:dvizh/screens/reports_screen.dart';

Future<void> loadFrame(WidgetTester tester) async {
  // Let the SQLite FFI worker respond outside the fake test clock.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pumpAndSettle();
}

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 40 && !ready(); i++) {
    await loadFrame(tester);
  }
  expect(ready(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temporary = await Directory.systemTemp.createTemp('orbitakt-screen-tests-');
    await databaseFactory.setDatabasesPath(temporary.path);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.database;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          ProgressReports.channel,
          (call) async => {'steps': <Object>[], 'water': <Object>[]},
        );
  });
  tearDown(() async {
    await StorageService.deleteAllData();
  });
  tearDownAll(() async {
    await temporary.delete(recursive: true);
  });

  testWidgets(
    'toilet add is visible, persists, and mistaken entry can be deleted',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ToiletScreen()));
      await loadFrame(tester);
      expect(find.text('Сегодня: 0 · Всего: 0'), findsOneWidget);
      await waitFor(
        tester,
        () =>
            tester
                .widget<FilledButton>(
                  find.byWidgetPredicate((w) => w is FilledButton).first,
                )
                .onPressed !=
            null,
      );
      await tester.tap(find.text('Добавить посещение'));
      await loadFrame(tester);
      await waitFor(
        tester,
        () => find.text('Сегодня: 1 · Всего: 1').evaluate().isNotEmpty,
      );
      expect(find.text('Сегодня: 1 · Всего: 1'), findsOneWidget);
      final visits = await tester.runAsync(StorageService.getAllToiletVisits);
      expect(visits!.length, 1);
      final delete = find.byTooltip('Удалить ошибочную запись');
      await tester.ensureVisible(delete);
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
      await loadFrame(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      await waitFor(
        tester,
        () => find.text('Сегодня: 0 · Всего: 0').evaluate().isNotEmpty,
      );
      expect(find.text('Сегодня: 0 · Всего: 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reports only offer month/year and show empty statistics on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: const ReportsScreen(),
        ),
      );
      await loadFrame(tester);
      expect(find.text('Месяц'), findsOneWidget);
      expect(find.text('Год'), findsOneWidget);
      expect(find.text('0 стаканов'), findsOneWidget);
      await tester.tap(find.text('Год'));
      await tester.pumpAndSettle();
      expect(find.text('13 февраля'), findsOneWidget);
      expect(find.text('8 марта'), findsOneWidget);
      expect(find.text('1 января'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed report load offers retry without showing fake zero totals',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            ProgressReports.channel,
            (call) async => throw PlatformException(code: 'db_error'),
          );
      await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
      await loadFrame(tester);
      expect(find.text('Повторить загрузку'), findsOneWidget);
      expect(find.text('0 стаканов'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
