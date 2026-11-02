
Да — отметил в `TASKS.md`, собрал файлы для нового релиза **v3.2.0 Local-Only** и провёл статическую проверку кода.

Важно: я **не могу скомпилировать Flutter-проект** и запустить его на устройстве, поэтому статус всех задач ниже — **`CODE_READY`**, а не `VERIFIED`. Финальную проверку дадут `flutter analyze`, сборка и ручной тест.

---

# 1. Что сделано в релизе v3.2.0

## Убрано полностью

- вес;
- калории;
- никнеймы;
- коды групп;
- экспорт PDF;
- share / отправка файлов;
- foreground service;
- зависимость `flutter_foreground_task`;
- зависимость `pdf`;
- зависимость `share_plus`;
- зависимость `path_provider`, если она не нужна.

## Добавлено / исправлено

- экран согласия `ConsentScreen`;
- подтверждение возраста;
- подтверждение понимания офлайн-режима;
- master toggle «Разрешить запись»;
- toggle «Показывать уведомление во время записи»;
- очистка истории;
- удаление всех данных;
- тёмная / светлая / системная тема;
- исправленная интерполяция таймера;
- запрос разрешения на датчики движения только после согласия;
- уведомления только если пользователь включил toggle;
- усиленный `AndroidManifest.xml`;
- отключение backup;
- `data_extraction_rules.xml`;
- `PRIVACY.md`;
- `README.md`;
- `LICENSE`;
- `CHANGELOG.md`;
- `RELEASE_NOTES_v3.2.0.md`.

---

# 2. Обновлённый `TASKS.md`

Сохрани как `TASKS.md` в корне проекта.

```markdown
# 🐛 Трекер задач и релизов — Движ

## Статусы
- 🔴 TODO — не начато
- 🟡 CODE_READY — код подготовлен, ожидает компиляции и ручного теста
- 🟢 VERIFIED — проверено на устройстве
- ⚪ DEFERRED — отложено

---

## Релиз v3.2.0 Local-Only

### BUG-001: Ошибка интерполяции строк в таймере 🟡 CODE_READY
**Файл:** `app/lib/screens/activity_screen.dart`  
**Проблема:** Была некорректная строка с экранированным символом валюты.  
**Фикс:** Исправлена интерполяция времени.  
**Проверка после сборки:** Таймер отображается как `00:00:30`.

---

### BUG-002: Нет корректного запроса разрешения на датчики движения 🟡 CODE_READY
**Файл:** `app/lib/screens/activity_screen.dart`  
**Проблема:** Разрешение не запрашивалось до начала записи.  
**Фикс:** Добавлен запрос `Permission.activityRecognition.request()` после consent и при включённой записи.  
**Проверка после сборки:** При первом нажатии «Начать» появляется системный запрос разрешения.

---

### REMOVE-001: Удалить сбор веса 🟡 CODE_READY
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/models/workout.dart`
- `app/lib/screens/activity_screen.dart`

**Действие:**
- удалено поле веса;
- удалён расчёт калорий;
- вес не сохраняется локально.

**Проверка после сборки:**
- в настройках нет веса;
- в истории нет калорий;
- в локальной БД нет поля калорий.

---

### REMOVE-002: Удалить никнеймы 🟡 CODE_READY
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/screens/consent_screen.dart`
- `app/lib/screens/history_screen.dart`

**Действие:**
- удалён ввод имени/ника;
- никнейм не сохраняется;
- в истории нет идентификатора пользователя.

**Проверка после сборки:**
- нигде нет поля для ввода имени;
- в `SharedPreferences` нет ключа никнейма.

---

### REMOVE-003: Удалить коды групп 🟡 CODE_READY
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/screens/history_screen.dart`

**Действие:**
- удалён код группы;
- групповой режим не используется;
- приложение не формирует групповые отчёты.

**Проверка после сборки:**
- нет поля «код группы»;
- нет групповой логики.

---

### REMOVE-004: Удалить foreground service 🟡 CODE_READY
**Файлы:**
- `app/pubspec.yaml`
- `app/lib/screens/activity_screen.dart`
- `app/android/app/src/main/AndroidManifest.xml`

**Действие:**
- удалена зависимость foreground service;
- удалены вызовы запуска/остановки сервиса;
- оставлено только обычное локальное уведомление, если пользователь включил уведомления.

