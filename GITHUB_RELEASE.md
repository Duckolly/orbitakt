# Движ 3.9.2+15 — компактный главный экран

## Что входит в релиз

Шаги и вода показаны вместе на стартовом экране при обычном размере шрифта. Быстрое добавление 200 мл и отмена доступны без начальной прокрутки. При увеличенном шрифте используется прокрутка без уменьшения текста.

Название «Движ» сохранено: результат поиска «Орбитакт» в официальной форме Роспатента не получен из-за ошибки доступа. Условие для переименования сайта и приложения не подтверждено. См. docs/ORBITAKT_SEARCH_STATUS.md.

## Файлы

- dvizh_392_source.zip — исходники для обновления существующего репозитория, без APK и ключей.
- dvizh_392_arm64.apk — отдельная устанавливаемая предварительная сборка Android ARM64.
- Подробности и приёмка: RELEASE_NOTES_3.9.2.md.
- Результаты проверки: docs/BUILD_VERIFICATION.json и docs/VERIFICATION_3.9.2.md.

## Обновление Git-репозитория

Распаковать содержимое исходников в корень существующего репозитория, где находится .git. Не создавать вложенный дубликат каталога и не удалять .git. Не удалять локальные приватные ключи и android/key.properties.

Перед коммитом:

```powershell
git diff --check
git status --short
```

Убедиться, что изменения соответствуют релизу, затем:

```powershell
git add app/lib/screens/home_screen.dart app/lib/widgets/daily_summary.dart app/lib/widgets/water_summary.dart app/pubspec.yaml app/test/orbit_ui_test.dart RELEASE_NOTES_3.9.2.md README.md START_HERE.md GITHUB_RELEASE.md CHECKSUMS_SHA256.txt docs
git diff --cached --stat
git commit -m "Fit daily steps and water on the home screen"
git push
```

APK прикрепляется к GitHub Release отдельно. Подпись разработки сохранена для обновления установленных предварительных APK; это не означает готовность магазинной сборки или регистрацию названия.
