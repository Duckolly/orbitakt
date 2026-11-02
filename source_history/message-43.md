
Да, я могу подготовить **все три фичи**: фоновое уведомление/anti-kill, экспорт PDF и тёмную тему.  
Но сразу зафиксирую честно: **я не могу скомпилировать и прогнать приложение на устройстве**, поэтому ниже будет не “проверено”, а **“код готов, статус: ожидает сборки”**. Мы будем вести учёт в `TASKS.md`, пока ты не скомпилируешь на ПК.

---

# 1. Что добавляем

## FEAT-001 — Уведомление о записи
Показывает постоянное уведомление, когда идёт тренировка.

**Зачем:**
- пользователь видит, что запись идёт;
- Android реже убивает приложение;
- снижает риск “я нажал начать, телефон заблокировался, и всё пропало”.

**Ограничение:**  
Обычное уведомление **не гарантирует 100%**, что Android не убьёт фоновый процесс. Для более надёжной защиты добавляем foreground service.

---

## FEAT-002 — Foreground service для Android
Дополнительный “якорь”, который повышает приоритет процесса во время записи.

**Зачем:**
- сильнее защищает от убийства системой;
- полезно на Xiaomi / Redmi / Huawei / Tecno / Infinix, где агрессивный battery optimizer.

**Ограничение:**
- на iOS полноценного аналога Android foreground service нет;
- на некоторых прошивках пользователю всё равно нужно вручную разрешить приложению работать в фоне.

---

## FEAT-003 — Экспорт PDF для тренера
Генерирует PDF локально на устройстве.

**Важно для приватности:**
- PDF создаётся офлайн;
- приложение само никуда его не отправляет;
- пользователь сам нажимает “Поделиться” и выбирает, куда отправить: тренеру, в WhatsApp, в почту, в файл и т.д.

**Нюанс:**  
Для корректного кириллического PDF нужен шрифт, например Roboto. Без него PDF может открыть русские буквы квадратиками.

---

## FEAT-004 — Тёмная тема
Добавляем:
- светлую тему;
- тёмную тему;
- системную тему;
- сохранение выбора локально.

---

# 2. Обновлённый `TASKS.md`

Замени свой файл учёта задач на этот. Я добавил новый статус:

- `🔴 TODO` — не сделано  
- `🟡 CODE_READY` — код подготовлен, но не скомпилирован  
- `🟢 VERIFIED` — ты проверил на устройстве  
- `⚪ DEFERRED` — отложено  

