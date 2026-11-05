import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/theme/app_theme.dart';
import 'package:dvizh/theme/seasonal_controller.dart';
import 'package:dvizh/widgets/seasonal_surface.dart';
import 'package:dvizh/widgets/seasonal_settings_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'theme_mode_index': 2,
      'activityPreferencesV1': 'unchanged',
    });
    SeasonalController.appearance.value = const SeasonalAppearance();
  });
  tearDown(
    () => SeasonalController.appearance.value = const SeasonalAppearance(),
  );
  test(
    'persist skin, preserve old settings, reset after clear and malformed input',
    () async {
      await SeasonalController.set(
        const SeasonalAppearance(newYear: true, animate: false),
      );
      SeasonalController.appearance.value = const SeasonalAppearance();
      await SeasonalController.load();
      expect(SeasonalController.appearance.value.newYear, isTrue);
      expect(SeasonalController.appearance.value.animate, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_mode_index'), 2);
      expect(prefs.getString('activityPreferencesV1'), 'unchanged');
      await prefs.clear();
      await SeasonalController.load();
      expect(SeasonalController.appearance.value.newYear, isFalse);
      await prefs.setString(SeasonalController.storageKey, '{bad json');
      await SeasonalController.load();
      expect(SeasonalController.appearance.value.newYear, isFalse);
    },
  );
  Widget harness({bool reduced = false, bool dark = false, Widget? child}) =>
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: SeasonalSurface(
              child: child ?? const Card(child: Text('Карточка')),
            ),
          ),
        ),
      );
  testWidgets('classic is static; winter decoration does not intercept taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(
        child: TextButton(
          onPressed: () => taps++,
          child: const Text('Действие'),
        ),
      ),
    );
    expect(tester.binding.transientCallbackCount, 0);
    SeasonalController.appearance.value = const SeasonalAppearance(
      newYear: true,
      animate: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Действие'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion and manual disable stop snow in both themes', (
    tester,
  ) async {
    SeasonalController.appearance.value = const SeasonalAppearance(
      newYear: true,
    );
    for (final dark in [false, true]) {
      await tester.pumpWidget(harness(reduced: true, dark: dark));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      final theme = Theme.of(tester.element(find.byType(Card)));
      expect(theme.brightness, dark ? Brightness.dark : Brightness.light);
      expect(
        (theme.cardTheme.shape! as RoundedRectangleBorder).side.width,
        greaterThan(0),
      );
      expect(tester.takeException(), isNull);
    }
    SeasonalController.appearance.value = const SeasonalAppearance(
      newYear: true,
      animate: false,
    );
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('background and covering route stop animation', (tester) async {
    SeasonalController.appearance.value = const SeasonalAppearance(
      newYear: true,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      harness(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Инструмент')),
              ),
            ),
            child: const Text('Открыть'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.tap(find.text('Открыть'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('settings save winter skin on narrow screen with large font', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: const SingleChildScrollView(child: SeasonalSettingsCard()),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Обычный'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Новогодний').last);
    await tester.pumpAndSettle();
    expect(SeasonalController.appearance.value.newYear, isTrue);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(SeasonalController.appearance.value.animate, isFalse);
    expect(tester.takeException(), isNull);
  });
}
