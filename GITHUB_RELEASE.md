# Орбитакт 3.9.4

Репозиторий: https://github.com/Duckolly/orbitakt . Тег: v3.9.4.

## Описание для GitHub Release

- Приложение теперь только для пользователей от 16 лет. При первом запуске обновления нужно заново подтвердить 16+; история и настройки сохраняются.
- В «О приложении и авторе» добавлены сайт https://duckolly.github.io/testofsilence/ , открытие в браузере и копирование адреса.
- На полосе прогресса и в иллюстрациях теперь фиолетовый котик с ушками, мордочкой, усами, лапками и хвостом.
- Компактный главный экран сохранён: шаги, километры и вода видны вместе при обычном шрифте на проверенных размерах.

Установить APK поверх предыдущей предварительной версии без удаления приложения. Android package и подпись не менялись. Подтверждение возраста — декларация пользователя, без сбора даты рождения и документов; это не результат рейтингового опроса магазина.

## Вложения

Скачанный файл orbitakt_394_arm64.apk перед загрузкой в Assets назвать **orbitakt-arm64.apk**, сохранив содержимое. Постоянная ссылка последнего опубликованного релиза:

https://github.com/Duckolly/orbitakt/releases/latest/download/orbitakt-arm64.apk

- orbitakt-arm64.apk — версия 3.9.4, Android versionCode 17, ARM64.
- orbitakt_394_source.zip — исходники без APK и приватных ключей.
- SHA-256 APK — CHECKSUMS_SHA256.txt.

Сам релиз GitHub и сайт этим пакетом автоматически не публикуются.

## Обновление исходников

Распаковать содержимое ZIP в корень существующего Git-репозитория (где .git). Сохранить .git и локальные ключи.

```powershell
git diff --check
git status --short
git add app docs RELEASE_NOTES_3.9.4.md README.md START_HERE.md GITHUB_RELEASE.md CHECKSUMS_SHA256.txt PRIVACY.md STORE_LISTING.md
git diff --cached --stat
git commit -m "Require age 16+, add website link and draw purple cat mascot"
git push
```