```markdown
# 🐛 Трекер задач и фич — Движ v3.0

## Статусы
- 🔴 TODO — не начато
- 🟡 CODE_READY — код подготовлен, ожидает компиляции
- 🟢 VERIFIED — проверено на устройстве
- ⚪ DEFERRED — отложено

---

## Критичные баги

### BUG-001: Ошибка интерполяции строк в activity_screen.dart 🟡 CODE_READY
**Файл:** `app/lib/screens/activity_screen.dart`  
**Проблема:** Был экранированный `\$`, из-за чего Dart не компилируется.  
**Фикс:** Заменено на корректную интерполяцию `${...}`.  
**Проверка после сборки:** Таймер отображается как `00:00:30`.

### BUG-002: Нет запроса разрешений на датчики движения 🟡 CODE_READY
**Файл:** `app/lib/screens/activity_screen.dart`  
**Проблема:** На Android 10+ и iOS нужно запрашивать доступ к движению/сенсорам.  
**Фикс:** Добавлен запрос `Permission.activityRecognition` и `Permission.sensors`.  
**Проверка после сборки:** При первом нажатии “Начать” появляется системный диалог разрешения.

---

## Фичи

### FEAT-001: Постоянное уведомление во время записи 🟡 CODE_READY
**Файлы:**
- `app/lib/services/notification_service.dart`
- `app/lib/screens/activity_screen.dart`

**Описание:** При старте тренировки показывается ongoing-уведомление. При остановке скрывается.

**Проверка после сборки:**
1. Начать тренировку.
2. Свернуть приложение.
3. В шторке уведомлений видно “Движ: идёт запись”.
4. Остановить тренировку — уведомление исчезает.

### FEAT-002: Foreground service для Android 🟡 CODE_READY
**Файлы:**
- `app/lib/services/foreground_service.dart`
- `app/android/app/src/main/AndroidManifest.xml`
- `app/pubspec.yaml`

**Описание:** Понижает риск убийства процесса системой во время записи.

**Риск:** Плагин `flutter_foreground_task` может потребовать точной настройки под Android 14. Если сборка упадёт, временно отключим вызовы `ForegroundService.start/stop`.

**Проверка после сборки:**
1. Начать тренировку.
2. Открыть список приложений.
3. Увидеть сервис/уведомление высокой приоритетности.
4. Вернуться в приложение — таймер и шаги не сбрасываются.

### FEAT-003: Экспорт PDF для тренера 🟡 CODE_READY
**Файлы:**
- `app/lib/services/pdf_export_service.dart`
- `app/lib/screens/report_screen.dart`
- `app/pubspec.yaml`
- `app/assets/fonts/Roboto-Regular.ttf`
- `app/assets/fonts/Roboto-Bold.ttf`

**Описание:** Локальная генерация PDF с никнеймом, кодом группы, шагами и калориями.

**Важно:** Нужны шрифты Roboto для кириллицы.

**Проверка после сборки:**
1. Провести хотя бы одну тренировку.
2. Открыть “Отчёт для тренера”.
3. Нажать “Сохранить / отправить PDF”.
4. Получить файл с читабельной кириллицей.
5. Убедиться, что приложение не запрашивает интернет.

### FEAT-004: Тёмная тема 🟡 CODE_READY
**Файлы:**
- `app/lib/theme/app_theme.dart`
- `app/lib/theme/theme_controller.dart`
- `app/lib/main.dart`
- `app/lib/screens/settings_screen.dart`

**Описание:** Светлая, тёмная и системная тема. Выбор сохраняется локально.

**Проверка после сборки:**
1. Открыть настройки.
2. Переключить тему на тёмную.
3. Закрыть и открыть приложение — тема сохранилась.
4. Проверить читаемость на AMOLED.

---

## Инфраструктура

### ASSET-001: Добавить шрифты Roboto 🔴 TODO
**Папка:** `app/assets/fonts/`  
**Файлы:**
- `Roboto-Regular.ttf`
- `Roboto-Bold.ttf`

**Источник:** официальный Roboto, лицензия Apache 2.0.  
**Без этого:** PDF может отображать кириллицу квадратиками.

### MANIFEST-001: Android permissions 🟡 CODE_READY
**Файл:** `app/android/app/src/main/AndroidManifest.xml`

Добавлены:
- `ACTIVITY_RECOGNITION`
- `POST_NOTIFICATIONS`
- `FOREGROUND_SERVICE`

**Проверка после сборки:**
```bash
aapt dump permissions app/build/outputs/apk/debug/app-debug.apk
```
Не должно быть `android.permission.INTERNET`.

### PRIVACY-001: Подтвердить отсутствие сети 🔴 TODO
**Метод:**
- посмотреть манифест;
- прогнать трафик через локальный monitor;
- убедиться, что PDF/share происходят через системные диалоги, а не через сетевые запросы приложения.

---

## Тесты

### TEST-001: Ручной smoke-test 🔴 TODO
**Проверить:**
- запуск;
- выбор активности;
- старт/стоп;
- шаги;
- сохранение;
- отчёт;
- PDF;
- тема.

### TEST-002: Battery sanity check 🔴 TODO
**Проверить:**
- 10 минут записи;
- расход батареи;
- поведение при сворачивании;
- поведение на Xiaomi/Redmi/Tecno.

### TEST-003: Device matrix 🔴 TODO
**Минимум:**
- Samsung;
- Xiaomi/Redmi;
- Pixel;
- Tecno/Infinix;
- iPhone, если будешь собирать iOS.

---

## Лог изменений

| Дата | Задача | Статус | Комментарий |
|------|--------|--------|-------------|
| 2026-10-31 | BUG-001 | 🟡 CODE_READY | Исправлена интерполяция в коде |
| 2026-10-31 | BUG-002 | 🟡 CODE_READY | Добавлен запрос разрешений |
| 2026-10-31 | FEAT-001 | 🟡 CODE_READY | Уведомление подготовлено |
| 2026-10-31 | FEAT-002 | 🟡 CODE_READY | Foreground service подготовлен |
| 2026-10-31 | FEAT-003 | 🟡 CODE_READY | PDF export подготовлен |
| 2026-10-31 | FEAT-004 | 🟡 CODE_READY | Тёмная тема подготовлена |
| 2026-10-31 | ASSET-001 | 🔴 TODO | Нужно положить шрифты |
```

