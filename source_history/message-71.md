
Собрал. Честная рамка перед кодом, чтобы потом не было иллюзий:

- Я **не компилирую и не запускаю** `apply_pack.py` — он исполняется у тебя. Статус всего, что он делает, — `APPLIED_BY_SCRIPT` после твоего `--apply`, и `VERIFIED` только после `flutter build` + устройств.
- Скрипт **не патчит вслепую там, где это опасно**: `R-5` (applicationId/namespace) и `R-8` (текст privacy на главной) он **не переписывает**, а диагностирует/оставляет на ручную правку. Причина: `applicationId` после первого AAB в сторе **неизменяем**, а редактура контента regex‑ом = хрупкость. Авто‑замена тут была бы вреднее пользы.
- Патч **идемпотентен и безопасен по умолчанию**: запуск без флагов = dry‑run с diff; запись только с `--apply`, каждый оригинал уходит в `.bak`.
- «Чистота разработки» соблюдена двумя механизмами: (1) `TASKS.md` — единый источник истины по статусам (даю целиком, без расхождения с чатом); (2) скрипт **сам дописывает** факт применения в секцию «Лог применения» — действие оставляет след автоматически, а не по моей памяти из ленты.

---

## 1. `apply_pack.py`

Клади в **корень flutter‑проекта** (рядом с `pubspec.yaml`). Если сайт‑статика лежит не в корне, поправь одну константу `SITE_DIR` внизу.

