import '../services/monthly_animals.dart';
import '../models/rank_level.dart';
import '../widgets/metric_levels_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/toilet_visit.dart';
import '../models/progress_report.dart';
import '../services/storage_service.dart';

class ToiletScreen extends StatefulWidget {
  const ToiletScreen({super.key});
  @override
  State<ToiletScreen> createState() => _ToiletScreenState();
}

class _ToiletScreenState extends State<ToiletScreen>
    with WidgetsBindingObserver {
  List<ToiletVisit> _visits = [];
  RankLevel? _animal;
  bool _busy = true;
  bool _loading = true;
  bool _reading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    if (_reading) return;
    _reading = true;
    setState(() {
      _busy = true;
      _loading = true;
      _error = null;
    });
    try {
      final visits = await StorageService.getAllToiletVisits();
      final now = DateTime.now();
      final previousKey = ToiletVisit.at(
        DateTime(now.year, now.month - 1),
      ).date.substring(0, 7);
      final animal = await MonthlyAnimals.get(
        'toilet',
        ProgressRanks.toilet(
          visits.where((v) => v.date.startsWith(previousKey)).length,
        ),
      );
      if (mounted) {
        setState(() {
          _visits = visits;
          _loading = false;
          _animal = animal;
          _busy = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось прочитать журнал';
          _loading = false;
          _busy = false;
        });
      }
    } finally {
      _reading = false;
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await StorageService.saveToiletVisit(ToiletVisit.at(DateTime.now()));
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Посещение не сохранено';
        });
      }
    }
  }

  Future<void> _delete(ToiletVisit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить ошибочную запись?'),
        content: Text(
          DateFormat('dd.MM.yyyy HH:mm').format(visit.timestamp.toLocal()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await StorageService.deleteToiletVisit(visit.id!);
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Не удалось удалить запись';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = ToiletVisit.at(now).date;
    final month = date.substring(0, 7);
    final current = _visits.where((v) => v.date.startsWith(month)).length;
    final rank = ProgressRanks.toilet(current);
    final animal = _animal;
    return Scaffold(
      appBar: AppBar(title: const Text('Туалет')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading) const Text('Загрузка журнала…'),
                if (!_loading && _error == null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$current',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          Text(
                            'Посещений за ${DateFormat('MM.yyyy').format(now)}',
                          ),
                          Text(
                            'Сегодня: ${_visits.where((v) => v.date == date).length} · Всего: ${_visits.length}',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            rank.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Text(
                            'Ниндзя: 0–14 · Уровень 2: 15–19 · Уровень 3: 20–24\nУровень 4: 25–34 · Уровень 5: от 35',
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
                FilledButton.icon(
                  onPressed: _busy || _loading || _error != null ? null : _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить посещение'),
                ),
                if (_error != null) ...[
                  Text(_error!),
                  TextButton(
                    onPressed: _busy ? null : _load,
                    child: const Text('Повторить'),
                  ),
                ],
                if (!_loading && _error == null) ...[
                  const SizedBox(height: 20),
                  RankProgressCard(
                    metric: 'toilet',
                    rank: rank,
                    monthly: animal,
                    date: now,
                    valueLabel: '$current посещений/месяц',
                  ),
                  const SizedBox(height: 20),
                  const Text('Последние посещения'),
                  if (_visits.isEmpty && !_busy)
                    const Text('Пока нет записей. Нажми «Добавить посещение».'),
                  ..._visits
                      .take(30)
                      .map(
                        (v) => ListTile(
                          leading: const Icon(Icons.wc),
                          title: Text(
                            DateFormat(
                              'dd.MM.yyyy HH:mm',
                            ).format(v.timestamp.toLocal()),
                          ),
                          trailing: IconButton(
                            tooltip: 'Удалить ошибочную запись',
                            onPressed: _busy ? null : () => _delete(v),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