---

# 3. Порядок применения изменений

Сделай по шагам. Не пытайся вставить всё одним куском, иначе сложно искать ошибку.

## Шаг 1. Обнови зависимости

Замени `app/pubspec.yaml` на этот:

```yaml
name: dvizh_trainer
description: Офлайн-трекер активностей для групп и тренеров
publish_to: 'none'
version: 3.0.0+1

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
  flutter_foreground_task: ^8.0.0

  pdf: ^3.11.0
  path_provider: ^2.1.1
  share_plus: ^7.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/fonts/
```

Потом:

```bash
flutter pub get
```

---

## Шаг 2. Добавь шрифты для PDF

Создай папку:

```bash
mkdir -p app/assets/fonts
```

Положи туда:

```text
app/assets/fonts/Roboto-Regular.ttf
app/assets/fonts/Roboto-Bold.ttf
```

Где взять: официальный Roboto, лицензия Apache 2.0.  
Это важно, потому что стандартные PDF-шрифты плохо работают с кириллицей.

---

## Шаг 3. Обнови AndroidManifest

Замени `app/android/app/src/main/AndroidManifest.xml` на этот:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Разрешения для датчиков движения -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

    <!-- Разрешение на уведомления Android 13+ -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Foreground service, чтобы система не убивала запись -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

    <!--
      ВАЖНО:
      Разрешение INTERNET намеренно отсутствует.
      Приложение должно работать офлайн.
    -->

    <application
        android:label="Движ"
        android:icon="@mipmap/ic_launcher">

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

Если Android 14 будет ругаться на foreground service type, позже добавим точечный фикс. Пока не усложняем.

---

## Шаг 4. Обнови iOS Info.plist

В `app/ios/Runner/Info.plist` убедись, что есть:

```xml
<key>NSMotionUsageDescription</key>
<string>Приложению нужен доступ к датчикам движения для подсчёта шагов</string>
```

Интернет-разрешения на iOS для офлайн-режима не добавляем.

---

# 4. Новые и обновлённые файлы кода

Ниже — файлы, которые нужно создать или заменить.

---

## 4.1. `app/lib/main.dart`

```dart
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/foreground_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeController.load();
  await NotificationService.instance.init();
  await ForegroundService.init();

  runApp(const DvizhApp());
}

class DvizhApp extends StatelessWidget {
  const DvizhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Движ',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
```

---

## 4.2. `app/lib/theme/app_theme.dart`

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
    cardTheme: const CardThemeData(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
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
    cardTheme: const CardThemeData(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
    ),
  );
}
```

---

## 4.3. `app/lib/theme/theme_controller.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static const String _key = 'theme_mode_index';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 0;

    final safeIndex = index < 0
        ? 0
        : (index >= ThemeMode.values.length
            ? ThemeMode.values.length - 1
            : index);

    themeMode.value = ThemeMode.values[safeIndex];
  }

  static Future<void> set(ThemeMode mode) async {
    themeMode.value = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }
}
```

---

## 4.4. `app/lib/services/notification_service.dart`

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

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
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

## 4.5. `app/lib/services/foreground_service.dart`

Этот файл отвечает за Android foreground service.

Если при сборке плагин `flutter_foreground_task` даст ошибку, временно можно отключить вызовы `ForegroundService.start()` и `ForegroundService.stop()` в `activity_screen.dart`.

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void _dvizhTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_DvizhTaskHandler());
}

class _DvizhTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Сервис запущен. Дополнительная логика пока не нужна.
  }

  @override
  Future<void> onRepeatInterval(DateTime timestamp) async {
    // Периодическая заглушка. Можно использовать позже для heartbeat.
  }

  @override
  void onDestroy(DateTime timestamp) {
    // Сервис остановлен.
  }
}

class ForegroundService {
  static bool _initialized = false;

  static Future<void> init() async {
    try {
      await FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'dvizh_foreground',
          channelName: 'Движ — фоновая запись',
          channelDescription: 'Помогает не прерывать запись тренировки',
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          interval: 5000,
          isOneShot: false,
          autoStartOnBoot: false,
        ),
      );

      _initialized = true;
    } catch (e, st) {
      debugPrint('ForegroundService init failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> start() async {
    if (!_initialized) return;

    try {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Движ',
        notificationText: 'Идёт запись активности',
        callback: _dvizhTaskCallback,
      );
    } catch (e) {
      debugPrint('ForegroundService start failed: $e');
    }
  }

  static Future<void> stop() async {
    if (!_initialized) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('ForegroundService stop failed: $e');
    }
  }
}
```

