import 'package:flutter/material.dart';
import 'sky_catalog.dart';

class SkyCityPicker extends StatefulWidget {
  const SkyCityPicker({super.key, required this.cities});
  final List<SkyCity> cities;
  @override
  State<SkyCityPicker> createState() => _SkyCityPickerState();
}

class _SkyCityPickerState extends State<SkyCityPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final items = widget.cities
        .where(
          (c) => '${c.name} ${c.country}'.toLowerCase().contains(
            _query.toLowerCase().trim(),
          ),
        )
        .toList();
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Город наблюдения'),
          leading: CloseButton(onPressed: () => Navigator.pop(context)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Поиск во встроенном списке',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Город не найден. Закрой список и введи координаты вручную.',
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final c = items[i];
                          return ListTile(
                            title: Text(c.name),
                            subtitle: Text(
                              '${c.country} · ${c.latitude.toStringAsFixed(2)}, ${c.longitude.toStringAsFixed(2)}',
                            ),
                            onTap: () => Navigator.pop(context, c),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkyCoordinatesDialog extends StatefulWidget {
  const SkyCoordinatesDialog({super.key});
  @override
  State<SkyCoordinatesDialog> createState() => _SkyCoordinatesDialogState();
}

class _SkyCoordinatesDialogState extends State<SkyCoordinatesDialog> {
  final _lat = TextEditingController(), _lon = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _save() {
    final lat = double.tryParse(
      _lat.text.trim().replaceAll(',', '.').replaceAll('−', '-'),
    );
    final lon = double.tryParse(
      _lon.text.trim().replaceAll(',', '.').replaceAll('−', '-'),
    );
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      setState(
        () => _error =
            'Широта: от −90 до 90. Долгота: от −180 до 180. Вводи десятичные градусы.',
      );
      return;
    }
    Navigator.pop(
      context,
      SkyCity(
        id: 0,
        name: 'Свои координаты',
        country: '',
        latitude: lat,
        longitude: lon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Координаты вручную'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Север и восток — положительные, юг и запад — отрицательные. GPS не используется.',
          ),
          TextField(
            controller: _lat,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(labelText: 'Широта'),
          ),
          TextField(
            controller: _lon,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(labelText: 'Долгота'),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      FilledButton(onPressed: _save, child: const Text('Применить')),
    ],
  );
}
