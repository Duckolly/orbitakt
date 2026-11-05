import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/progress_report.dart';
import '../models/rank_level.dart';
import '../services/monthly_animals.dart';
import '../services/progress_reports.dart';
import 'rank_animal.dart';

/// Full calendar history is read independently of the 90-day journal preview.
class MetricLevelsCard extends StatefulWidget {
  const MetricLevelsCard({
    super.key,
    required this.metric,
    required this.revision,
  });
  final String metric;
  final Object revision;
  @override
  State<MetricLevelsCard> createState() => _MetricLevelsCardState();
}

class _MetricLevelsCardState extends State<MetricLevelsCard> {
  RankLevel? _current, _monthly;
  double? _value;
  DateTime? _date;
  String? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MetricLevelsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision ||
        oldWidget.metric != widget.metric) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final data = await ProgressReports.load();
      final now = DateTime.now();
      final current = data.aggregate(DateTime(now.year, now.month), now);
      final previous = data.aggregate(
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month, 0),
      );
      RankLevel? rank(ProgressReport report) => widget.metric == 'steps'
          ? ProgressRanks.steps(report.averageSteps)
          : ProgressRanks.water(report.averageGlasses);
      final monthly = await MonthlyAnimals.get(
        widget.metric,
        rank(previous),
        now: now,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _date = now;
        _current = rank(current);
        _monthly = monthly;
        _value = widget.metric == 'steps'
            ? current.averageSteps
            : current.averageGlasses;
        _error = null;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = 'Не удалось прочитать уровни');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_error!),
              TextButton(
                onPressed: _load,
                child: const Text('Повторить загрузку уровней'),
              ),
            ],
          ),
        ),
      );
    }
    if (_date == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Загрузка уровней…'),
      );
    }
    return RankProgressCard(
      metric: widget.metric,
      rank: _current,
      monthly: _monthly,
      date: _date!,
      valueLabel:
          '${(widget.metric == 'steps' ? _value!.floor().toString() : _value!.toStringAsFixed(1)).replaceAll('.', ',')} ${widget.metric == 'steps' ? 'шагов/день' : 'стаканов/день'}',
    );
  }
}

class RankProgressCard extends StatelessWidget {
  const RankProgressCard({
    super.key,
    required this.metric,
    required this.rank,
    required this.monthly,
    required this.date,
    required this.valueLabel,
  });
  final String metric, valueLabel;
  final RankLevel? rank, monthly;
  final DateTime date;
  static List<RankLevel> levels(String metric) => metric == 'steps'
      ? [
          6000.0,
          10000.0,
          12000.0,
          15000.0,
          25000.0,
        ].map((v) => ProgressRanks.steps(v)!).toList()
      : metric == 'water'
      ? [4.0, 6.0, 8.0, 10.0, 12.0].map((v) => ProgressRanks.water(v)!).toList()
      : [0, 15, 20, 25, 35].map(ProgressRanks.toilet).toList();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final previous = DateTime(date.year, date.month - 1);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'УРОВЕНЬ · ${DateFormat('MM.yyyy').format(date)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RankAnimal(rank, size: 88),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rank?.name ?? 'Без уровня',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        rank?.animal ??
                            (metric == 'toilet'
                                ? 'Нейтральная иконка'
                                : 'Начало пути'),
                      ),
                      const SizedBox(height: 8),
                      Text(valueLabel, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                5,
                (i) => Semantics(
                  label:
                      'Уровень ${i + 1}${rank?.level == i + 1 ? ', текущий' : ''}',
                  child: Chip(
                    avatar: Icon(
                      (rank?.level ?? 0) > i
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 18,
                    ),
                    backgroundColor: rank?.level == i + 1
                        ? scheme.primaryContainer
                        : null,
                    label: Text('${i + 1}'),
                  ),
                ),
              ),
            ),
            Text(
              metric == 'toilet'
                  ? 'Сумма посещений за текущий месяц.'
                  : 'Среднее за все календарные дни месяца до сегодня, включая дни без записей.',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 32),
            Text(
              'Зверинец · ${DateFormat('MM.yyyy').format(previous)}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Center(child: RankAnimal(monthly, size: 132)),
            const SizedBox(height: 8),
            Text(
              monthly?.animal ?? 'Без животного',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              'По завершённому месяцу · обновляется раз в месяц',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Все уровни'),
              children: [
                for (final item in levels(metric))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: RankAnimal(item, size: 48),
                    title: Text('${item.level}. ${item.name}'),
                    subtitle: Text(
                      '${item.animal ?? 'Нейтральная иконка'} · ${item.maxExclusive == null ? 'от ${item.minInclusive.toInt()}' : '${item.minInclusive.toInt()}–<${item.maxExclusive!.toInt()}'}',
                    ),
                  ),
              ],
            ),
            Text(
              'Игровая шкала записей. Больше — не означает лучше; это не рекомендация менять привычки.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
