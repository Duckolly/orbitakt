import 'dart:async';
import 'package:flutter/material.dart';
import '../services/water_tracker.dart';
import '../services/activity_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/orbit/orbit_art.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});
  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> with WidgetsBindingObserver {
  WaterStatus? _status;
  ActivityPreferences _prefs = const ActivityPreferences();
  bool _busy = false;
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
      if (!_busy && ModalRoute.of(context)?.isCurrent == true) _load();
    });
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

  Future<void> _load() async {
    if (_busy) return;
    await _run(WaterTracker.status);
  }

  Future<void> _run(Future<WaterStatus> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final value = await action();
      final prefs = await ActivityPreferences.load();
      if (mounted) {
        setState(() {
          _status = value;
          _prefs = prefs;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось прочитать или сохранить воду. Повторите действие.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить историю воды?'),
        content: const Text(
          'Будут удалены все записи воды, включая сегодняшний день.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _run(() async {
        await WaterTracker.clear();
        return WaterTracker.status();
      });
    }
  }

  Future<void> _pin() async {
    try {
      final requested = await WaterTracker.pinWidget();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              requested
                  ? 'Подтвердите добавление в окне рабочего стола.'
                  : 'Зажмите свободное место рабочего стола → Виджеты → Орбитакт.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось добавить виджет. Откройте список виджетов рабочего стола.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Вода за день')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Один стакан = 200 мл. Отмечайте выпитую воду вручную.'),
          const SizedBox(height: 16),
          if (_status != null) ...[
            Card(
              color: OrbitColors.aqua(context),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Небольшими порциями в течение дня'),
                    OrbitArt(
                      water: true,
                      progress: _status!.millilitres / _prefs.waterGoalMl,
                    ),
                    Text(
                      '${_status!.millilitres} мл',
                      key: const Key('waterVolume'),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('из ${_prefs.waterGoalMl} мл'),
                    Text(
                      '${_status!.glasses} стаканов',
                      key: const Key('waterGlasses'),
                    ),
                    Text(_status!.today),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (_status!.millilitres / _prefs.waterGoalMl).clamp(
                        0,
                        1,
                      ),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    const Text('Личная цель · изменить в настройках'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() => WaterTracker.change(1)),
              icon: const Icon(Icons.water_drop),
              label: const Text('+1 стакан · 200 мл'),
            ),
            OutlinedButton(
              onPressed: _busy || _status!.glasses == 0
                  ? null
                  : () => _run(() => WaterTracker.change(-1)),
              child: const Text('Убрать стакан за сегодня'),
            ),
          ],
          if (_busy && _status == null)
            const Center(child: CircularProgressIndicator()),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: _busy ? null : _load,
              child: const Text('Повторить'),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pin,
            icon: const Icon(Icons.widgets_outlined),
            label: const Text('Виджет: шаги и вода'),
          ),
          const Text(
            'Новый день начинается по местной дате телефона. Минус исправляет только сегодняшний день. При смене часового пояса отображается соответствующая местная дата.',
          ),
          const SizedBox(height: 20),
          Text(
            'История воды · до 90 дней на экране',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_status != null && _status!.history.isEmpty)
            const Text('Записей пока нет.'),
          ...?_status?.history.map(
            (day) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(day.day),
              subtitle: Text('${day.glasses} стаканов · ${day.millilitres} мл'),
            ),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _clear,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Удалить историю воды'),
          ),
        ],
      ),
    ),
  );
}
