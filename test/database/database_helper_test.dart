import 'package:flutter_test/flutter_test.dart';
import 'package:health_mate/database/database_helper.dart';
import 'package:health_mate/models/goal_settings.dart';
import 'package:health_mate/models/health_record.dart';
import 'package:health_mate/repositories/health_repository.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_health_repository.dart';

// Runs the real DatabaseHelper against SQLite on the desktop through
// sqflite_common_ffi, using a fresh database file for every test.
void main() {
  final helper = DatabaseHelper.instance;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await helper.close();
    await databaseFactory.deleteDatabase(
      join(await databaseFactory.getDatabasesPath(), 'healthmate.db'),
    );
  });

  tearDownAll(() => helper.close());

  test('creates health_records with the required columns', () async {
    final db = await helper.database;
    final columns = await db.rawQuery('PRAGMA table_info(health_records)');

    final types = {for (final c in columns) c['name']: c['type']};
    expect(types, {
      'id': 'INTEGER',
      'date': 'TEXT',
      'steps': 'INTEGER',
      'calories': 'INTEGER',
      'water': 'INTEGER',
    });
    final pk = columns.firstWhere((c) => c['pk'] == 1);
    expect(pk['name'], 'id');
  });

  test('seeds four dummy records and default goals on first launch', () async {
    final records = await helper.getAllRecords();
    expect(records, hasLength(4));
    expect(records.first.date, daysAgo(0));
    expect(records.first.steps, 7850);

    final goals = await helper.getDailyGoals();
    expect(goals, {
      'steps_goal': 8000,
      'calories_goal': 500,
      'water_goal': 2500,
    });
  });

  test('insertRecord stores a record and returns its new id', () async {
    final id = await helper.insertRecord(
      HealthRecord(date: daysAgo(10), steps: 1234, calories: 56, waterMl: 789),
    );
    expect(id, 5);

    final saved = await helper.getRecordsByDate(daysAgo(10));
    expect(saved.single.id, id);
    expect(saved.single.steps, 1234);
    expect(saved.single.waterMl, 789);
  });

  test('getAllRecords returns newest dates first', () async {
    await helper.insertRecord(
      HealthRecord(date: daysAgo(30), steps: 1, calories: 1, waterMl: 1),
    );
    final dates = (await helper.getAllRecords()).map((r) => r.date).toList();
    final sorted = [...dates]..sort((a, b) => b.compareTo(a));
    expect(dates, sorted);
    expect(dates.last, daysAgo(30));
  });

  test('getRecordsByDate returns only that date', () async {
    final records = await helper.getRecordsByDate(daysAgo(1));
    expect(records, hasLength(1));
    expect(records.single.steps, 9120);
    expect(await helper.getRecordsByDate('2020-01-01'), isEmpty);
  });

  test('updateRecord changes one row and ignores records without id', () async {
    final first = (await helper.getAllRecords()).first;
    final changed = await helper.updateRecord(
      first.copyWith(steps: 10000, waterMl: 3000),
    );
    expect(changed, 1);

    final reloaded = (await helper.getRecordsByDate(first.date)).single;
    expect(reloaded.steps, 10000);
    expect(reloaded.waterMl, 3000);
    expect(reloaded.calories, first.calories);

    expect(
      await helper.updateRecord(
        const HealthRecord(
          date: '2026-01-01',
          steps: 1,
          calories: 1,
          waterMl: 1,
        ),
      ),
      0,
    );
  });

  test('deleteRecord removes exactly one row', () async {
    final first = (await helper.getAllRecords()).first;
    expect(await helper.deleteRecord(first.id!), 1);
    expect(await helper.getAllRecords(), hasLength(3));
    expect(await helper.deleteRecord(first.id!), 0);
  });

  test('saveDailyGoals replaces the single goals row', () async {
    await helper.saveDailyGoals(
      stepsGoal: 12000,
      caloriesGoal: 700,
      waterGoalMl: 3000,
    );
    final db = await helper.database;
    expect(await db.query(DatabaseHelper.tableDailyGoals), hasLength(1));
    expect((await helper.getDailyGoals())!['steps_goal'], 12000);
  });

  test('data survives closing and reopening the database', () async {
    await helper.insertRecord(
      HealthRecord(date: daysAgo(5), steps: 4321, calories: 1, waterMl: 1),
    );
    await helper.close();
    final records = await helper.getRecordsByDate(daysAgo(5));
    expect(records.single.steps, 4321);
  });

  test('HealthRepository converts stored goals into GoalSettings', () async {
    final repository = HealthRepository(dbHelper: helper);
    await repository.saveDailyGoals(
      const GoalSettings(stepsGoal: 9000, caloriesGoal: 450, waterGoalMl: 2200),
    );
    final goals = await repository.getDailyGoals();
    expect(goals.stepsGoal, 9000);
    expect(goals.caloriesGoal, 450);
    expect(goals.waterGoalMl, 2200);
  });
}