**Проверка после сборки:**
- в зависимостях нет foreground service;
- в манифесте нет активного разрешения на foreground service.

---

### REMOVE-005: Отключить PDF и share 🟡 CODE_READY
**Файлы:**
- `app/pubspec.yaml`
- `app/lib/screens/history_screen.dart`

**Действие:**
- удалён PDF-экспорт;
- удалён share;
- удалены соответствующие зависимости.

**Проверка после сборки:**
- нет кнопки экспорта;
- нет системного диалога отправки файла.

---

### CODE-010: Privacy consent screen 🟡 CODE_READY
**Новый файл:**
- `app/lib/screens/consent_screen.dart`

**Действие:**
- показывается при первом запуске;
- требует согласия с политикой;
- требует подтверждения возраста;
- требует подтверждения понимания офлайн-режима;
- до согласия не запрашиваются разрешения.

**Проверка после сборки:**
- при первом запуске открывается consent;
- кнопка «Продолжить» активна только после всех галочек.

---

### CODE-011: Master toggle «Разрешить запись» 🟡 CODE_READY
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/screens/activity_screen.dart`

**Действие:**
- добавлен локальный флаг `recordingEnabled`;
- если выключен, кнопка «Начать» не запускает датчики;
- пользователь видит пояснение.

**Проверка после сборки:**
- выключить запись;
- попробовать начать тренировку;
- приложение не запрашивает датчики и не считает шаги.

---

### CODE-012: Toggle уведомлений 🟡 CODE_READY
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/services/notification_service.dart`
- `app/lib/screens/activity_screen.dart`

**Действие:**
- добавлен локальный флаг `notificationsEnabled`;
- если выключен, уведомление не показывается;
- если включён, запрашивается разрешение на уведомления.

**Проверка после сборки:**
- выключить уведомления;
- начать запись;
- уведомление не появляется.

---

### CODE-013: Очистить историю 🟡 CODE_READY
**Файлы:**
- `app/lib/screens/history_screen.dart`
- `app/lib/services/storage_service.dart`

**Действие:**
- добавлена кнопка очистки истории;
- есть confirmation dialog;
- удаляются все тренировки из локальной БД.

**Проверка после сборки:**
- провести тренировку;
- очистить историю;
- список пуст;
- после перезапуска всё ещё пусто.

---

### CODE-014: Удалить все данные 🟡 CODE_READY
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/services/storage_service.dart`

**Действие:**
- удаляется локальная БД;
- очищаются `SharedPreferences`;
- есть confirmation dialog;
- приложение возвращается к экрану согласия.

**Проверка после сборки:**
- нажать «Удалить все данные»;
- подтвердить;
- проверить, что история, настройки и согласия сброшены.

---

### MANIFEST-002: Harden AndroidManifest 🟡 CODE_READY
**Файл:**
- `app/android/app/src/main/AndroidManifest.xml`

**Действие:**
- явно удалены потенциально лишние разрешения через `tools:node="remove"`;
- отключён backup;
- добавлены правила извлечения данных;
- оставлены только необходимые разрешения.

**Проверка после сборки:**
```bash
aapt dump permissions build/app/outputs/flutter-apk/app-debug.apk
```

Ожидаемо допустимо:
```text
android.permission.ACTIVITY_RECOGNITION
android.permission.POST_NOTIFICATIONS
```

Недопустимо:
```text
android.permission.INTERNET
android.permission.ACCESS_FINE_LOCATION
android.permission.ACCESS_COARSE_LOCATION
android.permission.CAMERA
android.permission.RECORD_AUDIO
android.permission.READ_CONTACTS
com.google.android.gms.permission.AD_ID
```

---

### DOC-001: PRIVACY.md 🟡 CODE_READY
**Действие:**
- добавлен файл политики конфиденциальности.

**Проверка:**
- файл присутствует в репозитории;
- перед публикацией в Google Play нужен публичный URL.

---

### DOC-002: LICENSE 🟡 CODE_READY
**Действие:**
- добавлена MIT-лицензия.

**Проверка:**
- заменить `[Имя владельца]` и год перед публичным релизом.

---

### DOC-003: README.md 🟡 CODE_READY
**Действие:**
- добавлено описание проекта;
- добавлен дисклеймер, что приложение не медицинское;
- указано, что приложение офлайн и open source.

---

### TEST-008: Store-safe smoke test 🔴 TODO
**Проверить вручную:**
- первый запуск;
- consent;
- отказ от разрешений;
- включение записи;
- выключение записи;
- очистка истории;
- удаление всех данных;
- отсутствие уведомлений при выключенном toggle;
- отсутствие интернета в merged manifest.

---

### TEST-009: Flutter static checks 🔴 TODO
**Команды:**
```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

