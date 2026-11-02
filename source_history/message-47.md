
Да — это очень правильный разворот. Если цель — **открытый код, помощь людям, без сбора веса, без групп, без никнеймов, без отправки данных**, то приложение можно сделать заметно проще и безопаснее для Google Play.

Важная оговорка: я **не могу гарантировать прохождение модерации Google Play** и не являюсь юристом. Но я могу подготовить инженерно-合规-чеклист, который сильно повышает шансы и делает проект понятным для reviewers, пользователей и открытого кода.

Ниже — отдельный файл, который можно сохранить как:

```text
GOOGLE_PLAY_AND_OPEN_SOURCE_READINESS.md
```

Он учитывает:

- удаление веса;
- удаление групп;
- удаление никнеймов;
- удаление калорий как производного от веса;
- очистку истории;
- удаление всех данных;
- отключение функции записи;
- отсутствие foreground service в первой store-версии;
- открытый код на GitHub;
- подготовку к Google Play Data Safety;
- privacy policy;
- лицензию;
- store listing;
- проверку манифеста;
- отказ от детской аудитории в первой версии.

---

````markdown
# Google Play & Open Source Readiness — Движ v3.2 Local-Only

**Проект:** Движ  
**Версия для подготовки:** v3.2 Local-Only  
**Статус:** Planning / Code-change required  
**Цель:** Открытое офлайн-приложение для локального учёта физической активности без сбора персональных данных.  
**Платформы приоритетно:** Android / Google Play. iOS и RuStore — позже, после стабилизации Android-версии.

---

## 1. Главный принцип версии v3.2

Приложение должно быть максимально простым и безопасным:

> Пользователь открывает приложение, выбирает активность, нажимает «Начать», ходит/бегает/делает зарядку, нажимает «Стоп», видит локальную историю. Всё хранится только на устройстве. Никаких серверов, аккаунтов, аналитики, рекламы, веса, групп, никнеймов и автоматической отправки данных.

---

## 2. Что убираем из текущей версии

### 2.1. Убираем сбор веса

**Причина:**

- вес может относиться к данным о здоровье;
- вес нужен только для расчёта калорий;
- без веса расчёт калорий некорректен;
- для Google Play и приватности лучше не трогать медицинские/около-медицинские данные.

**Решение:**

- удалить поле `weight`;
- удалить сохранение веса в `SharedPreferences`;
- удалить расчёт калорий;
- удалить отображение калорий в истории и отчётах;
- удалить `mets` из бизнес-логики, если он больше не используется.

### 2.2. Убираем калории

**Причина:**

Калории без веса — это либо гадание, либо медицински-подобная оценка. Для store-safe версии это лишний риск.

**Решение:**

- не показывать калории;
- не сохранять калории;
- не экспортировать калории;
- в описании не использовать формулировки «сожжённые калории», «похудение», «здоровье», «медицинский эффект».

### 2.3. Убираем никнеймы

**Причина:**

Никнейм может быть косвенным идентификатором, особенно если пользователь введёт имя, фамилию, класс, номер телефона или соцсетевой ник.

**Решение:**

- удалить поле `nickname`;
- удалить сохранение никнейма;
- не要求 user input для идентификации;
- в локальной истории запись принадлежит только устройству, без имени.

### 2.4. Убираем коды групп

**Причина:**

Код группы + история активности могут создавать групповой реестр и приближать приложение к обработке персональных данных несовершеннолетних или корпоративных сотрудников.

**Решение:**

- удалить поле `groupCode`;
- удалить экран/настройку кода группы;
- удалить групповые отчёты;
- не позиционировать первую версию как инструмент для школ, секций, классов или корпоративных HR-челленджей.

### 2.5. Убираем foreground service из первой store-версии

**Причина:**

`flutter_foreground_task` повышает риск вопросов от Google Play:

- нужен честный `foregroundServiceType`;
- нужно обоснование фоновой работы;
- может восприниматься как злоупотребление фоновым режимом;
- увеличивает расход батареи;
- усложняет аудит.

