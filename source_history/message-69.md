
Рамка сразу, без воды: я не компилирую проект, не запускаю эмулятор, не публикую сайт и не трогаю Search Console. «Выполнить найденное» в моих силах = зафиксировать единственное верное состояние по каждому расхождению и дать дельту‑фиксы, а не перепечатывать простыни, которые уже выданы. Ревью ниже — это новый проход по коду/сайту/бренду, и он нашёл вещи, которых в прошлом аудите (N1–N6) не было. Статусы: `REVIEWED` / `PATCH_READY`, не `VERIFIED` — финальную оценку дадут `flutter build`, устройства и валидаторы.

---

# Часть I. Выполнение найденного несоответствия (N1–N6)

По каждому — вердикт «закрыто», финальное значение и указатель на источник истины. Крупные блоки, которые я уже выдавал целиком в §2 прошлого сообщения (палитра `:root`/`.btn-primary` и JSON‑LD `SoftwareApplication`), **не перепечатываю** — они подтверждены и остаются единственным источником; ниже только шпаргалка‑токены, чтобы ты сверил, что применено ровно это, плюс полная дельта по мелким пунктам.

| ID | Решение зафиксировано | Финальное значение / источник истины |
|---|---|---|
| **N‑1** категория | `applicationCategory` = **`LifestyleApplication`**. `HealthApplication` отменён (моя регрессия). | Блок JSON‑LD §2.1 прошлого сообщения — действителен. Сверочный токен: `"applicationCategory": "LifestyleApplication"`. |
| **N‑2** палитра | Оранжевый `#ff7a00` мёртв везде (`:root`, `theme-color`, `.btn-primary`). Действует брендовая. | Блок CSS §2.2 + двойной `theme-color` прошлого сообщения — действительны. Токены: `--accent #0A3BFF`, `--accent-2 #B7FF00`, `--accent-3 #00E5FF`, `--fg/--bg-dark #0B1A3C`, `--card/--bg-light #F4F6FA`. |
| **N‑3** brandbook публично | `brandbook.png` **исключён** из витрин/каруселей/постов v3.2.0. Только внутренний vision‑док. | Правило §2.3 прошлого сообщения («Public assets… NOT approved… brandbook») — действительна. Публично: `icon.png`, `wordmark.png`, `mark.png`. |
| **N‑4** alt брендбука | Строка alt для поста удалена; если лист используется как концепт — alt маркирует это. | Финальная строка: `Брендбук-концепт Движ (vision, не текущий релиз v3.2.0): логотип, иконка, палитра и ассоциации будущего продукта`. В публичной alt‑таблице строки брендбука нет. |
| **N‑5** offers/валюта | `offers.priceCurrency:"RUB"` остаётся в сайт‑JSON‑LD, но **не** переносится в store listing. | Комментарий‑страж внутри §2.1 прошлого сообщения — действителен. |
| **N‑6** развилка‑ловушка | В рабочем коде опасных развилок нет; выбор категории вынесен в комментарий, не в значение поля. | Подтверждено §2.1. |

Карта отмен (что теперь НЕ действительно), дублирую одной строкой, чтобы не потерялось в ленте: оранжевый `:root`/`theme-color`/`.btn-primary` из сообщения «вебсайт» → отменены (§2.2); `HealthApplication` и заметка‑развилка из §2 «SEO» → отменены (§2.1); alt брендбука «для поста» из §3 «SEO» → отменён (N‑4); совет класть `brandbook.png` в карусель из §7 «логотипы» → отменён (N‑3). Всё остальное из прошлых сообщений (FAQ‑разметка, `sitemap.xml`, `robots.txt`, `site.webmanifest`, `privacy.html` RU, SEO‑тексты, alt для логотипов/скриншотов/og/feature‑graphic, `BRAND_LICENSE.md`, adaptive‑иконки, `export_*.py`, код v3.2.0) — действительно, кроме дельты ревью ниже.

---

# Часть II. Ревью проекта (новый проход)