---

## Лог изменений

| Дата | Задача | Статус | Комментарий |
|------|--------|--------|-------------|
| 2026-10-31 | v3.2.0 Local-Only | 🟡 CODE_READY | Подготовлены файлы релиза |
| 2026-10-31 | REMOVE-001..005 | 🟡 CODE_READY | Убраны вес, калории, группы, никнеймы, PDF, share, foreground service |
| 2026-10-31 | CODE-010..014 | 🟡 CODE_READY | Добавлены consent, toggles, очистка и удаление данных |
| 2026-10-31 | MANIFEST-002 | 🟡 CODE_READY | Манифест усилен |
| 2026-10-31 | DOC-001..003 | 🟡 CODE_READY | Добавлены privacy, license, readme |
```

---

# 3. Файлы фикса

Ниже — файлы, которые нужно создать или заменить.

---

## 3.1. `app/pubspec.yaml`

```yaml
name: dvizh
description: Офлайн-счётчик активности без сбора персональных данных
publish_to: 'none'
version: 3.2.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  sensors_plus: ^4.0.2
  shared_preferences: ^2.2.2
  sqflite: ^2.3.0
  path: ^1.8.3
  intl: ^0.18.1
  permission_handler: ^11.0.0
  flutter_local_notifications: ^17.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

---

## 3.2. `app/android/app/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Разрешение на распознавание физической активности -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

    <!-- Разрешение на уведомления, используется только по выбору пользователя -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!--
      Явно удаляем потенциально лишние разрешения,
      если они появятся через зависимости плагинов.
    -->
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" tools:node="remove" />
    <uses-permission android:name="android.permission.CAMERA" tools:node="remove" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" tools:node="remove" />
    <uses-permission android:name="android.permission.READ_CONTACTS" tools:node="remove" />
    <uses-permission android:name="android.permission.READ_CALENDAR" tools:node="remove" />
    <uses-permission android:name="android.permission.WRITE_CALENDAR" tools:node="remove" />
    <uses-permission android:name="android.permission.READ_SMS" tools:node="remove" />
    <uses-permission android:name="android.permission.RECEIVE_SMS" tools:node="remove" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" tools:node="remove" />
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />

    <application
        android:label="Движ"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:fullBackupContent="false"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:usesCleartextTraffic="false"
        tools:targetApi="s">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

---

## 3.3. `app/android/app/src/main/res/xml/data_extraction_rules.xml`

Создай папку `res/xml`, если её нет.

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="root" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
        <exclude domain="external" />
    </cloud-backup>
    <device-transfer>
        <exclude domain="root" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
        <exclude domain="external" />
    </device-transfer>
</data-extraction-rules>
```

---

## 3.4. `app/lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/consent_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeController.load();
  await NotificationService.instance.init();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final bool privacyAccepted = prefs.getBool('privacyAccepted') ?? false;
  final bool ageConfirmed = prefs.getBool('ageConfirmed') ?? false;
  final bool offlineUnderstood = prefs.getBool('offlineUnderstood') ?? false;

  final bool hasConsent =
      privacyAccepted && ageConfirmed && offlineUnderstood;

  runApp(DvizhApp(showConsentFirst: !hasConsent));
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
```

---

## 3.5. `app/lib/models/activity.dart`

```dart
import 'package:flutter/material.dart';

enum ActivityType {
  walking('Ходьба', Icons.directions_walk),
  running('Бег', Icons.directions_run),
  workout('Зарядка', Icons.fitness_center);

  final String title;
  final IconData icon;

  const ActivityType(this.title, this.icon);
}
```

---

## 3.6. `app/lib/models/workout.dart`

```dart
import 'activity.dart';

class Workout {
  final int id;
  final ActivityType type;
  final DateTime startedAt;
  final int durationSeconds;
  final int steps;

