import 'dart:async';
import 'package:flutter/material.dart';
import '../models/breathing.dart';
import '../services/tool_routes.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});
  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with WidgetsBindingObserver, RouteAware {
  final _clock = Stopwatch();
  Timer? _timer;
  BreathingPreset _preset = BreathingPreset.values.first;
  bool _started = false, _complete = false;
  ModalRoute<dynamic>? _route;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      toolRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) toolRouteObserver.subscribe(this, route);
    }
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    if (mounted) setState(() {});
  }

  void _start() {
    if (ModalRoute.of(context)?.isCurrent != true ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    if (_complete) _clock.reset();
    setState(() {
      _started = true;
      _complete = false;
      _clock.start();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) {
        _pause();
        return;
      }
      if (BreathingFrame(_preset, _clock.elapsed).done) {
        _clock.stop();
        _timer?.cancel();
        _timer = null;
        _complete = true;
      }
      setState(() {});
    });
  }

  void _reset() {
    _pause();
    _clock.reset();
    setState(() {
      _started = false;
      _complete = false;
    });
  }

  @override
  void didPushNext() => _pause();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    toolRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = BreathingFrame(_preset, _clock.elapsed);
    final running = _clock.isRunning;
    final phase = _complete
        ? 'Готово'
        : !_started
        ? 'Готов к началу'
        : !running
        ? 'Пауза'
        : frame.inhaling
        ? 'Вдох'
        : 'Выдох';
    return Scaffold(
      appBar: AppBar(title: const Text('Дыхание')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 8,
              children: BreathingPreset.values
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.title),
                      selected: _preset == preset,
                      onSelected: running
                          ? null
                          : (_) {
                              _reset();
                              setState(() {
                                _preset = preset;
                              });
                            },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(_preset.hint),
            Text(
              'Вдох ${_preset.inhale} с · выдох ${_preset.exhale} с · ${_preset.minutes} мин',
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: frame.progress,
                        strokeWidth: 8,
                        semanticsLabel: 'Прогресс сеанса',
                      ),
                    ),
                    const Icon(Icons.air, size: 60),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              phase,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (running)
              Text(
                '${frame.phaseSeconds}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            Text(
              'Осталось ${frame.remainingSeconds ~/ 60}:${(frame.remainingSeconds % 60).toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: running ? _pause : _start,
              icon: Icon(running ? Icons.pause : Icons.play_arrow),
              label: Text(
                running
                    ? 'Пауза'
                    : _complete
                    ? 'Повторить'
                    : _started
                    ? 'Продолжить'
                    : 'Начать',
              ),
            ),
            TextButton(onPressed: _reset, child: const Text('Сбросить')),
            const Text(
              'Дыши в удобном темпе, не старайся вдохнуть глубже или дольше, чем комфортно. '
              'Задержек дыхания нет. Если темп не подходит или появился дискомфорт — остановись и дыши обычно.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Это подсказка ритма, а не лечение или гарантия сна. При сворачивании сеанс '
              'ставится на паузу. Экран может погаснуть по настройкам телефона.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