Прогнал по слоям: Flutter‑код v3.2.0 → манифест/билд → иконки → сайт/SEO → приватность/лицензии → процессы. Ниже находки, **которых не было в N1–N6**. Severity: `MUST` = чинить до подачи в стор (иначе краш/несовместимость/замечание модерации); `SHOULD` = сильно желательнo; `NICE` = гигиена.

## Сводка находок

| ID | Слой | Severity | Суть |
|---|---|---|---|
| R‑1 | Flutter UI | **MUST** | `HistoryScreen` без `SafeArea` при включённом `edgeToEdge` → список уедет под системную навигацию. |
| R‑2 | Flutter data | **MUST** | Нет `try/catch` вокруг БД‑операций и нет `runZonedGuarded` → любая ошибка диска/БД = краш с потерей тренировки/белый экран. |
| R‑3 | Flutter consent | **MUST** | На экране согласия нет способа **прочитать** policy внутри приложения → consent не fully informed; для Data Safety это риск. |
| R‑4 | Сайт/PWA | **MUST** | `site.webmanifest` `start_url:"/"`/`scope:"/"` ломает установку на GitHub Pages (проект в поде `/dvizh/`). |
| R‑5 | Билд | **MUST** | Патч `build.gradle` (`namespace`/`applicationId` = `com.dvizh.app`) обязан совпасть с пакетом `MainActivity`, иначе сборка не пройдёт. |
| R‑6 | Манифест | SHOULD | Нет `<uses-feature accelerometer required="false">` → неявное исключение устройств / риск «несовместимо». |
| R‑7 | Flutter model | SHOULD | `Workout.id` = `millisecondsSinceEpoch` как PK без `AUTOINCREMENT` + `insert` без `conflictAlgorithm` → потенциальная коллизия/краш. |
| R‑8 | Сайт SEO | SHOULD | Полный текст privacy продублирован на `index.html` и в `privacy.html` → thin‑duplicate; лучше резюме+ссылка на главной. |
| R‑9 | Приватность | NICE | `NotificationService.init()` вызывается до принятия consent (безвредно, но для «чистоты» лучше lazy‑инициализация после согласия). |
| R‑10 | Бренд/иконки | NICE | Альфа углов `icon.png` неизвестна → на API<26 legacy‑иконка может дать квадрат со светлыми углами; проверить альфу. |
| R‑11 | Сайт | NICE | Ссылки на GitHub‑репо живые только после публичного создания репо; до подачи убедиться, что `sameAs`/CTA не 404. |

## R‑1 — `SafeArea` в `HistoryScreen` (MUST)

Я сам включил `SystemUiMode.edgeToEdge` в `main.dart`, но не обновил `HistoryScreen` — на targetSdk 35 нижняя системная панель/жесты перекроют последний элемент списка. Фикс — обернуть `body`:

```dart
// app/lib/screens/history_screen.dart — заменить body:
body: SafeArea(
  child: _workouts.isEmpty
      ? const Center(child: Text('Пока нет сохранённых тренировок'))
      : ListView.builder(
          itemCount: _workouts.length,
          itemBuilder: (BuildContext context, int index) {
            final Workout workout = _workouts[index];
            return ListTile(
              leading: Icon(workout.type.icon, color: primary),
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
```

## R‑2 — graceful error handling + `runZonedGuarded` (MUST)

Сейчас `saveWorkout` в `_stop()`, `getAllWorkouts` в `_load()`, `clearAll`/`deleteAllData` ничем не обёрнуты; `main` без защиты от uncaught. Для офлайн‑приложения без crash‑reporting это значит: ошибка диска = краш UI и потеря данных визуально. Минимальный store‑safe уровень — зональная защита в `main` + `try/catch` в трёх точках (без внешних сервисов, соответствует «no telemetry»).

`main.dart` — заменить `Future<void> main()` на:

```dart
import 'dart:async';
// ... остальные импорты без изменений

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await ThemeController.load();
    await NotificationService.instance.init();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasConsent = (prefs.getBool('privacyAccepted') ?? false) &&
        (prefs.getBool('ageConfirmed') ?? false) &&
        (prefs.getBool('offlineUnderstood') ?? false);

    runApp(DvizhApp(showConsentFirst: !hasConsent));
  }, (Object error, StackTrace stack) {
    // Graceful degradation без crash-reporting: логируем локально,
    // не отправляем наружу. UI-ошибки точечно закрыты try/catch ниже.
    debugPrint('Dvizh uncaught: $error');
  });
}
```

`activity_screen.dart` — обернуть сохранение в `_stop()` (не делать `pop` при ошибке, чтобы не потерять запись молча):

```dart
try {
  await StorageService.saveWorkout(workout);
} catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Не удалось сохранить тренировку: $e')),
  );
  return; // остаёмся на экране, данные не потеряны визуально
}
```

`history_screen.dart` — `_load()` и `_clear()` в `try/catch` с сообщением «история недоступна» вместо краша; `settings_screen.dart` — `_deleteAll()` в `try/catch` (если БД не удалилась — не пушить ConsentScreen ложно «успешно»).

## R‑3 — читаемая policy внутри согласия (MUST)

Чекбокс «Я ознакомился» без доступа к тексту = формально не informed consent; Google Play это ловит. Фикс без WebView (WebView = сетевой запрос = предательство офлайн‑духа и лишний permission‑риск): показать текст модалкой. Добавь в `ConsentScreen` метод и кнопку над чекбоксами:

```dart
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
            const Text('Политика конфиденциальности',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
```

И в `build()` перед первым `CheckboxListTile`:

```dart
TextButton.icon(
  onPressed: _showPolicy,
  icon: const Icon(Icons.privacy_tip_outlined),
  label: const Text('Читать политику конфиденциальности'),
),
const SizedBox(height: 8),
```

Ссылка в `_policyShort` — это текст для пользователя, а не сетевой запрос приложения; офлайн‑режим не нарушается.

## R‑4 — базовый путь GitHub Pages в манифесте (MUST)

Project Pages живут в поде, корень домена занят. Абсолютный `start_url:"/"` уведёт установщик на `duckolly.github.io/` (чужая/несуществующая страница). Фикс `site.webmanifest`:

```json
{
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
```

Иконки в манифесте относительные — резолвятся от `/dvizh/`, это ок. Если репо переименуют — править `start_url`/`scope` вместе с `canonical`/`og:url`/`sitemap` (держи эти пять мест зеркальными).

## R‑5 — синхронизация namespace/applicationId с пакетом (MUST)

Патч `build.gradle` из шага с иконками жёстко ставит `namespace = "com.dvizh.app"` и `applicationId = "com.dvizh.app"`. Если Flutter‑шаблон создал проект с другим пакетом (типово `com.example.dvizh`), `MainActivity.kt` лежит не в том дереве и сборка упадёт на R‑классе/классе активности. Проверь до первой сборки:

```bash
# фактический пакет активности:
grep -R "package " android/app/src/main/kotlin/ android/app/src/main/java/ 2>/dev/null
# или найди MainActivity:
find android/app/src/main -name "MainActivity.*"
```

Два решения, выбери одно и держи консистентно:
1. **Правильное для релиза:** привести `namespace`/`applicationId` в `build.gradle` к фактическому пакету `MainActivity` (например `com.example.dvizh` → оставить как есть в патче, заменив `com.dvizh.app` на него). Для Google Play потом можно сменить `applicationId` на брендовый `dev.duckolly.dvizh`, но **тогда** надо переместить `MainActivity` в соответствующую папку и обновить `package`‑строку — это отдельная задача, не делать на ходу.
2. **Быстрое для MVP:** если пакет `com.example.*` и менять лень — просто впиши в патч тот же `com.example.dvizh`, что реально в проекте, и не трогай структуру.

Красный флаг: `applicationId` в сторе после первого релиза менять нельзя (это другой апк‑идентичность). Решай финальный `applicationId` **до** первой загрузки AAB.