**Решение:**

- удалить зависимость `flutter_foreground_task`;
- удалить `ForegroundService.start()` и `ForegroundService.stop()`;
- оставить только обычное ongoing-уведомление, если пользователь включил уведомления;
- в UI предупредить: для надёжной записи не закрывайте приложение полностью и разрешите фоновую работу в настройках телефона, если это требуется.

### 2.6. Экспорт PDF и share откладываем

Для первой Google Play-версии я рекомендую убрать PDF и `share_plus`.

**Причина:**

- экспорт может содержать локальные данные пользователя;
- системный share открывает внешние приложения;
- для Data Safety нужно объяснять, куда пользователь может отправить данные;
- без групп и никнеймов тренерский use case пока не является основным.

**Решение:**

- удалить `pdf`;
- удалить `share_plus`;
- удалить кнопку «Сохранить / отправить PDF»;
- удалить экран отчёта для тренера или превратить его в локальный экран «История».

Если позже захотим вернуть экспорт, сделаем это как отдельную feature-flag-версию после юридической проверки.

---

## 3. Что оставляем в v3.2

Минимальный безопасный функционал:

1. Выбор активности:
   - Ходьба;
   - Бег;
   - Зарядка / произвольная активность.

2. Запись сессии:
   - таймер;
   - счётчик шагов через акселерометр;
   - кнопка «Начать»;
   - кнопка «Стоп».

3. Локальная история:
   - дата;
   - тип активности;
   - длительность;
   - количество шагов.

4. Управление данными:
   - очистить историю;
   - удалить все данные;
   - отключить запись;
   - отключить уведомления.

5. Приватность:
   - экран согласия перед первым запросом разрешений;
   - подтверждение возраста;
   - отсутствие интернета;
   - отсутствие аналитики;
   - отсутствие рекламы;
   - отсутствие аккаунтов;
   - отсутствие сервера.

---

## 4. Целевая аудитория первой версии

### Можно

- взрослые пользователи;
- коллеги;
- друзья;
- люди, которым нужен простой офлайн-счётчик активности;
- open-source сообщество.

### Нельзя или очень осторожно

- школьники младше 14 лет;
- дети без родительского согласия;
- корпоративные сотрудники в рамках HR-программ;
- медицинские рекомендации;
- лечение, диагностика, реабилитация;
- обещания похудения или здоровья.

### Рекомендуемая позиция в stores

> Приложение предназначено для общих фитнес-целей взрослых пользователей. Оно не предназначено для детей и не является медицинским изделием.

Возрастная маркировка: ориентировочно **12+** или выше, но финально выбирать по IARC / политике Google Play и локальному праву.

---

## 5. Google Play: ключевые риски и как их закрываем

| Риск | Как закрываем в v3.2 |
|---|---|
| Сбор персональных данных | Не собираем ФИО, телефон, email, адрес, аккаунт, группу, никнейм |
| Данные о здоровье | Убираем вес и калории |
| Детская аудитория | Не позиционируем для детей, ставим возрастные ограничения |
| Фоновая работа | Убираем foreground service |
| Интернет-утечки | Не добавляем `INTERNET`, проверяем merged manifest |
| Аналитика / реклама | Не используем Firebase Analytics, AdMob, crashlytics, sensors SDK с телеметрией |
| Неясные разрешения | Оставляем только `ACTIVITY_RECOGNITION` и, опционально, `POST_NOTIFICATIONS` |
| Отсутствие privacy policy | Добавляем `PRIVACY.md` и публичный URL |
| Медицинские заявления | Добавляем дисклеймер: not medical device |
| Данные не удаляются | Добавляем «Очистить историю» и «Удалить все данные» |
| Backup в облако | Отключаем Android backup |
| Open-source репозиторий с личными данными | Чистим git history, README, examples, issues |

---

## 6. Обязательные экраны и поведения

### 6.1. Privacy Consent Screen

Показывается при первом запуске, до запроса любых разрешений.

