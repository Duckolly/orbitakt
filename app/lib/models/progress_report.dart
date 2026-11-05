import 'rank_level.dart';

class ProgressReport {
  const ProgressReport({
    required this.start,
    required this.end,
    required this.days,
    required this.steps,
    required this.glasses,
    required this.visits,
    required this.stepDays,
    required this.waterDays,
    required this.estimated,
    required this.stepLengthCm,
  });
  final DateTime start, end;
  final int days, steps, glasses, visits, stepDays, waterDays;
  final bool estimated;
  final double stepLengthCm;
  double get averageSteps => steps / days;
  double get averageGlasses => glasses / days;
  double get kilometres => steps * stepLengthCm / 100000;
}

class ProgressRanks {
  /// Remap only derived artwork, preserving a frozen month's earned level.
  static RankLevel appearance(String metric, RankLevel rank) {
    final levels = metric == 'steps'
        ? [6000.0, 10000.0, 12000.0, 15000.0, 25000.0]
        : metric == 'water'
        ? [4.0, 6.0, 8.0, 10.0, 12.0]
        : [0.0, 15.0, 20.0, 25.0, 35.0];
    if (rank.level < 1 || rank.level > 5) {
      throw const FormatException('Invalid rank');
    }
    final value = levels[rank.level - 1];
    return metric == 'steps'
        ? steps(value)!
        : metric == 'water'
        ? water(value)!
        : toilet(value.toInt());
  }

  static const names = [
    'Ниндзя',
    'Гладиатор',
    'Геракл',
    'Мефистофель',
    'Титан',
  ];
  static RankLevel? steps(double average) => _rank(
    average,
    [6000, 10000, 12000, 15000, 25000],
    ['🦊', '🐺', '🦁', '🐆', '🐉'],
    ['Лиса', 'Волк', 'Лев', 'Пантера', 'Дракон'],
  );
  static RankLevel? water(double average) => _rank(
    average,
    [4, 6, 8, 10, 12],
    ['🦦', '🐬', '🦈', '🐋', '🐳'],
    ['Выдра', 'Дельфин', 'Акула', 'Косатка', 'Синий кит'],
  );
  static RankLevel toilet(int monthlyTotal) {
    final rank = _rank(
      monthlyTotal.toDouble(),
      [0, 15, 20, 25, 35],
      ['🐇', '🐒', '🐦', '🦖'],
      ['Заяц', 'Обезьяна', 'Эму', 'Динозавр'],
    )!;
    return RankLevel(
      level: rank.level,
      name: rank.level == 1 ? 'Ниндзя' : 'Уровень ${rank.level}',
      minInclusive: rank.minInclusive,
      maxExclusive: rank.maxExclusive,
      animal: rank.animal,
      icon: rank.icon,
    );
  }

  static RankLevel? _rank(
    double value,
    List<double> thresholds,
    List<String> icons,
    List<String> animals,
  ) {
    if (!value.isFinite || value < thresholds.first) return null;
    var index = thresholds.lastIndexWhere((t) => value >= t);
    return RankLevel(
      level: index + 1,
      name: names[index],
      minInclusive: thresholds[index],
      maxExclusive: index == 4 ? null : thresholds[index + 1],
      animal: animals.length == 5
          ? animals[index]
          : (index == 0 ? null : animals[index - 1]),
      icon: icons.length == 5
          ? icons[index]
          : (index == 0 ? null : icons[index - 1]),
    );
  }
}
