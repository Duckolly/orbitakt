import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../games/snake_game.dart';
import '../games/tilt_control.dart';
import '../services/tool_routes.dart';
import '../services/tool_sensors.dart';

class SnakeScreen extends StatefulWidget {
  const SnakeScreen({super.key});
  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen>
    with WidgetsBindingObserver, RouteAware {
  final _game = SnakeGame();
  final _tilt = TiltControl();
  final _tiltLease = ToolSensorLease();
  bool _tiltEnabled = false;
  bool? _tiltSupported;
  String? _tiltError;
  ModalRoute<dynamic>? _route;
  Timer? _tiltWatchdog;
  final _tiltClock = Stopwatch()..start();
  int _tiltLast = 0;
  Future<void> _checkTilt() async {
    try {
      final supported = await ToolSensors.supported('tilt');
      if (mounted) {
        setState(() {
          _tiltSupported = supported;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tiltError = 'Не удалось проверить акселерометр.';
        });
      }
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

  @override
  void didPushNext() => _pause();
  void _startTilt() {
    _tiltLease.stop();
    _tiltWatchdog?.cancel();
    _tilt.reset();
    if (!_tiltEnabled || _tiltSupported != true) return;
    _tiltError = null;
    _tiltLast = _tiltClock.elapsedMilliseconds;
    _tiltLease.start('tilt', (data) {
      if (!mounted || !_visible || _game.phase != SnakePhase.running) return;
      if (data['state'] != 'reading') {
        _tiltFailed();
        return;
      }
      try {
        final wasCalibrated = _tilt.calibrated;
        final direction = _tilt.add(
          (data['x'] as num).toDouble(),
          (data['y'] as num).toDouble(),
          (data['z'] as num).toDouble(),
          data['rotation'] as int,
        );
        _tiltLast = _tiltClock.elapsedMilliseconds;
        if (direction != null) _turn(direction);
        if (wasCalibrated != _tilt.calibrated) setState(() {});
      } catch (_) {
        _tiltFailed();
      }
    }, _tiltFailed);
    _tiltWatchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_tiltClock.elapsedMilliseconds - _tiltLast > 2500) _tiltFailed();
    });
  }

  void _tiltFailed() {
    if (!mounted) return;
    _pause();
    setState(() {
      _tiltError = 'Нет свежих данных наклона. Доступны кнопки и свайпы.';
    });
  }

