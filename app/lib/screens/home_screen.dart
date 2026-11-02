import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'snake_screen.dart';
import 'sensors_screen.dart';
import 'breathing_screen.dart';
import 'altitude_screen.dart';
import 'sky_screen.dart';
import 'battery_screen.dart';
import '../widgets/daily_summary.dart';
import '../widgets/water_summary.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Движ'),
        actions: [
          IconButton(
            tooltip: 'История',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: primary, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Локальный режим. Данные остаются на устройстве.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.battery_saver_outlined),
                title: const Text('Батарея и нагрузка'),
                subtitle: const Text('Ручной замер и управление шагомером'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BatteryScreen(),
                  ),
                ),
              ),
            ),
            const DailySummary(),
            const WaterSummary(),
            const SizedBox(height: 24),
            const Text(
              'Выбери активность',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ActivityType.values.map(
              (activity) => Card(
                child: ListTile(
                  leading: Icon(activity.icon, color: primary, size: 32),
                  title: Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ActivityScreen(activityType: activity),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Отдых и инструменты',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sports_esports_outlined),
                title: const Text('Бегалка'),
                subtitle: const Text('Игра без интернета'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SnakeScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.air),
                title: const Text('Дыхание'),
                subtitle: const Text('Для сна, утра и после занятий'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BreathingScreen(),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.terrain_outlined),
                title: const Text('Перепад высоты'),
                subtitle: const Text('Относительная оценка по барометру'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AltitudeScreen(),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.nights_stay_outlined),
                title: const Text('Ночное небо'),
                subtitle: const Text('Звёзды по городу и времени · офлайн'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SkyScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sensors),
                title: const Text('Датчики телефона'),
                subtitle: const Text('Что реально доступно на устройстве'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SensorsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
