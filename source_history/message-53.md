
Честно: **гарантию «с первого раза пройду Google Play» не может дать ни один инженер, юрист или AI**, потому что финальное решение принимает модерация Google, и она может запросить пояснения, проверить поведение приложения, аккаунт, Data Safety, privacy policy, контентную маркировку и даже устроить ручную проверку.

Но я могу довести релиз до состояния **max release-ready**, когда отказ с вероятностью 90% будет связан не с кривым кодом, а с оформлением консоли, подписью, закрытым тестированием или заполнением форм.

Ниже — **финальные патчи кода + release-gate для Google Play**. Статус: `CODE_READY`, не `VERIFIED`, пока ты не запустишь сборку.

---

# 1. Что обязательно доделать в коде перед релизом

## 1.1. Обновить Flutter и Android target SDK

Google Play для новых приложений и обновлений требует актуальный target API. На 2026 год ориентир — **Android 15 / targetSdk 35**. Проверь официальную политику перед подачей, потому что требования меняются.

Нужен свежий stable Flutter:

```bash
flutter upgrade
flutter doctor -v
```

В `android/app/build.gradle` выставь явно:

```gradle
android {
    // Замени на свой реальный package/applicationId
    namespace = "com.dvizh.app"

    compileSdk = 35

    defaultConfig {
        // Замени на свой реальный applicationId
        applicationId = "com.dvizh.app"

        // Лучше ставить 23+, чтобы избежать старых проблем с разрешениями и плагинами
        minSdk = 23

        // Обязательно для Google Play в 2026 году, сверь с актуальными правилами
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Подпись настроим отдельно через key.properties
            // Не коммить keystore и пароли в git!
            signingConfig = signingConfigs.debug
        }
    }
}
```

Для реального релиза в Google Play подпись должна быть production, не debug. Ниже дам шаблон.

---

## 1.2. Production signing шаблон

Создай локально файл:

```text
android/key.properties
```

Пример структуры, **без коммита в git**:

```properties
storePassword=ТВОЙ_ПАРОЛЬ
keyPassword=ТВОЙ_ПАРОЛЬ
keyAlias=ТВОЙ_ALIAS
storeFile=/абсолютный/или/относительный/путь/to/upload-keystore.jks
```

В `android/app/build.gradle` добавь перед `android {`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

И внутри `android {`:

```gradle
signingConfigs {
    release {
        if (keystorePropertiesFile.exists()) {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}

buildTypes {
    release {
        if (keystorePropertiesFile.exists()) {
            signingConfig signingConfigs.release
        } else {
            signingConfig signingConfigs.debug
        }
    }
}
```

В `.gitignore` обязательно добавь:

```gitignore
android/key.properties
*.jks
*.keystore
```

Для Google Play лучше использовать **Play App Signing**: ты загружаешь upload key, а Google хранит app signing key.

---

## 1.3. Усилить `AndroidManifest.xml`

Замени `android/app/src/main/AndroidManifest.xml` на эту версию.

Главное:

- нет `INTERNET`;
- нет location;
- нет camera;
- нет microphone;
- нет contacts;
- нет SMS;
- нет foreground service;
- нет advertising ID;
- backup выключен;
- явно запрещены потенциально лишние разрешения через `tools:node="remove"`;
- добавлен `tools:replace`, чтобы библиотеки не переопределили privacy-настройки.

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
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" tools:node="remove" />
    <uses-permission android:name="android.permission.WAKE_LOCK" tools:node="remove" />
    <uses-permission android:name="android.permission.VIBRATE" tools:node="remove" />
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />

    <application
        android:label="Движ"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:fullBackupContent="false"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:usesCleartextTraffic="false"
        tools:replace="android:allowBackup,android:fullBackupContent,android:dataExtractionRules,android:usesCleartextTraffic"
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

Если при сборке R8/ProGuard или плагины начнут ругаться на удалённый `VIBRATE`/`WAKE_LOCK`, удали именно эти две строки с `tools:node="remove"` и пересобери. Но для нашей логики они не нужны.

---

## 1.4. Обновить `NotificationService`

Замени `app/lib/services/notification_service.dart` на эту версию.

Добавлено:

