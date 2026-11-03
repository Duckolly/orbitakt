# Орбитакт — сведения для текущего патча 3.9.4

Возрастное ограничение разработчика: только 16+. Приложение требует самоподтверждения возраста при первом запуске и после обновления с прежнего порога. Не предназначено для пользователей младше 16 лет; согласие представителя не является альтернативой подтверждению 16+.

Это описание целевой аудитории продукта. Возрастной рейтинг магазина определяется отдельно по фактическим ответам на его рейтинговый опрос; опрос в этом пакете не отправлялся.

Сайт: https://duckolly.github.io/testofsilence/ . Поддержка: https://t.me/dvizhoffline .

## Остальные материалы карточки

> Извлечено из исходного чата. Актуальность внешних требований и заявленные в тексте статусы не подтверждены. Фактическая готовность: docs/PACKAGING_STATUS.md и docs/VERIFICATION.md.

# Store Listing — Орбитакт v3.2.0

## App name

```text
Орбитакт — offline activity tracker
```

Alternative:

```text
Dvizh: local step tracker
```

---

## Short description

```text
Simple offline activity tracker. No account, no internet, no ads, no analytics.
```

---

## Full description

```text
“Dvizh” is a simple offline mobile app for local physical activity tracking.

What it can do:
• choose activity type: walking, running, or workout;
• count steps using the device motion sensor;
• track workout duration;
• store history only on the device;
• let the user disable recording;
• let the user disable notifications;
• let the user clear history;
• let the user delete all local data.

Privacy:
• the app works offline;
• no registration;
• no server;
• no advertising;
• no analytics;
• no crash reporting;
• no location access;
• no camera access;
• no microphone access;
• no contacts access;
• no personal data collection;
• no automatic data sharing with the developer or third parties.

Important:
The app is not a medical device. It does not diagnose, treat, cure, or prevent any disease. Step counting and activity tracking are approximate and depend on the device, sensors, and how the phone is carried.
```

---

## Release notes

```text
v3.2.0 Local-Only

- Removed weight and calories.
- Removed nicknames and group codes.
- Removed PDF export and sharing.
- Removed foreground service.
- Added privacy consent screen.
- Added recording toggle.
- Added notifications toggle.
- Added clear history.
- Added delete all data.
- Hardened Android permissions.
- Disabled backup.
- Prepared for open-source distribution.
```

---

## Permission explanations

### ACTIVITY_RECOGNITION

```text
This permission is used only to access the device motion sensor in order to count steps during an active workout started by the user. Data are processed locally and are not sent to a server.
```

### POST_NOTIFICATIONS

```text
This permission is used only if the user enables notifications. The app shows a local ongoing notification indicating that recording is active. Notifications do not contain personal data and are not used for advertising.
```
