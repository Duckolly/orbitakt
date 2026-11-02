import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/workout.dart';

class StorageService {
  static Database? _db;
  static Future<Database>? _opening;

  static Future<Database> get database async {
    final Database? current = _db;

    if (current != null) {
      return current;
    }

    final opening = _opening ??= _initDB();
    try {
      final created = await opening;
      _db = created;
      return created;
    } finally {
      _opening = null;
    }
  }

  static Future<Database> _initDB() async {
    final String path = join(await getDatabasesPath(), 'dvizh.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // R-7: AUTOINCREMENT, id назначает SQLite => нет коллизий по millis.
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
  }

  // R-7: вставляем БЕЗ id — ключ генерит SQLite.
  static Future<int> saveWorkout(Workout workout) async {
    final Database db = await database;

    final Map<String, Object?> row = <String, Object?>{
      'type': workout.type.name,
      'startedAt': workout.startedAt.toIso8601String(),
      'durationSeconds': workout.durationSeconds,
      'steps': workout.steps,
    };

    return db.insert('workouts', row);
  }

  static Future<List<Workout>> getAllWorkouts() async {
    final Database db = await database;

    final List<Map<String, Object?>> maps = await db.query(
      'workouts',
      orderBy: 'startedAt DESC',
    );

    return maps
        .map(
          (Map<String, Object?> map) =>
              Workout.fromMap(map.cast<String, dynamic>()),
        )
        .toList();
  }

  static Future<int> clearAll() async {
    final Database db = await database;
    return db.delete('workouts');
  }

  static Future<void> deleteAllData() async {
    final Database? current = _db;

    if (current != null) {
      await current.close();
      _db = null;
    }

    final String path = join(await getDatabasesPath(), 'dvizh.db');

    await deleteDatabase(path);
  }
}
