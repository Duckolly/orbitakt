import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/services/activity_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('distance unit conversion and Russian formatting', () {
    const p = ActivityPreferences();
    expect(p.kilometres(1000), .7);
    expect(p.distanceLabel(6420), '≈ 4,49 км');
    expect(p.distanceLabel(0), '≈ 0,00 км');
    expect(p.kilometres(-1), 0);
  });
  test('calibration changes distance without changing steps', () {
    expect(const ActivityPreferences(stepLengthCm: 80).kilometres(1250), 1);
    expect(const ActivityPreferences(stepLengthCm: 50).kilometres(2000), 1);
  });
  test('preferences persist together and preserve existing data', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacyAccepted', true);
    await const ActivityPreferences(
      stepLengthCm: 71.4,
      stepGoal: 12000,
      waterGoalMl: 2400,
    ).save();
    final value = await ActivityPreferences.load();
    expect(value.stepLengthCm, 71.4);
    expect(value.stepGoal, 12000);
    expect(value.waterGoalMl, 2400);
    expect(prefs.getBool('privacyAccepted'), true);
  });
  test('malformed or out-of-range storage falls back safely', () async {
    final prefs = await SharedPreferences.getInstance();
    for (final raw in [
      'bad json',
      '{}',
      '{"stepLengthCm":0,"stepGoal":8000,"waterGoalMl":2000}',
    ]) {
      await prefs.setString(ActivityPreferences.storageKey, raw);
      expect((await ActivityPreferences.load()).stepLengthCm, 70);
    }
  });
  test('invalid calibration and goals are rejected before writing', () async {
    for (final p in [
      const ActivityPreferences(stepLengthCm: double.nan),
      const ActivityPreferences(stepLengthCm: 0),
      const ActivityPreferences(stepGoal: 0),
      const ActivityPreferences(waterGoalMl: 250),
    ]) {
      await expectLater(p.save(), throwsArgumentError);
    }
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        ActivityPreferences.storageKey,
      ),
      false,
    );
  });
}
