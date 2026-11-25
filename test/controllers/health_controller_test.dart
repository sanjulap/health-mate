import 'package:flutter_test/flutter_test.dart';
import 'package:health_mate/controllers/health_controller.dart';
import 'package:health_mate/models/goal_settings.dart';
import 'package:health_mate/models/health_record.dart';

import '../helpers/fake_health_repository.dart';

HealthRecord rec(String date, {int steps = 0, int cal = 0, int water = 0}) =>
    HealthRecord(date: date, steps: steps, calories: cal, waterMl: water);

void main() {
  group('validateRecordInput', () {
    final controller = HealthController(repository: FakeHealthRepository());
    final today = DateTime(2026, 11, 25);

    String? validate({
      String date = '2026-11-25',
      String steps = '7850',
      String calories = '420',
      String water = '2000',
    }) => controller.validateRecordInput(
      date: date,
      stepsText: steps,
      caloriesText: calories,
      waterText: water,
      today: today,
    );

    test('accepts valid values for today and past days', () {
      expect(validate(), isNull);
      expect(validate(date: '2026-11-01'), isNull);
    });

    test('rejects an empty date', () {
      expect(validate(date: ''), 'Please select a date.');
    });

    test('rejects dates that are not real YYYY-MM-DD dates', () {
      expect(
        validate(date: '2026-13-01'),
        'Date must be in YYYY-MM-DD format.',
      );
      expect(validate(date: '2026-2-1'), 'Date must be in YYYY-MM-DD format.');
      expect(validate(date: 'yesterday'), 'Date must be in YYYY-MM-DD format.');
    });

    test('rejects a future date', () {
      expect(
        validate(date: '2026-11-26'),
        'You cannot add a record for a future date.',
      );
    });

    test('rejects empty or non-numeric metric values', () {
      expect(validate(steps: ''), 'Steps must be a valid non-negative number.');
      expect(
        validate(calories: 'abc'),
        'Calories must be a valid non-negative number.',
      );
      expect(
        validate(water: '-5'),
        'Water intake (ml) must be a valid non-negative number.',
      );
    });

    test('enforces upper limits but accepts values exactly at the limit', () {
      expect(validate(steps: '100000'), isNull);
      expect(validate(steps: '100001'), contains('Steps cannot be more'));
      expect(validate(calories: '10001'), contains('Calories cannot be more'));
      expect(validate(water: '10001'), contains('Water intake cannot be more'));
    });

    test('rejects a record where every metric is zero', () {
      expect(
        validate(steps: '0', calories: '0', water: '0'),
        'Enter at least one non-zero health metric.',
      );
    });
  });

  group('CRUD through the controller', () {
    late FakeHealthRepository repo;
    late HealthController controller;

    setUp(() async {
      repo = FakeHealthRepository(
        records: [
          rec(daysAgo(1), steps: 9120, cal: 510, water: 2250),
          rec(daysAgo(0), steps: 7850, cal: 420, water: 2000),
        ],
      );
      controller = HealthController(repository: repo);
      await controller.loadRecords();
    });

    test('loadRecords loads records newest date first', () {
      expect(controller.allRecords.map((r) => r.date), [
        daysAgo(0),
        daysAgo(1),
      ]);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('addRecord saves the record and refreshes the list', () async {
      final ok = await controller.addRecord(
        date: daysAgo(2),
        steps: 5000,
        calories: 300,
        waterMl: 1500,
      );
      expect(ok, isTrue);
      expect(repo.stored, hasLength(3));
      expect(controller.allRecords.last.steps, 5000);
    });

    test('updateRecord changes the stored values', () async {
      final original = controller.allRecords.first;
      final ok = await controller.updateRecord(original.copyWith(steps: 12000));
      expect(ok, isTrue);
      expect(
        controller.allRecords.firstWhere((r) => r.id == original.id).steps,
        12000,
      );
    });

    test('updateRecord refuses a record without an id', () async {
      final ok = await controller.updateRecord(rec(daysAgo(0), steps: 1));
      expect(ok, isFalse);
      expect(controller.errorMessage, 'Cannot update a record without an ID.');
    });

    test('deleteRecord removes the record', () async {
      final id = controller.allRecords.first.id!;
      final ok = await controller.deleteRecord(id);
      expect(ok, isTrue);
      expect(controller.allRecords.any((r) => r.id == id), isFalse);
      expect(repo.stored, hasLength(1));
    });

    test('a failed write returns false and sets an error message', () async {
      repo.failWrites = true;
      final ok = await controller.addRecord(
        date: daysAgo(0),
        steps: 1,
        calories: 1,
        waterMl: 1,
      );
      expect(ok, isFalse);
      expect(controller.errorMessage, startsWith('Failed to save record'));
      expect(controller.isLoading, isFalse);
    });

    test('a failed load keeps the app running and reports the error', () async {
      repo.failReads = true;
      await controller.loadRecords();
      expect(
        controller.errorMessage,
        startsWith('Failed to load health records'),
      );
      expect(controller.isLoading, isFalse);
    });
  });

  group('date filter', () {
    late HealthController controller;

    setUp(() async {
      controller = HealthController(
        repository: FakeHealthRepository(
          records: [
            rec(daysAgo(0), steps: 100),
            rec(daysAgo(1), steps: 200),
            rec(daysAgo(1), steps: 300),
          ],
        ),
      );
      await controller.loadRecords();
    });

    test('shows only records for the selected date', () {
      controller.filterByDate(daysAgo(1));
      expect(controller.visibleRecords, hasLength(2));
      expect(
        controller.visibleRecords.every((r) => r.date == daysAgo(1)),
        isTrue,
      );
    });

    test('returns an empty list when no records match', () {
      controller.filterByDate('2020-01-01');
      expect(controller.visibleRecords, isEmpty);
    });

    test('clearDateFilter shows all records again', () {
      controller.filterByDate(daysAgo(1));
      controller.clearDateFilter();
      expect(controller.selectedDateFilter, isNull);
      expect(controller.visibleRecords, hasLength(3));
    });
  });

  group('dashboard summary', () {
    test('today totals add up every record for today only', () async {
      final controller = HealthController(
        repository: FakeHealthRepository(
          records: [
            rec(daysAgo(0), steps: 5000, cal: 300, water: 1500),
            rec(daysAgo(0), steps: 2850, cal: 120, water: 500),
            rec(daysAgo(1), steps: 9999, cal: 999, water: 999),
          ],
        ),
      );
      await controller.loadRecords();
      expect(controller.todaySteps, 7850);
      expect(controller.todayCalories, 420);
      expect(controller.todayWaterMl, 2000);
    });

    test('goal progress is a 0-1 fraction and never goes above 1', () async {
      final controller = HealthController(
        repository: FakeHealthRepository(
          records: [rec(daysAgo(0), steps: 4000, cal: 1000, water: 0)],
          goals: const GoalSettings(
            stepsGoal: 8000,
            caloriesGoal: 500,
            waterGoalMl: 2500,
          ),
        ),
      );
      await controller.loadRecords();
      expect(controller.stepsProgress, 0.5);
      expect(controller.caloriesProgress, 1.0);
      expect(controller.waterProgress, 0.0);
    });

    test('updateDailyGoals saves valid goals and rejects zero', () async {
      final repo = FakeHealthRepository();
      final controller = HealthController(repository: repo);

      expect(
        await controller.updateDailyGoals(
          stepsGoal: 0,
          caloriesGoal: 500,
          waterGoalMl: 2500,
        ),
        isFalse,
      );
      expect(
        controller.errorMessage,
        'All daily goals must be greater than 0.',
      );

      expect(
        await controller.updateDailyGoals(
          stepsGoal: 10000,
          caloriesGoal: 600,
          waterGoalMl: 3000,
        ),
        isTrue,
      );
      expect(repo.goals.stepsGoal, 10000);
      expect(controller.goals.waterGoalMl, 3000);
    });
  });

  group('currentStreakDays', () {
    Future<int> streakFor(List<HealthRecord> records) async {
      final controller = HealthController(
        repository: FakeHealthRepository(records: records),
      );
      await controller.loadRecords();
      return controller.currentStreakDays;
    }

    test('counts consecutive days that met at least one goal', () async {
      expect(
        await streakFor([
          rec(daysAgo(0), steps: 8000),
          rec(daysAgo(1), water: 2500),
          rec(daysAgo(2), cal: 500),
          rec(daysAgo(3), steps: 100),
        ]),
        3,
      );
    });

    test('an unfinished today does not break yesterday\'s streak', () async {
      expect(
        await streakFor([
          rec(daysAgo(0), steps: 100),
          rec(daysAgo(1), steps: 9000),
          rec(daysAgo(2), steps: 9000),
        ]),
        2,
      );
    });

    test('several entries on one day are added together', () async {
      expect(
        await streakFor([
          rec(daysAgo(0), steps: 5000),
          rec(daysAgo(0), steps: 3000),
        ]),
        1,
      );
    });

    test('a missing day ends the streak', () async {
      expect(
        await streakFor([
          rec(daysAgo(0), steps: 9000),
          rec(daysAgo(2), steps: 9000),
        ]),
        1,
      );
    });

    test('no records means no streak', () async {
      expect(await streakFor([]), 0);
    });
  });
}
