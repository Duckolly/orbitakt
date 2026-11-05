import 'dart:async';

import 'package:flutter/material.dart';
import 'services/tool_routes.dart';
import 'services/consent_preferences.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/consent_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/seasonal_controller.dart';

void main() {
  // R-2: зональная защита от uncaught без crash-reporting (наружу не уходит).
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      await ThemeController.load();
      await SeasonalController.load();
      try {
        await NotificationService.instance.init();
      } catch (_) {
        // Optional notifications must not prevent opening the local tracker.
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final bool hasConsent = ConsentPreferences.accepted(prefs);

      runApp(DvizhApp(showConsentFirst: !hasConsent));
    },
    (Object error, StackTrace stack) {
      // Graceful degradation: логируем локально, не отправляем наружу.
      // Точечные UI-ошибки закрыты try/catch в экранах.
      debugPrint('Dvizh uncaught: $error');
    },
  );
}

class DvizhApp extends StatelessWidget {
  final bool showConsentFirst;

  const DvizhApp({super.key, required this.showConsentFirst});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
        return MaterialApp(
          navigatorObservers: [toolRouteObserver],
          title: 'Орбитакт',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: showConsentFirst ? const ConsentScreen() : const HomeScreen(),
        );
      },
    );
  }
}