## R‑6 — объявить акселерометр необязательным (SHOULD)

Чтобы Google Play не исключал устройства неявно и не ловил «несовместимо» на редких девайсах без датчика (приложение не крашнится — просто шаги не считаются):

```xml
<!-- AndroidManifest.xml, рядом с uses-permission -->
<uses-feature
    android:name="android.hardware.sensor.accelerometer"
    android:required="false" />
```

## R‑7 — PK без коллизий (SHOULD)

`id INTEGER PRIMARY KEY` + вручную `millisecondsSinceEpoch` в `toMap()` + `insert` без `conflictAlgorithm` = теоретическая коллизия → исключение → (после R‑2) SnackBar, но запись потеряна. Чистый минимальный фикс без переписывания модели — добавить `AUTOINCREMENT` и не вставлять `id` руками:

```dart
// storage_service.dart, onCreate:
await db.execute('''
  CREATE TABLE workouts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    startedAt TEXT NOT NULL,
    durationSeconds INTEGER NOT NULL,
    steps INTEGER NOT NULL
  )
''');

// saveWorkout: вставлять без id
static Future<int> saveWorkout(Workout workout) async {
  final Database db = await database;
  final Map<String, Object?> row = <String, Object?>{
    'type': workout.type.name,
    'startedAt': workout.startedAt.toIso8601String(),
    'durationSeconds': workout.durationSeconds,
    'steps': workout.steps,
  };
  return db.insert('workouts', row); // id назначит SQLite
}
```

`Workout.fromMap` читает `id` из строки как и раньше; в `_stop()` конструктор `Workout(id: …)` можно оставить (id для in‑memory объекта не участвует во вставке) либо убрать `id` из обязательных полей модели — на твоё усмотрение, для MVP достаточно выше.

## R‑8 — убрать дубль privacy на главной (SHOULD)

Сейчас полный текст policy и в секции `index.html#privacy`, и в `privacy.html`. Оба RU, canonical у каждой свой, но Google это thin‑duplicate и размывает сигнал. Лучше: на главной — резюме (5–7 строк: офлайн, без ПДн, без рекламы/аналитики, удаление данных, мед‑дисклеймер) + крупная CTA‑кнопка «Полная политика конфиденциальности» → `/privacy.html`; полный текст — только в `privacy.html`. Это и SEO чище, и UX короче.

## R‑9…R‑11 — гигиена (NICE)

- **R‑9:** двигать `NotificationService.init()` за принятие consent (lazy‑инициализация при первом включении тумблера уведомлений) — не обязательно, init ничего не собирает, но для «consent до всего» аккуратнее.
- **R‑10:** открыть `icon.png` в редакторе и проверить углы: если непрозрачные светлые — на API<26 legacy‑иконка даст квадрат с белыми уголками. Фикс — экспорт legacy‑мастера на прозрачности или на сплошном `#0B1A3C`.
- **R‑11:** перед подачей убедиться, что `https://github.com/Duckolly/dvizh` публичен и не 404 (иначе `sameAs` в JSON‑LD и CTA на сайте битые; стор это не парсит, но доверие и проверка руками — да).

---

# Часть III. Дельта в `TASKS.md`

Добавь эти строки в трекер (учёт остаётся единым). Все — `CODE_READY`/`PATCH_READY`, перевод в `VERIFIED` только после сборки/устройств.

