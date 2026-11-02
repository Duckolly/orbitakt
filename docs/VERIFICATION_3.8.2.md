# Проверка Движа 3.8.2+12

- 72 Flutter + 32 Kotlin тестов — PASS; Flutter analyze без замечаний.
- Android Lint release — PASS, без новых разрешений.
- ARM64 release, debuggable=false, label «Движ», versionCode12.
- APK: 17973327 байт (17.97 МБ), SHA-256 `24e5e48ba11fb069353661b29f59fa23d3f75f571dc64da7d85dab865945c4d9`.
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

Исправление виджета покрыто9 новыми JVM-тестами; policy проверяет maxReportLatencyUs0 при интерактивном устройстве и60с в фоне. Device/launcher-проверка без нажатия на виджет ещё требуется.
