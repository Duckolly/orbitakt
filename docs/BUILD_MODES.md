# Сборка основной и тестовой версии

Flutter 3.35.7, JDK 17 и Android SDK 36 — как в START_HERE.md. Везде сначала flutter pub get --enforce-lockfile, flutter analyze --no-pub, flutter test --no-pub.

## Тестовая ARM64 release-сборка, отдельное приложение

PowerShell (из app):

```powershell
$env:ORG_GRADLE_PROJECT_dvizhPreview = "true"
flutter build apk --release --target-platform android-arm64 --dart-define=DVIZH_PREVIEW=true --no-pub
Remove-Item Env:ORG_GRADLE_PROJECT_dvizhPreview
```

Bash:

```bash
ORG_GRADLE_PROJECT_dvizhPreview=true flutter build apk --release --target-platform android-arm64 --dart-define=DVIZH_PREVIEW=true --no-pub
```

Результат: app/build/app/outputs/flutter-apk/app-release.apk, applicationId com.duckolly.dvizh.preview, название «Движ». Подпись — Android debug keystore, но код собирается в release с оптимизацией. Для обновления preview использовать тот же preview-keystore; это не прежний ключ основного приложения.

Проверка разрешений preview:

```bash
aapt dump permissions app-release.apk | python3 ../tools/check_permissions.py --package com.duckolly.dvizh.preview
```

## Основное приложение

Сбросить переменную dvizhPreview. Для основной подписанной release-сборки нужен android/key.properties, ссылающийся на постоянный ключ владельца. По умолчанию отсутствие файла блокирует release, как и раньше. Совместимость с уже установленным приложением определяется сертификатом, а не названием APK или versionCode.

Для явно неподписанного артефакта, который нельзя установить без последующей подписи:

```bash
ORG_GRADLE_PROJECT_dvizhUnsigned=true flutter build apk --release --target-platform android-arm64 --no-pub
```

Оба флага являются явными режимами подготовки. Ни preview с другим package, ни неподписанный APK не заменяют подписанный выпуск основного приложения для магазина. Ключи и android/key.properties не публиковать вместе с исходниками.

## Повторная сборка preview с сохранением подписи

Новый тестовый ключ хранится отдельно: DVIZH_Preview_Signing_Key_PRIVATE.zip. Он не является исходным ключом основного ДВИЖ. Не публиковать и не коммитить. Для повторной сборки preview задайте ORG_GRADLE_PROJECT_dvizhPreviewKeystore абсолютным путём к распакованному DVIZH_Preview_Debug.keystore. Это позволяет сохранить подпись без перезаписи глобального debug-keystore других проектов. Пароли и alias для этой стандартной тестовой подписи приведены в приватном комплекте. Для основного магазинного приложения нужен отдельный постоянный ключ владельца.