  Timer? _timer;
  int _best = 0;
  String? _recordError;
  Offset _drag = Offset.zero;
  bool _visible = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBest();
    _checkTilt();
  }

  Future<void> _loadBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(
          () => _best = math.max(_best, prefs.getInt('begalkaBest') ?? 0),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _recordError = 'Рекорд пока не удалось прочитать.');
      }
    }
  }

  Future<void> _saveBest() async {
    if (_game.score <= _best) return;
    final value = _game.score;
    setState(() {
      _best = value;
      _recordError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final previous = prefs.getInt('begalkaBest') ?? 0;
      if (!await prefs.setInt('begalkaBest', math.max(previous, value))) {
        throw StateError('Save failed');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _recordError = 'Рекорд этой игры не удалось сохранить.');
      }
    }
  }

  void _play() {
    if (!_visible || ModalRoute.of(context)?.isCurrent != true) return;
    if (_game.phase == SnakePhase.lost || _game.phase == SnakePhase.won) {
      _game.reset();
    }
    setState(_game.start);
    _startTilt();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (!mounted || !_visible || ModalRoute.of(context)?.isCurrent != true) {
        _pause();
        return;
      }
      if (_tiltEnabled && !_tilt.calibrated) return;
      setState(_game.tick);
      if (_game.phase == SnakePhase.lost || _game.phase == SnakePhase.won) {
        _timer?.cancel();
        _timer = null;
        _tiltLease.stop();
        _tiltWatchdog?.cancel();
        unawaited(_saveBest());
      }
    });
  }

  void _pause() {
    _tiltLease.stop();
    _tiltWatchdog?.cancel();
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(_game.pause);
  }

  void _turn(SnakeDirection direction) {
    _game.turn(direction);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    if (!_visible) _pause();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tiltLease.stop();
    _tiltWatchdog?.cancel();
    toolRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final running = _game.phase == SnakePhase.running;
    final title = switch (_game.phase) {
      SnakePhase.ready => 'Собирайте точки, избегайте стен и хвоста',
      SnakePhase.running => 'Игра идёт',
      SnakePhase.paused => 'Пауза · нажмите «Продолжить»',
      SnakePhase.lost => 'Игра окончена',
      SnakePhase.won => 'Поле заполнено — победа!',
    };
    Widget directionButton(
      IconData icon,
      String label,
      SnakeDirection direction,
    ) => IconButton.filledTonal(
      onPressed: running ? () => _turn(direction) : null,
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
      icon: Icon(icon),
    );
    return PopScope(
      onPopInvokedWithResult: (_, _) => _pause(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Бегалка')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 24,
                children: [
                  Text(
                    'Счёт: ${_game.score}',
                    key: const Key('snakeScore'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Рекорд: $_best',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Управление наклоном'),
                subtitle: Text(
                  _tiltSupported == false
                      ? 'Акселерометр недоступен'
                      : 'Включается только во время игры',
                ),
                value: _tiltEnabled,
                onChanged: running || _tiltSupported != true
                    ? null
                    : (value) => setState(() {
                        _tiltEnabled = value;
                      }),
              ),
              if (_tiltEnabled)
                Text(
                  _tilt.calibrated
                      ? 'Наклони в сторону поворота и верни в нейтральное положение.'
                      : 'Калибровка при старте: держи телефон почти горизонтально и неподвижно около секунды.',
                ),
              if (_tiltError != null) Text(_tiltError!),
              const SizedBox(height: 12),
              Text(title),
              const SizedBox(height: 12),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.min(
                      400,
                      math.max(160, MediaQuery.sizeOf(context).height - 360),
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Semantics(
                      label:
                          'Игровое поле. Счёт ${_game.score}. Управление кнопками ниже или свайпами.',
                      child: GestureDetector(
                        onPanStart: running ? (_) => _drag = Offset.zero : null,
                        onPanUpdate: running ? (d) => _drag += d.delta : null,
                        onPanEnd: running
                            ? (_) {
                                if (_drag.distance < 12) return;
                                _turn(
                                  _drag.dx.abs() > _drag.dy.abs()
                                      ? (_drag.dx > 0
                                            ? SnakeDirection.right
                                            : SnakeDirection.left)
                                      : (_drag.dy > 0
                                            ? SnakeDirection.down
                                            : SnakeDirection.up),
                                );
                              }
                            : null,
                        child: CustomPaint(
                          painter: _BoardPainter(_game, colors),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: directionButton(
                  Icons.keyboard_arrow_up,
                  'Вверх',
                  SnakeDirection.up,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  directionButton(
                    Icons.keyboard_arrow_left,
                    'Влево',
                    SnakeDirection.left,
                  ),
                  const SizedBox(width: 52),
                  directionButton(
                    Icons.keyboard_arrow_right,
                    'Вправо',
                    SnakeDirection.right,
                  ),
                ],
              ),
              Center(
                child: directionButton(
                  Icons.keyboard_arrow_down,
                  'Вниз',
                  SnakeDirection.down,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: running ? _pause : _play,
                icon: Icon(running ? Icons.pause : Icons.play_arrow),
                label: Text(
                  running
                      ? 'Пауза'
                      : _game.phase == SnakePhase.paused
                      ? 'Продолжить'
                      : _game.phase == SnakePhase.ready
                      ? 'Начать'
                      : 'Ещё раз',
                ),
              ),
              if (_recordError != null)
                Text(_recordError!, style: TextStyle(color: colors.error)),
              const SizedBox(height: 12),
              const Text(
                'Полностью офлайн. При сворачивании игра ставится на паузу; после закрытия экрана партия не восстанавливается. Сохраняется только рекорд.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.game, this.colors);
  final SnakeGame game;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / game.columns;
    final paint = Paint()..color = colors.surfaceContainerHighest;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      paint,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
    );
    paint.color = colors.outlineVariant;
    for (var i = 1; i < game.columns; i++) {
      canvas.drawLine(
        Offset(i * cell, 0),
        Offset(i * cell, size.height),
        paint..strokeWidth = .5,
      );
    }
    for (var i = 1; i < game.rows; i++) {
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), paint);
    }
    final food = game.food;
    if (food != null) {
      paint.color = colors.tertiary;
      canvas.drawCircle(
        Offset((food.x + .5) * cell, (food.y + .5) * cell),
        cell * .26,
        paint,
      );
    }
    final body = game.body;
    for (var i = 0; i < body.length; i++) {
      paint.color = i == 0
          ? colors.primary
          : colors.primary.withValues(alpha: .7);
      final p = body[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(p.x * cell + 1.5, p.y * cell + 1.5, cell - 3, cell - 3),
          Radius.circular(cell * .23),
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
