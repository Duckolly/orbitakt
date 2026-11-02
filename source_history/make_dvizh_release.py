from pathlib import Path
import zipfile

ROOT = Path("Dvizh_v3.2.0_release_ready")

files = {
    "README.md": """# Движ

Простое офлайн-приложение для локального учёта физической активности.

Repository: https://github.com/Duckolly/dvizh  
Author: Sergey Shvetsov

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
- без камеры;
- без микрофона;
- без контактов;
- без сбора ФИО, телефона, email, адреса, веса и медицинских данных.

Все данные хранятся только на устройстве пользователя.

## Дисклеймер

Приложение не является медицинским изделием. Оно не ставит диагнозы, не лечит и не заменяет консультацию врача. Точность подсчёта шагов зависит от устройства, датчиков и того, как пользователь носит телефон.

## Лицензия

MIT. См. файл `LICENSE`.
""",

    "LICENSE": """MIT License

Copyright (c) 2026 Sergey Shvetsov (https://github.com/Duckolly)

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
""",

    "PRIVACY.md": """# Privacy Policy — Движ

**Last updated:** 2026-10-31  
**Maintainer:** Sergey Shvetsov  
**Repository:** https://github.com/Duckolly/dvizh

## 1. General principle

The app “Dvizh” is an offline tool for local physical activity tracking.

The app:

- has no server;
- does not require registration;
- does not collect name, email, phone number, address, location, weight, or medical data;
- does not use advertising;
- does not use analytics;
- does not use crash reporting;
- does not send data to the developer;
- does not automatically send data to third parties.

## 2. Locally processed data

The app may locally store on the user’s device:

- activity type;
- workout start date and time;
- workout duration;
- step count calculated from the device motion sensor.

These data do not leave the device.

In version v3.2.0, file export and sharing are disabled.

## 3. Permissions

### Motion sensor access

The app may request access to motion sensors to count steps during an active workout started by the user.

Data are processed locally and are not sent to a server.

### Notifications

If the user enables notifications, the app may show a local ongoing notification indicating that recording is active.

Notifications are not used for advertising and do not send data outward.

## 4. Data deletion

All data are stored only on the user’s device.

The user can:

- clear workout history;
- delete all app data inside the app;
- uninstall the app, after which the operating system removes local app data according to its policy.

## 5. Children

The app is not intended for children under 14 without involvement of a parent or legal guardian.

Parents or legal guardians should control app usage by children.

## 6. Medical information

The app is not a medical device. It does not diagnose, treat, cure, or prevent any disease.

Step counting and activity tracking are approximate and depend on the device, sensors, and how the phone is carried.

## 7. Open source

The source code is publicly available so independent researchers can verify the absence of network requests, analytics, advertising, and hidden data transmission.

## 8. Contacts

For privacy questions, open an issue in the public repository or contact the maintainer through the method specified in the repository.
""",

    "CHANGELOG.md": """# Changelog

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
""",

    "RELEASE_NOTES_v3.2.0.md": """# Release Notes — Движ v3.2.0 Local-Only

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
""",

    "TASKS.md": """# Трекер задач и релизов — Движ

## Статусы
- TODO — не начато
- CODE_READY — код подготовлен, ожидает компиляции и ручного теста
- VERIFIED — проверено на устройстве
- DEFERRED — отложено

---

## Релиз v3.2.0 Local-Only

### BUG-001: Ошибка интерполяции строк в таймере — CODE_READY
**Файл:** `app/lib/screens/activity_screen.dart`  
**Проблема:** Была некорректная строка с экранированным символом валюты.  
**Фикс:** Исправлена интерполяция времени.  
**Проверка после сборки:** Таймер отображается как `00:00:30`.

### BUG-002: Нет корректного запроса разрешения на датчики движения — CODE_READY
**Файл:** `app/lib/screens/activity_screen.dart`  
**Проблема:** Разрешение не запрашивалось до начала записи.  
**Фикс:** Добавлен запрос разрешения после consent и при включённой записи.  
**Проверка после сборки:** При первом нажатии «Начать» появляется системный запрос разрешения.

### REMOVE-001: Удалить сбор веса — CODE_READY
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

### REMOVE-002: Удалить никнеймы — CODE_READY
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

### REMOVE-003: Удалить коды групп — CODE_READY
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

### REMOVE-004: Удалить foreground service — CODE_READY
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

### REMOVE-005: Отключить PDF и share — CODE_READY
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

### CODE-010: Privacy consent screen — CODE_READY
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

### CODE-011: Master toggle «Разрешить запись» — CODE_READY
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

### CODE-012: Toggle уведомлений — CODE_READY
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

### CODE-013: Очистить историю — CODE_READY
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

### CODE-014: Удалить все данные — CODE_READY
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

### MANIFEST-002: Harden AndroidManifest — CODE_READY
**Файл:** `app/android/app/src/main/AndroidManifest.xml`

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

### REL-001: Обновить target SDK до 35 — CODE_READY
**Файл:** `android/app/build.gradle`  
**Действие:** compileSdk 35, targetSdk 35, minSdk 23, namespace.  
**Проверка:** сборка проходит, приложение запускается на Android 13/14/15.

### REL-002: Настроить production signing — CODE_READY
**Файлы:**
- `android/key.properties` — локально, не в git
- `android/app/build.gradle`

**Действие:** использовать release signing, не debug.  
**Проверка:** `flutter build appbundle --release` создаёт подписанный AAB.

### REL-003: Notification permission hardening — CODE_READY
**Файлы:**
- `app/lib/services/notification_service.dart`
- `app/lib/screens/settings_screen.dart`
- `app/lib/screens/activity_screen.dart`

**Действие:** уведомление показывается только если разрешение реально выдано.  
**Проверка:** выключить уведомления в системе, начать запись — приложение не падает и не показывает уведомление.

### REL-004: Edge-to-edge для Android 15 — CODE_READY
**Файл:** `app/lib/main.dart`  
**Действие:** включить `SystemUiMode.edgeToEdge`.  
**Проверка:** UI не залезает под системные панели на Android 14/15.

### REL-005: Privacy policy public URL — TODO
**Действие:** опубликовать `docs/privacy.html` на GitHub Pages или другом публичном хостинге.  
**Проверка:** URL открывается без авторизации, содержит актуальную дату.

### REL-006: Google Play Data Safety — TODO
**Действие:** заполнить форму Data Safety в консоли.  
**Проверка:** ответы совпадают с кодом и privacy policy.

### REL-007: Content rating и аудитория — TODO
**Действие:** пройти анкету IARC, не выбирать детскую аудиторию.  
**Проверка:** в store listing нет слов “для детей”, “школьников”, “класса”, “родителей”.

### REL-008: Closed testing 12 testers / 14 days — TODO
**Действие:** если личный аккаунт, запустить закрытое тестирование.  
**Проверка:** Google Play Console показывает выполнение требования.

### REL-009: Store listing final — TODO
**Действие:** подготовить название, короткое описание, полное описание, скриншоты, release notes.  
**Проверка:** нет медицинских обещаний, нет персональных данных на скриншотах.

### REL-010: Manual smoke test on real devices — TODO
**Устройства минимум:**
- Samsung;
- Xiaomi/Redmi;
- Pixel;
- Tecno/Infinix, если возможно;
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

---

## Лог изменений

| Дата | Задача | Статус | Комментарий |
|------|--------|--------|-------------|
| 2026-10-31 | v3.2.0 Local-Only | CODE_READY | Подготовлены файлы релиза |
| 2026-10-31 | REMOVE-001..005 | CODE_READY | Убраны вес, калории, группы, никнеймы, PDF, share, foreground service |
| 2026-10-31 | CODE-010..014 | CODE_READY | Добавлены consent, toggles, очистка и удаление данных |
| 2026-10-31 | MANIFEST-002 | CODE_READY | Манифест усилен |
| 2026-10-31 | REL-001..004 | CODE_READY | Подготовка к Google Play |
| 2026-10-31 | REL-005..010 | TODO | Финальные магазинные и ручные проверки |
""",

    "GOOGLE_PLAY_RELEASE_CHECKLIST.md": """# Google Play Release Checklist — Движ v3.2.0

## 1. Аккаунт и релизный процесс

- [ ] Аккаунт разработчика Google Play создан.
- [ ] Если аккаунт личный, выполнено требование закрытого тестирования:
  - минимум 12 уникальных тестеров;
  - минимум 14 дней тестирования.
- [ ] Приложение подаётся как AAB, не APK.
- [ ] Используется Play App Signing или надёжно хранится upload keystore.
- [ ] `key.properties` и keystore не закоммичены в git.

---

## 2. Сборка

Выполни:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Ожидаемый файл:

```text
build/app/outputs/bundle/release/app-release.aab
```

- [ ] `flutter analyze` без errors.
- [ ] `flutter test` без падений.
- [ ] `flutter build appbundle --release` успешен.

---

## 3. Разрешения

Проверь debug APK:

```bash
flutter build apk --debug
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

- [ ] Нет `INTERNET`.
- [ ] Нет location.
- [ ] Нет camera.
- [ ] Нет microphone.
- [ ] Нет contacts.
- [ ] Нет SMS.
- [ ] Нет AD_ID.
- [ ] Нет foreground service.

Если какое-то разрешение появилось от плагина:

1. найди плагин через `flutter pub deps`;
2. удали плагин, если он не нужен;
3. либо оставь `tools:node="remove"` в манифесте;
4. пересобери и проверь снова.

---

## 4. Privacy Policy

- [ ] Файл `PRIVACY.md` есть в репозитории.
- [ ] Файл `docs/privacy.html` есть в репозитории.
- [ ] HTML опубликован по публичному URL.
- [ ] URL открывается без авторизации.
- [ ] В Google Play Console указан этот URL.
- [ ] Дата обновления в policy актуальна.

Пример URL:

```text
https://duckolly.github.io/dvizh/privacy.html
```

---

## 5. Data Safety

Примерные ответы для v3.2.0 Local-Only:

- Data collected: physical activity / motion sensor data.
- Purpose: app functionality.
- Collection: on-device only.
- Sharing: no.
- Encryption in transit: not applicable, no transmission.
- User can delete data: yes.
- Developer does not receive data: yes.

- [ ] Форма Data Safety заполнена.
- [ ] Ответы не противоречат коду.
- [ ] Ответы не противоречат privacy policy.
- [ ] Указано, что данные не передаются разработчику.
- [ ] Указано, что пользователь может удалить данные в приложении.

---

## 6. Content rating и аудитория

- [ ] Пройдена анкета IARC.
- [ ] Не выбрана детская аудитория.
- [ ] В описании нет слов:
  - children;
  - kids;
  - schoolchildren;
  - students;
  - classroom;
  - parent control.
- [ ] Приложение позиционируется как general/offline activity tracker.

---

## 7. Медицинские заявления

Нельзя писать:

- weight loss;
- health improvement;
- medical;
- diagnosis;
- treatment;
- calories burned as medical metric;
- rehabilitation.

Можно писать:

- local activity tracking;
- step counting;
- workout duration;
- offline history.

- [ ] В описании есть дисклеймер, что приложение не медицинское.
- [ ] В privacy policy есть медицинский дисклеймер.

---

## 8. Store listing

Используй тексты из `STORE_LISTING.md`.

- [ ] Название понятное.
- [ ] Короткое описание не обещает здоровье/похудение.
- [ ] Полное описание содержит privacy и medical disclaimer.
- [ ] Скриншоты не содержат реальных персональных данных.
- [ ] Release notes соответствуют версии v3.2.0.

---

## 9. Ручной smoke test

### Первый запуск

- [ ] Открывается экран согласия.
- [ ] Кнопка «Продолжить» неактивна, пока не поставлены все галочки.
- [ ] После галочек открывается главный экран.
- [ ] Разрешения пока не запрашиваются.

### Запись

- [ ] Выбираешь «Ходьба».
- [ ] Нажимаешь «Начать».
- [ ] Запрашивается доступ к датчикам движения.
- [ ] После разрешения таймер запускается.
- [ ] Шаги считаются при ходьбе/встряхивании.
- [ ] Нажимаешь «Стоп».
- [ ] Тренировка сохраняется.
- [ ] Возвращаешься на главный экран.

### История

- [ ] Открываешь историю.
- [ ] Видишь сохранённую тренировку.
- [ ] Нажимаешь «Очистить историю».
- [ ] Подтверждаешь удаление.
- [ ] История становится пустой.
- [ ] После перезапуска приложения история всё ещё пуста.

### Настройки

- [ ] Выключаешь «Разрешить запись активности».
- [ ] Пробуешь начать тренировку.
- [ ] Появляется сообщение, что запись отключена.
- [ ] Включаешь обратно.
- [ ] Тренировка снова доступна.

### Уведомления

- [ ] Выключаешь уведомления.
- [ ] Начинаешь запись.
- [ ] Уведомление не появляется.
- [ ] Включаешь уведомления.
- [ ] Система запрашивает разрешение.
- [ ] После разрешения уведомление появляется во время записи.
- [ ] После остановки уведомление исчезает.

### Удаление всех данных

- [ ] Нажимаешь «Удалить все данные».
- [ ] Подтверждаешь.
- [ ] Приложение возвращается на экран согласия.
- [ ] История пуста.
- [ ] Настройки сброшены.

---

## 10. Финальная проверка перед submit

- [ ] AAB собран в release.
- [ ] Подпись release корректна.
- [ ] Permissions проверены.
- [ ] Privacy policy URL работает.
- [ ] Data Safety заполнена.
- [ ] Content rating пройдена.
- [ ] Store listing заполнена.
- [ ] Closed testing выполнено, если требуется.
- [ ] Нет личных данных в репозитории.
- [ ] Нет keystore/passwords в git.
""",

    "STORE_LISTING.md": """# Store Listing — Движ v3.2.0

## App name

```text
Движ — offline activity tracker
```

Alternative:

```text
Dvizh: local step tracker
```

---

## Short description

```text
Simple offline activity tracker. No account, no internet, no ads, no analytics.
```

---

## Full description

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

## Permission explanations

### ACTIVITY_RECOGNITION

```text
This permission is used only to access the device motion sensor in order to count steps during an active workout started by the user. Data are processed locally and are not sent to a server.
```

### POST_NOTIFICATIONS

```text
This permission is used only if the user enables notifications. The app shows a local ongoing notification indicating that recording is active. Notifications do not contain personal data and are not used for advertising.
```
""",

    "COPYRIGHT_FIXATION.md": """# Copyright Fixation — Движ v3.2.0

Это не юридическая консультация, а практический инженерный способ зафиксировать дату наличия кода и документации.

## Шаг 1. Создай ZIP

Запусти:

```bash
python make_dvizh_release.py
```

Получишь:

```text
Dvizh_v3.2.0_release_ready.zip
```

## Шаг 2. Переименуй архив с датой

Пример:

```text
Dvizh_v3.2.0_2026-10-31_SergeyShvetsov.zip
```

## Шаг 3. Посчитай SHA-256

Linux/macOS/Git Bash:

```bash
sha256sum Dvizh_v3.2.0_2026-10-31_SergeyShvetsov.zip
```

Windows PowerShell:

```powershell
Get-FileHash .\\Dvizh_v3.2.0_2026-10-31_SergeyShvetsov.zip -Algorithm SHA256
```

Скопируй хэш.

## Шаг 4. Отправь архив самому себе на email

Тема письма:

```text
ФИКСАЦИЯ АВТОРСКОГО ПРАВА: Движ v3.2.0 — 2026-10-31 — Sergey Shvetsov
```

В теле письма укажи:

```text
Автор: Sergey Shvetsov
GitHub: https://github.com/Duckolly
Проект: Движ — offline activity tracker
Версия: v3.2.0 Local-Only
Дата фиксации: 2026-10-31
SHA-256 архива: [вставь хэш]
```

## Шаг 5. Сохрани письмо

- не удаляй письмо;
- сделай скриншот заголовка с датой;
- сохрани архив и хэш в надёжном месте.

## Дополнительно

Для официальной регистрации можно использовать:

- Роспатент / Реестр программ для ЭВМ;
- депонирование кода;
- нотариальное обеспечение доказательств.

Для открытого кода на GitHub также полезно:

- первый коммит с датой;
- signed commits, если настроишь GPG;
- релиз с тегом `v3.2.0`.
""",

    ".gitignore": """# Flutter/Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
pubspec.lock

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# Secrets / signing
android/key.properties
*.jks
*.keystore
google-services.json
GoogleService-Info.plist

# Local notes
LOCAL_NOTES.md
DRAFTS/
PRIVATE/
""",

    "analysis_options.yaml": """include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
    prefer_final_locals: true
""",

    "docs/privacy.html": """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Privacy Policy — Dvizh</title>
</head>
<body>
  <h1>Privacy Policy — Dvizh</h1>
  <p><strong>Last updated:</strong> 2026-10-31</p>
  <p><strong>Maintainer:</strong> Sergey Shvetsov</p>
  <p><strong>Repository:</strong> <a href="https://github.com/Duckolly/dvizh">https://github.com/Duckolly/dvizh</a></p>

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
    <li>The app does not use crash reporting.</li>
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
  <p>
    In version v3.2.0, file export and sharing are disabled.
  </p>

  <h2>3. Permissions</h2>
  <h3>Motion sensor access</h3>
  <p>
    The app may request access to motion sensors to count steps during an active workout started by the user.
    Data are processed locally and are not sent to a server.
  </p>

  <h3>Notifications</h3>
  <p>
    If the user enables notifications, the app may show a local ongoing notification indicating that recording is active.
    Notifications are not used for advertising and do not send data outward.
  </p>

  <h2>4. Data deletion</h2>
  <p>
    All data are stored only on the user’s device.
  </p>
  <p>
    The user can:
  </p>
  <ul>
    <li>clear workout history;</li>
    <li>delete all app data inside the app;</li>
    <li>uninstall the app, after which the operating system removes local app data according to its policy.</li>
  </ul>

  <h2>5. Children</h2>
  <p>
    The app is not intended for children under 14 without involvement of a parent or legal guardian.
  </p>

  <h2>6. Medical information</h2>
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
""",

    "app/pubspec.yaml": """name: dvizh
description: Offline local activity tracker without personal data collection
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
""",

    "app/android/app/src/main/AndroidManifest.xml": """<?xml version="1.0" encoding="utf-8"?>
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
""",

    "app/android/app/src/main/res/xml/data_extraction_rules.xml": """<?xml version="1.0" encoding="utf-8"?>
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
""",

    "app/android/app/build.gradle.release-patch.md": """# Android build.gradle release patch

Примени эти изменения к файлу:

```text
android/app/build.gradle
```

Не коммить `key.properties` и keystore в git.

---

## 1. Добавь чтение key.properties перед блоком `android`

Добавь в начало файла, после `plugins { ... }`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

---

## 2. Внутри `android {` выставь SDK

```gradle
android {
    namespace = "com.dvizh.app"

    compileSdk = 35

    defaultConfig {
        applicationId = "com.dvizh.app"

        minSdk = 23

        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

Если у тебя уже другой `namespace` или `applicationId`, замени на свой.  
Для Google Play лучше использовать стабильный reverse-domain ID, например:

```text
com.dvizh.app
```

или

```text
dev.duckolly.dvizh
```

---

## 3. Добавь release signing

Внутри `android {` добавь:

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
```

---

## 4. Замени `buildTypes.release`

```gradle
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

Для реального релиза в Google Play подпись должна быть production, не debug.

---

## 5. Локальный файл `android/key.properties`

Создай локально, не в git:

```properties
storePassword=ТВОЙ_ПАРОЛЬ
keyPassword=ТВОЙ_ПАРОЛЬ
keyAlias=ТВОЙ_ALIAS
storeFile=/путь/to/upload-keystore.jks
```

Добавь в `.gitignore`:

```gitignore
android/key.properties
*.jks
*.keystore
```

---

## 6. Сборка AAB

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Файл:

```text
build/app/outputs/bundle/release/app-release.aab
```
""",

    "app/ios/Runner/Info.plist.patch.md": """# iOS Info.plist note

Для iOS добавь в `ios/Runner/Info.plist`:

```xml
<key>NSMotionUsageDescription</key>
<string>The app needs access to motion sensors to count steps during local workouts.</string>
```

Не добавляй разрешения на интернет, камеру, микрофон, контакты, геолокацию.

Для первой версии основной таргет — Android / Google Play. iOS можно выпускать позже после стабилизации Android-версии.
""",

    "app/lib/main.dart": """import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/consent_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
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

    "app/lib/models/activity.dart": """import 'package:flutter/material.dart';

enum ActivityType {
  walking('Ходьба', Icons.directions_walk),
  running('Бег', Icons.directions_run),
  workout('Зарядка', Icons.fitness_center);

  final String title;
  final IconData icon;

  const ActivityType(this.title, this.icon);
}
""",

    "app/lib/models/workout.dart": """import 'activity.dart';

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
""",

    "app/lib/services/sensor_service.dart": """import 'dart:async';
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
""",

    "app/lib/services/storage_service.dart": """import 'package:path/path.dart';
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
""",

    "app/lib/services/notification_service.dart": """import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
""",

    "app/lib/theme/app_theme.dart": """import 'package:flutter/material.dart';

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
""",

    "app/lib/theme/theme_controller.dart": """import 'package:flutter/material.dart';
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
""",

    "app/lib/screens/consent_screen.dart": """import 'package:flutter/material.dart';
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
                'Это офлайн-приложение для локального учёта активности.\\n\\n'
                'Оно:\\n'
                '• не требует регистрации;\\n'
                '• не отправляет данные на сервер;\\n'
                '• не использует рекламу;\\n'
                '• не использует аналитику;\\n'
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
""",

    "app/lib/screens/home_screen.dart": """import 'package:flutter/material.dart';

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
""",

    "app/lib/screens/activity_screen.dart": """import 'dart:async';
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
""",

    "app/lib/screens/history_screen.dart": """import 'package:flutter/material.dart';
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
""",

    "app/lib/screens/settings_screen.dart": """import 'package:flutter/material.dart';
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
""",
}

def write_files() -> None:
    for rel_path, content in files.items():
        target = ROOT / rel_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        print(f"created: {target}")

def make_zip() -> Path:
    zip_path = Path("Dvizh_v3.2.0_release_ready.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(ROOT.rglob("*")):
            if path.is_file():
                arcname = path.relative_to(ROOT.parent)
                zf.write(path, arcname)
    return zip_path

if __name__ == "__main__":
    print("Creating Dvizh v3.2.0 release-ready package...")
    write_files()
    archive = make_zip()
    print("")
    print(f"Done. Archive created: {archive}")
    print("Next steps:")
    print("1. Extract the archive into your Flutter project or use its files as patch source.")
    print("2. Apply android/app/build.gradle.release-patch.md.")
    print("3. Run: flutter clean && flutter pub get && flutter analyze && flutter build appbundle --release")
    print("4. Check permissions with aapt dump permissions.")
    print("5. Publish docs/privacy.html and fill Google Play Console.")
