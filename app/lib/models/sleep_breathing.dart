import 'breathing.dart';

enum SleepRhythm { adaptive, shorter, longerExhale, free }

/// These adaptation steps are a product choice, not a validated medical protocol.
class SleepBreathing {
  const SleepBreathing({
    this.stage = 0,
    this.comfortable = 0,
    this.rhythm = SleepRhythm.adaptive,
    this.minutes = 5,
    this.sound = false,
    this.vibration = false,
  });
  final int stage, comfortable, minutes;
  final SleepRhythm rhythm;
  final bool sound, vibration;
  bool get canIncrease =>
      rhythm == SleepRhythm.adaptive && stage < 2 && comfortable >= 3;
  SleepBreathing copyWith({
    int? stage,
    int? comfortable,
    SleepRhythm? rhythm,
    int? minutes,
    bool? sound,
    bool? vibration,
  }) => SleepBreathing(
    stage: stage ?? this.stage,
    comfortable: comfortable ?? this.comfortable,
    rhythm: rhythm ?? this.rhythm,
    minutes: minutes ?? this.minutes,
    sound: sound ?? this.sound,
    vibration: vibration ?? this.vibration,
  );
  BreathingPreset get preset {
    final seconds = 4 + stage * 0.5;
    final (inhale, exhale) = switch (rhythm) {
      SleepRhythm.adaptive => (seconds, seconds),
      SleepRhythm.shorter => (3.0, 3.0),
      SleepRhythm.longerExhale => (4.5, 5.5),
      SleepRhythm.free => (0.0, 0.0),
    };
    return BreathingPreset(
      'Перед сном',
      inhale,
      exhale,
      minutes,
      'Дыши мягко, без усилий и задержек.',
    );
  }

  SleepBreathing feedback(bool wasComfortable) => copyWith(
    comfortable: wasComfortable && rhythm == SleepRhythm.adaptive
        ? (comfortable + 1).clamp(0, 3)
        : 0,
  );
  SleepBreathing increase() =>
      canIncrease ? copyWith(stage: stage + 1, comfortable: 0) : this;
  SleepBreathing keep() => copyWith(comfortable: 0);
  SleepBreathing easier() => copyWith(
    stage: stage > 0 ? stage - 1 : 0,
    rhythm: rhythm == SleepRhythm.adaptive && stage > 0
        ? SleepRhythm.adaptive
        : SleepRhythm.shorter,
    comfortable: 0,
  );
  Map<String, Object> toJson() => {
    'stage': stage,
    'comfortable': comfortable,
    'rhythm': rhythm.name,
    'minutes': minutes,
    'sound': sound,
    'vibration': vibration,
  };
  factory SleepBreathing.fromJson(Map<String, dynamic> json) {
    int integer(String key, int fallback) =>
        json[key] is int ? json[key] as int : fallback;
    final stage = integer('stage', 0).clamp(0, 2);
    final count = integer('comfortable', 0).clamp(0, 3);
    final minutes = integer('minutes', 5);
    final rhythm =
        SleepRhythm.values.where((r) => r.name == json['rhythm']).firstOrNull ??
        SleepRhythm.adaptive;
    return SleepBreathing(
      stage: stage,
      comfortable: count,
      rhythm: rhythm,
      minutes: [5, 10, 15].contains(minutes) ? minutes : 5,
      sound: json['sound'] == true,
      vibration: json['vibration'] == true,
    );
  }
}
