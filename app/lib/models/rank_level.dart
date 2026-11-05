/// Thresholds use [minInclusive] <= value < [maxExclusive].
/// A null upper bound represents the highest level.
class RankLevel {
  final int level;
  final String name;
  final double minInclusive;
  final double? maxExclusive;
  final String? animal;
  final String? icon;

  const RankLevel({
    required this.level,
    required this.name,
    required this.minInclusive,
    this.maxExclusive,
    this.animal,
    this.icon,
  }) : assert(level >= 1 && level <= 5),
       assert(minInclusive >= 0),
       assert(maxExclusive == null || maxExclusive > minInclusive);
}