---

## 4.6. `app/lib/services/pdf_export_service.dart`

```dart
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/workout.dart';

class PdfExportService {
  static Future<Uint8List> buildReport({
    required String nickname,
    required String groupCode,
    required List<Workout> workouts,
  }) async {
    pw.Theme? theme;

    try {
      final ByteData regularData =
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ByteData boldData =
          await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

      theme = pw.Theme.withFonts(
        regular: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      );
    } catch (_) {
      theme = null;
    }

    final pw.Document doc = pw.Document(theme: theme);

    final int totalSteps =
        workouts.fold<int>(0, (sum, workout) => sum + workout.steps);

    final double totalCalories = workouts.fold<double>(
      0.0,
      (sum, workout) => sum + workout.calories,
    );

    final DateFormat dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Header(level: 0, text: 'Отчёт по активности «Движ»'),

            pw.SizedBox(height: 12),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: <pw.TableRow>[
                pw.TableRow(
                  children: <pw.Widget>[
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Код группы'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(groupCode),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: <pw.Widget>[
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Никнейм'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(nickname),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: <pw.Widget>[
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Всего тренировок'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(workouts.length.toString()),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: <pw.Widget>[
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Всего шагов'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(totalSteps.toString()),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: <pw.Widget>[
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Всего ккал'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(totalCalories.toStringAsFixed(0)),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            pw.Header(level: 1, text: 'Тренировки'),

            pw.SizedBox(height: 8),

            if (workouts.isEmpty)
              pw.Text('Нет сохранённых тренировок.')
            else
              pw.Table.fromTextArray(
                headers: <String>[
                  'Дата',
                  'Тип',
                  'Шаги',
                  'Ккал',
                ],
                data: workouts
                    .map(
                      (Workout w) => <String>[
                        dateFormat.format(w.startTime),
                        w.type.title,
                        w.steps.toString(),
                        w.calories.toStringAsFixed(0),
                      ],
                    )
                    .toList(),
              ),

            pw.SizedBox(height: 24),

            pw.Divider(thickness: 1),

            pw.SizedBox(height: 8),

            pw.Text(
              'Отчёт сгенерирован локально в приложении «Движ». '
              'Данные не передаются автоматически.',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }
}
```

---

## 4.7. `app/lib/screens/activity_screen.dart`

