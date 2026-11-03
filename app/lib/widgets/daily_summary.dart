import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/daily_screen.dart';
import '../services/daily_tracker.dart';
import '../services/daily_issue.dart';
import '../services/activity_preferences.dart';
import '../theme/app_theme.dart';

class DailySummary extends StatefulWidget {
  const DailySummary({super.key});
  @override
  State<DailySummary> createState() => _DailySummaryState();
}

class _DailySummaryState extends State<DailySummary>
    with WidgetsBindingObserver {
  DailyStatus? _status;
  ActivityPreferences _prefs = const ActivityPreferences();
  bool _loading = false;
  String? _error;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (ModalRoute.of(context)?.isCurrent == true) _load();
    });
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final status = await DailyTracker.status();
      final prefs = await ActivityPreferences.load();
      if (mounted) {
        setState(() {
          _status = status;
          _prefs = prefs;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Не удалось обновить шаги');
    } finally {
      _loading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
      _start();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _status?.todaySteps;
    final status =
        _error ??
        (_status == null
            ? 'Читаем данные…'
            : _status!.issue.isNotEmpty
            ? 'Подсчёт остановлен · Подробнее'
            : _status!.active
            ? 'Шагомер работает'
            : 'Настроить фоновый подсчёт');
    final fullStatus = _status?.issue.isNotEmpty == true
        ? describeDailyIssue(_status!.issue)
        : status;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final totals = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            steps?.toString() ?? '—',
            key: const Key('homeDailySteps'),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            'из ${_prefs.stepGoal} шагов',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            steps == null ? '≈ — км' : _prefs.distanceLabel(steps),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          Text(
            'Оценка · шаг ${_prefs.stepLengthCm.toStringAsFixed(0)} см',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ];
    return Card(
      color: OrbitColors.peach(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const DailyScreen()));
          if (mounted) _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_walk, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Шаги сегодня',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              if (largeText) ...[
                totals[0],
                const SizedBox(height: 8),
                totals[1],
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: totals[0]),
                    const SizedBox(width: 8),
                    Expanded(child: totals[1]),
                  ],
                ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: ((steps ?? 0) / _prefs.stepGoal).clamp(0, 1),
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Tooltip(
                message: fullStatus,
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _status?.issue.isNotEmpty == true
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
