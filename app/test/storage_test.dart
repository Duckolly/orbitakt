import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dvizh/models/activity.dart';
import 'package:dvizh/models/workout.dart';
import 'package:dvizh/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temporary = await Directory.systemTemp.createTemp('dvizh-db-test-');
    await databaseFactory.setDatabasesPath(temporary.path);
  });
  tearDown(() async {
    await StorageService.deleteAllData();
  });
  tearDownAll(() async {
    await temporary.delete(recursive: true);
  });

  test(
    'same source id never overwrites a different workout; clear empties DB',
    () async {
      final workout = Workout(
        id: 1,
        type: ActivityType.running,
        startedAt: DateTime(2026, 10, 31),
        durationSeconds: 100,
        steps: 80,
      );
      await StorageService.saveWorkout(workout);
      await StorageService.saveWorkout(workout);
      final rows = await StorageService.getAllWorkouts();
      expect(rows.length, 2);
      expect(rows[0].id, isNot(rows[1].id));
      await StorageService.clearAll();
      expect(await StorageService.getAllWorkouts(), isEmpty);
    },
  );

  test('concurrent initialization shares one database connection', () async {
    final databases = await Future.wait([
      StorageService.database,
      StorageService.database,
    ]);
    expect(identical(databases[0], databases[1]), true);
  });
}