Полная замена. Здесь:
- исправлена интерполяция;
- добавлены разрешения;
- добавлено уведомление;
- добавлен foreground service;
- датчик не работает, когда запись не начата.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../models/workout.dart';
import '../services/foreground_service.dart';
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
  DateTime? _startTime;

  int _seconds = 0;
  int _steps = 0;
  bool _isRunning = false;

  Future<bool> _ensurePermissions() async {
    final PermissionStatus activityStatus =
        await Permission.activityRecognition.request();

    final PermissionStatus sensorsStatus =
        await Permission.sensors.request();

    if (activityStatus.isGranted || sensorsStatus.isGranted) {
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступа к датчикам движения. Шаги не считаются.'),
        ),
      );
    }

    return false;
  }

  Future<void> _start() async {
    if (_isRunning) return;

    final bool hasPermission = await _ensurePermissions();
    if (!hasPermission) return;

    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
      _seconds = 0;
      _steps = 0;
    });

    _sensor.reset();

    _sensor.start((int steps) {
      if (_isRunning && mounted) {
        setState(() => _steps = steps);
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning && mounted) {
        setState(() => _seconds++);
      }
    });

    await NotificationService.instance.showOngoing(
      'Движ',
      'Идёт запись: ${widget.activityType.title}',
    );

    await ForegroundService.start();
  }

  Future<void> _stop() async {
    if (!_isRunning) return;

    _timer?.cancel();
    _timer = null;

    _sensor.stop();

    await ForegroundService.stop();
    await NotificationService.instance.cancelOngoing();

    setState(() {
      _isRunning = false;
    });

    if (_startTime == null) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final double weight = prefs.getDouble('weight') ?? 70.0;

    final double durationMinutes = _seconds / 60.0;
    final double calories =
        widget.activityType.mets * weight * (durationMinutes / 60.0);

    final Workout workout = Workout(
      id: DateTime.now().millisecondsSinceEpoch,
      type: widget.activityType,
      startTime: _startTime!,
      endTime: DateTime.now(),
      steps: _steps,
      calories: calories,
    );

    await StorageService.saveWorkout(workout);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Сохранено: $_steps шагов, ${calories.toStringAsFixed(0)} ккал',
          ),
        ),
      );

      Navigator.pop(context);
    }
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

    // Fire-and-forget, потому что dispose не может быть async.
    NotificationService.instance.cancelOngoing();
    ForegroundService.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityType.title),
      ),
      body: Center(
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
                  _StatBox(
                    label: 'Ккал',
                    value: _isRunning ? '...' : '—',
                  ),
                ],
              ),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isRunning ? () => _stop() : () => _start(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64,
                    vertical: 20,
                  ),
                  backgroundColor:
                      _isRunning ? Colors.red : primary,
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

## 4.8. `app/lib/screens/report_screen.dart`

