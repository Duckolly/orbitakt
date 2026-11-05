/// A recurring calendar date; the report year is chosen separately.
class HolidayPreset {
  final String id;
  final String name;
  final int month;
  final int day;

  const HolidayPreset({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
  }) : assert(month >= 1 && month <= 12),
       assert(day >= 1 && day <= 31);

  static const List<HolidayPreset> presets = <HolidayPreset>[
    HolidayPreset(id: 'february13', name: '13 февраля', month: 2, day: 13),
    HolidayPreset(id: 'march8', name: '8 марта', month: 3, day: 8),
    HolidayPreset(id: 'january1', name: '1 января', month: 1, day: 1),
  ];
}
