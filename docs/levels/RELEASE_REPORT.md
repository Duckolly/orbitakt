# Проверка релиза 3.10.0+24 · 2026-11-05

## Состав

- Пакет: `com.duckolly.dvizh`, versionCode `24`, versionName `3.10.0`.
- APK: ARM64 (`arm64-v8a`), minSdk 24, targetSdk 36.
- Подписан постоянным release-сертификатом; SHA-256 сертификата:
  `57044e5fd5fa4a53e3636d8a6c245136bac8fd0adae65120eee4e624a1cf61c1`.
- APK SHA-256:
  `1fad89aead3bb911df20cb0bf94eed5cda8b9d59d28dd176b6b4ae1c78f3ea6a`.

## Проверки

- Flutter analyze: PASS, замечаний нет.
- Flutter tests: PASS, 135 тестов.
- Android release unit tests: PASS, 31 тест; 0 ошибок и пропусков.
- Android release lint: PASS, замечаний нет.
- Статические проверки проекта: PASS, 472 проверки.
- APK signature verification: PASS, сертификат совпадает с постоянным ключом.
- APK alignment: PASS (`zipalign -c -P 16 4`).
- В APK присутствуют только нужные разрешения: распознавание активности,
  уведомления и health foreground service. `INTERNET` отсутствует.
- APK не содержит `debuggable`.

## Воспроизведение

Сборка выполнена Flutter 3.35.7 / Dart 3.9.2, JDK 17, Android SDK 36:

```sh
flutter build apk --release --target-platform android-arm64 \
  --build-name=3.10.0 --build-number=24
```

Release unit tests и lint запускались Gradle по release-варианту. Для Flutter
тестов в данном Linux runner потребовался временный `LD_LIBRARY_PATH` на
системную SQLite-библиотеку: самого имени `libsqlite3.so` в runner нет.
Файлы приложения и системные настройки для этого не менялись.

## Ограничения

- Проверка на физическом телефоне и Android-лаунчере не выполнялась.
- Коммит, push, тег и GitHub Release не создавались; подготовлен source ZIP
  для загрузки пользователем.
- В source ZIP не включены приватный ключ, `key.properties`, APK, `.git`,
  сборочные каталоги, SDK и кэши.
