import 'package:flutter/material.dart';
import '../models/sleep_breathing.dart';

class SleepBreathingSettings extends StatelessWidget {
  const SleepBreathingSettings({
    super.key,
    required this.profile,
    required this.enabled,
    required this.onChanged,
  });
  final SleepBreathing profile;
  final bool enabled;
  final ValueChanged<SleepBreathing> onChanged;
  static const labels = {
    SleepRhythm.adaptive: 'Постепенный · от 4/4 до 5/5 с',
    SleepRhythm.shorter: 'Короткие фазы · 3/3 с',
    SleepRhythm.longerExhale: 'Выдох чуть длиннее · 4,5/5,5 с',
    SleepRhythm.free: 'Свободно · без заданного ритма',
  };
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Настроить под себя',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SleepRhythm>(
            key: const ValueKey('sleepRhythm'),
            initialValue: profile.rhythm,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Ритм'),
            items: labels.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: !enabled
                ? null
                : (value) {
                    if (value != null) {
                      onChanged(
                        profile.copyWith(rhythm: value, comfortable: 0),
                      );
                    }
                  },
          ),
          const SizedBox(height: 12),
          const Text('Длительность занятия'),
          Wrap(
            spacing: 8,
            children: [5, 10, 15]
                .map(
                  (minutes) => ChoiceChip(
                    key: ValueKey('sleepMinutes$minutes'),
                    label: Text('$minutes мин'),
                    selected: profile.minutes == minutes,
                    onSelected: !enabled
                        ? null
                        : (_) => onChanged(profile.copyWith(minutes: minutes)),
                  ),
                )
                .toList(),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Звуковая подсказка'),
            subtitle: const Text(
              'Системный щелчок на смене фаз; зависит от звука телефона.',
            ),
            value: profile.sound,
            onChanged: !enabled
                ? null
                : (value) => onChanged(profile.copyWith(sound: value)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Мягкая вибрация'),
            value: profile.vibration,
            onChanged: !enabled
                ? null
                : (value) => onChanged(profile.copyWith(vibration: value)),
          ),
          const Text(
            'Без задержек. Если фазы неудобны, выбери более короткие или свободное дыхание.',
          ),
          if (!enabled)
            const Text('Чтобы изменить настройки, заверши текущий сеанс.'),
        ],
      ),
    ),
  );
}

class SleepProgressCard extends StatelessWidget {
  const SleepProgressCard({
    super.key,
    required this.profile,
    required this.enabled,
    required this.onChanged,
  });
  final SleepBreathing profile;
  final bool enabled;
  final ValueChanged<SleepBreathing> onChanged;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Постепенно, без спешки',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            profile.rhythm != SleepRhythm.adaptive
                ? 'Для выбранного ритма нет автоматического увеличения.'
                : profile.stage == 2
                ? 'Основной ритм 5/5 с. Дальше увеличивать не нужно.'
                : 'Комфортных занятий на этой ступени: ${profile.comfortable}/3.',
          ),
          const Text(
            'Это адаптация по самочувствию, а не тренировка задержки дыхания. Пропуск дня ничего не обнуляет.',
          ),
          if (profile.canIncrease) ...[
            const SizedBox(height: 8),
            const Text(
              'Попробовать вдох и выдох на 0,5 с длиннее в следующем сеансе?',
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: enabled
                      ? () => onChanged(profile.increase())
                      : null,
                  child: const Text('Увеличить'),
                ),
                TextButton(
                  onPressed: enabled ? () => onChanged(profile.keep()) : null,
                  child: const Text('Оставить'),
                ),
              ],
            ),
          ],
          TextButton(
            onPressed: enabled ? () => onChanged(profile.easier()) : null,
            child: const Text('Сделать проще'),
          ),
        ],
      ),
    ),
  );
}
