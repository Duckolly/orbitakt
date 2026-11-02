import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/water_screen.dart';
import '../services/water_tracker.dart';
import '../services/activity_preferences.dart';
import '../theme/app_theme.dart';

class WaterSummary extends StatefulWidget {
  const WaterSummary({super.key});
  @override
  State<WaterSummary> createState() => _WaterSummaryState();
}

class _WaterSummaryState extends State<WaterSummary>
    with WidgetsBindingObserver {
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
      if (ModalRoute.of(context)?.isCurrent == true) _load();
    });
  }

  Future<void> _load() => _run(WaterTracker.status);

  Future<void> _run(Future<WaterStatus> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await action();
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
        setState(
          () => _error =
              'Не удалось прочитать или сохранить воду. Повторите действие.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
  Widget build(BuildContext context) => Card(
    color: OrbitColors.aqua(context),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_outlined),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Вода',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'История воды',
                icon: const Icon(Icons.chevron_right),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WaterScreen(),
                    ),
                  );
                  if (mounted) _load();
                },
              ),
            ],
          ),
          Text(
            _status == null
                ? '—'
                : '${_status!.millilitres} / ${_prefs.waterGoalMl} мл',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: ((_status?.millilitres ?? 0) / _prefs.waterGoalMl).clamp(
              0,
              1,
            ),
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('quickWaterAdd'),
            onPressed: _busy || _status == null
                ? null
                : () => _run(() => WaterTracker.change(1)),
            icon: const Icon(Icons.add),
            label: const Text('200 мл'),
          ),
          if (_status != null && _status!.glasses > 0)
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() => WaterTracker.change(-1)),
              icon: const Icon(Icons.undo),
              label: const Text('Убрать 200 мл за сегодня'),
            ),
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
        ],
      ),
    ),
  );
}
