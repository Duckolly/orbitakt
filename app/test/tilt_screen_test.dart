import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/screens/snake_screen.dart';
import 'package:dvizh/services/tool_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const status = MethodChannel('dvizh/tilt'),
      events = MethodChannel('dvizh/tilt/events');
  testWidgets(
    'tilt is opt-in, listens only during game, cancels on pause and route cover',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      final calls = <String>[];
      messenger.setMockMethodCallHandler(
        status,
        (c) async => {'supported': true},
      );
      messenger.setMockMethodCallHandler(events, (c) async {
        calls.add(c.method);
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(status, null);
        messenger.setMockMethodCallHandler(events, null);
      });
      Future<void> settle() async {
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
        await t.pump();
      }

      await t.pumpWidget(
        MaterialApp(
          navigatorObservers: [toolRouteObserver],
          home: const SnakeScreen(),
        ),
      );
      await t.pumpAndSettle();
      expect(calls, isEmpty);
      await t.tap(find.byType(SwitchListTile));
      await t.pump();
      expect(calls, isEmpty);
      await t.scrollUntilVisible(find.text('Начать'), 100);
      await t.tap(find.text('Начать'));
      await settle();
      expect(calls, ['listen']);
      for (var i = 0; i < 15; i++) {
        await messenger.handlePlatformMessage(
          'dvizh/tilt/events',
          const StandardMethodCodec().encodeSuccessEnvelope({
            'state': 'reading',
            'x': 0.0,
            'y': 0.0,
            'z': 9.8,
            'rotation': 0,
          }),
          (_) {},
        );
        await t.pump();
      }
      await t.scrollUntilVisible(find.textContaining('Наклони в сторону'), -100);
      expect(find.textContaining('Наклони в сторону'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Пауза'), 100);
      await t.tap(find.text('Пауза'));
      await settle();
      expect(calls.last, 'cancel');
      await t.tap(find.text('Продолжить'));
      await settle();
      expect(calls.last, 'listen');
      final nav = t.state<NavigatorState>(find.byType(Navigator));
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Overlay')),
        ),
      );
      await settle();
      await t.pumpAndSettle();
      expect(calls.last, 'cancel');
      nav.pop();
      await t.pumpAndSettle();
      expect(find.text('Продолжить'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await settle();
      expect(t.takeException(), isNull);
    },
  );
}