```python
#!/usr/bin/env python3
# apply_pack.py — точечное применение ревью-фиксов R-1..R-4, R-7 + аудиты R-5 и регресса.
# Запускать из корня flutter-проекта.  По умолчанию: DRY-RUN (только diff + аудиты).
#   python apply_pack.py            # dry-run: аудиты + diff, НИЧЕГО не пишет
#   python apply_pack.py --apply    # применить с бэкапом (.bak) + дописать лог в TASKS.md
#   python apply_pack.py --check    # только аудиты (R-5 + регресс), без diff и записи
import argparse
import difflib
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
FLUTTER_ROOT = HERE                 # корень flutter-проекта == где лежит скрипт
SITE_DIR = HERE                     # <-- ПОПРАВЬ, если index.html/site.webmanifest в подпапке (напр. HERE/"docs")
TASKS_FILE = HERE / "TASKS.md"
MANIFEST_PATH = SITE_DIR / "site.webmanifest"

# ---------------------------------------------------------------------------
# ЭТАЛОННЫЕ ФАЙЛЫ (уже содержат фиксы R-1 SafeArea, R-2 runZonedGuarded+try/catch,
# R-3 читаемая policy, R-7 AUTOINCREMENT).  r"""...""" => Dart-интерполяция ${}
# и escape \n уцелеют буквально (Python raw не трогает $, {}, \).
# ---------------------------------------------------------------------------
FILES = {
"lib/main.dart": r"""import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/consent_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() {
  // R-2: зональная защита от uncaught без crash-reporting (наружу не уходит).
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    await ThemeController.load();
    await NotificationService.instance.init();

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool privacyAccepted = prefs.getBool('privacyAccepted') ?? false;
    final bool ageConfirmed = prefs.getBool('ageConfirmed') ?? false;
    final bool offlineUnderstood = prefs.getBool('offlineUnderstood') ?? false;

    final bool hasConsent =
        privacyAccepted && ageConfirmed && offlineUnderstood;

    runApp(DvizhApp(showConsentFirst: !hasConsent));
  }, (Object error, StackTrace stack) {
    // Graceful degradation: логируем локально, не отправляем наружу.
    // Точечные UI-ошибки закрыты try/catch в экранах.
    debugPrint('Dvizh uncaught: $error');
  });
}

class DvizhApp extends StatelessWidget {
  final bool showConsentFirst;

  const DvizhApp({
    super.key,
    required this.showConsentFirst,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
        return MaterialApp(
          title: 'Движ',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: showConsentFirst ? const ConsentScreen() : const HomeScreen(),
        );
      },
    );
  }
}
""",

"lib/services/storage_service.dart": r"""import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/workout.dart';

class StorageService {
  static Database? _db;

  static Future<Database> get database async {
    final Database? current = _db;

    if (current != null) {
      return current;
    }

    final Database created = await _initDB();
    _db = created;

    return created;
  }

  static Future<Database> _initDB() async {
    final String path = join(await getDatabasesPath(), 'dvizh.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // R-7: AUTOINCREMENT, id назначает SQLite => нет коллизий по millis.
        await db.execute('''
          CREATE TABLE workouts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            startedAt TEXT NOT NULL,
            durationSeconds INTEGER NOT NULL,
            steps INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // R-7: вставляем БЕЗ id — ключ генерит SQLite.
  static Future<int> saveWorkout(Workout workout) async {
    final Database db = await database;

    final Map<String, Object?> row = <String, Object?>{
      'type': workout.type.name,
      'startedAt': workout.startedAt.toIso8601String(),
      'durationSeconds': workout.durationSeconds,
      'steps': workout.steps,
    };

    return db.insert('workouts', row);
  }

  static Future<List<Workout>> getAllWorkouts() async {
    final Database db = await database;

    final List<Map<String, Object?>> maps = await db.query(
      'workouts',
      orderBy: 'startedAt DESC',
    );

    return maps
        .map((Map<String, Object?> map) =>
            Workout.fromMap(map.cast<String, dynamic>()))
        .toList();
  }

  static Future<int> clearAll() async {
    final Database db = await database;
    return db.delete('workouts');
  }

  static Future<void> deleteAllData() async {
    final Database? current = _db;

    if (current != null) {
      await current.close();
      _db = null;
    }

    final String path = join(await getDatabasesPath(), 'dvizh.db');

    try {
      await deleteDatabase(path);
    } catch (_) {
      // Файл мог отсутствовать. Это не критично.
    }
  }
}
""",

"lib/screens/activity_screen.dart": r"""import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../models/workout.dart';
import '../services/notification_service.dart';
import '../services/sensor_service.dart';
import '../services/storage_service.dart';

class ActivityScreen extends StatefulWidget {
  final ActivityType activityType;

  const ActivityScreen({
    super.key,
    required this.activityType,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final SensorService _sensor = SensorService();

  Timer? _timer;
  DateTime? _startedAt;

  int _seconds = 0;
  int _steps = 0;
  bool _isRunning = false;

  Future<PermissionStatus> _requestMotionPermission() async {
    if (Platform.isAndroid) {
      return Permission.activityRecognition.request();
    }

    return Permission.sensors.request();
  }

  Future<void> _start() async {
    if (_isRunning) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool recordingEnabled = prefs.getBool('recordingEnabled') ?? true;

    if (!recordingEnabled) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запись отключена в настройках.'),
        ),
      );

      return;
    }

    final PermissionStatus status = await _requestMotionPermission();

    if (!status.isGranted) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Для подсчёта шагов нужен доступ к датчикам движения.',
          ),
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRunning = true;
      _startedAt = DateTime.now();
      _seconds = 0;
      _steps = 0;
    });

    _sensor.reset();

    _sensor.start((int steps) {
      if (_isRunning && mounted) {
        setState(() {
          _steps = steps;
        });
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning && mounted) {
        setState(() {
          _seconds++;
        });
      }
    });

    final bool notificationsEnabled =
        prefs.getBool('notificationsEnabled') ?? false;

    if (notificationsEnabled &&
        await NotificationService.instance.isPermissionGranted()) {
      await NotificationService.instance.showOngoing(
        'Движ',
        'Идёт запись: ${widget.activityType.title}',
      );
    }
  }

  Future<void> _stop() async {
    if (!_isRunning) {
      return;
    }

    _timer?.cancel();
    _timer = null;

    _sensor.stop();

    await NotificationService.instance.cancelOngoing();

    setState(() {
      _isRunning = false;
    });

    final DateTime? startedAt = _startedAt;

    if (startedAt == null) {
      return;
    }

    final Workout workout = Workout(
      id: DateTime.now().millisecondsSinceEpoch,
      type: widget.activityType,
      startedAt: startedAt,
      durationSeconds: _seconds,
      steps: _steps,
    );

    // R-2: ошибка диска/БД => понятное сообщение, без краша и без молчаливого pop.
    try {
      await StorageService.saveWorkout(workout);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить тренировку: $e')),
      );

      return; // остаёмся на экране
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Сохранено: $_steps шагов'),
      ),
    );

    Navigator.of(context).pop();
  }

  String _formatDuration(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;

    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensor.dispose();

    NotificationService.instance.cancelOngoing();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityType.title),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.activityType.icon,
                  size: 100,
                  color: primary,
                ),

                const SizedBox(height: 32),

                Text(
                  _formatDuration(_seconds),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBox(label: 'Шаги', value: '$_steps'),
                  ],
                ),

                const SizedBox(height: 48),

                FilledButton(
                  onPressed: _isRunning ? _stop : _start,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 64,
                      vertical: 20,
                    ),
                    backgroundColor: _isRunning ? Colors.red : primary,
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    _isRunning ? Icons.stop : Icons.play_arrow,
                    size: 48,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  _isRunning
                      ? 'Не закрывай приложение полностью, пока идёт запись.'
                      : 'Нажми play, чтобы начать запись.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
""",

"lib/screens/history_screen.dart": r"""import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/workout.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Workout> _workouts = <Workout>[];
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // R-2: ошибка БД => состояние «история недоступна», не краш.
    try {
      final List<Workout> workouts = await StorageService.getAllWorkouts();

      if (!mounted) {
        return;
      }

      setState(() {
        _workouts = workouts;
        _error = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _error = true);
    }
  }

  Future<void> _clear() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Очистить историю?'),
          content: const Text(
            'Будут удалены все сохранённые тренировки на этом устройстве.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // R-2: очистка в try/catch.
    try {
      await StorageService.clearAll();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось очистить историю: $e')),
      );

      return;
    }

    await _load();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('История очищена')),
    );
  }

  String _formatDuration(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;

    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    // R-1: SafeArea обязателен при включённом edgeToEdge (targetSdk 35).
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          IconButton(
            tooltip: 'Очистить историю',
            icon: const Icon(Icons.delete_outline),
            onPressed: _workouts.isEmpty ? null : _clear,
          ),
        ],
      ),
      body: SafeArea(
        child: _error
            ? const Center(
                child: Text('История временно недоступна. Попробуй позже.'),
              )
            : _workouts.isEmpty
                ? const Center(
                    child: Text('Пока нет сохранённых тренировок'),
                  )
                : ListView.builder(
                    itemCount: _workouts.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Workout workout = _workouts[index];

                      return ListTile(
                        leading: Icon(
                          workout.type.icon,
                          color: primary,
                        ),
                        title: Text(workout.type.title),
                        subtitle: Text(
                          '${DateFormat('dd.MM.yyyy HH:mm').format(workout.startedAt)}'
                          ' • ${_formatDuration(workout.durationSeconds)}'
                          ' • ${workout.steps} шагов',
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
""",

"lib/screens/settings_screen.dart": r"""import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recordingEnabled', value);
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
    final bool granted =
        await NotificationService.instance.requestPermission();

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = granted;
    });

    await _saveNotifications(granted);

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Разрешение на уведомления не выдано.'),
        ),
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
      await StorageService.deleteAllData();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить данные: $e')),
      );

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
        appBar: AppBar(
          title: const Text('Настройки'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                value: _recordingEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _recordingEnabled = value;
                  });

                  _saveRecording(value);
                },
                title: const Text('Разрешить запись активности'),
                subtitle: const Text(
                  'Если выключено, датчики не запускаются и тренировку нельзя начать.',
                ),
              ),

              const SizedBox(height: 8),

              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: _onNotificationsChanged,
                title: const Text('Показывать уведомление во время записи'),
                subtitle: const Text(
                  'Уведомление тихое и исчезает после остановки записи.',
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Тема',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<ThemeMode>(
                value: _themeMode,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
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
                        'История тренировок и настройки хранятся только на устройстве. '
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
""",

"lib/screens/consent_screen.dart": r"""import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _privacyAccepted = false;
  bool _ageConfirmed = false;
  bool _offlineUnderstood = false;

  bool get _canContinue =>
      _privacyAccepted && _ageConfirmed && _offlineUnderstood;

  // R-3: офлайн-текст policy, читаемый ВНУТРИ приложения (без WebView =>
  // без сетевого запроса, офлайн-дух не нарушается). Ссылка — текст для
  // пользователя, а не запрос.
  static const String _policyShort =
      'Движ работает офлайн и не имеет сервера. '
      'Приложение не собирает ФИО, email, телефон, адрес, геолокацию, вес и '
      'медицинские данные, не использует рекламу, аналитику и crash reporting, '
      'не отправляет данные разработчику или третьим лицам. '
      'История тренировок и настройки хранятся только на этом устройстве. '
      'Вы можете очистить историю или удалить все данные внутри приложения. '
      'Приложение не является медицинским изделием. '
      'Полный текст: https://duckolly.github.io/dvizh/privacy.html';

  void _showPolicy() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        builder: (BuildContext _, ScrollController c) =>
            SingleChildScrollView(
          controller: c,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Политика конфиденциальности',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SelectableText(_policyShort),
              const SizedBox(height: 16),
              const Text(
                'Полная версия доступна по ссылке выше и в файле PRIVACY.md '
                'репозитория.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('privacyAccepted', true);
    await prefs.setBool('ageConfirmed', true);
    await prefs.setBool('offlineUnderstood', true);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Движ'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Приватность прежде всего',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Это офлайн-приложение для локального учёта активности.\n\n'
                'Оно:\n'
                '• не требует регистрации;\n'
                '• не отправляет данные на сервер;\n'
                '• не использует рекламу;\n'
                '• не использует аналитику;\n'
                '• хранит историю только на этом устройстве.',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              // R-3: доступ к тексту ДО чекбокса «ознакомился».
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _showPolicy,
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Читать политику конфиденциальности'),
                ),
              ),

              const SizedBox(height: 8),

              CheckboxListTile(
                value: _privacyAccepted,
                onChanged: (bool? value) {
                  setState(() {
                    _privacyAccepted = value ?? false;
                  });
                },
                title: const Text(
                  'Я ознакомился с политикой конфиденциальности',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                value: _ageConfirmed,
                onChanged: (bool? value) {
                  setState(() {
                    _ageConfirmed = value ?? false;
                  });
                },
                title: const Text(
                  'Мне исполнилось 14 лет, либо я использую приложение '
                  'с согласия законного представителя',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                value: _offlineUnderstood,
                onChanged: (bool? value) {
                  setState(() {
                    _offlineUnderstood = value ?? false;
                  });
                },
                title: const Text(
                  'Я понимаю, что данные не передаются автоматически '
                  'и хранятся только на устройстве',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const Spacer(),

              FilledButton(
                onPressed: _canContinue ? _continue : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Продолжить'),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text('Не согласен'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",
}

# R-4: site.webmanifest с корректным базовым путём GitHub Pages (под /dvizh/).
MANIFEST_CONTENT = r"""{
  "name": "Движ — офлайн счётчик активности",
  "short_name": "Движ",
  "description": "Локальный трекер ходьбы, бега и зарядки. Без аккаунта, интернета, рекламы и аналитики.",
  "start_url": "/dvizh/",
  "scope": "/dvizh/",
  "display": "standalone",
  "background_color": "#0B1A3C",
  "theme_color": "#0B1A3C",
  "lang": "ru",
  "icons": [
    { "src": "assets/branding/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "assets/branding/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "assets/branding/icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
""",

# ---------------------------------------------------------------------------
# Регресс-аудит: токены, которые НЕ должны вернуться (закрытие N1..N6).
# Скрипт эти файлы НЕ патчит — находки = подсказка править вручную.
# ---------------------------------------------------------------------------
REGRESS_SCOPES = {
    "lib": [
        "Colors.orange", "#ff7a00", "HealthApplication", "nickname",
        "groupCode", "calories", "weight", "flutter_foreground_task",
        "share_plus",
    ],
    "pubspec.yaml": [
        "flutter_foreground_task", "share_plus", "pdf:", "path_provider", "csv",
    ],
    "index.html": ["#ff7a00", "orange", "HealthApplication", "brandbook"],
    "privacy.html": ["brandbook"],
}


def _iter_scope(scope: str):
    if scope == "lib":
        lib = FLUTTER_ROOT / "lib"
        if lib.exists():
            yield from lib.rglob("*.dart")
        return
    # одиночный файл относительно SITE_DIR (html) или FLUTTER_ROOT (pubspec)
    base = FLUTTER_ROOT if scope.endswith(".yaml") else SITE_DIR
    p = base / scope
    if p.exists():
        yield p


def regress_audit() -> tuple[str, list[str]]:
    hits: list[str] = []
    for scope, tokens in REGRESS_SCOPES.items():
        for path in _iter_scope(scope):
            try:
                text = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            for i, line in enumerate(text.splitlines(), 1):
                for tok in tokens:
                    if tok in line:
                        rel = path.relative_to(HERE) if path.is_relative_to(HERE) else path
                        hits.append(f"{rel}:{i}: [{tok}] {line.strip()[:90]}")
    status = "PASS" if not hits else "FAIL"
    return status, hits


def audit_r5() -> tuple[str, list[str]]:
    """R-5: сверка namespace/applicationId (build.gradle) с пакетом MainActivity.
    Read-only: НЕ меняем applicationId автоматически (неизменяем после 1-го AAB)."""
    msgs: list[str] = []
    gradle = FLUTTER_ROOT / "android" / "app" / "build.gradle"
    ns = aid = pkg = None

    if gradle.exists():
        t = gradle.read_text(encoding="utf-8", errors="replace")
        m = re.search(r'namespace\s*=\s*["\']([^"\']+)["\']', t)
        ns = m.group(1) if m else None
        m = re.search(r'applicationId\s*=\s*["\']([^"\']+)["\']', t)
        aid = m.group(1) if m else None
    else:
        msgs.append("build.gradle не найден — пропустил R-5 аудит")

    main = None
    for cand in FLUTTER_ROOT.rglob("MainActivity.*"):
        if "android/app/src/main" in str(cand):
            main = cand
            break
    if main is not None:
        t = main.read_text(encoding="utf-8", errors="replace")
        m = re.search(r'^\s*package\s+([\w.]+)', t, re.M)
        pkg = m.group(1) if m else None
    else:
        msgs.append("MainActivity не найден — пропустил R-5 аудит")

    if ns is None or pkg is None:
        status = "WARN"
        msgs.append(f"namespace={ns!r}, MainActivity.package={pkg!r} — проверь вручную")
    elif ns != pkg:
        status = "ERROR"
        msgs.append(
            f"РАСХОЖДЕНИЕ R-5: build.gradle namespace={ns!r} != пакет MainActivity={pkg!r}. "
            f"Сборка упадёт. Исправь ВРУЧНУЮ: приведи namespace к {pkg!r} "
            f"(или перенеси MainActivity в папку {ns!r}). applicationId после 1-го релиза менять нельзя."
        )
    else:
        status = "OK"
        msgs.append(f"R-5 OK: namespace == MainActivity.package == {ns!r}")

    if aid is not None and ns is not None and aid != ns:
        msgs.append(f"INFO: applicationId={aid!r} != namespace={ns!r} (допустимо, но проверь намеренность)")

    return status, msgs


def _diff(name: str, old: str | None, new: str) -> None:
    if old is None:
        print(f"  [NEW]      {name}")
        return
    if old == new:
        print(f"  [SAME]     {name}")
        return
    d = list(difflib.unified_diff(
        old.splitlines(), new.splitlines(),
        fromfile=f"a/{name}", tofile=f"b/{name}", lineterm=""))
    print(f"  [CHANGED]  {name}  ({len(d)} diff-строк)")
    for line in d[:50]:
        print("     " + line)
    if len(d) > 50:
        print(f"     ... ещё {len(d) - 50} строк (смотри файл после --apply)")


def dry_run() -> None:
    print("DRY-RUN — ничего не записываю. Для записи: python apply_pack.py --apply\n")
    print("Файлы flutter (перезапись с .bak):")
    for rel, content in FILES.items():
        target = FLUTTER_ROOT / rel
        old = target.read_text(encoding="utf-8") if target.exists() else None
        _diff(rel, old, content)
    print("\nФайл сайта (перезапись с .bak):")
    old = MANIFEST_PATH.read_text(encoding="utf-8") if MANIFEST_PATH.exists() else None
    _diff(str(MANIFEST_PATH.relative_to(HERE)), old, MANIFEST_CONTENT)


def apply() -> list[str]:
    written: list[str] = []
    for rel, content in FILES.items():
        target = FLUTTER_ROOT / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            target.with_suffix(target.suffix + ".bak").write_bytes(target.read_bytes())
        target.write_text(content, encoding="utf-8")
        written.append(rel)
        print(f"  written: {rel}")

    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    if MANIFEST_PATH.exists():
        MANIFEST_PATH.with_suffix(".webmanifest.bak").write_bytes(MANIFEST_PATH.read_bytes())
    MANIFEST_PATH.write_text(MANIFEST_CONTENT, encoding="utf-8")
    written.append(str(MANIFEST_PATH.relative_to(HERE)))
    print(f"  written: {written[-1]}")
    return written


LOG_HEADER = "## Лог применения автопатчей"


def append_log(written: list[str], r5: str, reg: str) -> None:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%MZ")
    line = (f"- {ts} `apply_pack.py --apply`: files={len(written)}; "
            f"R5={r5}; regress={reg}; written={', '.join(written) if written else '-'}")
    text = TASKS_FILE.read_text(encoding="utf-8") if TASKS_FILE.exists() else "# TASKS\n"
    if LOG_HEADER not in text:
        text = text.rstrip() + f"\n\n{LOG_HEADER}\n_(скрипт дописывает сюда факт применения; журнал, не идемпотентен)_\n\n"
    text = text.rstrip() + "\n" + line + "\n"
    TASKS_FILE.write_text(text, encoding="utf-8")
    print(f"\nЛог применения дописан в {TASKS_FILE.name}")


def print_audits(r5: str, r5_msgs: list[str], reg: str, reg_hits: list[str]) -> None:
    print("\n=== АУДИТ R-5 (read-only, НЕ меняем applicationId) ===")
    for m in r5_msgs:
        print("  " + m)
    print(f"  => R-5 статус: {r5}")

    print("\n=== РЕГРЕСС-АУДИТ N1..N6 (эти файлы скрипт НЕ патчит) ===")
    if reg_hits:
        for h in reg_hits:
            print("  REGRESSION " + h)
        print("  => регресс: FAIL — правь найденное ВРУЧНУЮ (оранжевый/Health/brandbook/удалённые поля).")
    else:
        print("  => регресс: PASS — запрещённые токены не обнаружены.")


def main() -> int:
    ap = argparse.ArgumentParser(description="Dvizh review-pack applier (dry-run by default)")
    ap.add_argument("--apply", action="store_true", help="записать файлы (с .bak) + дописать лог")
    ap.add_argument("--check", action="store_true", help="только аудиты, без diff и записи")
    args = ap.parse_args()

    r5, r5_msgs = audit_r5()
    reg, reg_hits = regress_audit()

    if args.check:
        print_audits(r5, r5_msgs, reg, reg_hits)
        return 0

    if args.apply:
        print("APPLY — записываю (оригиналы -> .bak):\n")
        written = apply()
        print_audits(r5, r5_msgs, reg, reg_hits)
        append_log(written, r5, reg)
        print("\nГотово. Дальше: flutter clean && flutter pub get && flutter analyze && flutter build appbundle --release")
        if r5 == "ERROR":
            print("ВНИМАНИЕ: R-5 ERROR — исправь namespace/package ВРУЧНУЮ до сборки, иначе билд упадёт.")
        return 0

    dry_run()
    print_audits(r5, r5_msgs, reg, reg_hits)
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

---

## 2. `TASKS.md` — единый источник истины (заменить целиком)

Здесь зафиксировано и «что поставил», и «что выполнил», и кто верифицирует. Статусы: `CLOSED` (решение зафиксировано/применено), `APPLIED_BY_SCRIPT` (пишет `apply_pack --apply`), `AUDIT_ONLY` (скрипт диагностирует, правка ручная), `MANUAL` (редактура/конфиг руками), `TODO` (не начато), `VERIFIED` (только после твоей сборки/устройств — пока ни одной задачи в `VERIFIED` нет, и это честно).

```markdown
# Трекер задач и релизов — Движ

