import 'activity.dart';

class Workout {
  final int id;
  final ActivityType type;
  final DateTime startedAt;
  final int durationSeconds;
  final int steps;

  Workout({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.durationSeconds,
    required this.steps,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'type': type.name,
      'startedAt': startedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'steps': steps,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int,
      type: ActivityType.values.firstWhere(
        (ActivityType value) => value.name == map['type'],
      ),
      startedAt: DateTime.parse(map['startedAt'] as String),
      durationSeconds: map['durationSeconds'] as int,
      steps: map['steps'] as int,
    );
  }
}
