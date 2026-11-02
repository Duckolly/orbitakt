import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/daily_screen.dart';
import '../services/daily_tracker.dart';
import '../services/daily_issue.dart';
import '../services/activity_preferences.dart';
import '../theme/app_theme.dart';
import 'orbit/orbit_art.dart';

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
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_walk),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Шаги сегодня',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
              Text(
                steps?.toString() ?? '—',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              Text('Цель: ${_prefs.stepGoal} шагов'),
              const SizedBox(height: 8),
              Text(
                steps == null
                    ? 'Расстояние пока недоступно'
                    : _prefs.distanceLabel(steps),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('Оценка · шаг ${_prefs.stepLengthCm.toStringAsFixed(0)} см'),
              OrbitArt(progress: (steps ?? 0) / _prefs.stepGoal),
              const Text(
                'Двигаемся в своём темпе',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _error ??
                    (_status == null
                        ? 'Читаем данные…'
                        : _status!.issue.isNotEmpty
                        ? describeDailyIssue(_status!.issue)
                        : _status!.active
                        ? 'Дневной шагомер работает'
                        : 'Настроить фоновый подсчёт'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
