import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/screens/daily_screen.dart';
import 'package:dvizh/services/daily_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late bool supported, enabled;
  late int total, enableCalls, clearCalls;
  Map<String, Object> status() => {
    'supported': supported,
    'enabled': enabled,
    'running': enabled,
    'permissionGranted': true,
    'notificationsAllowed': true,
    'totalRecorded': total,
    'todaySteps': total,
    'history': total > 0
        ? [
            {'day': '2026-10-31', 'steps': total, 'estimated': false},
          ]
        : [],
  };
  setUp(() {
    supported = true;
    enabled = false;
    total = 23;
    enableCalls = 0;
    clearCalls = 0;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DailyTracker.channel, (call) async {
          if (call.method == 'enable') {
            enabled = true;
            enableCalls++;
          }
          if (call.method == 'disable') enabled = false;
          if (call.method == 'clear') {
            enabled = false;
            total = 0;
            clearCalls++;
          }
          return call.method == 'clear' ? null : status();
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DailyTracker.channel, null),
  );
  testWidgets(
    'daily toggle starts and stops without changing accumulated steps',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailyScreen()));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('dailySteps'))).data,
        '23',
      );
      await tester.tap(find.byKey(const Key('dailyToggle')));
      await tester.pumpAndSettle();
      expect(enabled, true);
      expect(enableCalls, 1);
      await tester.tap(find.byKey(const Key('dailyToggle')));
      await tester.pumpAndSettle();
      expect(enabled, false);
      expect(total, 23);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('unsupported phone offers training mode without toggle', (
    tester,
  ) async {
    supported = false;
    await tester.pumpWidget(const MaterialApp(home: DailyScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dailyToggle')), findsNothing);
    expect(find.textContaining('нет системного счётчика'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'clearing daily history requires confirmation and stops counting',
    (tester) async {
      enabled = true;
      await tester.pumpWidget(const MaterialApp(home: DailyScreen()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Удалить историю шагов'), 200);
      await tester.tap(find.text('Удалить историю шагов'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(clearCalls, 0);
      await tester.tap(find.text('Удалить историю шагов'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(clearCalls, 1);
      expect(enabled, false);
      expect(total, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('global recording off prevents starting native service', () async {
    SharedPreferences.setMockInitialValues({'recordingEnabled': false});
    await expectLater(DailyTracker.enable(), throwsStateError);
    expect(enableCalls, 0);
  });
  test('no hardware prevents starting native service', () async {
    supported = false;
    await expectLater(DailyTracker.enable(), throwsStateError);
    expect(enableCalls, 0);
  });
}
