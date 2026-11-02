import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/daily_tracker.dart';
import '../services/water_tracker.dart';
import '../theme/theme_controller.dart';
import 'consent_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _recordingEnabled = true;
  bool _notificationsEnabled = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool _loaded = false;
  bool _savingRecording = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _recordingEnabled = prefs.getBool('recordingEnabled') ?? true;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      _themeMode = ThemeController.themeMode.value;
      _loaded = true;
    });
  }

  Future<void> _saveRecording(bool value) async {
    if (_savingRecording) return;
    setState(() => _savingRecording = true);
    try {
      if (!value) await DailyTracker.disable();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('recordingEnabled', value);
    } catch (_) {
      if (mounted) {
        setState(() => _recordingEnabled = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось изменить режим записи.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingRecording = false);
    }
  }

  Future<void> _saveNotifications(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  void _onNotificationsChanged(bool value) {
    if (!value) {
      setState(() {
        _notificationsEnabled = false;
      });

      _saveNotifications(false);
      return;
    }

    _requestNotifications();
  }

  Future<void> _requestNotifications() async {
    final bool granted = await NotificationService.instance.requestPermission();

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = granted;
    });

    await _saveNotifications(granted);
    if (!mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Разрешение на уведомления не выдано.')),
      );
    }
  }

  Future<void> _deleteAll() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить все данные?'),
          content: const Text(
            'Будут удалены история, настройки и согласия. '
            'Действие необратимо.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // R-2: удаление в try/catch; при ошибке НЕ пушим ConsentScreen ложно «успешно».
    try {
      await DailyTracker.clear();
      await WaterTracker.clear();
      await StorageService.deleteAllData();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось удалить данные: $e')));

      return;
    }

    await ThemeController.load();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ConsentScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Как в системе';
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Тёмная';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Настройки')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                value: _recordingEnabled,
                onChanged: _savingRecording
                    ? null
                    : (bool value) {
                        setState(() {
                          _recordingEnabled = value;
                        });

                        _saveRecording(value);
                      },
                title: const Text('Разрешить запись активности'),
                subtitle: const Text(
                  'Выключение также останавливает дневной шагомер. Повторное включение не запускает его автоматически. Воду можно отмечать вручную.',
                ),
              ),

              const SizedBox(height: 8),

              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: _onNotificationsChanged,
                title: const Text('Уведомление тренировки'),
                subtitle: const Text(
                  'Не относится к служебному уведомлению дневного шагомера.',
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Тема',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<ThemeMode>(
                initialValue: _themeMode,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ThemeMode.values
                    .map(
                      (ThemeMode mode) => DropdownMenuItem<ThemeMode>(
                        value: mode,
                        child: Text(_themeLabel(mode)),
                      ),
                    )
                    .toList(),
                onChanged: (ThemeMode? mode) {
                  if (mode == null) {
                    return;
                  }

                  setState(() {
                    _themeMode = mode;
                  });

                  ThemeController.set(mode);
                },
              ),

              const SizedBox(height: 32),

              FilledButton.tonalIcon(
                onPressed: _deleteAll,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Удалить все данные'),
              ),

              const SizedBox(height: 32),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Приватность',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Приложение работает локально. '
                        'История тренировок, шагов, воды и настройки хранятся только на устройстве. '
                        'Данные не отправляются автоматически.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