Содержание:

- приложение работает офлайн;
- данные хранятся только на устройстве;
- интернет не используется;
- аналитика и реклама не используются;
- пользователь может удалить данные;
- пользователь подтверждает, что ознакомился с политикой конфиденциальности;
- пользователь подтверждает возраст.

Чекбоксы:

```text
[ ] Я ознакомился с политикой конфиденциальности.
[ ] Я подтверждаю, что мне исполнилось 14 лет, либо я использую приложение с согласия законного представителя.
[ ] Я понимаю, что приложение не отправляет данные автоматически и не имеет сервера.
```

Кнопка «Продолжить» активна только после всех чекбоксов.

### 6.2. Master switch: разрешить запись

В настройках:

```text
Разрешить запись активности [ON/OFF]
```

Если OFF:

- кнопка «Начать» неактивна;
- датчики не запускаются;
- уведомления не создаются;
- пользователь видит пояснение: «Запись отключена в настройках».

### 6.3. Уведомления опционально

В настройках:

```text
Показывать уведомление во время записи [ON/OFF]
```

Если OFF:

- не запрашиваем `POST_NOTIFICATIONS`;
- не показываем ongoing notification.

Если ON:

- запрашиваем разрешение только при первом включении или при первой записи;
- уведомление не звуковое;
- не вибрирует;
- не спамит;
- исчезает после остановки записи.

### 6.4. Очистить историю

Кнопка в экране истории:

```text
Очистить историю
```

Действие:

- удаляет все записи тренировок из SQLite;
- показывает confirmation dialog;
- после очистки показывает «История пуста».

### 6.5. Удалить все данные

Кнопка в настройках:

```text
Удалить все данные
```

Действие:

- удаляет SQLite-базу;
- очищает SharedPreferences;
- удаляет временные файлы, если они были;
- сбрасывает consent? Лучше не сбрасывать автоматически, но можно предложить;
- показывает confirmation dialog с предупреждением: «Действие необратимо».

### 6.6. Отказ от разрешений

Если пользователь запрещает `ACTIVITY_RECOGNITION`:

- приложение не крашится;
- кнопка «Начать» неактивна или показывает понятную ошибку;
- текст: «Для подсчёта шагов нужен доступ к датчикам движения. Вы можете включить его в настройках системы.»

---

## 7. Изменения в данных и модели

### Текущая модель содержит лишнее

Было:

```dart
class Workout {
  final ActivityType type;
  final DateTime startTime;
  final DateTime endTime;
  final int steps;
  final double calories;
}
```

Стало для v3.2:

```dart
class Workout {
  final ActivityType type;
  final DateTime startTime;
  final DateTime endTime;
  final int steps;
  final int durationSeconds;
}
```

Или ещё проще:

```dart
class Workout {
  final ActivityType type;
  final DateTime startedAt;
  final int durationSeconds;
  final int steps;
}
```

### Убираем из `ActivityType`

Было:

```dart
enum ActivityType {
  walking('Ходьба', Icons.directions_walk, 0.04),
  running('Бег', Icons.directions_run, 0.10),
  workout('Зарядка/Тренировка', Icons.fitness_center, 0.06);

  final double mets;
}
```

Стало:

```dart
enum ActivityType {
  walking('Ходьба', Icons.directions_walk),
  running('Бег', Icons.directions_run),
  workout('Зарядка', Icons.fitness_center);

  final String title;
  final IconData icon;

  const ActivityType(this.title, this.icon);
}
```

### Убираем из настроек

Удалить:

- `weight`;
- `nickname`;
- `groupCode`;
- `caloriesEnabled` если калорий нет.

Оставить:

- `privacyAccepted`;
- `ageConfirmed`;
- `recordingEnabled`;
- `notificationsEnabled`;
- `themeMode`.

---

## 8. Зависимости для v3.2

### Рекомендуемый минимальный набор

```yaml
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
```

### Удалить

```yaml
flutter_foreground_task
pdf
share_plus
path_provider # если не используем экспорт файлов
csv # если не используем экспорт
```