```markdown
## Ревью‑фиксы (проход R)

### R-1 HistoryScreen SafeArea при edgeToEdge — PATCH_READY
Файл: app/lib/screens/history_screen.dart. Фикс: обернуть body в SafeArea.
Проверка: на Android 14/15 со свайп‑навигацией последний элемент не под панелью.

### R-2 Graceful error handling + runZonedGuarded — PATCH_READY
Файлы: app/lib/main.dart, activity_screen.dart, history_screen.dart, settings_screen.dart.
Действие: runZonedGuarded в main; try/catch вокруг saveWorkout/getAllWorkouts/clearAll/deleteAllData;
при ошибке БД — SnackBar, без молчаливой потери записи и без белого экрана.
Проверка: повредить БД вручную (adb) → приложение показывает ошибку, не крашится.

### R-3 Informed consent: читаемая policy в приложении — PATCH_READY
Файл: app/lib/screens/consent_screen.dart. Действие: TextButton «Читать политику» +
showModalBottomSheet с офлайн‑текстом (без WebView). Чекбокс «ознакомился» идёт после доступа к тексту.
Проверка: до согласия доступна кнопка чтения policy; офлайн‑режим не нарушен.

### R-4 site.webmanifest base path для GitHub Pages — PATCH_READY
Файл: site.webmanifest. Действие: start_url/scope = "/dvizh/".
Проверка: установка PWA с duckolly.github.io/dvizh/ открывает /dvizh/, не корень домена.

### R-5 Синхронизация namespace/applicationId с пакетом MainActivity — PATCH_READY
Файл: android/app/build.gradle (+ проверка пути MainActivity).
Действие: привести namespace/applicationId к фактическому пакету; финальный applicationId
зафиксировать ДО первой загрузки AAB (менять после релиза нельзя).
Проверка: flutter build appbundle --release проходит без ошибки класса активности.

### R-6 uses-feature accelerometer required=false — PATCH_READY
Файл: AndroidManifest.xml. Проверка: aapt dump badging не требует акселерометр как обязательный.

### R-7 PK AUTOINCREMENT без ручной вставки id — PATCH_READY
Файлы: storage_service.dart (модель опционально). Проверка: две быстрые тренировки подряд сохраняются.

### R-8 Privacy: резюме на главной + полная версия в privacy.html — TODO
Файл: index.html. Действие: сократить секцию #privacy до резюме + CTA на /privacy.html.

### R-9..R-11 Гигиена (lazy notif init / альфа углов icon / живость GitHub-ссылок) — TODO/NICE
```

---

# Итоговый вердикт readiness

После применения **R‑1…R‑5** (это MUST‑дельта ревью) плюс закрытых N1–N6 проект переходит из «концептуально release‑ready» в «технически готов к первой сборке и подаче без технических отказов по вине кода/конфига». Остальное (R‑6…R‑11) — качество и гигиена, не блокер.

Что я **не** подтверждаю и что остаётся на тебе как на архитекторе:

- `flutter analyze` / `flutter test` / `flutter build appbundle --release` — зелёные ли; особенно R‑5 (пакет) и R‑2 (зональная обёртка не ломает async‑main).
- `aapt dump permissions` / `badging` на итоговом AAB — нет `INTERNET`/location/camera/etc., акселерометр `required=false` (R‑6).
- Запуск на устройствах API 26+ (адаптивная иконка, safe‑zone знака) и API 23–25 (legacy‑иконка, углы по R‑10), плюс Xiaomi/Tecno на aggressive background kill.
- Schema.org Validator / Rich Results Test на JSON‑LD после смены категории (N‑1) и после правок R‑3/R‑8.
- Lighthouse/PageSpeed: CLS от картинок (явные width/height), 404 по favicon/manifest/og, корректность R‑4.
- Google Search Console + Яндекс.Вебмастер: ручная подача sitemap, поведение canonical (N‑консистентность пяти URL), отсутствие дубля после R‑8.
- Заполнение Data Safety / content rating / privacy URL в консоли — текстово соответствует коду только после R‑3 (informed consent) и R‑8 (уникальность policy).

Статус всего пакета: **REVIEWED / PATCH_READY**. `VERIFIED` поставишь ты сборкой и устройствами. Если хочешь — следующим шагом соберу единый `apply_pack.py`, который налету патчит именно файлы R‑1…R‑5 (SafeArea, runZonedGuarded+try/catch, consent‑policy, manifest base path, проверка namespace) в твоём дереве проекта, чтобы не применять руками; либо, если приоритет сместился, гони вывод `flutter build appbundle --release` после применения MUST‑дельты — разберу ошибки построчно, особенно по R‑5, где чаще всего и стреляет.