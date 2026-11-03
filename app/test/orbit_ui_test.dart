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
import 'package:dvizh/widgets/orbit/orbit_art.dart';

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
    double height = 844,
    bool systemInsets = false,
  }) async {
    t.view.physicalSize = Size(width, height);
    t.view.devicePixelRatio = 1;
    if (systemInsets) {
      t.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(t.view.resetPadding);
    }
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    // Use a real SDK font for layout assertions; Ahem has square glyphs and
    // cannot model Android text widths. The SDK layout is pinned by Flutter.
    final fontDir = Platform.environment['DVIZH_FONT_DIR'];
    final sdkAssets = File(Platform.resolvedExecutable).parent.parent.parent;
    final fontFile = fontDir == null
        ? File('${sdkAssets.path}/material_fonts/Roboto-Regular.ttf')
        : File('$fontDir/DejaVuSans.ttf');
    await t.runAsync(() async {
      final bytes = ByteData.sublistView(await fontFile.readAsBytes());
      for (final family in ['OrbitPreview', 'Roboto']) {
        final loader = FontLoader(family)..addFont(Future.value(bytes));
        await loader.load();
      }
      final iconPath = Platform.environment['DVIZH_MATERIAL_ICONS'];
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          iconPath == null
              ? rootBundle.load('fonts/MaterialIcons-Regular.otf')
              : File(iconPath).readAsBytes().then(ByteData.sublistView),
        );
      await icons.load();
    });
    const buttonText = TextStyle(
      fontFamily: 'OrbitPreview',
      fontSize: 17,
      fontWeight: FontWeight.w700,
    );
    final base = dark ? AppTheme.dark : AppTheme.light;
    final theme = base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'OrbitPreview'),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          textStyle: const WidgetStatePropertyAll(buttonText),
        ),
      ),
    );
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
      await t.tap(find.byTooltip('Убрать 200 мл за сегодня'));
      await t.pumpAndSettle();
      expect(find.text('1200 / 2000 мл'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'steps and complete water card fit before scrolling: $size dark=$dark',
        (t) async {
          await mount(
            t,
            const HomeScreen(),
            width: size.width,
            height: size.height,
            dark: dark,
            systemInsets: true,
          );
          expect(find.text('Орбитакт'), findsOneWidget);
          expect(find.byType(StepTrailProgress), findsOneWidget);
          final indicator = find.descendant(
            of: find.byType(StepTrailProgress),
            matching: find.byType(LinearProgressIndicator),
          );
          expect(
            t.widget<LinearProgressIndicator>(indicator).value,
            closeTo(6420 / 8000, 0.0001),
          );
          expect(
            t.widget<LinearProgressIndicator>(indicator).semanticsLabel,
            'Прогресс цели шагов',
          );
          final navTop = t.getTopLeft(find.byType(NavigationBar)).dy;
          final water = find.byType(WaterSummary);
          expect(t.getBottomRight(water).dy, lessThanOrEqualTo(navTop + 1));
          expect(
            find.byKey(const Key('homeDailySteps')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('quickWaterAdd')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('quickWaterUndo')).hitTestable(),
            findsOneWidget,
          );
          expect(t.takeException(), isNull);
          await capture(
            t,
            'compact-${size.width.toInt()}x${size.height.toInt()}-${dark ? 'dark' : 'light'}',
          );
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets('compact cards retain large-text scrolling and navigation', (
    t,
  ) async {
    await mount(
      t,
      const HomeScreen(),
      width: 320,
      height: 568,
      scale: 2,
      systemInsets: true,
    );
    await t.scrollUntilVisible(find.byKey(const Key('quickWaterAdd')), 180);
    await Scrollable.ensureVisible(
      t.element(find.byKey(const Key('quickWaterAdd'))),
      alignment: 0.5,
    );
    await t.pumpAndSettle();
    expect(
      find.byKey(const Key('quickWaterAdd')).hitTestable(),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('quickWaterAdd')));
    await t.pumpAndSettle();
    expect(find.text('1400 / 2000 мл'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
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
