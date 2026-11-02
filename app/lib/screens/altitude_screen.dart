import 'dart:async';
import 'package:flutter/material.dart';
import '../models/relative_altitude.dart';
import '../services/tool_sensors.dart';
import '../services/tool_routes.dart';

class AltitudeScreen extends StatefulWidget {
  const AltitudeScreen({super.key});
  @override
  State<AltitudeScreen> createState() => _AltitudeScreenState();
}

class _AltitudeScreenState extends State<AltitudeScreen>
    with WidgetsBindingObserver, RouteAware {
  final _lease = ToolSensorLease();
  final _altitude = RelativeAltitude();
  final _clock = Stopwatch()..start();
  bool? _supported;
  bool _running = false;
  String? _error;
  Timer? _watchdog;
  int _lastSample = 0, _statusGeneration = 0;
  ModalRoute<dynamic>? _route;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  Future<void> _check() async {
    final generation = ++_statusGeneration;
    try {
      final supported = await ToolSensors.supported('pressure');
      if (mounted && generation == _statusGeneration) {
        setState(() {
          _supported = supported;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && generation == _statusGeneration) {
        setState(() {
          _error = 'Не удалось проверить барометр.';
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

  void _stop() {
    _lease.stop();
    _watchdog?.cancel();
    _watchdog = null;
    _altitude.reset();
    if (mounted) {
      setState(() {
        _running = false;
      });
    }
  }

  void _failed() {
    if (!mounted) return;
    _stop();
    setState(() {
      _error = 'Нет доступных показаний. Попробуй начать измерение заново.';
    });
  }

  void _start() {
    if (_supported != true ||
        ModalRoute.of(context)?.isCurrent != true ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    _altitude.reset();
    _lastSample = _clock.elapsedMilliseconds;
    setState(() {
      _running = true;
      _error = null;
    });
    _lease.start('pressure', (data) {
      if (!mounted || !_running) return;
      if (data['state'] != 'reading') {
        _failed();
        return;
      }
      final value = data['pressure'];
      if (value is! num || !_altitude.add(value.toDouble())) {
        _failed();
        return;
      }
      _lastSample = _clock.elapsedMilliseconds;
      setState(() {});
    }, _failed);
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_clock.elapsedMilliseconds - _lastSample > 3000) _failed();
    });
  }

  @override
  void didPushNext() => _stop();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    _statusGeneration++;
    _lease.stop();
    _watchdog?.cancel();
    _clock.stop();
    toolRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delta = _altitude.meters;
    final meters = delta?.round();
    final value = meters == null ? '—' : '${meters > 0 ? '+' : ''}$meters м';
    return Scaffold(
      appBar: AppBar(title: const Text('Перепад высоты')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.terrain_outlined, size: 64),
            const SizedBox(height: 20),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Text(
              _supported == false
                  ? 'Барометр недоступен на этом телефоне.'
                  : _running
                  ? (_altitude.calibrated
                        ? 'Примерно относительно точки «ноль»'
                        : 'Определяю точку «ноль»… Стой неподвижно.')
                  : _supported == null
                  ? 'Проверяю наличие барометра…'
                  : 'Начни измерение в исходной точке.',
              textAlign: TextAlign.center,
            ),
            if (_running && _altitude.pressure != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Давление: ${_altitude.pressure!.toStringAsFixed(1)} гПа',
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _running
                  ? _stop
                  : _supported == true
                  ? _start
                  : null,
              icon: Icon(_running ? Icons.stop : Icons.play_arrow),
              label: Text(_running ? 'Остановить' : 'Начать измерение'),
            ),
            if (_running)
              TextButton(
                onPressed: () => setState(_altitude.reset),
                child: const Text('Новая точка «ноль»'),
              ),
            if (_error != null) Text(_error!),
            if (_supported == null && _error != null)
              TextButton(
                onPressed: _check,
                child: const Text('Повторить проверку'),
              ),
            const SizedBox(height: 20),
            const Text(
              'Барометр оценивает изменение высоты по давлению. Погода, вентиляция, '
              'лифт и транспорт могут исказить результат. Это не точная высота над морем и не счётчик этажей.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Офлайн, без GPS. Работает только на этом экране после запуска. '
              'При выходе или сворачивании останавливается; следующий запуск задаёт новый ноль. '
              'История измерений не сохраняется.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