Если `path_provider` нужен только для PDF/share — убираем.

---

## 9. Android Manifest: store-safe версия

Файл:

```text
app/android/app/src/main/AndroidManifest.xml
```

Рекомендуемое содержимое:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Разрешение на распознавание физической активности -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

    <!-- Разрешение на уведомления, используется только если пользователь включил уведомления -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!--
      Жёстко запрещаем потенциально лишние разрешения,
      если какой-то плагин попытается добавить их через manifest merger.
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

Файл правил бэкапа:

```text
app/android/app/src/main/res/xml/data_extraction_rules.xml
```

Содержимое:

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

Если не хотите возиться с `dataExtractionRules`, минимум:

```xml
android:allowBackup="false"
android:fullBackupContent="false"
```

Но для Google Play лучше явно запретить бэкап локальных данных.

---

## 10. Проверка отсутствия интернета

После сборки обязательно проверить merged manifest и APK/AAB.

### Команды

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

Проверка разрешений:

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
android.permission.ACCESS_NETWORK_STATE
android.permission.ACCESS_FINE_LOCATION
android.permission.ACCESS_COARSE_LOCATION
android.permission.CAMERA
android.permission.RECORD_AUDIO
android.permission.READ_CONTACTS
com.google.android.gms.permission.AD_ID
```

Если `INTERNET` всё-таки появился от плагина, нужно разбираться:

1. найти, какой плагин его добавляет;
2. удалить плагин, если он не нужен;
3. либо использовать `tools:node="remove"`;
4. либо заменить плагин на более чистый аналог.

---

## 11. Google Play Data Safety: черновые ответы

Финально заполнять в консоли Google Play, сверяясь с актуальными правилами на дату подачи.

### Вопрос: Собирает ли приложение данные?

Предварительный ответ для v3.2 без экспорта и без сервера:

> Приложение обрабатывает данные о физической активности только на устройстве. Разработчик не собирает и не получает эти данные. Данные не передаются третьим лицам. Пользователь может удалить данные в приложении.

Если Google Play требует указывать on-device collection, то декларировать:

- Data type: Physical activity / motion sensors;
- Purpose: App functionality;
- Sharing: No;
- Collection: On-device only;
- User can delete: Yes.

### Важно

Не писать в Data Safety то, чего нет:

- нет location;
- нет personal info;
- нет financial info;
- нет health data, если убрали вес и калории;
- нет photos/media;
- нет device IDs, если не используем advertising ID;
- нет diagnostics, если нет crashlytics/analytics.

---

## 12. Privacy Policy: минимальный текст

Файл в репозитории:

```text
PRIVACY.md
```

Черновик:

```markdown
# Privacy Policy — Движ

**Последнее обновление:** [дата]

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

Эти данные не покидают устройство, если пользователь самостоятельно не выполнил действия, которые могут привести к передаче данных, например системный шеринг, если такая функция будет добавлена в будущих версиях.

В версии v3.2 экспорт и шеринг отключены.

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

По вопросам приватности можно открыть issue в публичном репозитории или связаться с Maintainer через контакты, указанные в репозитории.
```

---

## 13. Open Source репозиторий: обязательные файлы

Для личного GitHub-репозитория с открытым кодом рекомендую добавить:

```text
LICENSE
README.md
PRIVACY.md
SECURITY.md
CONTRIBUTING.md
CODE_OF_CONDUCT.md
CHANGELOG.md
.gitignore
.github/ISSUE_TEMPLATE/bug_report.md
.github/ISSUE_TEMPLATE/feature_request.md
.github/ISSUE_TEMPLATE/privacy_concern.md
```

### LICENSE

Для максимальной простоты:

```text
MIT License
```

Для чуть более защитной лицензии с patent grant:

```text
Apache License 2.0
```

Я бы выбрал **Apache-2.0**, если проект может использоваться другими разработчиками и компаниями.  
Если хочется максимально просто — **MIT**.

### README.md: обязательный дисклеймер

Добавить в README:

```markdown
## Disclaimer

