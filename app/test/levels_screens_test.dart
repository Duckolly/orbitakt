import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dvizh/screens/daily_screen.dart';
import 'package:dvizh/screens/water_screen.dart';
import 'package:dvizh/screens/toilet_screen.dart';
import 'package:dvizh/services/storage_service.dart';
import 'package:dvizh/services/daily_tracker.dart';
import 'package:dvizh/services/water_tracker.dart';
import 'package:dvizh/services/progress_reports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  var glasses = 8;
  final now = DateTime.now();
  String date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  setUpAll(() async {
    if (Platform.environment['ORBITAKT_PREVIEW_DIR'] != null) {
      final font = FontLoader('PreviewSans');
      font.addFont(
        File(
          '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temporary = await Directory.systemTemp.createTemp('orbitakt-levels-');
    await databaseFactory.setDatabasesPath(temporary.path);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.database;
    glasses = 8;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      DailyTracker.channel,
      (call) async => {
        'supported': true,
        'enabled': true,
        'running': true,
        'permissionGranted': true,
        'notificationsAllowed': true,
        'todaySteps': 9200,
        'totalRecorded': 9200,
        'history': <Object>[],
      },
    );
    messenger.setMockMethodCallHandler(WaterTracker.channel, (call) async {
      if (call.method == 'change') {
        glasses += (call.arguments as Map)['delta'] as int;
      }
      return {'today': date(now), 'glasses': glasses, 'history': <Object>[]};
    });
    messenger.setMockMethodCallHandler(
      ProgressReports.channel,
      (call) async => {
        'steps': [
          for (var day = 1; day <= now.day; day++)
            {'day': date(DateTime(now.year, now.month, day)), 'steps': 9200},
        ],
        'water': [
          for (var day = 1; day <= now.day; day++)
            {
              'day': date(DateTime(now.year, now.month, day)),
              'glasses': glasses,
            },
        ],
      },
    );
  });
  tearDown(() async => StorageService.deleteAllData());
  tearDownAll(() async => temporary.delete(recursive: true));

  Future<void> frame(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 160)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'all three full screens render with larger type; water actions remain usable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      for (final brightness in Brightness.values) {
        final screens = <String, Widget>{
          'steps': const DailyScreen(),
          'water': const WaterScreen(),
          'toilet': const ToiletScreen(),
        };
        for (final entry in screens.entries) {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: brightness,
                useMaterial3: true,
                fontFamily: Platform.environment['ORBITAKT_PREVIEW_DIR'] != null
                    ? 'PreviewSans'
                    : null,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: RepaintBoundary(key: boundary, child: entry.value),
            ),
          );
          for (var i = 0; i < 8; i++) {
            await frame(tester);
          }
          expect(tester.takeException(), isNull);
          if (entry.key == 'water') {
            await tester.scrollUntilVisible(
              find.text('+1 стакан · 200 мл'),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.tap(find.text('+1 стакан · 200 мл'));
            await frame(tester);
            expect(glasses, 9);
            await tester.scrollUntilVisible(
              find.text('Убрать стакан за сегодня'),
              150,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.tap(find.text('Убрать стакан за сегодня'));
            await frame(tester);
            expect(glasses, 8);
          }
          final title = find.text(
            'УРОВЕНЬ · ${now.month.toString().padLeft(2, '0')}.${now.year}',
          );
          await tester.scrollUntilVisible(
            title,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await frame(tester);
          expect(title, findsOneWidget);
          expect(tester.takeException(), isNull);
          // Reviewable screenshots are optional output of this regression, not goldens.
          if (Platform.environment['ORBITAKT_PREVIEW_DIR']
              case final String path) {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await render.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(path).create(recursive: true);
              await File(
                '$path/${entry.key}-${brightness.name}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
        }
      }
    },
  );
}
