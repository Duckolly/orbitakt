import 'package:flutter/material.dart';
import '../theme/seasonal_controller.dart';

class SeasonalSettingsCard extends StatefulWidget {
  const SeasonalSettingsCard({super.key});
  @override
  State<SeasonalSettingsCard> createState() => _SeasonalSettingsCardState();
}

class _SeasonalSettingsCardState extends State<SeasonalSettingsCard> {
  bool _saving = false;
  int _revision = 0;
  Future<void> _save(SeasonalAppearance value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await SeasonalController.set(value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось сохранить оформление. Повтори попытку.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _revision++;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<SeasonalAppearance>(
    valueListenable: SeasonalController.appearance,
    builder: (context, value, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Сезонное оформление',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<bool>(
              key: ValueKey((value.newYear, _revision)),
              initialValue: value.newYear,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Скин'),
              items: const [
                DropdownMenuItem(value: false, child: Text('Обычный')),
                DropdownMenuItem(value: true, child: Text('Новогодний')),
              ],
              onChanged: _saving
                  ? null
                  : (enabled) {
                      if (enabled != null) {
                        _save(
                          SeasonalAppearance(
                            newYear: enabled,
                            animate: value.animate,
                          ),
                        );
                      }
                    },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Анимация снега'),
              subtitle: const Text(
                'На главной и во вкладке «Отдых». Системное снижение анимации учитывается.',
              ),
              value: value.animate,
              onChanged: !value.newYear || _saving
                  ? null
                  : (enabled) => _save(
                      SeasonalAppearance(
                        newYear: value.newYear,
                        animate: enabled,
                      ),
                    ),
            ),
            const Text(
              'Светлый и тёмный режимы сохраняются. Данные и цели не меняются.',
            ),
          ],
        ),
      ),
    ),
  );
}
