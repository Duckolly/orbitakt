import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/screens/about_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];
  var opens = true;
  var metadata = true;
  Completer<bool>? pending;
  String? copied;
  setUp(() {
    calls.clear();
    opens = true;
    metadata = true;
    pending = null;
    copied = null;
    messenger.setMockMethodCallHandler(AboutScreen.channel, (call) async {
      calls.add(call.method);
      if (call.method == 'info') {
        if (!metadata) throw PlatformException(code: 'unavailable');
        return {'version': '3.8.1', 'build': 11};
      }
      return pending == null ? opens : await pending!.future;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(AboutScreen.channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });
  Future<void> open(WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(home: AboutScreen()));
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String text) async {
    await t.ensureVisible(find.text(text));
    await t.pumpAndSettle();
    await t.tap(find.text(text));
    await t.pumpAndSettle();
  }

  testWidgets(
    'load real version and fixed public contact without auto opening',
    (t) async {
      await open(t);
      expect(find.text('Версия: 3.8.1 (сборка 11)'), findsOneWidget);
      expect(find.text('Автор: Сергей Швецов'), findsOneWidget);
      expect(find.text(AboutScreen.telegramUrl), findsOneWidget);
      expect(calls, ['info']);
      await tap(t, 'Скопировать адрес');
      expect(copied, 'https://t.me/dvizhoffline');
      expect(calls, ['info']);
      await tap(t, 'Открыть Telegram');
      expect(calls, ['info', 'openTelegram']);
    },
  );
  testWidgets('unavailable handler and metadata leave copy contact usable', (
    t,
  ) async {
    metadata = false;
    opens = false;
    await open(t);
    expect(find.text('Версия: Недоступна'), findsOneWidget);
    await tap(t, 'Открыть Telegram');
    expect(find.textContaining('Не удалось открыть ссылку'), findsOneWidget);
    await tap(t, 'Скопировать адрес');
    expect(copied, AboutScreen.telegramUrl);
  });
  testWidgets(
    'opening busy lock prevents duplicate intents and tolerates disposal',
    (t) async {
      await open(t);
      pending = Completer<bool>();
      await t.ensureVisible(find.text('Открыть Telegram'));
      await t.pumpAndSettle();
      await t.tap(find.text('Открыть Telegram'));
      await t.pump();
      await t.tap(find.text('Открыть Telegram'));
      await t.pump();
      expect(calls.where((c) => c == 'openTelegram').length, 1);
      await t.pumpWidget(const SizedBox());
      pending!.complete(false);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('small display and large font remain scrollable', (t) async {
    t.view.physicalSize = const Size(320, 480);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(
            c,
          ).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: const AboutScreen(),
      ),
    );
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Скопировать адрес'), 250);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
