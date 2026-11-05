import '../services/monthly_animals.dart';
import '../widgets/rank_animal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/holiday_preset.dart';
import '../models/progress_report.dart';
import '../models/rank_level.dart';
import '../services/progress_reports.dart';
import 'toilet_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ProgressData? _data;
  List<RankLevel?> _monthly = [];
  String? _error;
  bool _loading = true;
  bool _yearMode = false;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  HolidayPreset? _preset;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ProgressReports.load();
      final now = DateTime.now();
      final previous = data.aggregate(
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month, 0),
      );
      final monthly = <RankLevel?>[
        await MonthlyAnimals.get(
          'steps',
          ProgressRanks.steps(previous.averageSteps),
        ),
        await MonthlyAnimals.get(
          'water',
          ProgressRanks.water(previous.averageGlasses),
        ),
        await MonthlyAnimals.get(
          'toilet',
          ProgressRanks.toilet(previous.visits),
        ),
      ];
      if (mounted) {
        setState(() {
          _data = data;
          _monthly = monthly;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Не удалось загрузить отчёт. Данные не изменены.';
        });
      }
    }
  }

  Widget _metric(String title, String total, String detail, RankLevel? rank) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(total, style: Theme.of(context).textTheme.headlineMedium),
              Text(detail),
              if (rank != null)
                Text(
                  '${rank.name} · уровень ${rank.level}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var end = _yearMode
        ? DateTime(_year, 12, 31)
        : DateTime(_year, _month + 1, 0);
    final start = _yearMode ? DateTime(_year) : DateTime(_year, _month);
    if (_preset != null) end = DateTime(_year, _preset!.month, _preset!.day);
    final future =
        start.isAfter(today) || (_preset != null && end.isAfter(today));
    if (end.isAfter(today)) end = today;
    final report = _data == null || future
        ? null
        : _data!.aggregate(start, end);
    // Preserve a selected historical year even if its last records were removed.
    final years = <int>{now.year, _year};
    if (_data != null) {
      for (final day in [
        ..._data!.steps.map((d) => d.day),
        ..._data!.water.map((d) => d.day),
        ..._data!.visits.map((d) => d.date),
      ]) {
        final year = DateTime.tryParse(day)?.year;
        if (year != null) years.add(year);
      }
    }
    final firstYear = years.reduce((a, b) => a < b ? a : b);
    final format = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчёты'),
        actions: [
          IconButton(
            tooltip: 'Обновить отчёт',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Месяц')),
                ButtonSegment(value: true, label: Text('Год')),
              ],
              selected: {_yearMode},
              onSelectionChanged: (v) => setState(() {
                _yearMode = v.first;
                _preset = null;
              }),
            ),
            Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<int>(
                  value: _year,
                  items: [
                    for (var y = now.year; y >= firstYear; y--)
                      DropdownMenuItem(value: y, child: Text('$y год')),
                  ],
                  onChanged: (v) => setState(() {
                    _year = v!;
                    _preset = null;
                  }),
                ),
                if (!_yearMode)
                  DropdownButton<int>(
                    value: _month,
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text('${m.toString().padLeft(2, '0')} месяц'),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _month = v!;
                      _preset = null;
                    }),
                  ),
              ],
            ),
            if (_yearMode) ...[
              const Text('Промежуточный отчёт с 1 января по дату:'),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Весь год'),
                    selected: _preset == null,
                    onSelected: (_) => setState(() => _preset = null),
                  ),
                  ...HolidayPreset.presets.map(
                    (p) => ChoiceChip(
                      label: Text(p.name),
                      selected: _preset == p,
                      onSelected: (_) => setState(() => _preset = p),
                    ),
                  ),
                ],
              ),
              Text(
                'Итоговый годовой отчёт: 31.12.$_year. До этой даты показан промежуточный итог.',
              ),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null) ...[
              Text(_error!),
              TextButton(
                onPressed: _load,
                child: const Text('Повторить загрузку'),
              ),
            ],
            if (future) const Text('Этот период ещё не наступил.'),
            if (report != null && !_loading && _error == null) ...[
              const SizedBox(height: 12),
              Text(
                '${format.format(report.start)} — ${format.format(report.end)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                _yearMode &&
                        _preset == null &&
                        !DateTime(_year, 12, 31).isAfter(today)
                    ? 'Дата итогового отчёта: 31.12.$_year'
                    : 'Сформирован: ${format.format(today)}',
              ),
              _metric(
                'Шаги',
                '${report.steps}',
                '≈ ${report.kilometres.toStringAsFixed(2)} км\nСреднее: ${report.averageSteps.toStringAsFixed(0)} шагов/день',
                ProgressRanks.steps(report.averageSteps),
              ),
              _metric(
                'Вода',
                '${report.glasses} стаканов',
                '${report.glasses * 200} мл за период\nСреднее: ${report.averageGlasses.toStringAsFixed(1)} стакана/день',
                ProgressRanks.water(report.averageGlasses),
              ),
              _metric(
                'Туалет',
                '${report.visits} посещений',
                _yearMode
                    ? 'Сумма за выбранный период. Уровень определяется только по месяцу.'
                    : 'Сумма за месяц',
                _yearMode ? null : ProgressRanks.toilet(report.visits),
              ),
              Text(
                'Средние рассчитаны за ${report.days} календарных дней. Дни без записей включены в расчёт как 0.\nЗаписей шагов: ${report.stepDays} дней; воды: ${report.waterDays} дней. Отсутствие записи не подтверждает отсутствие активности.',
              ),
              if (report.estimated)
                const Text(
                  'Часть шагов отмечена счётчиком как приблизительная.',
                ),
              const SizedBox(height: 20),
              const Text('Зверинец · по последнему завершённому месяцу'),
              ..._animals(now),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ToiletScreen()),
                );
                if (mounted) await _load();
              },
              icon: const Icon(Icons.wc),
              label: const Text('Журнал посещений'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _animals(DateTime now) {
    final previous = _data!.aggregate(
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month, 0),
    );
    final ranks = _monthly;
    return [
      for (var i = 0; i < 3; i++)
        ListTile(
          leading: RankAnimal(ranks[i], size: 32),
          title: Text(['Шаги', 'Вода', 'Туалет'][i]),
          subtitle: Text(
            '${ranks[i]?.animal ?? 'Без животного'} · ${DateFormat('MM.yyyy').format(previous.start)}',
          ),
        ),
    ];
  }
}
