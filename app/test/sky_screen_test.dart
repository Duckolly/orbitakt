import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/screens/sky_screen.dart';
import 'package:dvizh/services/tool_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];
  setUp(() {
    for (final name in ['stars', 'figures', 'cities']) {
      rootBundle.evict('assets/sky/$name.json');
    }
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    messenger.setMockMethodCallHandler(
      const MethodChannel('dvizh/sky'),
      (c) async => {'supported': false},
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dvizh/sky/events'),
      (c) async {
        calls.add(c.method);
        return null;
      },
    );
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(const MethodChannel('dvizh/sky'), null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('dvizh/sky/events'),
      null,
    );
  });
  Future<void> load(WidgetTester t) async {
    for (var i = 0; i < 30; i++) {
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await t.pump();
      if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
    }
    await t.pumpAndSettle();
  }

  Widget app() => MaterialApp(
    debugShowCheckedModeBanner: false,
    navigatorObservers: [toolRouteObserver],
    home: const SkyScreen(),
  );
  Future<void> choose(WidgetTester t) async {
    await t.tap(find.text('Выбрать город'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Самара');
    await t.pump();
    await t.tap(find.widgetWithText(ListTile, 'Самара'));
    await load(t);
  }

  testWidgets('city selection is local, persistent and starts no sensors', (
    t,
  ) async {
    await t.pumpWidget(app());
    await load(t);
    expect(find.text('Выбрать город'), findsOneWidget);
    await choose(t);
    expect(find.text('Самара'), findsOneWidget);
    expect(calls, isEmpty);
    expect(
      (await SharedPreferences.getInstance()).getString('skyCity'),
      contains('Самара'),
    );
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(app());
    await load(t);
    expect(find.text('Самара'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets('manual coordinates validate range and decimal comma', (t) async {
    await t.pumpWidget(app());
    await load(t);
    await t.tap(find.text('Ввести координаты вручную'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).at(0), '91');
    await t.enterText(find.byType(TextField).at(1), '50');
    await t.tap(find.text('Применить'));
    await t.pump();
    expect(find.textContaining('Широта: от'), findsOneWidget);
    await t.enterText(find.byType(TextField).at(0), '53,2');
    await t.enterText(find.byType(TextField).at(1), '50,15');
    await t.tap(find.text('Применить'));
    await load(t);
    expect(find.text('Свои координаты'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets('chart and city picker work at 320px with doubled text', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 480);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        navigatorObservers: [toolRouteObserver],
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(
            c,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const SkyScreen(),
      ),
    );
    await load(t);
    await choose(t);
    await t.scrollUntilVisible(find.textContaining('Верх карты'), 100);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets('render real chart preview', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.runAsync(() async {
      final fontFile = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
      if (await fontFile.exists()) {
        final loader = FontLoader('Roboto');
        loader.addFont(
          Future.value(ByteData.sublistView(await fontFile.readAsBytes())),
        );
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    const key = Key('preview');
    await t.pumpWidget(RepaintBoundary(key: key, child: app()));
    await load(t);
    await choose(t);
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '/tmp/dvizh-sky-preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
}
