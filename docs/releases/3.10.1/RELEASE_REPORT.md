# Орбитакт 3.10.1+25 — проверка релиза, 2026-11-05

## Результат

- Подписанный release APK: `orbitakt-3.10.1-25-arm64.apk`.
- Пакет: `com.duckolly.dvizh`; версия `3.10.1`, versionCode `25`.
- ARM64, Android 7.0+ (minSdk 24), targetSdk 36.
- Размер APK: 20,046,686 байт; ранее 51,259,070 байт.
- APK уменьшился на 60.9%.
- 14 картинок уровней: 32 915 634 → 1 703 186 байт (-94,83%).
- Разрешение картинок 1024×1024, WebP quality 86.
- Программный код совпадает с 3.10.0+24; изменены изображения и документация.
- Версия передана через CLI, pubspec.yaml сохранён.

## Проверки

- Flutter analyze: PASS, замечаний нет.
- Flutter tests: PASS, 135 тестов.
- Android release unit tests: PASS, 31 тест, 0 ошибок и пропусков.
- Android release lint: PASS, 0 замечаний.
- Статические проверки проекта: PASS, 472 проверки.
- Подпись APK: PASS; сертификат совпадает с предыдущим release APK.
- ZIP alignment: PASS (`zipalign -c -P 16 4`).
- Все LOAD-сегменты native ELF совместимы с размером страницы 16 КБ.
- Все 14 уменьшенных изображений внутри APK побайтово совпадают с исходниками.
- Только ABI arm64-v8a; debuggable выключен; INTERNET отсутствует.

## Контрольные суммы

Сертификат SHA-256: `57044e5fd5fa4a53e3636d8a6c245136bac8fd0adae65120eee4e624a1cf61c1`.

APK SHA-256: `1a57fe77f32c44f307ac36dbd16fc7084ff24b58cdf627fb1176ebd8497680c5`.

## Воспроизведение

Flutter 3.35.7 / Dart 3.9.2, Amazon Corretto JDK 17.0.21,
Android SDK platform 36, NDK 27.0.12077973, Gradle 8.11.1.

```sh
cd app
flutter pub get
flutter build apk --release --target-platform android-arm64 \
  --build-name=3.10.1 --build-number=25
cd android
./gradlew :app:testReleaseUnitTest :app:lintRelease -Ptarget-platform=android-arm64
```

Приватный постоянный ключ и key.properties хранятся отдельно.
Ключи, пароли, APK, SDK и build-кэши в архив исходников не включены.

## Границы проверки

На физическом телефоне и в Android-лаунчере новая сборка не проверялась.
GitHub, сайт, теги и GitHub Releases в рамках этой пересборки не менялись.
В новой среде восстановлены SDK и зависимости; исправлены расположение
компонентов SDK и кэш Gradle. Эти исправления касаются только среды сборки.
