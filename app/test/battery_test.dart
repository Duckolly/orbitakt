import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/models/battery_session.dart';
import 'package:dvizh/screens/battery_screen.dart';

Map<String, dynamic> data({
  String token = 'one',
  int wall = 100000,
  int elapsed = 10000,
  int cpu = 20,
  double? percent = 80,
  int boot = 2,
  int step = 500,
}) => {
  'wallMs': wall,
  'elapsedMs': elapsed,
  'cpuMs': cpu,
  'processToken': token,
  'bootCount': boot,
  'percent': percent,
  'temperature': null,
  'plugged': false,
  'powerSave': false,
  'thermal': null,
  'usage': {'step': step},
  'active': ['foreground'],
  'model': 'Phone',
  'android': '16',
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'snapshot rejects bad clocks, filters unknown and unavailable values',
    () {
      expect(() => BatterySnapshot({'wallMs': -1}), throwsFormatException);
      final s = BatterySnapshot({
        ...data(),
        'percent': 101,
        'temperature': double.nan,
        'usage': {'step': -1, 'unknown': 50},
      });
      expect(s.percent, isNull);
      expect(s.temperature, isNull);
      expect(s.usage, isEmpty);
    },
  );
  test('same boot uses monotonic time despite clock changes', () {
    final s = BatterySession(
      BatterySnapshot(data()),
      BatterySnapshot(
        data(wall: 1, elapsed: 70000, cpu: 300, percent: 77, step: 60500),
      ),
    );
    expect(s.duration, 60000);
    expect(s.cpu, 280);
    expect(s.chargeDelta, -3);
    expect(s.usage['step'], 60000);
    expect(BatterySession.decode(s.encode()).duration, 60000);
  });
  test('process restart retains device delta but invalidates own counters', () {
    final s = BatterySession(
      BatterySnapshot(data()),
      BatterySnapshot(data(token: 'two', elapsed: 11000, cpu: 1, percent: 90)),
    );
    expect(s.cpu, isNull);
    expect(s.usage, isEmpty);
    expect(s.duration, 1000);
    expect(s.chargeDelta, 10);
  });
  test('reboot uses system time and backward wall is unavailable', () {
    final s = BatterySession(
      BatterySnapshot(data()),
      BatterySnapshot(
        data(token: 'two', boot: 3, elapsed: 1, wall: 101000, percent: null),
      ),
    );
    expect(s.monotonic, isFalse);
    expect(s.duration, 1000);
    expect(s.chargeDelta, isNull);
    final backwards = BatterySession(
      s.start,
      BatterySnapshot(data(token: 'two', boot: 3, wall: 0)),
    );
    expect(backwards.duration, isNull);
    expect(
      () => BatterySession.decode(jsonEncode({'version': 99})),
      throwsFormatException,
    );
  });
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const battery = MethodChannel('dvizh/battery'),
      daily = MethodChannel('dvizh/daily');
  var next = data();
  final calls = <String>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    next = data();
    messenger.setMockMethodCallHandler(battery, (call) async {
      calls.add(call.method);
      return call.method == 'snapshot' ? next : false;
    });
    messenger.setMockMethodCallHandler(daily, (call) async {
      calls.add(call.method);
      return {'enabled': call.method != 'disable', 'running': true};
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(battery, null);
    messenger.setMockMethodCallHandler(daily, null);
  });
  Future<void> settle(WidgetTester t) async {
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await t.pumpAndSettle();
  }

  Future<void> open(WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(home: BatteryScreen()));
    await settle(t);
  }

  testWidgets(
    'manual start finish restore and reset, no automatic tracking changes',
    (t) async {
      await open(t);
      expect(calls, ['snapshot', 'status']);
      await t.ensureVisible(find.text('Начать замер'));
      await settle(t);
      await t.tap(find.text('Начать замер'));
      await settle(t);
      expect(
        (await SharedPreferences.getInstance()).getString('batterySession'),
        isNotNull,
      );
      next = data(elapsed: 70000, cpu: 300, percent: 77);
      await t.ensureVisible(find.text('Завершить замер'));
      await settle(t);
      await t.tap(find.text('Завершить замер'));
      await settle(t);
      expect(find.textContaining('−3'), findsNothing);
      expect(find.textContaining('-3.0 п.п.'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump();
      await open(t);
      expect(find.textContaining('-3.0 п.п.'), findsOneWidget);
      await t.ensureVisible(find.text('Удалить замер'));
      await settle(t);
      await t.tap(find.text('Удалить замер'));
      await settle(t);
      expect(
        (await SharedPreferences.getInstance()).getString('batterySession'),
        isNull,
      );
      expect(calls.contains('enable'), isFalse);
      expect(calls.contains('disable'), isFalse);
    },
  );
  testWidgets(
    'unsupported battery and settings are honest, explicit step disable',
    (t) async {
      next = {...data(percent: null), 'temperature': null};
      await open(t);
      expect(find.text('Заряд телефона: Недоступно'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Отключить фоновый шагомер'), 250);
      await settle(t);
      await t.tap(find.text('Отключить фоновый шагомер'));
      await settle(t);
      expect(calls.where((c) => c == 'disable').length, 1);
      await t.scrollUntilVisible(find.text('Сведения о приложении'), 200);
      await settle(t);
      await t.tap(find.text('Сведения о приложении'));
      await settle(t);
      expect(
        find.text('Этот раздел настроек недоступен на телефоне.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'corrupt persisted data recoverable and compact large-text layout',
    (t) async {
      SharedPreferences.setMockInitialValues({'batterySession': 'bad'});
      t.view.physicalSize = const Size(320, 480);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(
              c,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: const BatteryScreen(),
        ),
      );
      await settle(t);
      await t.scrollUntilVisible(find.textContaining('повреждён'), 100);
      await settle(t);
      expect(find.textContaining('повреждён'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await settle(t);
    },
  );
}