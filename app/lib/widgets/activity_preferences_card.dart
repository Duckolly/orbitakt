import 'package:flutter/material.dart';
import '../services/activity_preferences.dart';

class ActivityPreferencesCard extends StatefulWidget {
  const ActivityPreferencesCard({super.key});
  @override
  State<ActivityPreferencesCard> createState() =>
      _ActivityPreferencesCardState();
}

class _ActivityPreferencesCardState extends State<ActivityPreferencesCard> {
  final _form = GlobalKey<FormState>();
  final _length = TextEditingController();
  final _steps = TextEditingController();
  final _water = TextEditingController();
  bool _ready = false, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await ActivityPreferences.load();
      if (!mounted) return;
      _length.text = value.stepLengthCm.toStringAsFixed(1).replaceAll('.', ',');
      _steps.text = '${value.stepGoal}';
      _water.text = '${value.waterGoalMl}';
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Не удалось прочитать настройки');
    }
  }

  @override
  void dispose() {
    _length.dispose();
    _steps.dispose();
    _water.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ActivityPreferences(
        stepLengthCm: double.parse(_length.text.replaceAll(',', '.')),
        stepGoal: int.parse(_steps.text),
        waterGoalMl: int.parse(_water.text),
      ).save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Цели и длина шага сохранены')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось сохранить. Повторите действие.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Цели и расстояние',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_ready) ...[
              TextFormField(
                controller: _length,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Длина одного шага, см',
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  return n == null || !n.isFinite || n < 20 || n > 150
                      ? 'Введите от 20 до 150 см'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _steps,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Цель шагов за день',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 500 || n > 50000
                      ? 'От 500 до 50 000 шагов'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _water,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Личная цель воды, мл',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 200 || n > 6000 || n % 200 != 0
                      ? 'От 200 до 6 000, кратно 200 мл'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Километры — оценка без GPS. По умолчанию шаг 70 см. Для калибровки пройдите известное расстояние: длина шага = метры × 100 / число шагов. Например, 100 м / 140 шагов ≈ 71,4 см. Изменение пересчитывает отображаемую историю, исходные шаги сохраняются. Цели — ваши ориентиры, а не медицинские нормы.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Сохранить цели'),
              ),
            ] else if (_error == null)
              const LinearProgressIndicator(),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
  );
}
