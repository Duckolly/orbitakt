# Обновление GitHub до Движа 3.8.2

Рабочая папка остаётся C:\Users\s.shvetsov\Documents\dvizh\dvizh.
Новый репозиторий не создавать: git clone/git init больше не нужны.

1. Если после предыдущей публикации ты менял код, сначала сохрани/закоммить свои
   изменения. Архив обновления заменяет одноимённые файлы выданного релиза.
2. Распакуй DVIZH_3.8.2_GitHub_Ready.zip прямо в рабочую папку с заменой файлов.
   В корне ZIP сразу app/, docs/, branding/, .gitignore и dist/; обёртки нет.
   Существующую .git не удалять. Архив не удаляет старые файлы, которых в нём нет.
3. Выполни каждую команду отдельно:

```powershell
cd "C:\Users\s.shvetsov\Documents\dvizh\dvizh"
git status --short
git add .
git ls-files -ci --exclude-standard
git --no-pager diff --cached --name-only
```

Проверка ignored tracked должна быть пустой; в списке исходников нет APK/ZIP/ключей.
При ошибке не продолжай автоматически и не используй --force.

```powershell
git commit -m "Fix widget trailing refresh for Dvizh 3.8.2"
git push
```

4. GitHub → Releases → Draft a new release → новый тег v3.8.2, Target main,
   название «Движ 3.8.2». В описание вставить RELEASE_NOTES_3.8.2.md.
5. Прикрепить dist/dvizh-3.8.2-arm64.apk и CHECKSUMS_SHA256.txt; Publish release.
   Старые v3.8.0/v3.8.1 не переименовывать и не заменять его APK файлом новой версии.
6. Установить новую APK поверх3.8.0, проверить прежние данные и раздел
   «Настройки → О приложении и связь»: открыть Telegram и скопировать адрес.

dist/, APK, ZIP, ключи, local.properties, SDK и кэши игнорируются. Приватных ключей
и SDK в архиве нет. Сборка подписана прежним development-ключом для совместимости
нынешних установок; магазинная подпись требует отдельного решения.
Скачивание из приватного репозитория доступно людям с правом чтения.

Для команд Flutter: cd .\app. Для Git вернись в корень: cd ..
