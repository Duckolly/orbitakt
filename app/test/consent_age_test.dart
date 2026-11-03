import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvizh/services/consent_preferences.dart';
import 'package:dvizh/screens/consent_screen.dart';
import 'package:dvizh/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy 14+ acceptance requires a new 16+ confirmation without deleting data',
    () async {
      SharedPreferences.setMockInitialValues({
        'privacyAccepted': true,
        'ageConfirmed': true,
        'offlineUnderstood': true,
        'snakeBest': 37,
        'recordingEnabled': true,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(ConsentPreferences.accepted(prefs), isFalse);
      expect(prefs.getInt('snakeBest'), 37);
      expect(await ConsentPreferences.confirm(prefs), isTrue);
      expect(ConsentPreferences.accepted(prefs), isTrue);
      expect(prefs.getBool(ConsentPreferences.ageKey), isTrue);
      expect(prefs.getInt('snakeBest'), 37);
      expect(prefs.getBool('recordingEnabled'), isTrue);
    },
  );

  testWidgets('16+ checkbox is mandatory and has no parental-consent bypass', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({'snakeBest': 37});
    await t.pumpWidget(const MaterialApp(home: ConsentScreen()));
    await t.pumpAndSettle();
    expect(find.text('Мне исполнилось 16 лет'), findsOneWidget);
    expect(
      find.textContaining('с согласия законного представителя'),
      findsNothing,
    );
    final boxes = find.byType(CheckboxListTile);
    for (final i in [0, 2]) {
      await t.ensureVisible(boxes.at(i));
      await t.tap(boxes.at(i));
      await t.pump();
    }
    final button = find.widgetWithText(FilledButton, 'Продолжить');
    expect(t.widget<FilledButton>(button).onPressed, isNull);
    await t.ensureVisible(boxes.at(1));
    await t.tap(boxes.at(1));
    await t.pump();
    expect(t.widget<FilledButton>(button).onPressed, isNotNull);
    await t.ensureVisible(button);
    await t.tap(button);
    await t.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ConsentPreferences.ageKey), isTrue);
    expect(prefs.getInt('snakeBest'), 37);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
}
