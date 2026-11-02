import 'dart:async';
import 'package:flutter/material.dart';
import '../services/tool_sensors.dart';
import '../services/tool_routes.dart';
import 'sky_catalog.dart';

class SkyOrientation {
  const SkyOrientation(this.enabled, this.heading);
  final bool enabled;
  final double? heading;
}

class SkyCompassControl extends StatefulWidget {
  const SkyCompassControl({
    super.key,
    required this.city,
    required this.utc,
    required this.onChanged,
  });
  final SkyCity city;
  final DateTime utc;
  final ValueChanged<SkyOrientation> onChanged;
  @override
  State<SkyCompassControl> createState() => _SkyCompassControlState();
}

class _SkyCompassControlState extends State<SkyCompassControl>
    with WidgetsBindingObserver, RouteAware {
  final _lease = ToolSensorLease();
  final _clock = Stopwatch()..start();
  bool? _supported;
  bool _enabled = false, _visible = true, _covered = false, _help = false;
  double? _heading;
  String _message = 'Ручной поворот работает без датчиков.';
  Timer? _watchdog;
  int _last = 0, _notification = 0;
  ModalRoute<dynamic>? _route;
  bool get _dateAllowed => widget.utc.year >= 2020 && widget.utc.year <= 2030;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _visible =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _check();
    _publish();
  }

  Future<void> _check() async {
    try {
      final supported = await ToolSensors.supported('sky');
      if (mounted) setState(() => _supported = supported);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Не удалось проверить датчики. Доступен ручной поворот.',
        );
      }
    }
  }

  void _publish() {
    final token = ++_notification;
    final value = SkyOrientation(_enabled, _heading);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && token == _notification) widget.onChanged(value);
    });
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
  void didUpdateWidget(SkyCompassControl old) {
    super.didUpdateWidget(old);
    if (old.utc.year != widget.utc.year ||
        old.city.latitude != widget.city.latitude ||
        old.city.longitude != widget.city.longitude) {
      _restart();
    }
  }

  void _stop() {
    _lease.stop();
    _watchdog?.cancel();
    _watchdog = null;
    _heading = null;
    _publish();
  }

  void _restart() {
    _stop();
    if (!_dateAllowed) {
      _enabled = false;
      _message = 'Для этой даты используй ручной поворот.';
      _publish();
      return;
    }
    if (!_enabled ||
        !_visible ||
        _covered ||
        _route?.isCurrent != true ||
        !_dateAllowed) {
      return;
    }
    _last = _clock.elapsedMilliseconds;
    _message = 'Ожидаю свежие показания. Пока действует ручной поворот.';
    _lease.start(
      'sky',
      (data) {
        if (!mounted || !_enabled || !_visible || _covered) return;
        final state = data['state'];
        final raw = data['heading'];
        _last = _clock.elapsedMilliseconds;
        if (state == 'reading' &&
            raw is num &&
            raw.isFinite &&
            raw >= 0 &&
            raw < 360 &&
            data['accuracy'] != 0) {
          setState(() {
            _heading = raw.toDouble();
            _message =
                'Автоповорот: приблизительно по истинному северу. '
                'Точность датчика: ${switch (data['accuracy']) {
                  3 => 'высокая',
                  2 => 'средняя',
                  1 => 'низкая',
                  _ => 'не определена',
                }}.';
          });
        } else if ({
          'waiting',
          'calibration',
          'tilted',
          'paused',
        }.contains(state)) {
          setState(() {
            _heading = null;
            _message = switch (state) {
              'calibration' =>
                'Нужна калибровка. Плавно проведи телефоном восьмёрку вдали от металла.',
              'tilted' => 'Держи телефон почти горизонтально.',
              _ => 'Нет свежего направления. Пока действует ручной поворот.',
            };
          });
        } else {
          _failed();
          return;
        }
        _publish();
      },
      _failed,
      arguments: {
        'latitude': widget.city.latitude,
        'longitude': widget.city.longitude,
        'timeMillis': widget.utc.millisecondsSinceEpoch,
      },
    );
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _clock.elapsedMilliseconds - _last > 3000) {
        setState(() {
          _heading = null;
          _message =
              'Датчики не присылают свежие данные. Пока действует ручной поворот.';
        });
        _publish();
      }
    });
  }

  void _failed() {
    if (!mounted) return;
    _stop();
    setState(() {
      _enabled = false;
      _message = 'Автоповорот недоступен. Используй ручной поворот.';
    });
    _publish();
  }

  @override
  void didPushNext() {
    _covered = true;
    _stop();
  }

  @override
  void didPopNext() {
    _covered = false;
    if (_enabled) {
      setState(_restart);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    if (_visible) {
      if (_enabled) setState(_restart);
    } else {
      _stop();
    }
  }

  @override
  void dispose() {
    _lease.stop();
    _watchdog?.cancel();
    _notification++;
    _clock.stop();
    toolRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Автоповорот по компасу'),
        subtitle: Text(
          _supported == false
              ? 'Магнитометр или акселерометр недоступен'
              : !_dateAllowed
              ? 'Для этой даты используй ручной поворот'
              : 'Датчики только на открытой карте',
        ),
        value: _enabled,
        onChanged: _supported == true && _dateAllowed
            ? (value) => setState(() {
                _enabled = value;
                _restart();
              })
            : null,
      ),
      Text(_message),
      TextButton(
        onPressed: () => setState(() => _help = !_help),
        child: const Text('Как ориентировать карту'),
      ),
      if (_help)
        const Text(
          'Это круговая карта неба над головой, не камера. Верх карты соответствует направлению верхнего края телефона. '
          'При сопоставлении с небом учитывай, что восток на такой карте слева. '
          'Для совмещения с небом подними телефон над головой экраном к себе и держи почти горизонтально. Можно смотреть карту перед собой и пользоваться азимутами в списке. Магниты, чехол, металл и транспорт искажают направление. '
          'Если направление сомнительно, выключи автоповорот и поверни карту вручную. Геолокация не используется.',
        ),
    ],
  );
}
