import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../theme/app_theme.dart';
import '../widgets/daily_summary.dart';
import '../widgets/water_summary.dart';
import 'activity_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'snake_screen.dart';
import 'sensors_screen.dart';
import 'breathing_screen.dart';
import 'altitude_screen.dart';
import 'sky_screen.dart';
import 'battery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selected = 0;
  void _open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));
  Widget _entry(
    String title,
    String subtitle,
    IconData icon,
    Widget screen, {
    Color? color,
  }) => Card(
    color: color,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(screen),
    ),
  );
  Widget _rest() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Пауза для себя',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text('Без спешки. В своём темпе.'),
      const SizedBox(height: 20),
      _entry(
        'Подышать',
        'Для сна, утра и после занятий',
        Icons.air,
        const BreathingScreen(),
        color: OrbitColors.peach(context),
      ),
      _entry(
        'Ночное небо',
        'Звёзды по городу и времени · офлайн',
        Icons.nights_stay_outlined,
        const SkyScreen(),
        color: OrbitColors.lavender(context),
      ),
      _entry(
        'Бегалка',
        'Небольшая игра без интернета',
        Icons.sports_esports_outlined,
        const SnakeScreen(),
      ),
    ],
  );
  Widget _today() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          Text(
            'Сегодня',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text('Шаги и вода', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      const SizedBox(height: 8),
      const DailySummary(),
      const WaterSummary(),
      const SizedBox(height: 12),
      _entry(
        'Подышать',
        'Пауза для себя',
        Icons.air,
        const BreathingScreen(),
        color: OrbitColors.peach(context),
      ),
      _entry(
        'Ночное небо',
        'Посмотреть на звёзды',
        Icons.nights_stay_outlined,
        const SkyScreen(),
        color: OrbitColors.lavender(context),
      ),
      const SizedBox(height: 20),
      Text('Тренировки', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      ...ActivityType.values.map(
        (a) => _entry(
          a.title,
          'Записать тренировку',
          a.icon,
          ActivityScreen(activityType: a),
        ),
      ),
      const SizedBox(height: 20),
      Text('Инструменты', style: Theme.of(context).textTheme.titleLarge),
      _entry(
        'Батарея и нагрузка',
        'Ручной замер и управление шагомером',
        Icons.battery_saver_outlined,
        const BatteryScreen(),
      ),
      _entry(
        'Перепад высоты',
        'Относительная оценка по барометру',
        Icons.terrain_outlined,
        const AltitudeScreen(),
      ),
      _entry(
        'Датчики телефона',
        'Доступные датчики устройства',
        Icons.sensors,
        const SensorsScreen(),
      ),
      _entry(
        'Бегалка',
        'Игра без интернета',
        Icons.sports_esports_outlined,
        const SnakeScreen(),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _selected == 0 || _selected == 2
        ? AppBar(
            title: const Text('Движ'),
            actions: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 16),
                      SizedBox(width: 6),
                      Text('Офлайн'),
                    ],
                  ),
                ),
              ),
            ],
          )
        : null,
    body: SafeArea(
      child: switch (_selected) {
        1 => const HistoryScreen(),
        2 => _rest(),
        3 => const SettingsScreen(),
        _ => _today(),
      },
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selected,
      onDestinationSelected: (index) => setState(() => _selected = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Сегодня',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'История',
        ),
        NavigationDestination(icon: Icon(Icons.spa_outlined), label: 'Отдых'),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Настройки',
        ),
      ],
    ),
  );
}
