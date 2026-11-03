## Орбитакт 3.9.5+18

Режим «Перед сном»: постепенное дыхание 4/4 → 4,5/4,5 → 5/5 с по комфорту и явному выбору, свободный ритм, 4,5/5,5 с, локальный прогресс, 5/10/15 минут. Подробности: RELEASE_NOTES_3.9.5.md; проверка: docs/VERIFICATION_3.9.5.md. Предыдущие записи ниже — история версий.

# 3.7.1+9

Утверждённая иконка Д, adaptive/round/monochrome и legacy ресурсы. Видимые метки теста сняты: приложение и заголовок Движ, виджет Движ: шаги и вода. Пакет и ключ сохранены, логика хранения/датчиков не менялась. Отзыв пользователя о пилоте зафиксирован. 82 теста и Android Lint PASS.

# 3.7.0+8

Ночное небо: встроенные 920 звёзд/14 фигур/44 города, ручные координаты, UTC, тёмная карта, ручной и необязательный автоматический поворот. Новых разрешений нет. 61 Flutter + 21 Kotlin тестов и Android Lint. Лицензии данных включены.

# 3.6.0+7

Три режима дыхания, необязательный наклон в Бегалке, относительный перепад высоты при наличии барометра. Опрос только при активном использовании, без новых разрешений. 47 Flutter + 17 Kotlin тестов. Звёздная карта исследована, не включена.

> Извлечено из исходного чата. Актуальность внешних требований и заявленные в тексте статусы не подтверждены. Фактическая готовность: docs/PACKAGING_STATUS.md и docs/VERIFICATION.md.

# Changelog

## [3.2.0] - 2026-10-31

### Removed
- Weight collection.
- Calories calculation.
- Nickname field.
- Group code field.
- Foreground service.
- PDF export.
- Share integration.

### Added
- Privacy consent screen.
- Age confirmation.
- Offline understanding confirmation.
- Master recording toggle.
- Notifications toggle.
- Clear history.
- Delete all data.
- Local-only store-safe build.
- Hardened Android manifest.
- Backup disabled.
- Privacy policy.
- Open-source license and README.
