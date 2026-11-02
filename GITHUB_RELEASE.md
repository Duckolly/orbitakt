# Движ 3.8.0: первая публикация на GitHub

## Единственная рабочая папка

Сохраняем уже созданный репозиторий:
C:\Users\s.shvetsov\Documents\dvizh\dvizh

Внешняя Documents\dvizh — контейнер. Вложенная Documents\dvizh\dvizh — корень
репозитория с существующей скрытой папкой .git. Разработку и команды Git выполняем
во вложенной папке. Команды Flutter выполняем в её подпапке app.
Переименовывать папки, создавать бэкап, повторять git clone или git init не нужно.

## 1. Проверь рабочую папку

В PowerShell выполняй каждую команду отдельно, нажимая Enter после каждой.

```powershell
Set-Location -LiteralPath "C:\Users\s.shvetsov\Documents\dvizh\dvizh"
```

```powershell
git rev-parse --show-toplevel
```

Ожидается C:/Users/s.shvetsov/Documents/dvizh/dvizh (слеши могут отличаться).
Если выводит другой путь или сообщает not a git repository — не выполняй push:
сначала нужно определить, где находится клонированный репозиторий.

```powershell
git remote -v
```

origin должен указывать на https://github.com/Duckolly/dvizh.git (либо SSH-адрес
того же репозитория). Адрес можно сверить в GitHub: Code → HTTPS.

## 2. Распакуй новый ZIP прямо в рабочую папку

DVIZH_3.8.0_GitHub_Ready.zip содержит файлы прямо в корне архива: app/, docs/,
branding/, .gitignore, README.md и другие документы. Папки-обёртки внутри нет.
Извлеки содержимое именно в Documents\dvizh\dvizh, согласившись заменить
одноимённые файлы ранее выданного пакета. Своих новых изменений к коду после
выданного релиза здесь не предполагается: если ты их уже делал, сначала сохрани их.
Не создавай ещё одну папку dvizh или 02_dvizh_offline_tracker при распаковке.

Правильные пути после распаковки:
- Documents\dvizh\dvizh\app\pubspec.yaml
- Documents\dvizh\dvizh\app\lib\main.dart
- Documents\dvizh\dvizh\docs
- Documents\dvizh\dvizh\branding
- Documents\dvizh\dvizh\.gitignore
- Documents\dvizh\dvizh\dist\dvizh-3.8.0-arm64.apk
- Documents\dvizh\dvizh\.git — уже создан Git, в ZIP этой папки нет.

APK в dist/ предназначен для GitHub Release; dist/ и APK исключены из Git.
Архив не содержит приватных ключей, SDK, local.properties, key.properties и кэшей.
Скрытый .gitignore уже включён: скачивать и переименовывать отдельно не нужно.
Новый архив не удаляет лишние файлы, ранее ошибочно скопированные тобой.

## 3. Подготовь коммит и проверь состав

В PowerShell оставайся в Documents\dvizh\dvizh.

```powershell
git status --short
```

```powershell
git check-ignore -v dist/dvizh-3.8.0-arm64.apk
```

Последняя команда должна вывести правило из .gitignore для dist/ или APK.
Если файл уже отслеживается Git, обычный check-ignore может ничего не вывести;
в этом случае следующая проверка покажет его.

```powershell
git ls-files -ci --exclude-standard
```

Этот список должен быть пустым. Если он показывает APK, архив, ключ или кэш,
файл уже добавлен в индекс раньше: .gitignore сам его не убирает.
Убери конкретный файл из индекса (он останется на диске):

```powershell
git rm --cached -- "ОТНОСИТЕЛЬНЫЙ_ПУТЬ_К_ФАЙЛУ"
```

Для конкретного каталога применяется git rm -r --cached -- "ПУТЬ_К_КАТАЛОГУ".
Подставляй настоящий путь из вывода, не выполняй шаблон буквально.
Если ключ когда-либо уже был в коммите, удаления из индекса недостаточно для
удаления из истории; не публикуй такую историю без отдельной проверки.

```powershell
git add .
```

```powershell
git diff --cached --name-only
```

```powershell
git ls-files -ci --exclude-standard
```

В списке коммита должны быть app/, docs/, branding/, лицензии, .gitignore,
pubspec.lock и документы. Не должно быть APK/ZIP/keystore/JKS, dist/, SDK/кэшей,
key.properties или local.properties. Вторая проверка должна быть пустой.
Также не должно быть лишней папки 02_dvizh_offline_tracker/ либо ещё одной dvizh/.
Не применяй git add -f: это обходит .gitignore.

## 4. Сделай коммит и отправь исходники

```powershell
git commit -m "Release Dvizh 3.8.0: battery and load"
```

Если Git попросит имя и email, задай их только для этого репозитория и повтори commit:

```powershell
git config user.name "Сергей Швецов"
```

```powershell
git config user.email "ВАШ_EMAIL_ИЛИ_NOREPLY_АДРЕС_GITHUB"
```

Email можно взять в GitHub Settings → Emails. Подставь свой, не выполняй шаблон
с вымышленным адресом. При настроенной подписи коммитов соблюдай свои настройки.

После успешного commit:

```powershell
git branch -M main
```

```powershell
git push -u origin main
```

При запросе авторизации используй обычное окно Git/GitHub. Не вставляй токен в
URL репозитория и файлы проекта. Если push отклонён или появилась ошибка —
не используй --force; разберись с сообщением перед повтором.
Обнови страницу репозитория: на верхнем уровне должны появиться app/, docs/ и README.md.

## 5. Создай релиз с APK

GitHub → репозиторий Duckolly/dvizh → Releases → Draft a new release:
- Tag: v3.8.0 → Create new tag.
- Target: main.
- Title: Движ 3.8.0.
- Description: содержимое RELEASE_NOTES_3.8.0.md из корня проекта.
- Attachments: dist/dvizh-3.8.0-arm64.apk и CHECKSUMS_SHA256.txt.
- Publish release.

APK прикрепляется здесь отдельно; он не должен находиться в истории исходников.
Релиз приватного репозитория доступен людям с доступом к репозиторию. Друзьям без
доступа APK можно передать напрямую. Приватный ключ нигде на GitHub не публикуем.

## 6. Дальнейшая разработка

Корень Git: C:\Users\s.shvetsov\Documents\dvizh\dvizh
Flutter-проект: C:\Users\s.shvetsov\Documents\dvizh\dvizh\app

Для Flutter-команд сначала cd .\app; для git-команд удобнее вернуться cd ..
После изменений: git status → git add нужных файлов → git commit → git push.
При разработке с нескольких ПК перед началом синхронизируй ветку; незакоммиченные
изменения сначала сохрани. Не публикуй случайные изменения, появившиеся от сборки.

## Что входит в этот комплект

Все исходники и тесты Движа 3.8.0+10, ресурсы/иконка/каталоги/лицензии, документация,
обновлённый .gitignore и проверенный ARM64 APK. Исходный код приложения не менялся:
68 Flutter + 23 Kotlin тестов, analyze и Android Lint ранее пройдены для этого APK.
В этой операции проверены только упаковка, контрольная сумма APK и правила Git.
Сама сборка не запускалась заново. Подпись разработки прежняя; выпуск в магазине
требует отдельной подготовки. Физический замер батареи ещё остаётся задачей.

Официальные инструкции:
https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository
https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository
