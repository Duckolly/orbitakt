import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/screens/snake_screen.dart';
import 'package:dvizh/screens/sensors_screen.dart';
import 'package:dvizh/services/device_sensors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'begalkaBest': 7});
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceSensors.channel, null);
  });
  testWidgets(
    'game pauses on leaving foreground and requires explicit resume',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SnakeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Рекорд: 7'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Начать'), 160);
      await tester.tap(find.text('Начать'));
      await tester.pump();
      expect(find.text('Пауза'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Продолжить'), findsOneWidget);
      expect(find.text('Игра окончена'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Продолжить'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('game remains usable with large text on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(
            c,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const SnakeScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Начать'), 120);
    expect(find.text('Начать'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('inventory reflects native sensors and does not start a stream', (
    tester,
  ) async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceSensors.channel, (call) async {
          calls.add(call.method);
          return {
            'manufacturer': 'Test',
            'model': 'Device',
            'release': '16',
            'sdk': 36,
            'sensors': [
              {
                'type': 6,
                'name': 'Test pressure',
                'vendor': 'Test',
                'label': 'Атмосферное давление',
                'power': 0.1,
                'resolution': 0.01,
                'maxRange': 1100.0,
                'minDelay': 10000,
                'wakeUp': false,
              },
            ],
          };
        });
    await tester.pumpWidget(const MaterialApp(home: SensorsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Test Device · Android 16 (API 36)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Барометр'), 160);
    expect(find.text('Доступен'), findsOneWidget);
    expect(find.text('Не предоставлен Android'), findsWidgets);
    expect(calls, ['listSensors']);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('sensor failure offers retry without inventing capabilities', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          DeviceSensors.channel,
          (_) async => throw PlatformException(code: 'failed'),
        );
    await tester.pumpWidget(const MaterialApp(home: SensorsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Доступен'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
