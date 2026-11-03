import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';
import '../models/workout.dart';
import '../services/notification_service.dart';
import '../services/sensor_service.dart';
import '../services/storage_service.dart';
import '../services/daily_tracker.dart';
import '../services/hardware_workout_sensor.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    required this.activityType,
    this.sensor,
    this.requestPermission,
    this.saveWorkout,
  });
  final ActivityType activityType;
  // Injection points allow testing failures without Android plugins.
  final SensorService? sensor;
  final Future<bool> Function()? requestPermission;
  final Future<void> Function(Workout)? saveWorkout;
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  late SensorService _sensor = widget.sensor ?? SensorService();
  final Stopwatch _clock = Stopwatch();
  Timer? _timer;
  DateTime? _startedAt;
  Workout? _pending;
  bool _recording = false, _paused = false, _busy = false;
  int _steps = 0;
  String? _error;
  bool get _countsSteps => widget.activityType != ActivityType.workout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<bool> _permission() async {
    if (widget.requestPermission != null) return widget.requestPermission!();
    if (!_countsSteps) return true;
    final status =
        await (Platform.isAndroid
                ? Permission.activityRecognition
                : Permission.sensors)
            .request();
    return status.isGranted;
  }

  Future<void> _start() async {
    if (_busy || _recording || _pending != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('recordingEnabled') ?? true)) {
        throw StateError('Запись отключена в настройках.');
      }
      if (widget.sensor == null && _countsSteps) {
        final daily = await DailyTracker.status();
        _sensor.dispose();
        _sensor = daily.active ? HardwareWorkoutSensor() : SensorService();
      }
      if (!await _permission()) {
        throw StateError('Нет разрешения на распознавание активности.');
      }
      if (!mounted) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
        throw StateError('Вернитесь в приложение и нажмите «Начать».');
      }
      _sensor.reset();
      _clock.reset();
      _steps = 0;
      _startedAt = DateTime.now();
      _recording = true;
      _paused = false;
      _resume();
      if (prefs.getBool('notificationsEnabled') ?? false) {
        try {
          if (await NotificationService.instance.isPermissionGranted() &&
              mounted &&
              _recording &&
              !_paused) {
            await NotificationService.instance.showOngoing(
              'Орбитакт',
              'Запись: ${widget.activityType.title}',
            );
          }
        } catch (_) {
          /* Optional notification never blocks recording. */
        }
      }
    } catch (error) {
      _recording = false;
      _clock.stop();
      await _sensor.stop();
      if (mounted) {
        _error = error is StateError
            ? error.message.toString()
            : 'Не удалось запустить датчик. Попробуйте снова.';
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resume() {
    if (!_recording) return;
    _paused = false;
    _clock.start();
    if (_countsSteps) {
      _sensor.start(
        (steps) {
          if (mounted && _recording) setState(() => _steps = steps);
        },
        onError: (_) {
          if (mounted && _recording) {
            _pause();
            setState(
              () =>
                  _error = 'Датчик недоступен. Можно сохранить текущую запись.',
            );
          }
        },
      );
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _pause() {
    _paused = true;
    _clock.stop();
    _timer?.cancel();
    _timer = null;
    unawaited(_sensor.stop());
    unawaited(_cancelNotification());
  }

  Future<void> _cancelNotification() async {
    try {
      await NotificationService.instance.cancelOngoing();
    } catch (_) {
      /* No plugin in tests. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_recording) return;
    if (state != AppLifecycleState.resumed) {
      _pause();
    } else if (_paused && _error == null) {
      try {
        _resume();
      } catch (_) {
        _error = 'Не удалось возобновить датчик. Сохраните запись.';
        _pause();
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _stopAndSave() async {
    if (_busy || (!_recording && _pending == null)) return;
    setState(() => _busy = true);
    if (_recording) {
      _recording = false;
      _clock.stop();
      _timer?.cancel();
      _timer = null;
      await _sensor.stop();
      await _cancelNotification();
      _pending = Workout(
        id: 0,
        type: widget.activityType,
        startedAt: _startedAt!,
        durationSeconds: _clock.elapsed.inSeconds,
        steps: _steps,
      );
    }
    try {
      final save = widget.saveWorkout;
      if (save != null) {
        await save(_pending!);
      } else {
        await StorageService.saveWorkout(_pending!);
      }
      _pending = null;
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Не удалось сохранить. Нажмите «Повторить сохранение».',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmExit() async {
    if (_busy) return;
    if (!_recording && _pending == null) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Уйти без сохранения?'),
        content: const Text('Текущая тренировка будет потеряна.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Не сохранять'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      _recording = false;
      _pending = null;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  String _duration() {
    final s = _clock.elapsed.inSeconds;
    return '${(s ~/ 3600).toString().padLeft(2, '0')}:${(s ~/ 60 % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clock.stop();
    _sensor.dispose();
    unawaited(_cancelNotification());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy && !_recording && _pending == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.activityType.title)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  widget.activityType.icon,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _duration(),
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
                const SizedBox(height: 16),
                if (_countsSteps)
                  Text(
                    '$_steps шагов · оценка датчика',
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, key: const Key('recordingError')),
                  ),
                FilledButton(
                  key: const Key('recordingButton'),
                  onPressed: _busy
                      ? null
                      : (_recording || _pending != null
                            ? _stopAndSave
                            : _start),
                  child: Text(
                    _busy
                        ? 'Подождите…'
                        : _pending != null
                        ? 'Повторить сохранение'
                        : _recording
                        ? 'Остановить и сохранить'
                        : 'Начать',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _paused && _recording
                      ? 'Пауза: запись продолжается при возврате на экран.'
                      : 'Вне приложения запись ставится на паузу. После завершения процесса незавершённая тренировка не восстанавливается.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