This software is provided "as is", without warranty of any kind.

The app is not a medical device. It does not diagnose, treat, cure, or prevent any disease.
Step counting and activity tracking are approximate and depend on the device, sensors, and how the phone is carried.

The app is designed to work offline. It does not include analytics, advertising, crash reporting, or remote data collection.
```

### SECURITY.md

```markdown
# Security Policy

## Reporting a Vulnerability

If you find a security issue, please open a private report or contact the maintainer through the method specified in the repository.

Do not publish exploitable details in public issues until a fix is available.
```

### PRIVACY.md

См. раздел 12.

### CHANGELOG.md

Вести по SemVer:

```markdown
# Changelog

## [3.2.0] - YYYY-MM-DD
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
- Master recording toggle.
- Notifications toggle.
- Clear history.
- Delete all data.
- Local-only store-safe build.
```

---

## 14. Git hygiene: чтобы не слить личное в открытый репозиторий

Перед публичным push обязательно проверить:

### 1. Нет личных данных в коде

Искать:

```bash
grep -RniE "фио|фамилия|имя|отчество|паспорт|снилс|инн|email|почта|телефон|адрес|group|nickname|weight|calories" .
```

Особенно проверить:

- комментарии;
- тестовые данные;
- примеры;
- screenshots;
- issue templates;
- README;
- CHANGELOG;
- git commit messages.

### 2. Нет личных邮箱 в коммитах

Если хотите анонимность или корпоративную чистоту, настройте git:

```bash
git config user.name "Your Public Name"
git config user.email "your-public-email@example.com"
```

Если уже были коммиты с личным email, нужно чистить history:

```bash
git filter-repo
```

или BFG Repo-Cleaner.

### 3. Нет внутренних документов компании

Удалить из репозитория:

- служебные записки;
- внутренние ТЗ;
- переписку;
- данные коллег;
- скриншоты рабочих систем;
- API-ключи;
- токены;
- приватные ссылки.

### 4. `.gitignore`

Минимально:

```gitignore
# Flutter/Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
pubspec.lock # опционально, для приложений часто коммитят, для библиотек нет

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# Secrets
*.env
*.pem
*.p12
*.keystore
google-services.json
GoogleService-Info.plist

# Local docs not for public repo
LOCAL_NOTES.md
DRAFTS/
PRIVATE/
```

Если используете подписи Android, keystore никогда не коммитить.

---

## 15. Google Play listing: черновые тексты

### Название

```text
Движ — офлайн счётчик активности
```

Альтернатива:

```text
Движ: локальный трекер шагов
```

### Короткое описание

```text
Простой офлайн-счётчик активности. Без аккаунта, без интернета, без рекламы и без отправки данных.
```

### Полное описание

```text
«Движ» — простое мобильное приложение для локального учёта физической активности.

Что умеет:
• выбирать тип активности: ходьба, бег или зарядка;
• считать шаги с помощью датчика движения смартфона;
• показывать длительность тренировки;
• хранить историю только на устройстве;
•允许 отключить запись и уведомления;
•允许 очистить историю или удалить все данные.

Приватность:
• приложение работает офлайн;
• не требует регистрации;
• не собирает ФИО, телефон, email, адрес, геолокацию, вес или медицинские данные;
• не использует рекламу;
• не использует аналитику;
• не отправляет данные разработчику или третьим лицам;
• исходный код открыт и доступен для независимой проверки.

