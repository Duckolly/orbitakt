import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/breathing.dart';
import '../models/sleep_breathing.dart';
import '../services/sleep_breathing_store.dart';
import '../services/tool_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/sleep_breathing_settings.dart';
import 'breathing_help_screen.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key, this.session, this.store});
  final BreathingSession? session;
  final SleepBreathingStore? store;
  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with WidgetsBindingObserver, RouteAware {
  late final _session = widget.session ?? BreathingSession();
  late final _store = widget.store ?? SleepBreathingStore();
  SleepBreathing _profile = const SleepBreathing();
  int _mode = 0, _cueGeneration = 0;
  bool _ready = false, _busy = false, _feedbackDone = false;
  bool? _lastInhaling;
  Timer? _timer;
  ModalRoute<dynamic>? _route;
  bool get _sleep => _mode == 0;
  bool get _canConfigure => _ready && !_busy && !_session.started;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final value = await _store.load();
      if (!mounted) return;
      setState(() {
        _profile = value;
        _ready = true;
        _configure();
      });
    } catch (_) {
      _message('Не удалось загрузить настройки дыхания. Повтори загрузку.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _configure() => _session.configure(
    _sleep ? _profile.preset : BreathingPreset.values[_mode],
  );
  Future<bool> _save(SleepBreathing value) async {
    if (_busy || !_ready) return false;
    setState(() => _busy = true);
    try {
      await _store.save(value);
      if (!mounted) return false;
      setState(() {
        _profile = value;
        _configure();
      });
      return true;
    } catch (_) {
      _message('Не удалось сохранить настройки. Повтори действие.');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rate(bool comfortable) async {
    if (!_session.complete || _feedbackDone || !_sleep || _busy) return;
    if (await _save(_profile.feedback(comfortable)) && mounted) {
      setState(() => _feedbackDone = true);
    }
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
    _cueGeneration++;
    _timer?.cancel();
    _timer = null;
    _session.pause();
    if (mounted) setState(() {});
  }

  Future<void> _cue() async {
    final generation = _cueGeneration;
    if (!mounted || !_session.running) return;
    try {
      if (_profile.sound) await SystemSound.play(SystemSoundType.click);
      if (mounted &&
          _session.running &&
          generation == _cueGeneration &&
          _profile.vibration) {
        await HapticFeedback.selectionClick();
      }
    } catch (_) {
      /* Unavailable system effects must not stop the timer. */
    }
  }

  void _tick() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      _pause();
      return;
    }
    _session.tick();
    if (_session.complete) {
      _timer?.cancel();
      _timer = null;
    } else if (_sleep && _session.preset.paced && _session.running) {
      final inhaling = _session.frame.inhaling;
      if (_lastInhaling != inhaling) {
        _lastInhaling = inhaling;
        unawaited(_cue());
      }
    }
    setState(() {});
  }

  void _start() {
    if (!_ready ||
        _busy ||
        _session.complete ||
        ModalRoute.of(context)?.isCurrent != true ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    _configure();
    _lastInhaling = _session.started ? _session.frame.inhaling : null;
    _session.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
    _tick();
  }

  void _reset() {
    _pause();
    setState(() {
      _session.reset();
      _feedbackDone = false;
      _lastInhaling = null;
      _configure();
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
    _cueGeneration++;
    _timer?.cancel();
    _session.pause();
    toolRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: _sleep || Theme.of(context).brightness == Brightness.dark
        ? AppTheme.dark
        : AppTheme.light,
    child: Builder(builder: _buildBody),
  );
  Widget _buildBody(BuildContext context) {
    final frame = _session.frame, preset = _session.preset;
    final running = _session.running;
    final phase = _session.complete
        ? 'Сеанс завершён'
        : !_session.started
        ? 'Без спешки'
        : !running
        ? 'Пауза'
        : !preset.paced
        ? 'Дыши свободно'
        : frame.inhaling
        ? 'Вдох'
        : 'Выдох';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дыхание'),
        actions: [
          IconButton(
            tooltip: 'О методике и источниках',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BreathingHelpScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('breathingList'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Wrap(
              spacing: 8,
              children: List.generate(
                BreathingPreset.values.length,
                (index) => ChoiceChip(
                  label: Text(BreathingPreset.values[index].title),
                  selected: _mode == index,
                  onSelected: !_canConfigure
                      ? null
                      : (_) => setState(() {
                          _mode = index;
                          _configure();
                        }),
                ),
              ),
            ),
            if (!_ready) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Загрузка настроек…'),
              ),
              TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('Повторить загрузку'),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                _sleep ? 'Спокойная пауза перед сном' : preset.hint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                preset.paced
                    ? 'Вдох ${breathingSeconds(preset.inhale)} с · выдох ${breathingSeconds(preset.exhale)} с · ${preset.minutes} мин'
                    : 'Свободное дыхание · ${preset.minutes} мин',
                key: const ValueKey('breathingTiming'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Center(
                child: Semantics(
                  label: 'Плавная подсказка дыхания',
                  child: SizedBox(
                    width: 164,
                    height: 164,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: frame.progress,
                            strokeWidth: 3,
                            semanticsLabel: 'Прогресс сеанса',
                          ),
                        ),
                        Transform.scale(
                          scale:
                              0.63 + (running ? frame.expansion : 0.5) * 0.28,
                          child: Container(
                            width: 148,
                            height: 148,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.40),
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.08),
                                ],
                              ),
                            ),
                            child: const Icon(Icons.air_rounded, size: 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                phase,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                running && preset.paced
                    ? '${frame.phaseSeconds} с'
                    : 'Без усилий и задержек',
                textAlign: TextAlign.center,
              ),
              Text(
                'Осталось ${frame.remainingSeconds ~/ 60}:${(frame.remainingSeconds % 60).toString().padLeft(2, '0')}',
                key: const ValueKey('breathingRemaining'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (!_session.complete)
                FilledButton.icon(
                  key: const ValueKey('breathingStart'),
                  style: FilledButton.styleFrom(enableFeedback: false),
                  onPressed: _busy
                      ? null
                      : running
                      ? _pause
                      : _start,
                  icon: Icon(running ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    running
                        ? 'Пауза'
                        : _session.started
                        ? 'Продолжить'
                        : 'Начать',
                  ),
                ),
              if (_session.complete && _sleep && !_feedbackDone) ...[
                const Text(
                  'Было комфортно? Оценка добровольная.',
                  textAlign: TextAlign.center,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _busy ? null : () => _rate(true),
                      child: const Text('Комфортно'),
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : () => _rate(false),
                      child: const Text('Был дискомфорт'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _feedbackDone = true),
                      child: const Text('Пропустить'),
                    ),
                  ],
                ),
              ],
              if (_session.started)
                TextButton(
                  onPressed: _busy ? null : _reset,
                  child: Text(_session.complete ? 'Новый сеанс' : 'Завершить'),
                ),
              const SizedBox(height: 8),
              const Text(
                'Дыши мягко. Если кружится голова, не хватает воздуха или появился дискомфорт — остановись и дыши обычно.',
                textAlign: TextAlign.center,
              ),
              if (_sleep) ...[
                const SizedBox(height: 12),
                SleepProgressCard(
                  profile: _profile,
                  enabled:
                      !_busy &&
                      (!_session.started || _session.complete && _feedbackDone),
                  onChanged: _save,
                ),
                SleepBreathingSettings(
                  profile: _profile,
                  enabled: _canConfigure,
                  onChanged: _save,
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'При сворачивании и блокировке экрана сеанс ставится на паузу. '
                'Завершение без сигнала. Это режим расслабления, а не лечение бессонницы.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
