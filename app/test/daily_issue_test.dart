import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/services/daily_issue.dart';
import 'package:dvizh/services/daily_tracker.dart';
import 'package:dvizh/screens/daily_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('sensor registration failures are not labelled as database errors', () {
    final message = describeDailyIssue('registration_failed');
    expect(message, contains('подключить датчик'));
    expect(message, isNot(contains('сохранить')));
    expect(message, isNot(contains('разрешения')));
    expect(describeDailyIssue('storage_error'), contains('сохранить счётчик'));
    expect(describeDailyIssue('permission'), contains('Проверьте разрешения'));
    expect(describeDailyIssue('no_sensor'), contains('Датчики телефона'));
    expect(describeDailyIssue('start_failed'), contains('запустить службу'));
    expect(describeDailyIssue('internal_error'), contains('внутренней ошибки'));
    expect(describeDailyIssue(''), isEmpty);
    expect(describeDailyIssue('future_failure'), contains('future_failure'));
  });
  testWidgets('native reason is shown and cleared after a successful restart', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var running = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(DailyTracker.channel, (call) async {
      if (call.method == 'enable') running = true;
      return {
        'supported': true,
        'permissionGranted': true,
        'notificationsAllowed': true,
        'enabled': running,
        'running': running,
        'issue': running ? '' : 'registration_failed',
        'todaySteps': 456,
        'history': [],
      };
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(DailyTracker.channel, null),
    );
    await t.pumpWidget(const MaterialApp(home: DailyScreen()));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('dailyIssue')), 100);
    expect(
      t.widget<Text>(find.byKey(const Key('dailyIssue'))).data,
      contains('registration_failed'),
    );
    await t.ensureVisible(find.byKey(const Key('dailyToggle')));
    await t.tap(find.byKey(const Key('dailyToggle')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('dailyIssue')), findsNothing);
    await t.scrollUntilVisible(find.byKey(const Key('dailySteps')), -150);
    expect(t.widget<Text>(find.byKey(const Key('dailySteps'))).data, '456');
    await t.pumpWidget(const SizedBox());
  });
}
