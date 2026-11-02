import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tool_routes.dart';
import '../sky/sky_catalog.dart';
import '../sky/sky_snapshot.dart';
import '../sky/sky_chart.dart';
import '../sky/city_picker.dart';
import '../sky/sky_compass_control.dart';

class SkyScreen extends StatelessWidget {
  const SkyScreen({super.key});
  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffa998df),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff10121b),
    ),
    child: const _SkyScreenBody(),
  );
}

class _SkyScreenBody extends StatefulWidget {
  const _SkyScreenBody();
  @override
  State<_SkyScreenBody> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<_SkyScreenBody>
    with WidgetsBindingObserver, RouteAware {
  SkyCatalog? _catalog;
  SkyCity? _city;
  SkySnapshot? _snapshot;
  DateTime _utc = DateTime.now().toUtc();
  String? _error, _saveError, _figure;
  int? _selectedStar;
  double _manualTop = 0;
  double? _heading;
  bool _automatic = false;
  bool _visible = true;
  ModalRoute<dynamic>? _route;
  Timer? _timer;
  Future<void> _saveQueue = Future<void>.value();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _visible =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _load();
  }

  Future<void> _load() async {
    try {
      final catalog = await SkyCatalog.load();
      SkyCity? city;
      String? saveError;
      try {
        final raw = (await SharedPreferences.getInstance()).getString(
          'skyCity',
        );
        if (raw != null) {
          city = SkyCity.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      } catch (_) {
        saveError =
            'Не удалось прочитать сохранённое место. Выбери город заново.';
      }
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _city = city;
        _saveError = saveError;
        _error = null;
      });
      _resume();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось загрузить встроенный каталог.');
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

  void _refresh() {
    if (_catalog == null) return;
    if (!mounted) return;
    final utc = DateTime.now().toUtc();
    SkySnapshot? snapshot;
    String? error;
    if (_catalog != null && _city != null) {
      try {
        snapshot = SkySnapshot(_catalog!, _city!, utc);
      } catch (_) {
        error = 'Проверь системную дату: карта поддерживает 2000–2100 годы.';
      }
    }
    setState(() {
      _utc = utc;
      _snapshot = snapshot;
      if (snapshot == null) {
        _heading = null;
        _automatic = false;
      }
      _error = error;
    });
  }

  void _resume() {
    if (!_visible || _route?.isCurrent != true) return;
    _refresh();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didPushNext() => _pause();
  @override
  void didPopNext() => _resume();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    if (_visible) {
      _resume();
    } else {
      _pause();
    }
  }

  void _selectCity(SkyCity city) {
    setState(() {
      _city = city;
      _selectedStar = null;
      _heading = null;
      _automatic = false;
      _saveError = null;
    });
    _refresh();
    final encoded = jsonEncode(city.toJson());
    _saveQueue = _saveQueue
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          if (!await prefs.setString('skyCity', encoded)) {
            throw StateError('Cannot save city');
          }
        })
        .catchError((Object _) {
          if (mounted) {
            setState(
              () => _saveError =
                  'Место выбрано, но не сохранено для следующего запуска.',
            );
          }
        });
  }

  Future<void> _pickCity() async {
    final city = await showDialog<SkyCity>(
      context: context,
      builder: (_) => SkyCityPicker(cities: _catalog!.cities),
    );
    if (mounted && city != null) _selectCity(city);
  }

  Future<void> _coordinates() async {
    final city = await showDialog<SkyCity>(
      context: context,
      builder: (_) => const SkyCoordinatesDialog(),
    );
    if (mounted && city != null) _selectCity(city);
  }

  Future<void> _sources() async {
    try {
      final texts = await Future.wait(
        [
          'NOTICE.txt',
          'LICENSE_CC-BY-SA-4.0.txt',
          'LICENSE_CC-BY-4.0.txt',
        ].map((n) => rootBundle.loadString('assets/sky/$n')),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Источники данных'),
          content: SingleChildScrollView(
            child: SelectableText(texts.join('\n\n')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть сведения о данных.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pause();
    toolRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _catalog, s = _snapshot;
    final selected = _selectedStar == null || c == null
        ? null
        : c.stars.firstWhere((star) => star.id == _selectedStar);
    final pos = selected == null ? s?.positions[-1] : s?.positions[selected.id];
    final figures = c == null || s == null
        ? <SkyFigure>[]
        : c.figures.where((f) => s.above(f) >= 3).toList();
    final named =
        c == null || s == null
              ? <SkyStar>[]
              : c.stars
                    .where(
                      (star) =>
                          star.name.isNotEmpty &&
                          s.positions[star.id]!.altitude >= 0,
                    )
                    .toList()
          ..sort((a, b) => a.magnitude.compareTo(b.magnitude));
    final time =
        '${_utc.year}-${_utc.month.toString().padLeft(2, '0')}-${_utc.day.toString().padLeft(2, '0')} ${_utc.hour.toString().padLeft(2, '0')}:${_utc.minute.toString().padLeft(2, '0')} UTC';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ночное небо'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Обновить время',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (c == null && _error == null) const LinearProgressIndicator(),
            if (_error != null) Text(_error!),
            if (c == null && _error != null)
              TextButton(onPressed: _load, child: const Text('Повторить')),
            if (c != null) ...[
              FilledButton.icon(
                onPressed: _pickCity,
                icon: const Icon(Icons.location_city),
                label: Text(_city?.name ?? 'Выбрать город'),
              ),
              TextButton(
                onPressed: _coordinates,
                child: const Text('Ввести координаты вручную'),
              ),
              if (_city != null)
                Text(
                  '${_city!.latitude.toStringAsFixed(3)}, ${_city!.longitude.toStringAsFixed(3)} · координаты выбранного места',
                ),
              if (_saveError != null) Text(_saveError!),
              Text('Системное время: $time'),
              if (_city == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Выбери город наблюдения. Местоположение автоматически не определяется.',
                  ),
                ),
              if (s != null) ...[
                SkyCompassControl(
                  key: ValueKey('${_city!.latitude}/${_city!.longitude}'),
                  city: _city!,
                  utc: _utc,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _automatic = value.enabled;
                        _heading = value.heading;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SkyChart(
                        catalog: c,
                        snapshot: s,
                        top: _heading ?? _manualTop,
                        figure: _figure,
                        selectedStar: _selectedStar,
                        onSelect: (id) => setState(() => _selectedStar = id),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Центр — зенит, край — горизонт. Это карта неба над головой: восток слева, запад справа.',
                ),
                Text(
                  'Верх карты: ${(_heading ?? _manualTop).round() % 360}° от севера',
                ),
                Slider(
                  value: _manualTop,
                  min: 0,
                  max: 359,
                  divisions: 359,
                  label: '${_manualTop.round()}°',
                  semanticFormatterCallback: (v) =>
                      'Верх карты ${v.round()} градусов',
                  onChanged: _automatic && _heading != null
                      ? null
                      : (v) => setState(() => _manualTop = v),
                ),
                if (selected != null && pos != null)
                  Text(
                    '${selected.name.isEmpty ? 'HIP ${selected.id}' : selected.name}: высота ${pos.altitude.round()}°, азимут ${pos.azimuth.round() % 360}°.',
                  ),
                ExpansionTile(
                  title: const Text('Фигуры над горизонтом'),
                  children: [
                    if (figures.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Опорные звёзды этих фигур сейчас ниже горизонта.',
                        ),
                      ),
                    ...figures.map(
                      (f) => ListTile(
                        title: Text(f.name),
                        subtitle: Text(
                          '${s.above(f)} из ${f.ids.length} опорных звёзд над горизонтом',
                        ),
                        selected: _figure == f.name,
                        trailing: _figure == f.name
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => setState(
                          () => _figure = _figure == f.name ? null : f.name,
                        ),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Яркие звёзды над горизонтом'),
                  children: named.map((star) {
                    final h = s.positions[star.id]!;
                    return ListTile(
                      title: Text(star.name),
                      subtitle: Text(
                        'Высота ${h.altitude.round()}° · азимут ${h.azimuth.round() % 360}°',
                      ),
                      selected: _selectedStar == star.id,
                      onTap: () => setState(() => _selectedStar = star.id),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Все данные встроены. GPS и интернет не используются. При поездке меняй город сам. '
                'Карта обновляется раз в минуту и при возврате на экран. Проверь часы телефона.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Показано положение звёзд, а не фактическая видимость: днём, в облаках и при засветке их может быть не видно. '
                'Солнце, Луна и планеты в этот каталог не входят. Линии фигур упрощены; это не точный навигационный прибор.',
                style: TextStyle(fontSize: 12),
              ),
              TextButton(
                onPressed: _sources,
                child: const Text('Источники данных и лицензии'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
