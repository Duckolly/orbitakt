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
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final volume = Text(
      _status == null
          ? '—'
          : '${_status!.millilitres} / ${_prefs.waterGoalMl} мл',
      key: const Key('homeWaterVolume'),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
    Future<void> openHistory() async {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const WaterScreen()));
      if (mounted) _load();
    }

    return Card(
      color: OrbitColors.aqua(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: openHistory,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: largeText
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.water_drop_outlined, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Вода',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                          volume,
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(Icons.water_drop_outlined, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Вода',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: volume,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
              ),
            ),
            LinearProgressIndicator(
              value: ((_status?.millilitres ?? 0) / _prefs.waterGoalMl).clamp(
                0,
                1,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('quickWaterAdd'),
                    onPressed: _busy || _status == null
                        ? null
                        : () => _run(() => WaterTracker.change(1)),
                    icon: const Icon(Icons.add),
                    label: const Text('200 мл'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('quickWaterUndo'),
                  tooltip: 'Убрать 200 мл за сегодня',
                  onPressed: _busy || _status == null || _status!.glasses == 0
                      ? null
                      : () => _run(() => WaterTracker.change(-1)),
                  icon: const Icon(Icons.undo),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
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
}