- запрос разрешения на уведомления;
- проверка разрешения;
- без автоматического запроса при старте приложения.

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> isPermissionGranted() async {
    final PermissionStatus status = await Permission.notification.status;
    return status.isGranted;
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

## 1.5. Обновить `SettingsScreen`

В `app/lib/screens/settings_screen.dart` замени импорт и метод запроса уведомлений.

Добавь импорт:

```dart
import '../services/notification_service.dart';
```

Замени метод `_requestNotifications()` на этот:

```dart
Future<void> _requestNotifications() async {
  final bool granted = await NotificationService.instance.requestPermission();

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
```

Это безопаснее, чем просить разрешение напрямую из экрана настроек.

---

## 1.6. Обновить `ActivityScreen`

В `app/lib/screens/activity_screen.dart` нужно сделать две вещи:

1. корректно запрашивать разрешение на движение;
2. показывать уведомление только если разрешение реально выдано.

Добавь импорт:

```dart
import 'dart:io';
```

Добавь метод в `_ActivityScreenState`:

```dart
Future<PermissionStatus> _requestMotionPermission() async {
  if (Platform.isAndroid) {
    return Permission.activityRecognition.request();
  }

  // Для iOS/других платформ permission_handler может использовать sensors.
  // Основная цель — Android/Google Play, но так код будет переносимее.
  return Permission.sensors.request();
}
```

Замени в `_start()` блок запроса разрешения на этот:

```dart
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
```

И замени показ уведомления на этот:

```dart
final bool notificationsEnabled =
    prefs.getBool('notificationsEnabled') ?? false;

if (notificationsEnabled &&
    await NotificationService.instance.isPermissionGranted()) {
  await NotificationService.instance.showOngoing(
    'Движ',
    'Идёт запись: ${widget.activityType.title}',
  );
}
```

---

## 1.7. Добавить edge-to-edge для targetSdk 35

В `app/lib/main.dart` добавь импорт:

```dart
import 'package:flutter/services.dart';
```

И после:

```dart
WidgetsFlutterBinding.ensureInitialized();
```

добавь:

```dart
await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
```

Получится начало `main()` так:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await ThemeController.load();
  await NotificationService.instance.init();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  ...
}
```

Это важно, потому что Android 15 / targetSdk 35 требует корректной работы с системными панелями. Наши экраны используют `SafeArea`, поэтому должно быть нормально, но тестировать всё равно нужно.

---

# 2. Финальный release-gate для Google Play

Чтобы повысить шанс прохождения, нужно закрыть не только код, но и консоль.

## 2.1. Аккаунт и тестирование

Если у тебя **личный аккаунт разработчика Google Play**, для нового приложения обычно требуется:

- закрытое тестирование;
- минимум **12 уникальных тестеров**;
- тестирование минимум **14 дней**;
- только после этого можно подавать в production.

Это не про код, но без этого релиз не выйдет.

Подготовь список тестеров заранее: друзья, коллеги, открытые email, которые согласятся установить тестовую сборку.

---

## 2.2. Сборка должна быть AAB, не APK

Для Google Play нужен Android App Bundle.

Собирай так:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Файл будет здесь:

```text
build/app/outputs/bundle/release/app-release.aab
```

APK можно использовать только для локального теста.

---

## 2.3. Privacy Policy должен быть по публичному URL

Google Play требует ссылку на privacy policy.Markdown в репозитории — это хорошо, но в консоль нужен URL.

Лучше всего залить на GitHub Pages:

```text
https://твой-логин.github.io/dvizh/privacy.html
```

Создай в репозитории файл:

```text
docs/privacy.html
```

Пример минимального HTML:

```html
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Privacy Policy — Движ</title>
</head>
<body>
  <h1>Privacy Policy — Движ</h1>
  <p><strong>Last updated:</strong> 2026-10-31</p>

  <h2>1. General principle</h2>
  <p>
    The app “Dvizh” is an offline tool for local physical activity tracking.
  </p>
  <ul>
    <li>The app has no server.</li>
    <li>The app does not require registration.</li>
    <li>The app does not collect name, email, phone number, address, location, weight, or medical data.</li>
    <li>The app does not use advertising.</li>
    <li>The app does not use analytics.</li>
    <li>The app does not send data to the developer.</li>
    <li>The app does not automatically send data to third parties.</li>
  </ul>

  <h2>2. Locally processed data</h2>
  <p>
    The app may locally store on the user’s device:
  </p>
  <ul>
    <li>activity type;</li>
    <li>workout start date and time;</li>
    <li>workout duration;</li>
    <li>step count calculated from the device motion sensor.</li>
  </ul>
  <p>
    These data do not leave the device.
  </p>

  <h2>3. Permissions</h2>
  <p>
    The app may request access to motion sensors to count steps during an active workout started by the user.
    Data are processed locally and are not sent to a server.
  </p>
  <p>
    If the user enables notifications, the app may show a local ongoing notification indicating that recording is active.
    Notifications are not used for advertising and do not send data outward.
  </p>

  <h2>4. Data deletion</h2>
  <p>
    The user can clear workout history or delete all app data inside the app.
    Uninstalling the app also removes local app data according to the operating system policy.
  </p>

  <h2>5. Children</h2>
  <p>
    The app is not intended for children under 14 without involvement of a parent or legal guardian.
  </p>

  <h2>6. Medical disclaimer</h2>
  <p>
    The app is not a medical device. It does not diagnose, treat, cure, or prevent any disease.
    Step counting and activity tracking are approximate and depend on the device, sensors, and how the phone is carried.
  </p>

  <h2>7. Open source</h2>
  <p>
    The source code is publicly available so independent researchers can verify the absence of network requests, analytics, advertising, and hidden data transmission.
  </p>
