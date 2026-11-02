import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/models/relative_altitude.dart';
import 'package:dvizh/screens/altitude_screen.dart';
import 'package:dvizh/services/tool_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const status = MethodChannel('dvizh/pressure'),
      events = MethodChannel('dvizh/pressure/events');
  var supported = true;
  final calls = <String>[];
  setUp(() {
    supported = true;
    calls.clear();
    messenger.setMockMethodCallHandler(
      status,
      (c) async => {'supported': supported},
    );
    messenger.setMockMethodCallHandler(events, (c) async {
      calls.add(c.method);
      return null;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(status, null);
    messenger.setMockMethodCallHandler(events, null);
  });
  Future<void> settle(WidgetTester t) async {
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await t.pumpAndSettle();
  }

  Future<void> send(WidgetTester t, Object? pressure) async {
    await messenger.handlePlatformMessage(
      'dvizh/pressure/events',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'state': 'reading',
        'pressure': pressure,
      }),
      (_) {},
    );
    await t.pump();
  }

  Widget app() => MaterialApp(
    navigatorObservers: [toolRouteObserver],
    home: const AltitudeScreen(),
  );
  test('relative altitude: zero, ascent, descent and new baseline', () {
    final m = RelativeAltitude();
    expect(m.add(double.nan), isFalse);
    expect(m.add(-1), isFalse);
    for (var i = 0; i < 10; i++) {
      m.add(1000);
    }
    expect(m.meters, closeTo(0, .001));
    for (var i = 0; i < 5; i++) {
      m.add(999);
    }
    expect(m.meters, closeTo(8.44, .05));
    for (var i = 0; i < 5; i++) {
      m.add(1001);
    }
    expect(m.meters, lessThan(0));
    m.reset();
    expect(m.meters, isNull);
    expect(m.samples, 0);
  });
  testWidgets('missing barometer never listens', (t) async {
    supported = false;
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('Барометр недоступен на этом телефоне.'), findsOneWidget);
    expect(calls, isEmpty);
    await t.pumpWidget(const SizedBox());
    await settle(t);
  });
  testWidgets('explicit start, baseline, re-zero and background stop', (
    t,
  ) async {
    await t.pumpWidget(app());
    await settle(t);
    expect(calls, isEmpty);
    await t.tap(find.text('Начать измерение'));
    await settle(t);
    expect(calls, ['listen']);
    for (var i = 0; i < 10; i++) {
      await send(t, 1000.0);
    }
    expect(find.text('0 м'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await send(t, 999.0);
    }
    expect(find.text('+8 м'), findsOneWidget);
    await t.tap(find.text('Новая точка «ноль»'));
    await t.pump();
    expect(find.text('+8 м'), findsNothing);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await settle(t);
    expect(calls.last, 'cancel');
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(t);
    expect(calls.last, 'cancel');
    await t.pumpWidget(const SizedBox());
    await settle(t);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'invalid pressure stops measurement rather than inventing height',
    (t) async {
      await t.pumpWidget(app());
      await settle(t);
      await t.tap(find.text('Начать измерение'));
      await settle(t);
      await send(t, 0.0);
      await settle(t);
      expect(calls.last, 'cancel');
      expect(find.textContaining('Нет доступных показаний'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await settle(t);
    },
  );
}
