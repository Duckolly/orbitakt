import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/screens/home_screen.dart';
import 'package:dvizh/screens/water_screen.dart';
import 'package:dvizh/services/daily_tracker.dart';
import 'package:dvizh/services/water_tracker.dart';
import 'package:dvizh/theme/app_theme.dart';
import 'package:dvizh/widgets/activity_preferences_card.dart';
import 'package:dvizh/widgets/water_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var glasses = 6;
  Completer<Map<String, dynamic>>? pending;
  var changes = 0;
  Map<String, dynamic> water() => {
    'today': '2026-11-02',
    'glasses': glasses,
    'history': [
      {'day': '2026-11-02', 'glasses': glasses},
    ],
  };
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    glasses = 6;
    changes = 0;
    pending = null;
    messenger.setMockMethodCallHandler(
      DailyTracker.channel,
      (_) async => {
        'todaySteps': 6420,
        'enabled': true,
        'running': true,
        'supported': true,
        'history': [],
      },
    );
    messenger.setMockMethodCallHandler(WaterTracker.channel, (call) async {
      if (call.method == 'change') {
        changes++;
        if (pending != null) return pending!.future;
        glasses += call.arguments['delta'] as int;
      }
      return water();
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(DailyTracker.channel, null);
    messenger.setMockMethodCallHandler(WaterTracker.channel, null);
  });

  Future<void> mount(
    WidgetTester t,
    Widget child, {
    bool dark = false,
    double scale = 1,
    double width = 390,
  }) async {
    t.view.physicalSize = Size(width, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final fontDir = Platform.environment['DVIZH_FONT_DIR'];
    if (fontDir != null) {
      await t.runAsync(() async {
        final loader = FontLoader('OrbitPreview')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                await File('$fontDir/DejaVuSans.ttf').readAsBytes(),
              ),
            ),
          );
        await loader.load();
        for (final family in ['Roboto', 'Ahem']) {
          final fallback = FontLoader(family)
            ..addFont(
              Future.value(
                ByteData.sublistView(
                  await File('$fontDir/DejaVuSans.ttf').readAsBytes(),
                ),
              ),
            );
          await fallback.load();
        }
        final iconPath = Platform.environment['DVIZH_MATERIAL_ICONS'];
        if (iconPath != null) {
          final icons = FontLoader('MaterialIcons')
            ..addFont(
              Future.value(
                ByteData.sublistView(await File(iconPath).readAsBytes()),
              ),
            );
          await icons.load();
        }
      });
    }
    var theme = dark ? AppTheme.dark : AppTheme.light;
    if (fontDir != null) {
      const buttonText = TextStyle(fontFamily: 'OrbitPreview', fontSize: 17, fontWeight: FontWeight.w700);
      theme = theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'OrbitPreview'),
        filledButtonTheme: FilledButtonThemeData(style: theme.filledButtonTheme.style?.copyWith(
          textStyle: const WidgetStatePropertyAll(buttonText))),
      );
    }
    await t.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: const Key('capture'), child: child!),
        ),
        home: child,
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> capture(WidgetTester t, String name) async {
    final dir = Platform.environment['DVIZH_PREVIEW_DIR'];
    if (dir == null) return;
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('capture')),
    );
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(dir).create(recursive: true);
      await File('$dir/$name.png').writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'Orbit light and dark render real sensor distance and navigation',
    (t) async {
      for (final dark in [false, true]) {
        await mount(t, const HomeScreen(), dark: dark);
        expect(find.text('≈ 4,49 км'), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(t.takeException(), isNull);
        await capture(t, dark ? 'home-dark' : 'home-light');
        await t.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets('Orbit water layout supports normal and large text', (t) async {
    await mount(t, const WaterScreen());
    await capture(t, 'water-light');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await mount(t, const WaterScreen(), width: 320, scale: 2);
    await t.scrollUntilVisible(find.text('+1 стакан · 200 мл'), 180);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('home remains usable at 320px and 200 percent text', (t) async {
    await mount(t, const HomeScreen(), width: 320, scale: 2);
    expect(t.takeException(), isNull);
    await t.scrollUntilVisible(find.text('200 мл'), 180);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'quick water action locks while pending and undo updates totals',
    (t) async {
      await mount(t, const Scaffold(body: WaterSummary()));
      pending = Completer<Map<String, dynamic>>();
      await t.tap(find.text('200 мл'));
      await t.pump();
      expect(
        t
            .widget<FilledButton>(find.byKey(const Key('quickWaterAdd')))
            .onPressed,
        isNull,
      );
      expect(changes, 1);
      glasses = 7;
      pending!.complete(water());
      pending = null;
      await t.pumpAndSettle();
      expect(find.text('1400 / 2000 мл'), findsOneWidget);
      await t.tap(find.text('Убрать 200 мл за сегодня'));
      await t.pumpAndSettle();
      expect(find.text('1200 / 2000 мл'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('settings accept decimal comma and reject invalid calibration', (
    t,
  ) async {
    await mount(
      t,
      const Scaffold(
        body: SingleChildScrollView(child: ActivityPreferencesCard()),
      ),
    );
    final field = find.byType(TextFormField).first;
    await t.enterText(field, '0');
    await t.ensureVisible(find.text('Сохранить цели'));
    await t.tap(find.text('Сохранить цели'));
    await t.pumpAndSettle();
    expect(find.text('Введите от 20 до 150 см'), findsOneWidget);
    await t.enterText(field, '71,4');
    await t.ensureVisible(find.text('Сохранить цели'));
    await t.tap(find.text('Сохранить цели'));
    await t.pumpAndSettle();
    expect(find.text('Цели и длина шага сохранены'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
