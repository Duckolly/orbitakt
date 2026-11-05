# Орбитакт 3.10.1 (25)

Уменьшен размер изображений уровней: 14 WebP-картинок занимают
1 703 186 байт вместо примерно 32,9 МБ. Разрешение — 1024×1024.
Включена подготовленная оптимизация остальных PNG-изображений проекта.
Логика приложения, пороги уровней и формат пользовательских данных не менялись.

Пакет com.duckolly.dvizh, ARM64, Android 7.0+ (minSdk 24).
Сборка: Flutter 3.35.7, Dart 3.9.2, JDK 17, Android SDK 36.

```sh
cd app
flutter pub get
flutter build apk --release --target-platform android-arm64 \
  --build-name=3.10.1 --build-number=25
```

Для подписи нужен прежний приватный release-ключ, который хранится отдельно.
Результаты проверок: docs/releases/3.10.1/RELEASE_REPORT.md.
