import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/water_screen.dart';
import '../services/water_tracker.dart';

class WaterSummary extends StatefulWidget {
  const WaterSummary({super.key});
  @override
  State<WaterSummary> createState() => _WaterSummaryState();
}

class _WaterSummaryState extends State<WaterSummary>
    with WidgetsBindingObserver {
  WaterStatus? _status;
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
      final status = await WaterTracker.status();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      /* The water screen offers retry on storage errors. */
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
      leading: const Icon(Icons.water_drop_outlined),
      title: Text(
        _status == null
            ? 'Вода за день'
            : 'Вода за день: ${_status!.glasses} стаканов',
      ),
      subtitle: Text(
        _status == null
            ? 'Открыть счётчик · стакан 200 мл'
            : '${_status!.millilitres} мл · стакан 200 мл',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const WaterScreen()));
        if (mounted) _load();
      },
    ),
  );
}
