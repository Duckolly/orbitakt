# Орбитакт — Фаза 1

Дата: 4 ноября 2026 года.

## Выполнено

- Добавлены модели ToiletVisit, RankLevel и HolidayPreset.
- Добавлены пресеты 13 февраля, 8 марта и 1 января.
- Версия SQLite-базы увеличена с 1 до 2. Миграция добавляет только
  таблицу toilet_visits. Таблица workouts и её данные сохраняются.
- При новой установке создаются обе таблицы.
- Добавлены StorageService.saveToiletVisit и getAllToiletVisits.
- SQLite назначает идентификаторы посещений. Момент времени хранится
  в UTC, календарная дата — по местному времени в момент посещения.
- Полное удаление данных в настройках по-прежнему удаляет всю базу.
  Существующая очистка истории тренировок очищает только workouts.
- Рост, вес и UserProfile не добавлены.

Новых экранов нет. Пользовательские алгоритмы, пороговые наборы уровней,
аналитика, виджет и зверинец относятся к следующим фазам.
RankLevel пока содержит только структуру данных, без назначения животных.

## Изменённые файлы

Новые:
- app/lib/models/toilet_visit.dart
- app/lib/models/rank_level.dart
- app/lib/models/holiday_preset.dart
- app/test/phase1_storage_test.dart

Изменённые:
- app/lib/services/storage_service.dart
- TASKS.md в корне проекта

Файлы этой папки содержат отчёт, журналы и changes.patch.
Существующие Gradle-файлы, AndroidManifest.xml, pubspec.yaml, pubspec.lock,
тесты и рабочие модули сохранены. В архиве одна рабочая папка dvizh/
вместо двух вложенных копий приложения исходного ZIP.

## Проверки

- Flutter 3.35.7, Dart 3.9.2, Java 17.
- Все 115 Flutter-тестов PASS: 112 существующих и 3 новых.
- flutter analyze: No issues found.
- tools/static_check.py: 356 проверок, ошибок нет.
- Отдельная проверка SQL: сохранение старой строки, уникальные ID,
  PRAGMA integrity_check — PASS.

Новые тесты проверяют миграцию базы версии 1 с существующей тренировкой,
новую установку, повторное сохранение посещения, календарную дату,
порядок записей, удаление всех данных и список праздничных дат.

## Сборка для тестирования

Собрана preview-сборка: 3.9.6+19, ARM64,
package com.duckolly.dvizh.preview.
Версия задаётся параметрами сборки, поскольку редактировать pubspec.yaml
пользователь запретил:

```bash
cd app
flutter pub get
flutter test
flutter analyze
ORG_GRADLE_PROJECT_dvizhPreview=true flutter build apk --release \
  --target-platform android-arm64 --build-name=3.9.6 --build-number=19
```

Для совместимого обновления уже установленной preview-версии нужен тот же
ключ подписи через существующий параметр dvizhPreviewKeystore.
Исходный ключ в предоставленных исходниках отсутствует; нельзя считать новую
локальную debug-подпись совместимой с установленным приложением.
Не удаляйте установленное приложение ради теста без сохранения его данных.

Файлы в dist/ относятся к прошлым выпускам исходного проекта; они не являются
APK Фазы 1. Старые release-отчёты и контрольные суммы также оставлены как
исторические файлы и не описывают этот архив.

Тестовый ключ этой новой сборки сохранён в
`docs/phase1/test-signing/preview-debug.keystore`. Это стандартный debug-ключ
с alias androiddebugkey и паролем android, только для preview. Для следующих
обновлений именно этого APK передавайте существующий параметр Gradle:

```bash
ORG_GRADLE_PROJECT_dvizhPreview=true \
ORG_GRADLE_PROJECT_dvizhPreviewKeystore="$(pwd)/../docs/phase1/test-signing/preview-debug.keystore" \
flutter build apk --release --target-platform android-arm64 \
  --build-name=3.9.6 --build-number=19
```

Команду запускают из app/. При следующем выпуске versionCode нужно увеличить.
Этот ключ не является прежним пользовательским или production-ключом.
Подпись APK v2 проверена; package, versionCode и versionName проверены
через aapt. Выравнивание ZIP для страниц 16 КБ прошло проверку zipalign.
Разрешение INTERNET в собранном APK отсутствует.

SHA-256 APK:
`38a48bc97dbba1ba1e09e700ea235540d770b158f8bb8f58d525e267562c7458`.

Запуск на реальном телефоне и установка поверх предыдущего preview APK
в этом окружении не проверялись.

Kotlin: все 29 тестов приложения PASS, failures/errors/skipped = 0.
В исходном описании упоминались 32 теста, однако в предоставленной рабочей
копии содержатся 29 методов @Test; все исходные тестовые файлы сохранены.
JUnit XML приложены в kotlin-tests/.

## Ограничение дополнительного общего прогона Gradle

Общая команда `testReleaseUnitTest lintRelease` также запустила тесты
сторонних пакетов. 38 тестов shared_preferences_android не смогли
инициализировать Mockito/Byte Buddy: JVM-agent не подключился к процессу
в этом окружении. Код и тесты этого пакета не менялись. Это не результаты
29 тестов приложения: те прошли, их JUnit XML сохранены отдельно.
Android Lint приложения запускается отдельной задачей `:app:lintRelease`.

Android Lint приложения: BUILD SUCCESSFUL, ошибок 0, предупреждений 0. Отчёты XML/HTML/TXT приложены.