Полная замена. Добавлен PDF.

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout.dart';
import '../services/pdf_export_service.dart';
import '../services/storage_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Workout> _workouts = [];

  String _nickname = 'Ученик';
  String _groupCode = 'БЕЗ_КОДА';

  bool _isLoadingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String nickname = prefs.getString('nickname') ?? 'Ученик';
    final String groupCode = prefs.getString('groupCode') ?? 'БЕЗ_КОДА';

    final List<Workout> workouts = await StorageService.getAllWorkouts();

    if (!mounted) return;

    setState(() {
      _nickname = nickname;
      _groupCode = groupCode;
      _workouts = workouts;
    });
  }

  void _copyReportToClipboard() {
    if (_workouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет данных для отчёта.')),
      );
      return;
    }

    final int totalSteps =
        _workouts.fold<int>(0, (sum, workout) => sum + workout.steps);

    final double totalCalories = _workouts.fold<double>(
      0.0,
      (sum, workout) => sum + workout.calories,
    );

    final String report = '''
ОТЧЁТ ПО АКТИВНОСТИ
-------------------
Код группы: $_groupCode
Никнейм: $_nickname
Всего тренировок: ${_workouts.length}
Всего шагов: $totalSteps
Всего ккал: ${totalCalories.toStringAsFixed(0)}
-------------------
Сгенерировано в приложении "Движ" офлайн.
''';

    Clipboard.setData(ClipboardData(text: report));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Отчёт скопирован. Отправь его тренеру вручную.'),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_workouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет данных для PDF-отчёта.')),
      );
      return;
    }

    setState(() => _isLoadingPdf = true);

    try {
      final Uint8List bytes = await PdfExportService.buildReport(
        nickname: _nickname,
        groupCode: _groupCode,
        workouts: _workouts,
      );

      final Directory dir = await getTemporaryDirectory();
      final String fileName =
          'dvizh_${_groupCode}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final File file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Отчёт Движ',
        text: 'Локальный PDF-отчёт по активности',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось создать PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    final int totalSteps =
        _workouts.fold<int>(0, (sum, workout) => sum + workout.steps);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчёт для тренера'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Группа: $_groupCode',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ученик: $_nickname',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Divider(height: 32),
                    Text(
                      'Всего шагов: $totalSteps',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _workouts.isEmpty
                  ? const Center(
                      child: Text('Нет данных. Проведи тренировку.'),
                    )
                  : ListView.builder(
                      itemCount: _workouts.length,
                      itemBuilder: (context, index) {
                        final Workout workout = _workouts[index];

                        return ListTile(
                          leading: Icon(
                            workout.type.icon,
                            color: primary,
                          ),
                          title: Text(workout.type.title),
                          subtitle: Text(
                            '${workout.steps} шагов • '
                            '${workout.calories.toStringAsFixed(0)} ккал',
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingPdf ? null : _exportPdf,
                icon: _isLoadingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: const Text('Сохранить / отправить PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _copyReportToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Скопировать текстовый отчёт'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Данные не отправляются автоматически. '
              'PDF создаётся локально, а отправляешь его ты сам.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4.9. `app/lib/screens/settings_screen.dart`

Полная замена. Добавлены:
- никнейм;
- код группы;
- вес;
- выбор темы;
- валидация пустых полей.

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  double _weight = 70;
  ThemeMode _themeMode = ThemeMode.system;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String nickname = prefs.getString('nickname') ?? 'Ученик';
    final String groupCode = prefs.getString('groupCode') ?? 'БЕЗ_КОДА';
    final double weight = prefs.getDouble('weight') ?? 70;

    if (!mounted) return;

    setState(() {
      _nicknameController.text = nickname;
      _groupController.text = groupCode;
      _weight = weight;
      _themeMode = ThemeController.themeMode.value;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    String nickname = _nicknameController.text.trim();
    String groupCode = _groupController.text.trim().toUpperCase();

    if (nickname.isEmpty) {
      nickname = 'Ученик';
    }

    if (groupCode.isEmpty) {
      groupCode = 'БЕЗ_КОДА';
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('nickname', nickname);
    await prefs.setString('groupCode', groupCode);
    await prefs.setDouble('weight', _weight);

    await ThemeController.set(_themeMode);

    if (!mounted) return;

    setState(() {
      _nicknameController.text = nickname;
      _groupController.text = groupCode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки сохранены локально')),
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
  void dispose() {
    _nicknameController.dispose();
    _groupController.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ваш никнейм',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                hintText: 'Например: Alex_9A',
                helperText: 'Не используй ФИО. Достаточно никнейма.',
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Код группы от тренера',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _groupController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Например: FIT_OCT',
                helperText: 'Тренер даёт код группы. ФИО не нужны.',
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Вес для расчёта калорий',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _weight,
              min: 30,
              max: 200,
              divisions: 170,
              label: '${_weight.round()} кг',
              onChanged: (double value) {
                setState(() => _weight = value);
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Тема приложения',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                if (mode == null) return;

                setState(() => _themeMode = mode);
                ThemeController.set(mode);
              },
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Сохранить локально'),
              ),
            ),

            const SizedBox(height: 32),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Privacy First',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Приложение не имеет разрешения на интернет. '
                      'Никнейм, код группы, вес и тренировки хранятся только '
                      'на этом устройстве. PDF создаётся локально и отправляется '
                      'только если ты сам нажмёшь "Поделиться".',
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
}
```

---

# 5. Что осталось без изменений

Эти файлы можно оставить из предыдущей версии, если ты уже применил фиксы:

```text
app/lib/models/activity.dart
app/lib/models/workout.dart
app/lib/services/sensor_service.dart
app/lib/services/storage_service.dart
app/lib/screens/home_screen.dart
```

Но `home_screen.dart` желательно чуть освежить под тему. Если хочешь, следующим шагом дам обновлённый `home_screen.dart` с адаптивной сеткой и корректными цветами для тёмной темы.

---

# 6. Как собрать и проверить

## 6.1. Сборка Android APK

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

APK будет здесь:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## 6.2. Установка на устройство

```bash
flutter install
```

или вручную:

```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## 6.3. Проверка, что нет интернета

```bash
aapt dump permissions build/app/outputs/flutter-apk/app-debug.apk
```

Ищи строку:

```text
android.permission.INTERNET
```

Её **не должно быть**.

Если она всё-таки появилась от какого-то плагина, надо будет разбираться точечно. Но в манифесте мы её не добавляли.

---

# 7. Ручной тест-чеклист после компиляции

Отметь в `TASKS.md`, когда проверишь.

## Basic

- [ ] Приложение запускается.
- [ ] Главное меню открывается.
- [ ] Можно выбрать активность.
- [ ] Кнопка Play запускает таймер.
- [ ] Шаги считаются при встряхивании/ходьбе.
- [ ] Кнопка Stop сохраняет тренировку.
- [ ] После перезапуска история сохраняется.

## Permissions

- [ ] При первом старте запрашивается доступ к движению.
- [ ] Если запретить, появляется понятное сообщение.
- [ ] Если разрешить, шаги считаются.

## Notification

- [ ] При старте появляется уведомление.
- [ ] Уведомление не исчезает при сворачивании.
- [ ] При остановке уведомление исчезает.
- [ ] Уведомление не звуковое и не раздражающее.

## Foreground service

- [ ] При старте тренировки сервис запускается.
- [ ] Приложение не убивается сразу при сворачивании.
- [ ] На Xiaomi/Tecno проверить отдельно.
- [ ] Если система всё равно убивает, добавить инструкцию для пользователя: “разрешить работу в фоне”.

## PDF

- [ ] Кнопка PDF работает.
- [ ] Файл создаётся.
- [ ] Кириллица читается.
- [ ] В PDF нет ФИО.
- [ ] В PDF есть никнейм и код группы.
- [ ] Отправка PDF происходит через системный диалог “Поделиться”.

## Dark theme

- [ ] Светлая тема норм.
- [ ] Тёмная тема норм.
- [ ] Системная тема переключается вместе с телефоном.
- [ ] Выбор сохраняется после перезапуска.

---

# 8. Battery-оценка после этих изменений

При текущей архитектуре:  
**запись идёт только когда пользователь нажал “Начать”**.

| Ситуация | Примерный расход |
|---|---:|
| Приложение открыто, запись не идёт | почти 0% |
| Запись идёт, экран включён | 2–5%/час на средних Android |
| Запись идёт, приложение свёрнуто, foreground service активен | 3–6%/час |
| Дешёвые Xiaomi/Tecno/Infinix | 5–10%/час |
| iPhone с ограниченным фоном | зависит от iOS, может быть нестабильно |

Это нормально для session-трекера.  
Если позже захотим “весь день считаем шаги пассивно”, надо будет переходить на нативный step counter: Android `TYPE_STEP_COUNTER`, iOS `CMPedometer`.

---

# 9. Если сборка упадёт на foreground service

Самое вероятное место — `flutter_foreground_task`.

Если получишь ошибку, сделай временный fallback:

В `app/lib/screens/activity_screen.dart` закомментируй:

```dart
await ForegroundService.start();
```

и

```dart
await ForegroundService.stop();
```

а также в `dispose`:

```dart
ForegroundService.stop();
```

После этого останутся:
- уведомление;
- PDF;
- тёмная тема;
- разрешения;
- исправленный таймер.

Foreground service вернём отдельной задачей, когда поймём точную версию плагина и ошибку компилятора.

---

# 10. Что я считаю следующим приоритетом после твоей сборки

Когда ты скомпилируешь, мы по `TASKS.md` переведём статусы:

- `🟡 CODE_READY` → `🟢 VERIFIED`, если работает;
- или создадим новые `BUG-xxx`, если что-то падает.

Следующие лучшие улучшения после этого:

1. **Адаптивный home screen** для планшетов и больших телефонов.
2. **Кнопка “Удалить все данные”** для соответствия приватности.
3. **Экспорт CSV рядом с PDF**, если тренеру нужна таблица.
4. **QR-код отчёта**, чтобы тренер сканировал и видел только никнейм + цифры.
5. **Переход на нативный step counter**, если захотим полноценный фоновый шагомер на весь день.

---

## Итог

Я подготовил:

- уведомление о записи;
- Android foreground service;
- локальный PDF-экспорт;
- тёмную тему;
- запрос разрешений;
- исправление критичных багов;
- обновлённый `TASKS.md`;
- чек-лист ручной проверки;
- battery-оценку;
- fallback, если foreground service сломает сборку.

Сейчас всё помечено как **CODE_READY**, а не **VERIFIED**, потому что финальную проверку может дать только твоя компиляция на ПК и установка на реальный телефон.