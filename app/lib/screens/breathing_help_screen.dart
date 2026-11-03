import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BreathingHelpScreen extends StatelessWidget {
  const BreathingHelpScreen({super.key});
  static const sources = {
    'Спокойное дыхание без усилия · NHS':
        'https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/',
    'Ритм 4,5/5,5 с перед сном · исследование 2019':
        'https://www.mdpi.com/2077-0383/8/2/193',
    'Обзор исследований сна · 2026':
        'https://pubmed.ncbi.nlm.nih.gov/41886931/',
    'Избыточное дыхание · MedlinePlus':
        'https://medlineplus.gov/ency/article/003071.htm',
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('О дыхании перед сном')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Спокойнее, а не глубже',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Устройся удобно. Дыши мягко, без усилия, не стремись максимально наполнить или опустошить лёгкие. Задержек нет. Если 4/4 с неудобно, выбери короткие фазы или свободный ритм.',
          ),
          const SizedBox(height: 12),
          const Text(
            'При головокружении, покалывании, нехватке воздуха или другом дискомфорте прекрати упражнение и дыши обычно. При сильной боли в груди или выраженном затруднении дыхания нужна срочная медицинская помощь. При заболеваниях сердца или лёгких, беременности и повторяющемся дискомфорте согласуй индивидуальный режим с врачом.',
          ),
          const SizedBox(height: 16),
          Text(
            'Что означает прогресс',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'Ступени 4/4 → 4,5/4,5 → 5/5 с и предложение увеличения после трёх комфортных занятий — продуктовая схема адаптации. Она не проверена как отдельная лечебная методика. Темп не меняется без твоего выбора; длиннее не значит лучше. Пропуск дня не меняет ступень. На 5/5 с предложения увеличения заканчиваются.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Отдельный ритм 4,5/5,5 с изучали по 15 минут перед сном в течение 30 дней. Субъективное качество сна улучшалось по сравнению с соцсетями. Стартовые 5 минут в приложении выбраны для удобства и не приравниваются к этому протоколу. Обзор 2026 года отмечает неоднозначные результаты объективных измерений сна.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Режим помогает выделить время для расслабления; он не гарантирует сон, не лечит бессонницу или апноэ и не накапливает кислород. Приложение не измеряет SpO₂, CO₂ и дыхательный объём. Возраст 35+ сам по себе не задаёт ритм. Связь этой прогрессии с Шаолинем не установлена.',
          ),
          const SizedBox(height: 16),
          Text('Источники', style: Theme.of(context).textTheme.titleLarge),
          for (final source in sources.entries)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.key),
                    SelectableText(source.value),
                    TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Скопировать адрес'),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: source.value),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Адрес скопирован')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
