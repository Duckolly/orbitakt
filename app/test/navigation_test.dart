import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/main.dart';
import 'package:dvizh/models/activity.dart';
import 'package:dvizh/models/workout.dart';
import 'package:dvizh/screens/activity_screen.dart';
import 'package:dvizh/screens/consent_screen.dart';
import 'package:dvizh/screens/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'small screen and large text: consent is scrollable and Continue requires all confirmations',
    (tester) async {
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
          home: const ConsentScreen(),
        ),
      );
      final button = find.widgetWithText(FilledButton, 'Продолжить');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      final boxes = find.byType(CheckboxListTile);
      for (var i = 0; i < 3; i++) {
        final checkbox = find.descendant(
          of: boxes.at(i),
          matching: find.byType(Checkbox),
        );
        await tester.ensureVisible(checkbox);
        await tester.pumpAndSettle();
        await tester.tap(checkbox);
        await tester.pump();
      }
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Зарядка'), 200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home opens workout screen without plugin access', (
    tester,
  ) async {
    await tester.pumpWidget(const DvizhApp(showConsentFirst: false));
    await tester.scrollUntilVisible(find.text('Зарядка'), 150);
    await tester.tap(find.text('Зарядка'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recordingButton')), findsOneWidget);
    expect(find.text('Начать'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<void> open(WidgetTester tester, ActivityScreen screen) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => screen),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('failed save can be retried without starting a second workout', (
    tester,
  ) async {
    var calls = 0;
    Workout? captured;
    await open(
      tester,
      ActivityScreen(
        activityType: ActivityType.workout,
        saveWorkout: (workout) async {
          calls++;
          captured = workout;
          if (calls == 1) throw StateError('disk full');
        },
      ),
    );
    await tester.tap(find.byKey(const Key('recordingButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Остановить и сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Повторить сохранение'), findsOneWidget);
    await tester.tap(find.text('Повторить сохранение'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(captured!.type, ActivityType.workout);
    expect(captured!.steps, 0);
    expect(find.text('Open'), findsOneWidget);
    expect(find.byKey(const Key('recordingButton')), findsNothing);
  });

  testWidgets('async start is locked while permission is pending', (
    tester,
  ) async {
    final permission = Completer<bool>();
    var requests = 0;
    await open(
      tester,
      ActivityScreen(
        activityType: ActivityType.workout,
        requestPermission: () {
          requests++;
          return permission.future;
        },
        saveWorkout: (_) async {},
      ),
    );
    await tester.tap(find.byKey(const Key('recordingButton')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('recordingButton')))
          .onPressed,
      isNull,
    );
    expect(requests, 1);
    permission.complete(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recordingError')), findsOneWidget);
    expect(find.text('Начать'), findsOneWidget);
  });

  testWidgets('disabled recording does not request permission', (tester) async {
    SharedPreferences.setMockInitialValues({'recordingEnabled': false});
    var requests = 0;
    await open(
      tester,
      ActivityScreen(
        activityType: ActivityType.workout,
        requestPermission: () async {
          requests++;
          return true;
        },
      ),
    );
    await tester.tap(find.byKey(const Key('recordingButton')));
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.text('Запись отключена в настройках.'), findsOneWidget);
  });
  testWidgets('inactive app pauses a workout and returning resumes it', (
    tester,
  ) async {
    await open(
      tester,
      ActivityScreen(
        activityType: ActivityType.workout,
        saveWorkout: (_) async {},
      ),
    );
    await tester.tap(find.byKey(const Key('recordingButton')));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(
      find.text('Пауза: запись продолжается при возврате на экран.'),
      findsOneWidget,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(
      find.text('Пауза: запись продолжается при возврате на экран.'),
      findsNothing,
    );
    await tester.tap(find.text('Остановить и сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('back from an active workout asks before discarding it', (
    tester,
  ) async {
    await open(
      tester,
      ActivityScreen(
        activityType: ActivityType.workout,
        saveWorkout: (_) async {},
      ),
    );
    await tester.tap(find.byKey(const Key('recordingButton')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Уйти без сохранения?'), findsOneWidget);
    await tester.tap(find.text('Остаться'));
    await tester.pumpAndSettle();
    expect(find.text('Остановить и сохранить'), findsOneWidget);
    await tester.tap(find.text('Остановить и сохранить'));
    await tester.pumpAndSettle();
  });
}
