import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dvizh/models/holiday_preset.dart';
import 'package:dvizh/models/toilet_visit.dart';
import 'package:dvizh/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temporary = await Directory.systemTemp.createTemp('orbitakt-phase1-');
    await databaseFactory.setDatabasesPath(temporary.path);
  });

  tearDown(() async {
    await StorageService.deleteAllData();
  });

  tearDownAll(() async {
    await temporary.delete(recursive: true);
  });

  test('migration preserves version 1 workout rows', () async {
    final path = '${temporary.path}/dvizh.db';
    final legacy = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workouts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            startedAt TEXT NOT NULL,
            durationSeconds INTEGER NOT NULL,
            steps INTEGER NOT NULL
          )
        ''');
      },
    );
    final original = <String, Object?>{
      'id': 7,
      'type': 'running',
      'startedAt': '2026-11-01T12:00:00.000',
      'durationSeconds': 100,
      'steps': 80,
    };
    await legacy.insert('workouts', original);
    await legacy.close();

    final db = await StorageService.database;
    expect(await db.getVersion(), 2);
    expect(await db.query('workouts'), [original]);
    expect(await StorageService.getAllToiletVisits(), isEmpty);
    await StorageService.saveToiletVisit(ToiletVisit.at(DateTime(2026, 11, 4)));
    expect((await StorageService.getAllToiletVisits()).length, 1);
  });

  test(
    'new database assigns unique visit ids and retains local dates',
    () async {
      final visit = ToiletVisit(
        id: 99,
        timestamp: DateTime.utc(2026, 11, 3, 23, 30),
        date: '2026-11-04',
      );
      final first = await StorageService.saveToiletVisit(visit);
      final second = await StorageService.saveToiletVisit(visit);
      expect(first, isNot(second));
      final rows = await StorageService.getAllToiletVisits();
      expect(rows.map((v) => v.id), [second, first]);
      expect(rows.every((v) => v.date == '2026-11-04'), isTrue);
      expect(rows.first.timestamp.isAtSameMomentAs(visit.timestamp), isTrue);
      // Existing workout-only clear semantics are preserved.
      await StorageService.clearAll();
      expect((await StorageService.getAllToiletVisits()).length, 2);
      await StorageService.deleteAllData();
      expect(await StorageService.getAllToiletVisits(), isEmpty);
    },
  );

  test('visit captures local calendar day and presets match specification', () {
    final visit = ToiletVisit.at(DateTime(2026, 1, 1, 0, 5));
    expect(visit.date, '2026-01-01');
    expect(visit.toMap().containsKey('id'), isFalse);
    expect(HolidayPreset.presets.map((p) => '${p.month}-${p.day}'), [
      '2-13',
      '3-8',
      '1-1',
    ]);
  });
}