## Статусы
- TODO — не начато
- APPLIED_BY_SCRIPT — применяется apply_pack.py --apply (до запуска = PATCH_READY)
- AUDIT_ONLY — скрипт диагностирует, правка ВРУЧНУЮ (автозамена опасна)
- MANUAL — редактура/конфиг руками
- CLOSED — решение зафиксировано и применено
- VERIFIED — проверено сборкой/устройством (ставит только maintainer)

---

## Консистентность бренда/контента (N1..N6) — CLOSED

| ID | Что закрыто | Финальное значение | Где источник истины |
|----|-------------|--------------------|---------------------|
| N-1 | applicationCategory | LifestyleApplication (Health отменён) | JSON-LD в index.html |
| N-2 | палитра сайта | #0A3BFF/#B7FF00/#00E5FF/#0B1A3C/#F4F6FA; оранжевый мёртв | :root + theme-color в index.html |
| N-3 | brandbook публично | исключён из витрин/постов v3.2.0, только внутр. vision | README «Public assets» + BRAND_LICENSE |
| N-4 | alt брендбука | для поста удалён; как концепт — маркируется vision | alt-таблица (не публичная) |
| N-5 | offers/валюта | RUB в сайт-JSON-LD, НЕ переносится в store listing | комментарий-страж в JSON-LD |
| N-6 | развилка-ловушка | опасных развилок в коде нет, выбор — в комментарии | JSON-LD |

