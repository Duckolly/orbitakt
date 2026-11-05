import 'package:flutter/material.dart';
import '../models/toilet_visit.dart';
import '../models/progress_report.dart';
import '../services/storage_service.dart';
import '../screens/toilet_screen.dart';

class ToiletSummary extends StatefulWidget {
  const ToiletSummary({super.key});
  @override
  State<ToiletSummary> createState() => _ToiletSummaryState();
}

class _ToiletSummaryState extends State<ToiletSummary>
    with WidgetsBindingObserver {
  List<ToiletVisit> _visits = [];
  bool _busy = true;
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
    setState(() => _busy = true);
    try {
      final visits = await StorageService.getAllToiletVisits();
      if (mounted) {
        setState(() {
          _visits = visits;
          _busy = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось прочитать посещения';
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
          _error = 'Посещение не сохранено. Повтори попытку.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = ToiletVisit.at(now).date;
    final month = today.substring(0, 7);
    final count = _visits.where((v) => v.date.startsWith(month)).length;
    final rank = ProgressRanks.toilet(count);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wc),
              title: const Text('Туалет'),
              subtitle: Text(
                _error ??
                    (_busy
                        ? 'Загрузка…'
                        : 'Сегодня: ${_visits.where((v) => v.date == today).length} · За месяц: $count\n${rank.name}'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ToiletScreen()),
                );
                if (mounted) await _load();
              },
            ),
            FilledButton.icon(
              onPressed: _busy || _error != null ? null : _add,
              icon: const Icon(Icons.add),
              label: Text(_busy ? 'Загрузка…' : 'Добавить посещение'),
            ),
            if (_error != null)
              TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('Повторить загрузку'),
              ),
          ],
        ),
      ),
    );
  }
}