Важно:
Приложение не является медицинским изделием. Оно не ставит диагнозы, не лечит и не заменяет консультацию врача. Точность подсчёта шагов зависит от устройства, датчиков и того, как пользователь носит телефон.
```

### Обоснование разрешения `ACTIVITY_RECOGNITION`

```text
Разрешение используется только для доступа к датчику движения устройства, чтобы считать шаги во время активной тренировки, запущенной пользователем. Данные обрабатываются локально и не отправляются на сервер.
```

### Обоснование разрешения `POST_NOTIFICATIONS`

```text
Разрешение используется только если пользователь включил уведомления. Приложение показывает локальное уведомление о том, что идёт запись активности. Уведомления не содержат персональных данных и не используются для рекламы.
```

---

## 16. Чек-лист перед загрузкой в Google Play Console

### Build

- [ ] Обновить version и build number.
- [ ] Собрать AAB, а не только APK.
- [ ] Использовать Play App Signing или надёжно хранить keystore.
- [ ] Включить minify/shrink resources, если не мешает.
- [ ] Проверить, что release build не содержит debug-логов с данными.

Команда:

```bash
flutter build appbundle --release
```

### Permissions

- [ ] В merged manifest нет `INTERNET`.
- [ ] Нет location.
- [ ] Нет camera.
- [ ] Нет contacts.
- [ ] Нет microphone.
- [ ] Нет SMS.
- [ ] Нет AD_ID.
- [ ] Есть только нужные разрешения.

### Data Safety

- [ ] Заполнена форма Data Safety.
- [ ] Указано, что данные не передаются разработчику.
- [ ] Указано, что данные обрабатываются локально.
- [ ] Указано, что пользователь может удалить данные.
- [ ] Нет противоречий с реальным поведением приложения.

### Privacy Policy

- [ ] Есть публичный URL.
- [ ] URL открывается без авторизации.
- [ ] В policy написано про локальное хранение.
- [ ] В policy написано про отсутствие сервера.
- [ ] В policy есть дата обновления.

### Content rating

- [ ] Пройдена анкета IARC.
- [ ] Не выбрано «для детей», если нет Families compliance.
- [ ] В описании нет обещаний медицинского эффекта.

### App content

- [ ] Нет рекламы.
- [ ] Нет аналитики.
- [ ] Нет crash reporting.
- [ ] Нет purchase/donation внутри приложения, если не готовы к billing policies.
- [ ] Нет ссылок на платные услуги, если это может потребовать отдельного compliance.

### Store listing

- [ ] Название понятное.
- [ ] Короткое описание не обещает здоровье/похудение.
- [ ] Полное описание содержит privacy disclaimer.
- [ ] Скриншоты не содержат реальных персональных данных.
- [ ] На скриншотах лучше использовать фейковые никнеймы? В v3.2 никнеймов нет — ещё проще.

### Release

- [ ] Release notes краткие и честные.
- [ ] Указано, что версия local-only.
- [ ] Указано, что экспорт/группы/вес удалены для приватности.

---

## 17. Что делать с благодарностью и донатами

Пока цель — «просто помочь», не добавляйте в приложение:

- кнопки «Купить мне кофе»;
- in-app donations;
- premium-функции;
- подписки;
- рекламу;
- referral-программы.

Почему:

- Google Play имеет правила вокруг платежей и донатов;
- любые monetary flows усложняют модерацию;
- open-source проект может принимать благодарность через GitHub Sponsors / external links, но лучше вынести это в README, а не в приложение, пока нет юридического анализа.

Безопасный вариант:

```text
В README:
If you find this project useful, you can star the repository, report issues, contribute code, or support the maintainer through public sponsorship links.
```

В самом приложении первой версии — ничего про деньги.

---

## 18. Рекомендуемый roadmap

### v3.2 — Google Play Safe Local-Only

- убрать вес;
- убрать калории;
- убрать никнеймы;
- убрать группы;
- убрать foreground service;
- убрать PDF/share;
- добавить privacy consent;
- добавить delete all data;
- добавить clear history;
- добавить master toggle;
- добавить notifications toggle;
- подготовить privacy policy;
- подготовить open-source repo.

### v3.3 — Optional Local Export

Только после review:

- локальный CSV/PDF без идентификаторов;
- feature flag;
- явное согласие на экспорт;
- explanation в Data Safety.

### v3.4 — Trainer/Group Mode

Только если готовы к юридической оценке:

- анонимные participant IDs;
- challenge codes;
- согласие;
- возрастная политика;
- возможно, отдельный build для школ/тренеров;
- возможно, не в Google Play, а как self-hosted / enterprise solution.

---

## 19. Итоговый вердикт по v3.2

Если реализовать этот чек-лист, приложение станет:

- проще;
- безопаснее;
- легче для аудита;
- понятнее для Google Play;
- полезнее как open-source инструмент;
- менее рискованным с точки зрения 152-ФЗ и персональных данных.

Но финальная готовность подтверждается только после:

1. изменения кода;
2. сборки release AAB;
3. проверки merged manifest;
4. ручного smoke-теста;
5. заполнения Google Play Console;
6. публикации privacy policy;
7. проверки репозитория на отсутствие личных данных.
````

---

## Что добавить в ваш `TASKS.md`

Вставьте эти задачи в трекер.

```markdown
## Store-safe v3.2