</body>
</html>
```

Этот URL вставляешь в Google Play Console → App content → Privacy policy.

---

## 2.4. Data Safety: что отвечать

Для версии v3.2.0 Local-Only ориентировочно:

- **Does your app collect or share any of the required user data types?**  
  Можно отвечать, что данные обрабатываются только на устройстве и не передаются разработчику. Но Google Play может требовать раскрытие on-device collection.

- **Data types:**  
  Physical activity / motion sensor data.

- **Purpose:**  
  App functionality.

- **Collection:**  
  On-device only.

- **Sharing:**  
  No.

- **Security:**  
  Data are stored locally on the user’s device.

- **User can delete data:**  
  Yes.

- **Is data encrypted in transit?**  
  N/A, because no transmission.

- **Do you allow users to request data deletion?**  
  Yes, inside the app.

Важно: ответы в Data Safety должны совпадать с реальным поведением приложения и privacy policy.

---

## 2.5. Content rating / детская аудитория

Не выбирай:

- “For kids”;
- “Target audience includes children”;
- “Schoolchildren”;
- “Children under 13/14”.

Для первой версии позиционируй как приложение для взрослых/общей аудитории.

В описании не пиши:

- “для школьников”;
- “для детей”;
- “для класса”;
- “для учителя физкультуры”;
- “для родительского контроля”.

Если хочешь позже версию для тренеров/школ, это отдельный compliance-релиз.

---

## 2.6. Медицинские заявления

Нельзя писать:

- “похудение”;
- “здоровье”;
- “калории”;
- “медицинский эффект”;
- “реабилитация”;
- “диагностика”;
- “улучшение сна”;
- “снижение риска заболеваний”.

Можно писать:

- “локальный учёт активности”;
- “подсчёт шагов”;
- “длительность тренировки”;
- “история на устройстве”.

В описании обязательно добавь дисклеймер:

```text
The app is not a medical device. It does not diagnose, treat, cure, or prevent any disease. Step counting is approximate and depends on the device and how the phone is carried.
```

---

# 3. Команды финальной проверки

Запусти в корне проекта.

## 3.1. Статический анализ

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

`flutter analyze` не должен показывать errors. Warnings лучше убрать, но для первого релиза критичны именно errors.

---

## 3.2. Сборка release AAB

```bash
flutter build appbundle --release
```

---

## 3.3. Проверка разрешений

Можно проверить debug APK:

```bash
flutter build apk --debug
```

Затем:

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
android.permission.ACCESS_NETWORK_STATE
android.permission.ACCESS_WIFI_STATE
android.permission.ACCESS_FINE_LOCATION
android.permission.ACCESS_COARSE_LOCATION
android.permission.CAMERA
android.permission.RECORD_AUDIO
android.permission.READ_CONTACTS
android.permission.READ_CALENDAR
android.permission.WRITE_CALENDAR
android.permission.READ_SMS
android.permission.RECEIVE_SMS
android.permission.FOREGROUND_SERVICE
android.permission.RECEIVE_BOOT_COMPLETED
android.permission.WAKE_LOCK
android.permission.VIBRATE
com.google.android.gms.permission.AD_ID
```

Если `aapt` не найден, используй Android Studio:

```text
Build → Analyze APK → выбрать app-debug.apk
```

Или `apkanalyzer` из Android SDK.

---

## 3.4. Проверка, что лишнее не вернулось в код

```bash
grep -RniE "weight|calories|nickname|groupCode|flutter_foreground_task|pdf|share_plus|path_provider" app/lib app/pubspec.yaml app/android/app/src/main/AndroidManifest.xml
```

