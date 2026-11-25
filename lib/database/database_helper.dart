import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/health_record.dart';
import '../utils/formatters.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  static const String _dbName = 'healthmate.db';
  static const int _dbVersion = 1;
  static const String tableHealthRecords = 'health_records';
  static const String tableDailyGoals = 'daily_goals';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    print('DATABASE LOCATION: $path'); // check db path

    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        water INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableDailyGoals (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        steps_goal INTEGER NOT NULL,
        calories_goal INTEGER NOT NULL,
        water_goal INTEGER NOT NULL
      )
    ''');

    await _seedDummyRecords(db);
  }

  Future<void> _seedDummyRecords(Database db) async {
    final now = DateTime.now();
    const formatDate = AppFormatters.storageDate;

    final dummyRecords = [
      HealthRecord(
        date: formatDate(now),
        steps: 7850,
        calories: 420,
        waterMl: 2000,
      ),
      HealthRecord(
        date: formatDate(now.subtract(const Duration(days: 1))),
        steps: 9120,
        calories: 510,
        waterMl: 2250,
      ),
      HealthRecord(
        date: formatDate(now.subtract(const Duration(days: 2))),
        steps: 6400,
        calories: 360,
        waterMl: 1750,
      ),
      HealthRecord(
        date: formatDate(now.subtract(const Duration(days: 3))),
        steps: 8300,
        calories: 465,
        waterMl: 2500,
      ),
    ];

    for (final record in dummyRecords) {
      await db.insert(tableHealthRecords, record.toMap());
    }

    await db.insert(tableDailyGoals, {
      'id': 1,
      'steps_goal': 8000,
      'calories_goal': 500,
      'water_goal': 2500,
    });
  }

  // Create
  Future<int> insertRecord(HealthRecord record) async {
    final db = await database;
    return db.insert(
      tableHealthRecords,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read All
  Future<List<HealthRecord>> getAllRecords() async {
    final db = await database;
    final rows = await db.query(
      tableHealthRecords,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map((row) => HealthRecord.fromMap(row)).toList();
  }

  // Read by date
  Future<List<HealthRecord>> getRecordsByDate(String date) async {
    final db = await database;
    final rows = await db.query(
      tableHealthRecords,
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
    return rows.map((row) => HealthRecord.fromMap(row)).toList();
  }

  // Update
  Future<int> updateRecord(HealthRecord record) async {
    if (record.id == null) return 0;
    final db = await database;
    return await db.update(
      tableHealthRecords,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // Delete
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      tableHealthRecords,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>?> getDailyGoals() async {
    final db = await database;
    final rows = await db.query(
      tableDailyGoals,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'steps_goal': (row['steps_goal'] as int?) ?? 8000,
      'calories_goal': (row['calories_goal'] as int?) ?? 500,
      'water_goal': (row['water_goal'] as int?) ?? 2500,
    };
  }

  Future<void> saveDailyGoals({
    required int stepsGoal,
    required int caloriesGoal,
    required int waterGoalMl,
  }) async {
    final db = await database;
    await db.insert(tableDailyGoals, {
      'id': 1,
      'steps_goal': stepsGoal,
      'calories_goal': caloriesGoal,
      'water_goal': waterGoalMl,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
