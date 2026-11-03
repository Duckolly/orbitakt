import 'dart:convert';

const usageLabels = {
  'foreground': 'Открытый экран Орбитакта',
  'step': 'Фоновый счётчик шагов',
  'tilt': 'Датчик наклона',
  'pressure': 'Барометр',
  'compass': 'Компас звёздного неба',
};

class BatterySnapshot {
  BatterySnapshot(Map<dynamic, dynamic> value)
    : data = Map<String, dynamic>.from(value) {
    for (final key in ['wallMs', 'elapsedMs', 'cpuMs']) {
      if (data[key] is! int || (data[key] as int) < 0) {
        throw const FormatException('Некорректный снимок');
      }
    }
    if (data['processToken'] is! String ||
        (data['processToken'] as String).isEmpty) {
      throw const FormatException('Нет идентификатора процесса');
    }
  }
  final Map<String, dynamic> data;
  int get wall => data['wallMs'] as int;
  int get elapsed => data['elapsedMs'] as int;
  int get cpu => data['cpuMs'] as int;
  String get token => data['processToken'] as String;
  int? get boot => data['bootCount'] is int && (data['bootCount'] as int) >= 0
      ? data['bootCount'] as int
      : null;
  double? number(String key, double min, double max) {
    final n = data[key];
    if (n is! num || !n.isFinite || n < min || n > max) return null;
    return n.toDouble();
  }

  double? get percent => number('percent', 0, 100);
  double? get temperature => number('temperature', -40, 120);
  bool? flag(String key) => data[key] is bool ? data[key] as bool : null;
  String text(String key) =>
      data[key] is String ? data[key] as String : 'Недоступно';
  Map<String, int> get usage {
    final raw = data['usage'];
    if (raw is! Map) return {};
    return {
      for (final key in usageLabels.keys)
        if (raw[key] is int && (raw[key] as int) >= 0) key: raw[key] as int,
    };
  }

  List<String> get active => data['active'] is List
      ? (data['active'] as List)
            .whereType<String>()
            .where(usageLabels.containsKey)
            .toList()
      : [];
}

class BatterySession {
  BatterySession(this.start, [this.end]);
  final BatterySnapshot start;
  final BatterySnapshot? end;
  String encode() =>
      jsonEncode({'version': 1, 'start': start.data, 'end': end?.data});
  factory BatterySession.decode(String json) {
    final map = jsonDecode(json);
    if (map is! Map ||
        map['version'] != 1 ||
        map['start'] is! Map ||
        (map['end'] != null && map['end'] is! Map)) {
      throw const FormatException('Некорректный замер');
    }
    return BatterySession(
      BatterySnapshot(map['start'] as Map),
      map['end'] == null ? null : BatterySnapshot(map['end'] as Map),
    );
  }
  bool get sameProcess => end != null && start.token == end!.token;
  bool get monotonic =>
      end != null &&
      (sameProcess || (start.boot != null && start.boot == end!.boot));
  int? get duration {
    if (end == null) return null;
    final delta = monotonic
        ? end!.elapsed - start.elapsed
        : end!.wall - start.wall;
    return delta >= 0 ? delta : null;
  }

  int? get cpu {
    if (!sameProcess) return null;
    final delta = end!.cpu - start.cpu;
    return delta >= 0 ? delta : null;
  }

  Map<String, int> get usage {
    if (!sameProcess) return {};
    final before = start.usage;
    return {
      for (final entry in end!.usage.entries)
        if (entry.value >= (before[entry.key] ?? 0))
          entry.key: entry.value - (before[entry.key] ?? 0),
    };
  }

  double? get chargeDelta => end?.percent != null && start.percent != null
      ? end!.percent! - start.percent!
      : null;
}

String batteryDuration(int? ms) {
  if (ms == null) return 'Недоступно';
  final s = ms ~/ 1000;
  return '${s ~/ 3600} ч ${(s ~/ 60) % 60} мин ${s % 60} с';
}

String batteryPercent(double? n) =>
    n == null ? 'Недоступно' : '${n.toStringAsFixed(0)}%';
String batteryFlag(bool? value) => value == null
    ? 'Недоступно'
    : value
    ? 'Да'
    : 'Нет';
