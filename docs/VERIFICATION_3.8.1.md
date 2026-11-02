# Проверка Движа 3.8.1+11

- 72 Flutter + 23 Kotlin тестов — PASS; Flutter analyze без замечаний.
- Android Lint release — PASS, без новых разрешений.
- ARM64 release, debuggable=false, label «Движ», versionCode11.
- APK: 17973331 байт (17.97 МБ), SHA-256 `fe113cc4d1aaeebf29bcb7e0e96b87a806b852721a6c085f1775e32c73045271`.
- Сертификат прежний: `e68b0a1dce65741b78635a55fc02f17cc253e5094ceb739beddb3449ad9e089f`, APK Signature v2 — PASS.
- ZIP CRC, exact permission allowlist5, zipalign16KB и ELF PT_LOAD≥16KB — PASS.
- Исходники/тесты/ресурсы и входы сборки сверены; данные каталога в APK сверены.
- Проверено на Linux с Flutter3.35.7/Dart3.9.2, JDK17, AndroidSDK36, AGP8.9.2.
- Источники модуля: android.os.BatteryManager, PowerManager, Process, SystemClock;
  API считываются локально по запросу, новых служб и периодического опроса нет.

Физический телефон, реальное обновление поверх3.8.0, расход батареи, точность
сенсоров, Android17 и Windows-сборка этой версии не проверены автоматически.
Совместимость обновления подтверждена пакетом/подписью/code, приёмка остаётся ручной.
Подпись разработки сохраняет нынешние установки; это не магазинный релиз с постоянным ключом.