Ожидаемо: пусто.

---

## 3.5. Проверка сетевых библиотек

```bash
grep -RniE "http|https|dio|socket|firebase|analytics|admob|crashlytics" app/lib app/pubspec.yaml
```

Ожидаемо: пусто.

Если находите только в комментариях/документации — не страшно, но в `app/lib` и `pubspec.yaml` должно быть чисто.

---

# 4. Обновлённые задачи в `TASKS.md`

Добавь в свой трекер вот эти задачи.

```markdown
## Release v3.2.0 Google Play Ready

### REL-001: Обновить target SDK до 35 🟡 CODE_READY
**Файл:** `android/app/build.gradle`  
**Действие:** compileSdk 35, targetSdk 35, minSdk 23, namespace.  
**Проверка:** сборка проходит, приложение запускается на Android 13/14/15.

### REL-002: Настроить production signing 🟡 CODE_READY
**Файлы:**
- `android/key.properties` — локально, не в git
- `android/app/build.gradle`

**Действие:** использовать release signing, не debug.  
**Проверка:** `flutter build appbundle --release` создаёт подписанный AAB.

### REL-003: Harden AndroidManifest 🟡 CODE_READY
**Файл:** `android/app/src/main/AndroidManifest.xml`  
**Действие:** удалить INTERNET, location, camera, microphone, contacts, SMS, foreground service, AD_ID, wake lock, vibrate, boot completed.  
**Проверка:** `aapt dump permissions` показывает только разрешённые permissions.

### REL-004: Notification permission hardening 🟡 CODE_READY
**Файлы:**
- `app/lib/services/notification_service.dart`
- `app/lib/screens/settings_screen.dart`
- `app/lib/screens/activity_screen.dart`

**Действие:** уведомление показывается только если разрешение реально выдано.  
**Проверка:** выключить уведомления в системе, начать запись — приложение не падает и не показывает уведомление.

### REL-005: Edge-to-edge для Android 15 🟡 CODE_READY
**Файл:** `app/lib/main.dart`  
**Действие:** включить `SystemUiMode.edgeToEdge`.  
**Проверка:** UI не залезает под системные панели на Android 14/15.

### REL-006: Privacy policy public URL 🔴 TODO
**Действие:** опубликовать `privacy.html` на GitHub Pages или другом публичном хостинге.  
**Проверка:** URL открывается без авторизации, содержит актуальную дату.

### REL-007: Google Play Data Safety 🔴 TODO
**Действие:** заполнить форму Data Safety в консоли.  
**Проверка:** ответы совпадают с кодом и privacy policy.

### REL-008: Content rating и аудитория 🔴 TODO
**Действие:** пройти анкету IARC, не выбирать детскую аудиторию.  
**Проверка:** в store listing нет слов “для детей”, “школьников”, “класса”, “родителей”.

### REL-009: Closed testing 12 testers / 14 days 🔴 TODO
**Действие:** если личный аккаунт, запустить закрытое тестирование.  
**Проверка:** Google Play Console показывает выполнение требования.

### REL-010: Store listing final 🔴 TODO
**Действие:** подготовить название, короткое описание, полное описание, скриншоты, release notes.  
**Проверка:** нет медицинских обещаний, нет персональных данных на скриншотах.

### REL-011: Manual smoke test on real devices 🔴 TODO
**Устройства минимум:**
- Samsung;
- Xiaomi/Redmi;
- Pixel;
- Tecno/Infinix, если Possible;
- Android 13/14/15.

**Проверить:**
- первый запуск;
- consent;
- разрешения;
- запись;
- историю;
- очистку;
- удаление данных;
- уведомления;
- тёмную тему;
- отсутствие крашей.
```

---

# 5. Store listing: безопасный текст для Google Play

## Название

```text
Движ — offline activity tracker
```

Или:

```text
Движ: local step tracker
```

Лучше использовать английское название, если подаёшь в global Google Play. Русское можно оставить как локализацию.

---

## Короткое описание

```text
Simple offline activity tracker. No account, no internet, no ads, no analytics.
```

---

## Полное описание

