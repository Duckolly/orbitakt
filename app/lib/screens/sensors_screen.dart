import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/device_sensors.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});
  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  List<DeviceSensor> _sensors = [];
  String _device = '';
  String? _error;
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await DeviceSensors.inventory();
      final sensors = (data['sensors'] as List)
          .map((e) => DeviceSensor(e as Map))
          .toList();
      if (mounted) {
        setState(() {
          _sensors = sensors;
          _device =
              '${data['manufacturer']} ${data['model']} · Android ${data['release']} (API ${data['sdk']})';
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => _error = 'Диагностика доступна в Android-сборке приложения.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось получить список датчиков. Повторите попытку.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = _sensors.map((s) => s.type).toSet();
    const features = <int, String>{
      19: 'Системный счётчик шагов',
      18: 'События шагов',
      1: 'Акселерометр',
      4: 'Гироскоп',
      2: 'Магнитометр / компас',
      5: 'Освещённость',
      6: 'Барометр',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Датчики телефона')),
      body: SafeArea(
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    Text(_error!),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Повторить'),
                    ),
                  ] else ...[
                    Text(
                      _device,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Показан реальный список, доступный приложению через Android. Некоторые датчики камеры, сканер отпечатка и закрытые датчики производителя сюда не входят.',
                    ),
                    const SizedBox(height: 12),
                    ...features.entries.map(
                      (e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          types.contains(e.key)
                              ? Icons.check_circle_outline
                              : Icons.remove_circle_outline,
                        ),
                        title: Text(e.value),
                        subtitle: Text(
                          types.contains(e.key)
                              ? 'Доступен'
                              : 'Не предоставлен Android',
                        ),
                      ),
                    ),
                    const Divider(),
                    Text(
                      'Все доступные датчики: ${_sensors.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Список не запускает сбор показаний. Потребление ниже — паспортная оценка датчика, а не измеренный расход ОРБИТАКТ.',
                    ),
                    ..._sensors.map(
                      (s) => ExpansionTile(
                        title: Text(s.label),
                        subtitle: Text(s.name),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Производитель: ${s.vendor}\nТип Android: ${s.type}\nПаспортное потребление: ${s.power} мА\nРазрешение: ${s.resolution}\nМаксимальный диапазон: ${s.maxRange}\nМинимальный период: ${s.minDelay} мкс\nWake-up: ${s.wakeUp ? 'да' : 'нет'}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Обновить список'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