Регресс-страж: `apply_pack.py` при каждом запуске сканирует lib/, pubspec.yaml,
index.html, privacy.html на возврат запрещённых токенов и печатает PASS/FAIL.

---

## Ревью-фиксы (проход R)

| ID | Severity | Слой | Статус | Что делает apply_pack | Как проверить (VERIFIED) |
|----|----------|------|--------|-----------------------|--------------------------|
| R-1 | MUST | HistoryScreen SafeArea при edgeToEdge | APPLIED_BY_SCRIPT | перезапись history_screen.dart | Android 14/15 свайп-навигация: последний элемент не под панелью |
| R-2 | MUST | runZonedGuarded + try/catch БД-операций | APPLIED_BY_SCRIPT | перезапись main/activity/history/settings | повредить БД через adb → SnackBar, не краш, не белый экран |
| R-3 | MUST | читаемая policy в consent (informed) | APPLIED_BY_SCRIPT | перезапись consent_screen.dart | до согласия доступна кнопка «Читать политику»; офлайн не нарушен |
| R-4 | MUST | site.webmanifest base-path /dvizh/ | APPLIED_BY_SCRIPT | перезапись site.webmanifest | установка PWA с /dvizh/ открывает /dvizh/, не корень домена |
| R-5 | MUST | namespace/applicationId == пакет MainActivity | AUDIT_ONLY | диагностика, НЕ меняет gradle | flutter build appbundle проходит; applicationId зафиксирован ДО 1-го AAB |
| R-6 | SHOULD | uses-feature accelerometer required=false | MANUAL | не трогает | aapt dump badging: акселерометр не required |
| R-7 | SHOULD | PK AUTOINCREMENT без ручной вставки id | APPLIED_BY_SCRIPT | перезапись storage_service.dart | две быстрые тренировки подряд сохраняются без коллизии |
| R-8 | SHOULD | privacy: резюме на главной + полная в privacy.html | MANUAL | не трогает index.html | на главной нет дубля полного текста; CTA ведёт на /privacy.html |
| R-9 | NICE | lazy-инициализация уведомлений после consent | MANUAL | не трогает | init уведомлений не до consent (опц.) |
| R-10 | NICE | альфа углов icon.png (квадрат на API<26) | MANUAL | не трогает | открыть icon.png: углы прозрачные или на #0B1A3C |
| R-11 | NICE | живость GitHub-ссылок до подачи | MANUAL | не трогает | github.com/Duckolly/dvizh не 404 |

