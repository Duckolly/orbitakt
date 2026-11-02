import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/screens/water_screen.dart';
import 'package:dvizh/services/water_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var count = 0;
  var date = '2026-10-31';
  var fail = false;
  final days = <String, int>{};
  Map<String, dynamic> snapshot() => {
    'today': date,
    'glasses': count,
    'millilitres': count * 200,
    'history': days.entries
        .map((e) => {'day': e.key, 'glasses': e.value})
        .toList(),
  };
  setUp(() {
    count = 0;
    date = '2026-10-31';
    fail = false;
    days.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(WaterTracker.channel, (call) async {
          if (fail) throw PlatformException(code: 'storage');
          switch (call.method) {
            case 'change':
              count = (count + (call.arguments['delta'] as int)).clamp(0, 100);
              days[date] = count;
            case 'clear':
              count = 0;
              days.clear();
            case 'pinWidget':
              return false;
          }
          return snapshot();
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(WaterTracker.channel, null);
  });
  test('200ml glass, undo and native validation boundary', () async {
    expect((await WaterTracker.change(1)).millilitres, 200);
    expect((await WaterTracker.change(1)).glasses, 2);
    expect((await WaterTracker.change(-1)).millilitres, 200);
    expect(() => WaterTracker.change(3), throwsArgumentError);
  });
  testWidgets('add and remove update visible daily water totals', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WaterScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+1 стакан · 200 мл'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('waterVolume')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('waterVolume'))).data,
      '200 мл',
    );
    await tester.tap(find.text('Убрать стакан за сегодня'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('waterVolume'))).data,
      '0 мл',
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('rollover reads new day and preserves previous history', (
    tester,
  ) async {
    await WaterTracker.change(1);
    await tester.pumpWidget(const MaterialApp(home: WaterScreen()));
    await tester.pumpAndSettle();
    date = '2026-11-01';
    count = 0;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('2026-11-01'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('waterVolume'))).data,
      '0 мл',
    );
    expect(find.text('2026-10-31'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('write failure retains previous count and reports error', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WaterScreen()));
    await tester.pumpAndSettle();
    fail = true;
    await tester.tap(find.text('+1 стакан · 200 мл'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('waterVolume'))).data,
      '0 мл',
    );
    expect(find.textContaining('Не удалось прочитать'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('small screen and large text remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const WaterScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('clear confirmation can cancel and then removes water history', (
    tester,
  ) async {
    await WaterTracker.change(1);
    await tester.pumpWidget(const MaterialApp(home: WaterScreen()));
    await tester.pumpAndSettle();
    final clear = find.text('Удалить историю воды');
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect((await WaterTracker.status()).glasses, 1);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect((await WaterTracker.status()).glasses, 0);
    expect(find.text('Записей пока нет.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('unsupported launcher offers manual widget instructions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WaterScreen()));
    await tester.pumpAndSettle();
    final button = find.text('Виджет: шаги и вода');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('Зажмите свободное место'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
