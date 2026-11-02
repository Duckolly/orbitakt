import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/workout.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Workout> _workouts = <Workout>[];
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // R-2: ошибка БД => состояние «история недоступна», не краш.
    try {
      final List<Workout> workouts = await StorageService.getAllWorkouts();

      if (!mounted) {
        return;
      }

      setState(() {
        _workouts = workouts;
        _error = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _error = true);
    }
  }

  Future<void> _clear() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Очистить историю?'),
          content: const Text(
            'Будут удалены все сохранённые тренировки на этом устройстве.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // R-2: очистка в try/catch.
    try {
      await StorageService.clearAll();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось очистить историю: $e')),
      );

      return;
    }

    await _load();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('История очищена')));
  }

  String _formatDuration(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;

    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    // R-1: SafeArea обязателен при включённом edgeToEdge (targetSdk 35).
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          IconButton(
            tooltip: 'Очистить историю',
            icon: const Icon(Icons.delete_outline),
            onPressed: _workouts.isEmpty ? null : _clear,
          ),
        ],
      ),
      body: SafeArea(
        child: _error
            ? const Center(
                child: Text('История временно недоступна. Попробуй позже.'),
              )
            : _workouts.isEmpty
            ? const Center(child: Text('Пока нет сохранённых тренировок'))
            : ListView.builder(
                itemCount: _workouts.length,
                itemBuilder: (BuildContext context, int index) {
                  final Workout workout = _workouts[index];

                  return ListTile(
                    leading: Icon(workout.type.icon, color: primary),
                    title: Text(workout.type.title),
                    subtitle: Text(
                      '${DateFormat('dd.MM.yyyy HH:mm').format(workout.startedAt)}'
                      ' • ${_formatDuration(workout.durationSeconds)}'
                      ' • ${workout.steps} шагов',
                    ),
                  );
                },
              ),
      ),
    );
  }
}
