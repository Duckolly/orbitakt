> Извлечено из исходного чата. Актуальность внешних требований и заявленные в тексте статусы не подтверждены. Фактическая готовность: docs/PACKAGING_STATUS.md и docs/VERIFICATION.md.

# Google Play Release Checklist — Движ v3.2.0

## 1. Аккаунт и релизный процесс

- [ ] Аккаунт разработчика Google Play создан.
- [ ] Если аккаунт личный, выполнено требование закрытого тестирования:
  - минимум 12 уникальных тестеров;
  - минимум 14 дней тестирования.
- [ ] Приложение подаётся как AAB, не APK.
- [ ] Используется Play App Signing или надёжно хранится upload keystore.
- [ ] `key.properties` и keystore не закоммичены в git.

---

## 2. Сборка

Выполни:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Ожидаемый файл:

```text
build/app/outputs/bundle/release/app-release.aab
```

- [ ] `flutter analyze` без errors.
- [ ] `flutter test` без падений.
- [ ] `flutter build appbundle --release` успешен.

---

## 3. Разрешения

Проверь debug APK:

```bash
flutter build apk --debug
aapt dump permissions build/app/outputs/flutter-apk/app-debug.apk
```

Допустимо:

```text
android.permission.ACTIVITY_RECOGNITION
android.permission.POST_NOTIFICATIONS
```

Не должно быть:

```text
android.permission.INTERNET
android.permission.ACCESS_NETWORK_STATE
android.permission.ACCESS_WIFI_STATE
android.permission.ACCESS_FINE_LOCATION
android.permission.ACCESS_COARSE_LOCATION
android.permission.CAMERA
android.permission.RECORD_AUDIO
android.permission.READ_CONTACTS
android.permission.READ_CALENDAR
android.permission.WRITE_CALENDAR
android.permission.READ_SMS
android.permission.RECEIVE_SMS
android.permission.FOREGROUND_SERVICE
android.permission.RECEIVE_BOOT_COMPLETED
android.permission.WAKE_LOCK
android.permission.VIBRATE
com.google.android.gms.permission.AD_ID
```

- [ ] Нет `INTERNET`.
- [ ] Нет location.
- [ ] Нет camera.
- [ ] Нет microphone.
- [ ] Нет contacts.
- [ ] Нет SMS.
- [ ] Нет AD_ID.
- [ ] Нет foreground service.

Если какое-то разрешение появилось от плагина:

1. найди плагин через `flutter pub deps`;
2. удали плагин, если он не нужен;
3. либо оставь `tools:node="remove"` в манифесте;
4. пересобери и проверь снова.

---

## 4. Privacy Policy

- [ ] Файл `PRIVACY.md` есть в репозитории.
- [ ] Файл `docs/privacy.html` есть в репозитории.
- [ ] HTML опубликован по публичному URL.
- [ ] URL открывается без авторизации.
- [ ] В Google Play Console указан этот URL.
- [ ] Дата обновления в policy актуальна.

Пример URL:

```text
https://duckolly.github.io/dvizh/privacy.html
```

---

## 5. Data Safety

Примерные ответы для v3.2.0 Local-Only:

- Data collected: physical activity / motion sensor data.
- Purpose: app functionality.
- Collection: on-device only.
- Sharing: no.
- Encryption in transit: not applicable, no transmission.
- User can delete data: yes.
- Developer does not receive data: yes.

- [ ] Форма Data Safety заполнена.
- [ ] Ответы не противоречат коду.
- [ ] Ответы не противоречат privacy policy.
- [ ] Указано, что данные не передаются разработчику.
- [ ] Указано, что пользователь может удалить данные в приложении.

---

## 6. Content rating и аудитория

- [ ] Пройдена анкета IARC.
- [ ] Не выбрана детская аудитория.
- [ ] В описании нет слов:
  - children;
  - kids;
  - schoolchildren;
  - students;
  - classroom;
  - parent control.
- [ ] Приложение позиционируется как general/offline activity tracker.

---

## 7. Медицинские заявления

Нельзя писать:

- weight loss;
- health improvement;
- medical;
- diagnosis;
- treatment;
- calories burned as medical metric;
- rehabilitation.

Можно писать:

- local activity tracking;
- step counting;
- workout duration;
- offline history.

- [ ] В описании есть дисклеймер, что приложение не медицинское.
- [ ] В privacy policy есть медицинский дисклеймер.

---

## 8. Store listing

Используй тексты из `STORE_LISTING.md`.

- [ ] Название понятное.
- [ ] Короткое описание не обещает здоровье/похудение.
- [ ] Полное описание содержит privacy и medical disclaimer.
- [ ] Скриншоты не содержат реальных персональных данных.
- [ ] Release notes соответствуют версии v3.2.0.

---

## 9. Ручной smoke test

### Первый запуск

- [ ] Открывается экран согласия.
- [ ] Кнопка «Продолжить» неактивна, пока не поставлены все галочки.
- [ ] После галочек открывается главный экран.
- [ ] Разрешения пока не запрашиваются.

### Запись

- [ ] Выбираешь «Ходьба».
- [ ] Нажимаешь «Начать».
- [ ] Запрашивается доступ к датчикам движения.
- [ ] После разрешения таймер запускается.
- [ ] Шаги считаются при ходьбе/встряхивании.
- [ ] Нажимаешь «Стоп».
- [ ] Тренировка сохраняется.
- [ ] Возвращаешься на главный экран.

### История

- [ ] Открываешь историю.
- [ ] Видишь сохранённую тренировку.
- [ ] Нажимаешь «Очистить историю».
- [ ] Подтверждаешь удаление.
- [ ] История становится пустой.
- [ ] После перезапуска приложения история всё ещё пуста.

### Настройки

- [ ] Выключаешь «Разрешить запись активности».
- [ ] Пробуешь начать тренировку.
- [ ] Появляется сообщение, что запись отключена.
- [ ] Включаешь обратно.
- [ ] Тренировка снова доступна.

### Уведомления

- [ ] Выключаешь уведомления.
- [ ] Начинаешь запись.
- [ ] Уведомление не появляется.
- [ ] Включаешь уведомления.
- [ ] Система запрашивает разрешение.
- [ ] После разрешения уведомление появляется во время записи.
- [ ] После остановки уведомление исчезает.

### Удаление всех данных

- [ ] Нажимаешь «Удалить все данные».
- [ ] Подтверждаешь.
- [ ] Приложение возвращается на экран согласия.
- [ ] История пуста.
- [ ] Настройки сброшены.

---

## 10. Финальная проверка перед submit

- [ ] AAB собран в release.
- [ ] Подпись release корректна.
- [ ] Permissions проверены.
- [ ] Privacy policy URL работает.
- [ ] Data Safety заполнена.
- [ ] Content rating пройдена.
- [ ] Store listing заполнена.
- [ ] Closed testing выполнено, если требуется.
- [ ] Нет личных данных в репозитории.
- [ ] Нет keystore/passwords в git.
