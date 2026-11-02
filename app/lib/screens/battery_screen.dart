import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/battery_session.dart';
import '../services/battery_service.dart';
import '../services/daily_tracker.dart';

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});
  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen>
    with WidgetsBindingObserver {
  BatterySnapshot? current;
  BatterySession? session;
  DailyStatus? daily;
  bool busy = true;
  String? error;
  static const keyName = 'batterySession';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !busy) _run(_refresh);
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(keyName);
      if (saved != null) {
        try {
          session = BatterySession.decode(saved);
        } catch (_) {
          error =
              'Сохранённый замер повреждён. Можно удалить его или начать новый.';
        }
      }
      await _refresh();
    } catch (_) {
      error = 'Не удалось прочитать данные. Попробуйте обновить снимок.';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _refresh() async {
    current = await BatteryService.snapshot();
    try {
      daily = await DailyTracker.status();
    } catch (_) {
      daily = null;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (_) {
      _message('Действие недоступно. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save(BatterySession? value) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = value == null
        ? await prefs.remove(keyName)
        : await prefs.setString(keyName, value.encode());
    if (!ok) throw StateError('Сохранение не выполнено');
    session = value;
    error = null;
  }

  Future<void> _start() async {
    final snap = await BatteryService.snapshot();
    await _save(BatterySession(snap));
    current = snap;
  }

  Future<void> _finish() async {
    final snap = await BatteryService.snapshot();
    await _save(BatterySession(session!.start, snap));
    current = snap;
  }

  Future<void> _settings(String method) async {
    if (!await BatteryService.settings(method)) {
      _message('Этот раздел настроек недоступен на телефоне.');
    }
  }

  String _report() {
    final s = session!;
    final delta = s.chargeDelta;
    return [
      'Движ 3.8.0 • замер всего телефона',
      '${s.start.text('model')} • Android ${s.start.text('android')}',
      'Начало: ${DateTime.fromMillisecondsSinceEpoch(s.start.wall).toLocal()}',
      'Конец: ${DateTime.fromMillisecondsSinceEpoch(s.end!.wall).toLocal()}',
      'Длительность: ${batteryDuration(s.duration)}${s.monotonic ? '' : ' (системные часы; возможна смена времени)'}',
      'Заряд телефона: ${batteryPercent(s.start.percent)} → ${batteryPercent(s.end!.percent)}',
      'Изменение: ${delta == null ? 'Недоступно' : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} п.п.'}',
      'Питание подключено в начале/конце: ${batteryFlag(s.start.flag('plugged'))} / ${batteryFlag(s.end!.flag('plugged'))}',
      'CPU процесса Движа: ${s.cpu == null ? 'Недоступно: процесс изменился или счётчик сброшен' : '${s.cpu} мс'}',
      for (final entry in s.usage.entries)
        '${usageLabels[entry.key]}: ${batteryDuration(entry.value)}',
      'Заряд относится ко всему телефону. Другие приложения, экран, связь и зарядка влияют на результат. Зарядка между снимками не отслеживается.',
      'Время CPU — сумма работы потоков, не расход энергии. Интервалы модулей могут пересекаться.',
    ].join('\n');
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text('$label: $value'),
  );
  @override
  Widget build(BuildContext context) {
    final snap = current;
    final s = session;
    const thermalNames = [
      'Без ограничений',
      'Небольшая нагрузка',
      'Умеренные ограничения',
      'Серьёзные ограничения',
      'Критическое состояние',
      'Аварийное состояние',
      'Выключение',
    ];
    final thermal = snap?.number('thermal', 0, 6)?.toInt();
    return Scaffold(
      appBar: AppBar(title: const Text('Батарея и нагрузка')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Изменение заряда показывает расход всего телефона. Android не предоставляет Движу универсальный точный счётчик собственного расхода в процентах.',
            ),
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Снимок состояния',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (snap == null)
                      const Text('Нет снимка. Нажмите «Обновить».')
                    else ...[
                      _line(
                        'Время',
                        DateTime.fromMillisecondsSinceEpoch(
                          snap.wall,
                        ).toLocal().toString().split('.').first,
                      ),
                      _line(
                        'Телефон',
                        '${snap.text('model')} • Android ${snap.text('android')}',
                      ),
                      _line('Заряд телефона', batteryPercent(snap.percent)),
                      _line(
                        'Температура батареи',
                        snap.temperature == null
                            ? 'Недоступно'
                            : '${snap.temperature!.toStringAsFixed(1)} °C',
                      ),
                      _line(
                        'Подключено питание',
                        batteryFlag(snap.flag('plugged')),
                      ),
                      _line(
                        'Энергосбережение Android',
                        batteryFlag(snap.flag('powerSave')),
                      ),
                      _line(
                        'Тепловой статус Android',
                        thermal == null ? 'Недоступно' : thermalNames[thermal],
                      ),
                      _line(
                        'Активные модули',
                        snap.active.isEmpty
                            ? 'Нет данных об активных модулях'
                            : snap.active
                                  .map((k) => usageLabels[k]!)
                                  .join(', '),
                      ),
                      const Text(
                        'Температура батареи и тепловой статус системы — разные показатели. Снимок обновляется вручную и при возвращении на экран.',
                      ),
                    ],
                    TextButton.icon(
                      onPressed: busy ? null : () => _run(_refresh),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Обновить'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ручной замер',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Хранится только последний замер. Постоянного опроса батареи нет.',
                    ),
                    if (s != null && s.end == null) ...[
                      _line(
                        'Начат',
                        DateTime.fromMillisecondsSinceEpoch(
                          s.start.wall,
                        ).toLocal().toString().split('.').first,
                      ),
                      _line('Заряд в начале', batteryPercent(s.start.percent)),
                      const Text('Можно закрыть экран. Завершение вручную.'),
                      FilledButton(
                        onPressed: busy ? null : () => _run(_finish),
                        child: const Text('Завершить замер'),
                      ),
                    ] else ...[
                      if (s?.end != null) SelectableText(_report()),
                      FilledButton(
                        onPressed: busy ? null : () => _run(_start),
                        child: Text(
                          s == null ? 'Начать замер' : 'Начать новый замер',
                        ),
                      ),
                    ],
                    if (s?.end != null)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => _run(() async {
                                await Clipboard.setData(
                                  ClipboardData(text: _report()),
                                );
                                _message('Отчёт скопирован');
                              }),
                        child: const Text('Скопировать отчёт'),
                      ),
                    if (s != null || error != null)
                      TextButton(
                        onPressed: busy ? null : () => _run(() => _save(null)),
                        child: const Text('Удалить замер'),
                      ),
                    const Text(
                      'После перезапуска процесса время CPU и модулей за интервал недоступно. Изменение заряда телефона сохраняется. После перезагрузки длительность рассчитывается по системным часам и может быть неточной.',
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Управление',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _line(
                      'Фоновый шагомер',
                      daily == null
                          ? 'Статус недоступен'
                          : daily!.enabled
                          ? (daily!.running
                                ? 'Включён'
                                : 'Включён, сейчас не работает')
                          : 'Выключен',
                    ),
                    if (daily?.enabled == true)
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => _run(() async {
                                await DailyTracker.disable();
                                await _refresh();
                              }),
                        child: const Text('Отключить фоновый шагомер'),
                      ),
                    const Text(
                      'Отключение сохраняет записанные шаги. Расположение системных настроек зависит от производителя.',
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => _run(() => _settings('appSettings')),
                      child: const Text('Сведения о приложении'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => _run(() => _settings('powerSettings')),
                      child: const Text('Энергосбережение Android'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
