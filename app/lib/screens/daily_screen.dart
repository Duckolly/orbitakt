import 'dart:async';
import 'package:flutter/material.dart';
import '../services/daily_tracker.dart';
import '../services/daily_issue.dart';
import '../services/activity_preferences.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});
  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> with WidgetsBindingObserver {
  DailyStatus? _status;
  ActivityPreferences _prefs = const ActivityPreferences();
  String? _error;
  bool _busy = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _refresh() async {
    if (_busy) return;
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
      if (mounted) {
        setState(() => _error = 'Не удалось прочитать историю шагов.');
      }
    }
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await (value
          ? DailyTracker.enable()
          : DailyTracker.disable());
      if (mounted) setState(() => _status = status);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Не удалось изменить режим. Откройте приложение и повторите.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _refresh();
      }
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить историю шагов?'),
        content: const Text(
          'Дневной шагомер остановится, все дневные итоги удалятся. Тренировки останутся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await DailyTracker.clear();
    } catch (_) {
      if (mounted) setState(() => _error = 'Не удалось удалить историю.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _refresh();
      }
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
    final s = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Шаги за день')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${s?.todaySteps ?? 0}',
                key: const Key('dailySteps'),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text('шагов сегодня'),
            Text(
              _prefs.distanceLabel(s?.todaySteps ?? 0),
              key: const Key('dailyDistance'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text(
              'Приблизительное расстояние без GPS. Длину шага можно изменить в настройках.',
            ),
            const SizedBox(height: 16),
            if (s == null)
              const LinearProgressIndicator()
            else if (!s.supported)
              const Text(
                'На телефоне нет системного счётчика шагов. Можно записывать отдельные тренировки.',
              )
            else ...[
              SwitchListTile(
                key: const Key('dailyToggle'),
                contentPadding: EdgeInsets.zero,
                value: s.enabled,
                onChanged: _busy ? null : _toggle,
                title: const Text('Дневной шагомер'),
                subtitle: Text(
                  s.active
                      ? 'Работает при погашенном экране'
                      : s.enabled
                      ? 'Подсчёт прерван'
                      : 'Выключен — новые шаги не учитываются',
                ),
              ),
              if (s.enabled && !s.running)
                FilledButton(
                  onPressed: _busy ? null : () => _toggle(true),
                  child: const Text('Возобновить подсчёт'),
                ),
              if (s.enabled && !s.notificationsAllowed)
                const Text(
                  'Уведомления запрещены. Подсчёт можно остановить в приложении; на Android 13+ также в системном списке активных приложений.',
                ),
              if (s.issue.isNotEmpty)
                Text(describeDailyIssue(s.issue), key: const Key('dailyIssue')),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!, key: const Key('dailyError')),
              ),
            const SizedBox(height: 16),
            const Text(
              'После включения системный датчик считает шаги без открытого экрана. Служба показывает тихое уведомление. GPS, интернет и часы не нужны. Первое показание задаёт начало отсчёта. Показания могут приходить с задержкой, особенно при погашенном экране.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Остановка пользователем отключает учёт. После перезагрузки откройте приложение и возобновите подсчёт. Android или ограничения производителя могут прерывать службу; возможны пропуски.',
            ),
            if ((s?.gaps ?? 0) > 0)
              Text(
                'Обнаружены перезапуски/сбросы: ${s!.gaps}. Полнота истории за эти интервалы не гарантируется.',
              ),
            const SizedBox(height: 12),
            const Text(
              'У полуночи и при смене часового пояса распределение между днями может быть приблизительным. Задержанные показания относятся к дате события; приращение между разными датами целиком относится к поздней дате.',
            ),
            const SizedBox(height: 24),
            const Text(
              'История по дням (последние 90)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (s != null && s.history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Пока нет записанных шагов.'),
              ),
            for (final day in s?.history ?? <DailyDay>[])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(day.day),
                trailing: Text('${day.steps} шагов'),
                subtitle: Text(
                  '${_prefs.distanceLabel(day.steps)}${day.estimated ? ' · дата приблизительная' : ''}',
                ),
              ),
            TextButton(
              onPressed: _busy ? null : _clear,
              child: const Text('Удалить историю шагов'),
            ),
          ],
        ),
      ),
    );
  }
}