```text
“Dvizh” is a simple offline mobile app for local physical activity tracking.

What it can do:
• choose activity type: walking, running, or workout;
• count steps using the device motion sensor;
• track workout duration;
• store history only on the device;
• let the user disable recording;
• let the user disable notifications;
• let the user clear history;
• let the user delete all local data.

Privacy:
• the app works offline;
• no registration;
• no server;
• no advertising;
• no analytics;
• no crash reporting;
• no location access;
• no camera access;
• no microphone access;
• no contacts access;
• no personal data collection;
• no automatic data sharing with the developer or third parties.

Important:
The app is not a medical device. It does not diagnose, treat, cure, or prevent any disease. Step counting and activity tracking are approximate and depend on the device, sensors, and how the phone is carried.
```

---

## Release notes

```text
v3.2.0 Local-Only

- Removed weight and calories.
- Removed nicknames and group codes.
- Removed PDF export and sharing.
- Removed foreground service.
- Added privacy consent screen.
- Added recording toggle.
- Added notifications toggle.
- Added clear history.
- Added delete all data.
- Hardened Android permissions.
- Disabled backup.
- Prepared for open-source distribution.
```

---

# 6. Что я считаю остаточными рисками даже после этих правок

## 6.1. Плагины могут неожиданно добавить разрешения

Нужно проверять не наш исходный manifest, а **merged manifest** или готовый AAB/APK.

Если `INTERNET` всё-таки появится, нужно найти источник:

```bash
flutter pub deps
```

и смотреть, какой плагин тянет network.

---

## 6.2. `flutter_local_notifications` может потребовать канал/разрешения

Мы не просим разрешение автоматически. Но на Android 13+ уведомление не покажется без `POST_NOTIFICATIONS`. Наш код это учитывает.

---

## 6.3. Xiaomi/Tecno/Huawei могут убивать фон

Это не нарушение Google Play, но пользователь может жаловаться: “шаги не считаются”. Для первой версии мы честно пишем:

```text
For reliable recording, do not fully close the app and allow background activity in device settings if required.
```

---

## 6.4. Точность шагов

Акселерометр даёт погрешность. В описании есть дисклеймер. Это важно.

---

## 6.5. Личный аккаунт Google Play и closed testing

Если ты подаёшь как физлицо, требование 12 тестеров / 14 дней может быть главным блокером. Код может быть идеальным, но production не откроется, пока не выполнено тестирование.

---

# 7. Мой честный ответ на “сможешь допить, чтобы с первого раза прошло?”

**Код я могу довести до release-ready состояния.**  
**Релизный пакет, чек-листы, тексты, манифест, privacy policy, команды проверки — могу подготовить полностью.**

Но **гарантировать прохождение Google Play с первого раза я не могу**, потому что на результат влияют:

1. твой аккаунт разработчика;
2. корректность подписи;
3. AAB;
4. target SDK;
5. Data Safety;
6. privacy policy URL;
7. content rating;
8. store listing;
9. скриншоты;
10. закрытое тестирование;
11. поведение модератора;
12. актуальные правила Google на дату подачи.

Я могу сделать так, чтобы с высокой вероятностью **отказ не был по техническим причинам**. Для этого тебе нужно:

1. применить патчи выше;
2. запустить `flutter analyze`;
3. собрать AAB;
4. проверить permissions;
5. опубликовать privacy policy;
6. заполнить Google Play Console по чек-листу;
7. пройти closed testing, если аккаунт личный.

---

# 8. Что я могу сделать следующим сообщением прямо сейчас

Выбери один вариант:

## Вариант A: “Собери финальный ZIP-скрипт”

Я дам один Python-скрипт, который создаст:

```text
Dvizh_v3.2.0_release_ready.zip
```

внутри:

- обновлённые Dart-файлы;
- AndroidManifest;
- build.gradle snippet;
- privacy.html;
- Google Play checklist;
- TASKS.md;
- release notes;
- store listing texts.

## Вариант B: “Дай только diff/патчи”

Я выдам минимальные замены по файлам, чтобы ты вручную применил их к текущему проекту.

## Вариант C: “Проверь мой вывод flutter analyze”

Ты запускаешь:

```bash
flutter analyze
flutter build apk --debug
```

и присылаешь вывод. Я разберу ошибки точечно и дам фиксы.

## Вариант D: “Подготовь Google Play Console forms”

Я распишу по полям:

- App name;
- Summary;
- Description;
- Data Safety;
- Privacy policy;
- Content rating;
- Target audience;
- App access;
- Ads;
- Analytics;
- Security;
- Release notes.

---

Моя рекомендация: сначала **Вариант C**, потому что без реального вывода `flutter analyze` и сборки мы не узнаем, есть ли скрытые ошибки совместимости. После чистого `analyze` и `build appbundle` можно делать **Вариант A** или **D**.