### REMOVE-001: Удалить сбор веса 🔴 TODO
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/services/storage_service.dart`
- `app/lib/models/workout.dart`
- `app/lib/screens/activity_screen.dart`

**Действие:**
- удалить `weight` из SharedPreferences;
- удалить слайдер веса;
- удалить расчёт калорий;
- удалить поле calories из модели, если оно больше не нужно.

**Проверка:**
- в настройках нет веса;
- в истории нет калорий;
- в PDF/экспорте нет калорий, если экспорт отключён.

---

### REMOVE-002: Удалить никнеймы 🔴 TODO
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/screens/report_screen.dart`

**Действие:**
- удалить поле nickname;
- удалить сохранение nickname;
- удалить отображение nickname в отчёте.

**Проверка:**
- нигде нет ввода имени/ника;
- в локальных данных нет nickname.

---

### REMOVE-003: Удалить коды групп 🔴 TODO
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/screens/report_screen.dart`

**Действие:**
- удалить groupCode;
- удалить сохранение groupCode;
- удалить групповой контекст из UI.

**Проверка:**
- приложение не знает о группах;
- нет полей «код группы».

---

### REMOVE-004: Удалить foreground service 🔴 TODO
**Файлы:**
- `app/pubspec.yaml`
- `app/lib/services/foreground_service.dart`
- `app/lib/screens/activity_screen.dart`
- `app/android/app/src/main/AndroidManifest.xml`

**Действие:**
- удалить зависимость `flutter_foreground_task`;
- удалить файл `foreground_service.dart`;
- удалить вызовы `ForegroundService.start()` и `ForegroundService.stop()`;
- удалить разрешение `FOREGROUND_SERVICE`, если оно было.

**Проверка:**
- сборка не содержит foreground service;
- уведомление остаётся только как обычное ongoing notification.

---

### REMOVE-005: Отключить PDF и share 🔴 TODO
**Файлы:**
- `app/pubspec.yaml`
- `app/lib/services/pdf_export_service.dart`
- `app/lib/screens/report_screen.dart`

**Действие:**
- удалить `pdf`;
- удалить `share_plus`;
- удалить `path_provider`, если больше не нужен;
- удалить кнопку экспорта;
- превратить экран отчёта в локальную историю или удалить его.

**Проверка:**
- приложение не создаёт файлы для шаринга;
- нет системного диалога «Поделиться».

---

### CODE-010: Добавить Privacy Consent Screen 🔴 TODO
**Новый файл:**
- `app/lib/screens/consent_screen.dart`

**Действие:**
- показать до запроса разрешений;
- чекбоксы: privacy policy, возраст, понимание офлайн-режима;
- сохранять `privacyAccepted` и `ageConfirmed` локально;
- без согласия не запрашивать `ACTIVITY_RECOGNITION`.

**Проверка:**
- при первом запуске сначала consent;
- при отказе приложение не собирает данные.

---

### CODE-011: Добавить Master Toggle «Разрешить запись» 🔴 TODO
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/screens/activity_screen.dart`

**Действие:**
- локальный флаг `recordingEnabled`;
- если OFF, кнопка «Начать» неактивна;
- датчики не запускаются;
- показать пояснение.