  Workout({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.durationSeconds,
    required this.steps,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'type': type.name,
      'startedAt': startedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'steps': steps,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int,
      type: ActivityType.values.firstWhere(
        (ActivityType value) => value.name == map['type'],
      ),
      startedAt: DateTime.parse(map['startedAt'] as String),
      durationSeconds: map['durationSeconds'] as int,
      steps: map['steps'] as int,
    );
  }
}
```

---

## 3.7. `app/lib/services/sensor_service.dart`

```dart
import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _subscription;

  int _steps = 0;
  double _lastMagnitude = 0;
  DateTime _lastStepTime = DateTime.now();
  bool _isActive = false;

  static const double _stepThreshold = 1.3;
  static const int _minStepIntervalMs = 300;

  int get steps => _steps;

  bool get isActive => _isActive;

  void start(void Function(int steps) onStep) {
    if (_isActive) {
      return;
    }

    _isActive = true;

    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((AccelerometerEvent event) {
      final double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final DateTime now = DateTime.now();
      final int timeSinceLastStep =
          now.difference(_lastStepTime).inMilliseconds;

      if (magnitude > _stepThreshold &&
          _lastMagnitude <= _stepThreshold &&
          timeSinceLastStep > _minStepIntervalMs) {
        _steps++;
        _lastStepTime = now;
        onStep(_steps);
      }

      _lastMagnitude = magnitude;
    });
  }

  void stop() {
    if (!_isActive) {
      return;
    }

    _isActive = false;
    _subscription?.cancel();
    _subscription = null;
  }

  void reset() {
    _steps = 0;
  }

  void dispose() {
    stop();
  }
}
```

---

## 3.8. `app/lib/services/storage_service.dart`

```dart
import 'package:path/path.dart';
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
        await db.execute('''
          CREATE TABLE workouts (
            id INTEGER PRIMARY KEY,
            type TEXT NOT NULL,
            startedAt TEXT NOT NULL,
            durationSeconds INTEGER NOT NULL,
            steps INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  static Future<int> saveWorkout(Workout workout) async {
    final Database db = await database;
    return db.insert('workouts', workout.toMap());
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
```

---

## 3.9. `app/lib/services/notification_service.dart`

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _ongoingId = 1001;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<void> showOngoing(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'dvizh_recording',
      'Запись активности',
      channelDescription: 'Показывает, что приложение записывает тренировку',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    await _plugin.show(
      _ongoingId,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  Future<void> cancelOngoing() async {
    await _plugin.cancel(_ongoingId);
  }
}
```

---

## 3.10. `app/lib/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
    ),
  );
}
```

---

## 3.11. `app/lib/theme/theme_controller.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static const String _key = 'theme_mode_index';

  static Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int index = prefs.getInt(_key) ?? 0;

    final int safeIndex = index < 0
        ? 0
        : (index >= ThemeMode.values.length
            ? ThemeMode.values.length - 1
            : index);

    themeMode.value = ThemeMode.values[safeIndex];
  }

  static Future<void> set(ThemeMode mode) async {
    themeMode.value = mode;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }
}
```

---

## 3.12. `app/lib/screens/consent_screen.dart`

```dart
import 'package:flutter/material.dart';
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

              const SizedBox(height: 24),

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
```

---

## 3.13. `app/lib/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';

import '../models/activity.dart';
import 'activity_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Движ'),
        actions: [
          IconButton(
            tooltip: 'История',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const HistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: primary,
                        size: 32,
                      ),
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

              const SizedBox(height: 24),

              const Text(
                'Выбери активность',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 1,
                  mainAxisSpacing: 12,
                  children: ActivityType.values
                      .map(
                        (ActivityType activity) => Card(
                          child: ListTile(
                            leading: Icon(
                              activity.icon,
                              size: 40,
                              color: primary,
                            ),
                            title: Text(
                              activity.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (BuildContext context) =>
                                      ActivityScreen(activityType: activity),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 3.14. `app/lib/screens/activity_screen.dart`

```dart
import 'dart:async';

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

    final PermissionStatus status =
        await Permission.activityRecognition.request();

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

    if (notificationsEnabled) {
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

    await StorageService.saveWorkout(workout);

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
```

---

## 3.15. `app/lib/screens/history_screen.dart`

```dart
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Workout> workouts = await StorageService.getAllWorkouts();

    if (!mounted) {
      return;
    }

    setState(() {
      _workouts = workouts;
    });
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

    await StorageService.clearAll();
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
      body: _workouts.isEmpty
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
    );
  }
}
```

---

## 3.16. `app/lib/screens/settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final PermissionStatus status = await Permission.notifications.request();

    if (!mounted) {
      return;
    }

    if (status.isGranted) {
      setState(() {
        _notificationsEnabled = true;
      });

      await _saveNotifications(true);
    } else {
      setState(() {
        _notificationsEnabled = false;
      });

      await _saveNotifications(false);

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

    await StorageService.deleteAllData();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

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
```

---

# 4. Документы для open-source и магазина

---

## 4.1. `PRIVACY.md`

```markdown
# Privacy Policy — Движ

**Последнее обновление:** 2026-10-31

## 1. Общий принцип

Приложение «Движ» разработано как офлайн-инструмент для локального учёта физической активности.

Приложение:

- не имеет сервера;
- не требует регистрации;
- не собирает ФИО;
- не собирает email;
- не собирает номер телефона;
- не собирает адрес;
- не собирает геолокацию;
- не собирает вес;
- не собирает медицинские данные;
- не использует рекламу;
- не использует аналитику;
- не передаёт данные разработчику;
- не передаёт данные третьим лицам автоматически.

## 2. Какие данные обрабатываются локально

Приложение может локально хранить на устройстве пользователя:

- тип активности;
- дату и время начала тренировки;
- длительность тренировки;
- количество шагов, рассчитанное на основе датчика движения устройства.

Эти данные не покидают устройство.

В версии v3.2.0 экспорт файлов и отправка данных отключены.

## 3. Разрешения

### Доступ к физической активности

Приложение может запрашивать разрешение на доступ к датчикам движения для подсчёта шагов.

Данные обрабатываются локально и используются только для отображения результата пользователю.

### Уведомления

Если пользователь включил уведомления, приложение может показывать локальное уведомление о том, что идёт запись активности.

Уведомления не используются для рекламы и не отправляют данные наружу.

## 4. Хранение и удаление данных

Все данные хранятся только на устройстве пользователя.

Пользователь может:

- очистить историю тренировок;
- удалить все данные приложения;
- удалить приложение, после чего операционная система удалит данные приложения.

## 5. Дети

Приложение не предназначено для детей младше 14 лет без участия законного представителя.

Родители или законные представители должны контролировать использование приложения детьми.

## 6. Медицинская информация

Приложение не является медицинским изделием, не ставит диагнозы, не лечит, не заменяет консультацию врача и не гарантирует точность измерений.

Данные о шагах и длительности активности носят информационный характер и могут быть неточными в зависимости от устройства, способа ношения телефона и условий использования.

## 7. Открытый код

Исходный код приложения доступен публично. Это позволяет любому независимому исследователю проверить отсутствие сетевых запросов, аналитики, рекламы и скрытой передачи данных.

## 8. Контакты

По вопросам приватности можно открыть issue в публичном репозитории или связаться с maintainer через контакты, указанные в репозитории.
```

---

## 4.2. `README.md`

```markdown
# Движ

Простое офлайн-приложение для локального учёта физической активности.

## Возможности

- выбор типа активности;
- подсчёт шагов через датчик движения устройства;
- длительность тренировки;
- локальная история;
- очистка истории;
- удаление всех данных;
- переключатель записи;
- переключатель уведомлений;
- светлая, тёмная и системная тема.

## Приватность

- без сервера;
- без регистрации;
- без рекламы;
- без аналитики;
- без передачи данных разработчику;
- без геолокации;
- без сбора ФИО, телефона, email, адреса, веса и медицинских данных.

Все данные хранятся только на устройстве пользователя.

## Дисклеймер

Приложение не является медицинским изделием. Оно не ставит диагнозы, не лечит и не заменяет консультацию врача. Точность подсчёта шагов зависит от устройства, датчиков и того, как пользователь носит телефон.

## Лицензия

MIT. См. файл `LICENSE`.
```

---

## 4.3. `LICENSE`

Замени `[Имя владельца]` на своё имя или ник, который хочешь публично указать.

```text
MIT License

Copyright (c) 2026 [Имя владельца]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 4.4. `CHANGELOG.md`

```markdown
# Changelog

## [3.2.0] - 2026-10-31

### Removed
- Weight collection.
- Calories calculation.
- Nickname field.
- Group code field.
- Foreground service.
- PDF export.
- Share integration.

### Added
- Privacy consent screen.
- Age confirmation.
- Offline understanding confirmation.
- Master recording toggle.
- Notifications toggle.
- Clear history.
- Delete all data.
- Local-only store-safe build.
- Hardened Android manifest.
- Backup disabled.
- Privacy policy.
- Open-source license and README.
```

---

## 4.5. `RELEASE_NOTES_v3.2.0.md`

```markdown
# Release Notes — Движ v3.2.0 Local-Only

## Главное

Это локальная версия без сбора персональных данных, без групп, без никнеймов, без веса и без калорий.

## Изменения

- убран вес;
- убраны калории;
- убраны никнеймы;
- убраны коды групп;
- убран PDF-экспорт;
- убран share;
- убран foreground service;
- добавлен экран согласия;
- добавлено подтверждение возраста;
- добавлен переключатель записи;
- добавлен переключатель уведомлений;
- добавлена очистка истории;
- добавлено удаление всех данных;
- добавлена тёмная тема;
- усилен Android manifest;
- отключён backup.

## Приватность

Приложение работает офлайн. Данные хранятся только на устройстве и не отправляются автоматически.

## Известные ограничения

- точность подсчёта шагов зависит от устройства;
- на некоторых Android-прошивках приложение может останавливаться при сворачивании;
- для надёжной записи лучше не закрывать приложение полностью.
```

---

# 5. Что я проверил статически

Я прошёл по файлам и проверил следующее.

## 5.1. Удалены лишние данные

В коде больше нет:

- `weight`;
- `calories`;
- `nickname`;
- `groupCode`;
- `mets`.

## 5.2. Удалены рискованные зависимости

В `pubspec.yaml` больше нет:

- `flutter_foreground_task`;
- `pdf`;
- `share_plus`;
- `path_provider`.

## 5.3. Consent идёт до разрешений

В `main.dart` приложение сначала проверяет:

- `privacyAccepted`;
- `ageConfirmed`;
- `offlineUnderstood`.

Если согласия нет, открывается `ConsentScreen`.

Разрешение на датчики запрашивается только в `ActivityScreen._start()`, то есть после consent и после включения записи.

## 5.4. Master toggle работает

В `ActivityScreen._start()` читается:

```dart
prefs.getBool('recordingEnabled')
```

Если `false`, приложение показывает сообщение и не запускает датчики.

## 5.5. Notifications toggle работает

Уведомление показывается только если:

```dart
prefs.getBool('notificationsEnabled') == true
```

Разрешение на уведомления запрашивается только при включении тумблера в настройках.

## 5.6. Очистка истории реализована

В `HistoryScreen` есть кнопка очистки.

Вызывается:

```dart
StorageService.clearAll()
```

Она удаляет все строки из таблицы `workouts`.

## 5.7. Удаление всех данных реализовано

В `SettingsScreen` есть кнопка удаления всех данных.

Вызывается:

```dart
StorageService.deleteAllData()
```

и

```dart
prefs.clear()
```

После этого приложение возвращается на `ConsentScreen`.

## 5.8. Манифест усилен

В `AndroidManifest.xml` явно удалены:

- `INTERNET`;
- `ACCESS_NETWORK_STATE`;
- `ACCESS_WIFI_STATE`;
- `ACCESS_FINE_LOCATION`;
- `ACCESS_COARSE_LOCATION`;
- `CAMERA`;
- `RECORD_AUDIO`;
- `READ_CONTACTS`;
- `READ_CALENDAR`;
- `WRITE_CALENDAR`;
- `READ_SMS`;
- `RECEIVE_SMS`;
- `FOREGROUND_SERVICE`;
- `AD_ID`.

Также отключён backup:

```xml
android:allowBackup="false"
android:fullBackupContent="false"
android:dataExtractionRules="@xml/data_extraction_rules"
```

## 5.9. Таймер исправлен

В `ActivityScreen` используется корректная интерполяция:

```dart
'${h.toString().padLeft(2, '0')}:'
'${m.toString().padLeft(2, '0')}:'
'${s.toString().padLeft(2, '0')}'
```

## 5.10. Нет отправки данных наружу

В коде нет:

- HTTP-клиентов;
- сокетов;
- Firebase;
- аналитики;
- рекламы;
- crash reporting;
- server URL.

---

# 6. Команды для твоей финальной проверки

Запусти в корне проекта.

## 6.1. Базовая проверка

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Если `flutter analyze` покажет ошибки — присылай вывод, разберём точечно.

---

## 6.2. Проверка разрешений APK

```bash
aapt dump permissions build/app/outputs/flutter-apk/app-debug.apk
```

Допустимо:

```text
android.permission.ACTIVITY_RECOGNITION
android.permission.POST_NOTIFICATIONS
```

Не должно быть:

```text
android.permission.INTERNET
android.permission.ACCESS_FINE_LOCATION
android.permission.ACCESS_COARSE_LOCATION
android.permission.CAMERA
android.permission.RECORD_AUDIO
android.permission.READ_CONTACTS
com.google.android.gms.permission.AD_ID
android.permission.FOREGROUND_SERVICE
```

---

## 6.3. Быстрая проверка, что лишнее не вернулось в код

Для Linux/macOS/Git Bash:

```bash
grep -RniE "weight|calories|nickname|groupCode|flutter_foreground_task|pdf|share_plus|path_provider" app/lib app/pubspec.yaml app/android/app/src/main/AndroidManifest.xml
```

Ожидаемый результат: пусто.

---

## 6.4. Проверка, что нет сетевых библиотек в коде

```bash
grep -RniE "http|https|dio|socket|firebase|analytics|admob" app/lib app/pubspec.yaml
```

Ожидаемый результат: пусто.

Если находите совпадения в комментариях или документации — это не страшно, но в `app/lib` и `pubspec.yaml` лучше держать чисто.

---

## 6.5. Проверка merged manifest

Найди собранный манифест, обычно здесь:

```bash
build/app/intermediates/merged_manifests/debug/AndroidManifest.xml
```

Открой и проверь, что нет активных:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Допустимы только строки с:

```xml
tools:node="remove"
```

---

# 7. Ручной smoke-test, который нужно пройти

Отметь в `TASKS.md`, когда проверишь.

## Первый запуск

- [ ] Открывается экран согласия.
- [ ] Кнопка «Продолжить» неактивна, пока не поставлены все галочки.
- [ ] После галочек открывается главный экран.
- [ ] Разрешения пока не запрашиваются.

## Запись

- [ ] Выбираешь «Ходьба».
- [ ] Нажимаешь «Начать».
- [ ] Запрашивается доступ к датчикам движения.
- [ ] После разрешения таймер запускается.
- [ ] Шаги считаются при ходьбе/встряхивании.
- [ ] Нажимаешь «Стоп».
- [ ] Тренировка сохраняется.
- [ ] Возвращаешься на главный экран.

## История

- [ ] Открываешь историю.
- [ ] Видишь сохранённую тренировку.
- [ ] Нажимаешь «Очистить историю».
- [ ] Подтверждаешь удаление.
- [ ] История становится пустой.
- [ ] После перезапуска приложения история всё ещё пуста.

## Настройки

- [ ] Выключаешь «Разрешить запись активности».
- [ ] Пробуешь начать тренировку.
- [ ] Появляется сообщение, что запись отключена.
- [ ] Включаешь обратно.
- [ ] Тренировка снова доступна.

## Уведомления

- [ ] Выключаешь уведомления.
- [ ] Начинаешь запись.
- [ ] Уведомление не появляется.
- [ ] Включаешь уведомления.
- [ ] Система запрашивает разрешение.
- [ ] После разрешения уведомление появляется во время записи.
- [ ] После остановки уведомление исчезает.

## Удаление всех данных

- [ ] Нажимаешь «Удалить все данные».
- [ ] Подтверждаешь.
- [ ] Приложение возвращается на экран согласия.
- [ ] История пуста.
- [ ] Настройки сброшены.

---

# 8. Мой итоговый статус

Сейчас релиз **v3.2.0 Local-Only** находится в статусе:

```text
CODE_READY
```

Он не может быть `VERIFIED`, пока ты не запустишь:

```bash
flutter analyze
flutter build apk --debug
```

и не пройдёшь ручной smoke-test.

Но по коду это уже гораздо более безопасная версия для открытого репозитория и будущей подготовки к Google Play, чем предыдущая: без веса, без калорий, без групп, без никнеймов, без foreground service, без PDF/share и с явным consent-потоком.