import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/sky/sky_compass_control.dart';
import 'package:dvizh/sky/sky_catalog.dart';
import 'package:dvizh/services/tool_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const status = MethodChannel('dvizh/sky'),
      events = MethodChannel('dvizh/sky/events');
  final calls = <MethodCall>[];
  final values = <SkyOrientation>[];
  var supported = true;
  final city = SkyCity(
    id: 0,
    name: 'Самара',
    country: 'RU',
    latitude: 53.2,
    longitude: 50.15,
  );
  setUp(() {
    calls.clear();
    values.clear();
    supported = true;
    messenger.setMockMethodCallHandler(
      status,
      (c) async => {'supported': supported},
    );
    messenger.setMockMethodCallHandler(events, (c) async {
      calls.add(c);
      return null;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(status, null);
    messenger.setMockMethodCallHandler(events, null);
  });
  Widget app({DateTime? date}) => MaterialApp(
    navigatorObservers: [toolRouteObserver],
    home: Scaffold(
      body: SingleChildScrollView(
        child: SkyCompassControl(
          city: city,
          utc: date ?? DateTime.utc(2026, 11, 2),
          onChanged: values.add,
        ),
      ),
    ),
  );
  Future<void> settle(WidgetTester t) async {
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await t.pumpAndSettle();
  }

  Future<void> send(WidgetTester t, Map<String, Object?> data) async {
    await messenger.handlePlatformMessage(
      'dvizh/sky/events',
      const StandardMethodCodec().encodeSuccessEnvelope(data),
      (_) {},
    );
    await t.pump();
    await t.pump();
  }

  testWidgets('manual mode and absent sensors never subscribe', (t) async {
    supported = false;
    await t.pumpWidget(app());
    await settle(t);
    expect(calls, isEmpty);
    expect(
      find.text('Магнитометр или акселерометр недоступен'),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
    await settle(t);
  });
  testWidgets(
    'opt-in passes selected coordinates; unreliable data never becomes north',
    (t) async {
      await t.pumpWidget(app());
      await settle(t);
      expect(calls, isEmpty);
      await t.tap(find.byType(SwitchListTile));
      await settle(t);
      expect(calls.last.method, 'listen');
      final arguments = calls.last.arguments as Map;
      expect(arguments['latitude'], 53.2);
      expect(arguments['longitude'], 50.15);
      expect(arguments['timeMillis'], isA<int>());
      await send(t, {'state': 'reading', 'heading': 42.0, 'accuracy': 3});
      expect(values.last.heading, 42);
      await send(t, {'state': 'calibration', 'heading': null, 'accuracy': 0});
      expect(values.last.heading, isNull);
      expect(find.textContaining('Нужна калибровка'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await settle(t);
      expect(calls.last.method, 'cancel');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'background and route cover stop polling; return waits for new heading',
    (t) async {
      await t.pumpWidget(app());
      await settle(t);
      await t.tap(find.byType(SwitchListTile));
      await settle(t);
      await send(t, {'state': 'reading', 'heading': 180.0, 'accuracy': 2});
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await settle(t);
      expect(calls.last.method, 'cancel');
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(t);
      expect(calls.last.method, 'listen');
      expect(values.last.heading, isNull);
      final nav = t.state<NavigatorState>(find.byType(Navigator));
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Overlay')),
        ),
      );
      await settle(t);
      expect(calls.last.method, 'cancel');
      nav.pop();
      await settle(t);
      expect(calls.last.method, 'listen');
      await t.pumpWidget(const SizedBox());
      await settle(t);
    },
  );
  testWidgets('invalid heading stops compass and returns manual control', (
    t,
  ) async {
    await t.pumpWidget(app());
    await settle(t);
    await t.tap(find.byType(SwitchListTile));
    await settle(t);
    await send(t, {'state': 'reading', 'heading': double.nan, 'accuracy': 3});
    await settle(t);
    expect(calls.last.method, 'cancel');
    expect(values.last.enabled, isFalse);
    expect(values.last.heading, isNull);
    await t.pumpWidget(const SizedBox());
    await settle(t);
  });
  testWidgets(
    'changing the system year stops an active compass outside model range',
    (t) async {
      await t.pumpWidget(app());
      await settle(t);
      await t.tap(find.byType(SwitchListTile));
      await settle(t);
      await send(t, {'state': 'reading', 'heading': 90.0, 'accuracy': 3});
      await t.pumpWidget(app(date: DateTime.utc(2050)));
      await settle(t);
      expect(calls.last.method, 'cancel');
      expect(values.last.enabled, isFalse);
      expect(values.last.heading, isNull);
      await t.pumpWidget(const SizedBox());
      await settle(t);
    },
  );
  testWidgets(
    'far future date leaves manual sky available without model extrapolation',
    (t) async {
      await t.pumpWidget(app(date: DateTime.utc(2050)));
      await settle(t);
      expect(calls, isEmpty);
      expect(
        find.text('Для этой даты используй ручной поворот'),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox());
      await settle(t);
    },
  );
}