### Готовые ручные вставки (MANUAL)

R-6 — в AndroidManifest.xml рядом с uses-permission:
```xml
<uses-feature android:name="android.hardware.sensor.accelerometer" android:required="false" />
```

R-8 — заменить полную секцию privacy в index.html на резюме + CTA:
```html
<section id="privacy" class="section container">
  <h2>Приватность</h2>
  <p>Движ работает офлайн и не имеет сервера. Не собираем ФИО, email, телефон,
  адрес, геолокацию, вес и медицинские данные. Без рекламы, аналитики и
  crash reporting. История хранится только на устройстве; её и все данные
  можно удалить внутри приложения. Приложение не является медицинским изделием.</p>
  <a class="btn btn-secondary" href="privacy.html">Полная политика конфиденциальности</a>
</section>
```

R-5 — если аудит дал ERROR: привести `namespace` в build.gradle к фактическому
пакету MainActivity (или перенести MainActivity в папку namespace). Финальный
`applicationId` зафиксировать ДО первой загрузки AAB — после релиза не менять.

---

## Релиз v3.2.0 Local-Only (ранее закрытые REMOVE/CODE/MANIFEST/REL)

REMOVE-001..005 (вес/калории/никнеймы/группы/PDF+share/foreground) — CLOSED.
CODE-010..014 (consent/master-toggle/notif-toggle/clear-history/delete-all) — CLOSED (в эталоне).
MANIFEST-002 (hardened) — CLOSED. REL-001..004 (SDK35/signing/notif-hardening/edge2edge) — CLOSED.
REL-005..010 (privacy URL / Data Safety / content rating / closed-testing / store listing / smoke) — TODO (консоль+устройства, не код).

