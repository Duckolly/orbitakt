import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/models/breathing.dart';
import 'package:dvizh/models/sleep_breathing.dart';
import 'package:dvizh/services/sleep_breathing_store.dart';
import 'package:dvizh/services/tool_routes.dart';
import 'package:dvizh/screens/breathing_screen.dart';

class FailingSleepStore extends SleepBreathingStore {
  bool fail = true;
  int attempts = 0;
  Completer<void>? pending;
  @override
  Future<void> save(SleepBreathing value) async {
    attempts++;
    if (pending != null) await pending!.future;
    if (fail) throw StateError('Disk full');
    return super.save(value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('fractional phases transition at exact milliseconds without holds', () {
    final p = const SleepBreathing(stage: 1).preset;
    expect(
      BreathingFrame(p, const Duration(milliseconds: 4499)).inhaling,
      isTrue,
    );
    final exhale = BreathingFrame(p, const Duration(milliseconds: 4500));
    expect(exhale.inhaling, isFalse);
    expect(exhale.expansion, 1);
    expect(
      BreathingFrame(p, const Duration(milliseconds: 8999)).inhaling,
      isFalse,
    );
    expect(
      BreathingFrame(p, const Duration(milliseconds: 9000)).inhaling,
      isTrue,
    );
    expect(BreathingFrame(p, const Duration(minutes: 5)).done, isTrue);
    expect(breathingSeconds(p.inhale), '4,5');
  });
  test(
    'pauses exclude elapsed time and configuration is frozen during a session',
    () {
      var now = Duration.zero;
      final s = BreathingSession(now: () => now);
      s.configure(const SleepBreathing(stage: 1).preset);
      s.start();
      now += const Duration(milliseconds: 4700);
      s.pause();
      expect(s.frame.inhaling, isFalse);
      now += const Duration(days: 3);
      expect(s.elapsed.inMilliseconds, 4700);
      s.configure(const SleepBreathing(stage: 2).preset);
      expect(s.preset.inhale, 4.5);
      s.start();
      now += const Duration(milliseconds: 4300);
      s.tick();
      expect(s.elapsed.inMilliseconds, 9000);
      expect(s.frame.inhaling, isTrue);
      now += const Duration(minutes: 5);
      expect(s.tick(), isTrue);
      expect(s.tick(), isFalse);
      expect(s.elapsed, const Duration(minutes: 5));
      expect(s.running, isFalse);
      s.reset();
      s.configure(const SleepBreathing(stage: 2).preset);
      expect(s.preset.inhale, 5);
    },
  );
  test('three ratings only unlock a choice; two increases stop at 5/5', () {
    var p = const SleepBreathing();
    expect(p.increase().stage, 0);
    for (var stage = 0; stage < 2; stage++) {
      for (var i = 0; i < 3; i++) {
        p = p.feedback(true);
      }
      expect(p.stage, stage);
      expect(p.canIncrease, isTrue);
      p = p.increase();
      expect(p.comfortable, 0);
    }
    for (var i = 0; i < 20; i++) {
      p = p.feedback(true).increase();
    }
    expect(p.stage, 2);
    expect(p.canIncrease, isFalse);
    expect(p.preset.inhale, 5);
    expect(p.preset.exhale, 5);
  });
  test('discomfort, keep and easing cannot unlock a higher step', () {
    const p = SleepBreathing(stage: 1, comfortable: 3);
    expect(p.feedback(false).canIncrease, isFalse);
    expect(p.keep().comfortable, 0);
    expect(p.keep().stage, 1);
    expect(p.easier().stage, 0);
    expect(p.easier().comfortable, 0);
    expect(const SleepBreathing().easier().rhythm, SleepRhythm.shorter);
    for (final rhythm in [
      SleepRhythm.shorter,
      SleepRhythm.longerExhale,
      SleepRhythm.free,
    ]) {
      expect(
        SleepBreathing(
          rhythm: rhythm,
          comfortable: 3,
        ).feedback(true).canIncrease,
        isFalse,
      );
    }
  });
  test('free breathing has a timer and no phase pacing', () {
    final p = const SleepBreathing(rhythm: SleepRhythm.free).preset;
    expect(p.paced, isFalse);
    final f = BreathingFrame(p, const Duration(minutes: 1));
    expect(f.phaseSeconds, 0);
    expect(f.remainingSeconds, 240);
    expect(f.expansion, 0.5);
  });
  test(
    'profile survives store recreation without changing unrelated history',
    () async {
      SharedPreferences.setMockInitialValues({
        'age16Confirmed': true,
        'snakeBest': 37,
        'recordingEnabled': true,
        'waterLegacy': 'preserved',
      });
      const p = SleepBreathing(
        stage: 1,
        comfortable: 2,
        minutes: 15,
        sound: true,
      );
      await SleepBreathingStore().save(p);
      final q = await SleepBreathingStore().load();
      expect(q.toJson(), p.toJson());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('snakeBest'), 37);
      expect(prefs.getBool('age16Confirmed'), isTrue);
      expect(prefs.getBool('recordingEnabled'), isTrue);
      expect(prefs.getString('waterLegacy'), 'preserved');
    },
  );
  test('malformed profiles recover and bound persisted values', () async {
    for (final value in ['broken json', '[]', 77]) {
      SharedPreferences.setMockInitialValues({SleepBreathingStore.key: value});
      expect((await SleepBreathingStore().load()).stage, 0);
    }
    final p = SleepBreathing.fromJson({
      'stage': 99,
      'comfortable': -5,
      'rhythm': 'unknown',
      'minutes': 0,
    });
    expect(p.stage, 2);
    expect(p.comfortable, 0);
    expect(p.minutes, 5);
    expect(p.rhythm, SleepRhythm.adaptive);
  });

  var now = Duration.zero;
  late BreathingSession session;
  Future<void> mount(
    WidgetTester t, {
    SleepBreathingStore? store,
    double scale = 1,
  }) async {
    now = Duration.zero;
    session = BreathingSession(now: () => now);
    await t.pumpWidget(
      MaterialApp(
        navigatorObservers: [toolRouteObserver],
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const ValueKey('sleepPreview'),
          child: BreathingScreen(session: session, store: store),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder finder) async {
    await t.drag(
      find.byKey(const ValueKey('breathingList')),
      const Offset(0, 3000),
    );
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  Future<void> finish(WidgetTester t) async {
    await tap(t, find.byKey(const ValueKey('breathingStart')));
    now += Duration(minutes: session.preset.minutes);
    await t.pump(const Duration(milliseconds: 50));
    expect(session.complete, isTrue);
  }

  testWidgets(
    'three completed sessions require explicit increase and persist new rhythm',
    (t) async {
      await mount(t);
      for (var i = 0; i < 3; i++) {
        await finish(t);
        await tap(t, find.text('Комфортно'));
        expect((await SleepBreathingStore().load()).comfortable, i + 1);
        expect(find.text('Комфортно'), findsNothing);
        await tap(t, find.text('Новый сеанс'));
      }
      expect(session.preset.inhale, 4);
      await tap(t, find.text('Увеличить'));
      expect(session.preset.inhale, 4.5);
      await t.pumpWidget(const SizedBox());
      await mount(t);
      expect(session.preset.inhale, 4.5);
      expect((await SleepBreathingStore().load()).comfortable, 0);
    },
  );
  testWidgets(
    'aborting and skipping do not count a completed comfortable session',
    (t) async {
      await mount(t);
      await tap(t, find.byKey(const ValueKey('breathingStart')));
      now += const Duration(minutes: 1);
      await t.pump(const Duration(milliseconds: 50));
      await tap(t, find.text('Завершить'));
      expect((await SleepBreathingStore().load()).comfortable, 0);
      await finish(t);
      await tap(t, find.text('Пропустить'));
      expect((await SleepBreathingStore().load()).comfortable, 0);
    },
  );
  testWidgets(
    'failed feedback write can retry once and blocks duplicate taps while saving',
    (t) async {
      final store = FailingSleepStore();
      await mount(t, store: store);
      await finish(t);
      await tap(t, find.text('Комфортно'));
      expect((await store.load()).comfortable, 0);
      store.fail = false;
      store.pending = Completer<void>();
      await t.tap(find.text('Комфортно'));
      await t.pump();
      await t.tap(find.text('Комфортно'));
      await t.pump();
      expect(store.attempts, 2);
      store.pending!.complete();
      await t.pumpAndSettle();
      expect((await store.load()).comfortable, 1);
      expect(find.text('Комфортно'), findsNothing);
    },
  );
  testWidgets('background freezes partial phase and requires explicit resume', (
    t,
  ) async {
    await mount(t);
    await tap(t, find.byKey(const ValueKey('breathingStart')));
    now += const Duration(milliseconds: 4500);
    await t.pump(const Duration(milliseconds: 50));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    final frozen = session.elapsed;
    now += const Duration(hours: 8);
    await t.pump();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(session.elapsed, frozen);
    expect(session.running, isFalse);
    await tap(t, find.text('Продолжить'));
    expect(session.elapsed, frozen);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('discomfort resets streak without increasing and offers easing', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({
      SleepBreathingStore.key: jsonEncode(
        const SleepBreathing(stage: 1, comfortable: 2).toJson(),
      ),
    });
    await mount(t);
    await finish(t);
    await tap(t, find.text('Был дискомфорт'));
    expect((await SleepBreathingStore().load()).stage, 1);
    expect((await SleepBreathingStore().load()).comfortable, 0);
    await tap(t, find.text('Сделать проще'));
    await tap(t, find.text('Новый сеанс'));
    expect(session.preset.inhale, 4);
  });
  testWidgets(
    'alternate rhythms and duration are saved without automatic progression',
    (t) async {
      await mount(t);
      await tap(t, find.byKey(const ValueKey('sleepRhythm')));
      await t.tap(find.text('Выдох чуть длиннее · 4,5/5,5 с').last);
      await t.pumpAndSettle();
      await tap(t, find.byKey(const ValueKey('sleepMinutes10')));
      expect(session.preset.inhale, 4.5);
      expect(session.preset.exhale, 5.5);
      expect(session.preset.minutes, 10);
      await tap(t, find.byKey(const ValueKey('sleepRhythm')));
      await t.tap(find.text('Свободно · без заданного ритма').last);
      await t.pumpAndSettle();
      await tap(t, find.byKey(const ValueKey('breathingStart')));
      expect(session.preset.paced, isFalse);
      await t.drag(
        find.byKey(const ValueKey('breathingList')),
        const Offset(0, 3000),
      );
      await t.pumpAndSettle();
      expect(find.text('Дыши свободно'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'optional cues occur on phase changes only, never during pause or completion',
    (t) async {
      SharedPreferences.setMockInitialValues({
        SleepBreathingStore.key: jsonEncode(
          const SleepBreathing(sound: true, vibration: true).toJson(),
        ),
      });
      final calls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemSound.play' ||
            call.method == 'HapticFeedback.vibrate') {
          calls.add(call.method);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await mount(t);
      expect(calls, isEmpty);
      await tap(t, find.byKey(const ValueKey('breathingStart')));
      expect(calls.length, 2);
      now += const Duration(milliseconds: 4100);
      await t.pump(const Duration(milliseconds: 100));
      await t.pump();
      expect(calls.length, 4);
      await t.pump(const Duration(milliseconds: 200));
      expect(calls.length, 4);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      now += const Duration(hours: 8);
      await t.pump(const Duration(seconds: 1));
      expect(calls.length, 4);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tap(t, find.text('Продолжить'));
      expect(calls.length, 4);
      now += const Duration(minutes: 5);
      await t.pump(const Duration(milliseconds: 50));
      expect(session.complete, isTrue);
      expect(calls.length, 4);
      await t.pumpWidget(const SizedBox());
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'small display at text scale $scale keeps controls accessible',
      (t) async {
        t.view.physicalSize = const Size(320, 568);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await mount(t, scale: scale);
        await tap(t, find.byKey(const ValueKey('breathingStart')));
        expect(session.running, isTrue);
        await tap(t, find.text('Завершить'));
        await tap(t, find.byKey(const ValueKey('sleepMinutes15')));
        expect(session.preset.minutes, 15);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('render the real night screen for release preview', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final sdkAssets = File(Platform.resolvedExecutable).parent.parent.parent;
    await t.runAsync(() async {
      final bytes = ByteData.sublistView(
        await File(
          '${sdkAssets.path}/material_fonts/Roboto-Regular.ttf',
        ).readAsBytes(),
      );
      for (final family in ['Roboto', 'Ahem']) {
        final loader = FontLoader(family)..addFont(Future.value(bytes));
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    await mount(t);
    expect(t.takeException(), isNull);
    final path = Platform.environment['SLEEP_PREVIEW_PATH'];
    if (path != null) {
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('sleepPreview')),
      );
      await t.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(path).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    await t.pumpWidget(const SizedBox());
  });
}
