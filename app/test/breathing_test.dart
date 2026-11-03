import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/models/breathing.dart';
import 'package:dvizh/screens/breathing_screen.dart';
import 'package:dvizh/services/tool_routes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('all presets have no breath hold and finish at their duration', () {
    for (final p in BreathingPreset.values) {
      expect(BreathingFrame(p, Duration.zero).inhaling, isTrue);
      expect(
        BreathingFrame(
          p,
          Duration(milliseconds: (p.inhale * 1000).round()),
        ).inhaling,
        isFalse,
      );
      expect(
        BreathingFrame(
          p,
          Duration(milliseconds: ((p.inhale + p.exhale) * 1000).round()),
        ).inhaling,
        isTrue,
      );
      final end = BreathingFrame(p, Duration(minutes: p.minutes));
      expect(end.done, isTrue);
      expect(end.remainingSeconds, 0);
      expect(end.progress, 1);
      expect(BreathingFrame(p, const Duration(hours: 1)).progress, 1);
    }
  });
  testWidgets(
    'three modes, manual pause and background require explicit resume',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [toolRouteObserver],
          home: const BreathingScreen(),
        ),
      );
      await tester.pumpAndSettle();
      for (final p in BreathingPreset.values) {
        expect(find.text(p.title), findsOneWidget);
      }
      await tester.tap(find.text('Для утра'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Начать'));
      await tester.pump();
      expect(find.text('Вдох'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('Продолжить'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Продолжить'), findsOneWidget);
      await tester.tap(find.text('Продолжить'));
      await tester.pump();
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Overlay')),
        ),
      );
      await tester.pumpAndSettle();
      nav.pop();
      await tester.pumpAndSettle();
      expect(find.text('Продолжить'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('large text on small screen remains scrollable', (tester) async {
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
        home: const BreathingScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Начать'), 100);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
