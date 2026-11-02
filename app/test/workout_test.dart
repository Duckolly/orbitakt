import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/models/activity.dart';
import 'package:dvizh/models/workout.dart';

void main() {
  test('workout keeps fields through SQLite map conversion', () {
    final original = Workout(
      id: 7,
      type: ActivityType.walking,
      startedAt: DateTime(2026, 10, 31, 10),
      durationSeconds: 120,
      steps: 100,
    );
    final restored = Workout.fromMap(
      Map<String, dynamic>.from(original.toMap()),
    );
    expect(restored.id, original.id);
    expect(restored.type, ActivityType.walking);
    expect(restored.startedAt, original.startedAt);
    expect(restored.durationSeconds, 120);
    expect(restored.steps, 100);
  });
}