---

## Лог применения автопатчей
_(скрипт дописывает сюда факт применения; журнал, не идемпотентен)_
```

---

## 3. Как прогнать (3 шага, по порядку)

```bash
# 1. КЛАДЁШЬ apply_pack.py в корень flutter-проекта (рядом с pubspec.yaml).
#    Если сайт-статика (index.html/site.webmanifest) НЕ в корне — поправь SITE_DIR в шапке скрипта.

# 2. DRY-RUN: смотришь diff + аудиты, НИЧЕГО не пишется.
python apply_pack.py

# 3. Если diff и аудиты устраивают — применяешь (оригиналы уйдут в .bak):
python apply_pack.py --apply

# 4. Только аудиты без diff/записи (например, проверить регресс после ручных правок):
python apply_pack.py --check
```

Что делать по результатам, честно и по веткам:

- **Регресс = PASS, R-5 = OK** → жмёшь `--apply`, потом `flutter clean && flutter pub get && flutter analyze && flutter build appbundle --release`. Это закрывает R-1,R-2,R-3,R-4,R-7 механически.
- **R-5 = ERROR** → скрипт НЕ чинит gradle (и правильно делает). Правь `namespace`/пакет вручную по инструкции в `TASKS.md`, затем `--check`, пока не станет OK, и только потом сборка. Не игнорируй: это самый вероятный технический отказ сборки.
- **Регресс = FAIL по index.html/pubspec.yaml** → это НЕ баг скрипта (он эти файлы не трогает), а сигнал, что оранжевый/`HealthApplication`/`brandbook`/запрещённые зависимости всё ещё где-то в публичных файлах. Выпиши найденные `файл:строка` из вывода и правь вручную; после правки `--check` должен дать PASS.
- **R-6, R-8..R-11** → ручные вставки из `TASKS.md`; скрипт их сознательно не делает (контент/конфиг/проверка альфы — не место regex‑патчеру).

---

## 4. Итог и что осталось на тебе

Выполнено механически (после `--apply`): **R-1, R-2, R-3, R-4, R-7** — эталонные файлы с фиксами записаны, оригиналы в `.bak`, факт применения авто-дописан в `TASKS.md`. Зафиксировано решениями и защищено регресс-стражем: **N1..N6**. Оставлено на ручную правку намеренно, потому что автозамена была бы вреднее: **R-5** (неизменяемый после релиза `applicationId` — только аудит), **R-6, R-8..R-11** (манифест‑строка, редактура контента, проверка альфы, живость ссылок).

Чистота учёта соблюдена: один `TASKS.md` = единственный источник статусов (никаких «я в чате сказал одно, а в файле другое»), плюс автоматический журнал применений, который скрипт ведёт сам, а не по моей памяти из ленты.

Что я **не** подтверждаю и что даёшь ты как архитектор: `flutter analyze`/`test`/`build appbundle --release` зелёные (особенно после R-5); `aapt dump permissions/badging` на итоговом AAB (нет `INTERNET`/location/camera, акселерометр `required=false`); запуск на API 26+ (адаптивная иконка, safe-zone) и API 23–25 (legacy‑иконка, углы по R-10), плюс Xiaomi/Tecno на background‑kill; Schema.org Validator после R-3/R-8; Lighthouse на CLS/404 после R-4; Search Console/Вебмастер на canonical и отсутствие дубля после R-8; заполнение Data Safety/content rating/privacy URL в консоли.

Статус пакета: **APPLIED_BY_SCRIPT / AUDIT_DONE**, `VERIFIED` — за тобой сборкой.

Следующий открытый хвост из нашего списка — **(б) feature‑graphic на тёмном фоне**: для него нужен светлый/белый `wordmark`, которого в ассетах нет (текущий с тёмно‑синими буквами на `#0B1A3C` нечитаем). Скажи, генерим белый логотип из `mark.png` + типографики отдельным экспортом, или закрываем витрину на светлом варианте (`#F4F6FA`, уже в `og-cover`/`feature-graphic` из прошлого экспорта). Либо, если приоритет сместился, гони вывод `flutter build appbundle --release` после `--apply` и `--check` — разберу ошибки построчно, первым делом по R-5, где чаще всего и стреляет.