import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/daily_screen.dart';
import '../services/daily_tracker.dart';

class DailySummary extends StatefulWidget {
  const DailySummary({super.key});
  @override
  State<DailySummary> createState() => _DailySummaryState();
}

class _DailySummaryState extends State<DailySummary>
    with WidgetsBindingObserver {
  DailyStatus? _status;
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
    try {
      final status = await DailyTracker.status();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      /* Screen will offer retry. */
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
    child: ListTile(
      leading: const Icon(Icons.directions_walk),
      title: Text('Шаги за день: ${_status?.todaySteps ?? 0}'),
      subtitle: Text(
        _status?.active == true
            ? 'Дневной шагомер работает'
            : 'Настроить фоновый подсчёт',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const DailyScreen()));
        if (mounted) _load();
      },
    ),
  );
}