**Проверка:**
- выключить запись;
- попробовать начать тренировку;
- приложение не запрашивает датчики и не считает шаги.

---

### CODE-012: Добавить Toggle уведомлений 🔴 TODO
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/services/notification_service.dart`
- `app/lib/screens/activity_screen.dart`

**Действие:**
- локальный флаг `notificationsEnabled`;
- если OFF, не показывать уведомление;
- если ON, запрашивать `POST_NOTIFICATIONS` только при необходимости.

**Проверка:**
- выключить уведомления;
- начать запись;
- уведомление не появляется.

---

### CODE-013: Добавить «Очистить историю» 🔴 TODO
**Файлы:**
- `app/lib/screens/history_screen.dart`
- `app/lib/services/storage_service.dart`

**Действие:**
- кнопка очистки;
- confirmation dialog;
- удаление всех строк из таблицы workouts.

**Проверка:**
- провести тренировку;
- очистить историю;
- список пуст;
- после перезапуска всё ещё пусто.

---

### CODE-014: Добавить «Удалить все данные» 🔴 TODO
**Файлы:**
- `app/lib/screens/settings_screen.dart`
- `app/lib/services/storage_service.dart`

**Действие:**
- удалить SQLite;
- очистить SharedPreferences;
- confirmation dialog;
- вернуть приложение к первому запуску, кроме, возможно, языка/темы.

**Проверка:**
- нажать удалить все данные;
- проверить, что история, настройки и локальные флаги сброшены.

---

### MANIFEST-002: Harden AndroidManifest 🔴 TODO
**Файл:**
- `app/android/app/src/main/AndroidManifest.xml`

**Действие:**
- добавить `tools:node="remove"` для INTERNET и других опасных разрешений;
- отключить backup;
- добавить data extraction rules;
- оставить только ACTIVITY_RECOGNITION и POST_NOTIFICATIONS.

**Проверка:**
```bash
aapt dump permissions build/app/outputs/flutter-apk/app-debug.apk
```

---

### DOC-001: Подготовить PRIVACY.md 🔴 TODO
**Действие:**
- создать файл политики конфиденциальности;
- опубликовать на GitHub Pages;
- добавить URL в Google Play Console.

---

### DOC-002: Выбрать лицензию 🔴 TODO
**Варианты:**
- MIT;
- Apache-2.0.

**Рекомендация:**
- Apache-2.0 для более защитного open-source проекта;
- MIT для максимальной простоты.

---

### DOC-003: Почистить репозиторий перед публичным push 🔴 TODO
**Действие:**
- проверить git history;
- удалить личные email/имена, если не нужны;
- удалить внутренние документы;
- добавить `.gitignore`;
- добавить `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`.

---

### TEST-008: Store-safe smoke test 🔴 TODO
**Проверить:**
- первый запуск;
- consent;
- отказ от разрешений;
- включение записи;
- выключение записи;
- очистка истории;
- удаление всех данных;
- отсутствие уведомлений при выключенном toggle;
- отсутствие интернета в merged manifest.
```

---

## Мой прямой ответ на ваш вопрос

Да, мы должны учесть:

1. **Очистку истории** — обязательно.  
2. **Удаление всех данных** — обязательно.  
3. **Отключение функции приложения** — обязательно, как master toggle «Разрешить запись».  
4. **Сбор веса** — убираем полностью.  
5. **Группы и никнеймы** — убираем полностью.  
6. **Калории** — убираем вместе с весом.  
7. **Foreground service** — убираем из первой Google Play-версии.  
8. **PDF/share** — лучше отложить до отдельной compliance-версии.  
9. **Открытый код** — делаем репозиторий чистым, с лицензией, privacy policy и дисклеймером.  

Следующий лучший шаг — не добавлять новые фичи, а сделать **patch v3.2 Local-Only**: удалить лишнее, добавить consent, delete flow и toggles. После этого можно собирать release AAB и смотреть реальный merged manifest.