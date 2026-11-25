import 'package:flutter/foundation.dart';

import '../models/health_record.dart';
import '../repositories/health_repository.dart';
import '../models/goal_settings.dart';
import '../utils/formatters.dart';

class HealthController extends ChangeNotifier {
  final HealthRepository _repository;

  HealthController({HealthRepository? repository})
    : _repository = repository ?? HealthRepository();

  List<HealthRecord> _records = [];
  String? _selectedDateFilter; // Format: 'YYYY-MM-DD' or null for all records
  bool _isLoading = false;
  String? _errorMessage;

  List<HealthRecord> get allRecords => List.unmodifiable(_records);
  String? get selectedDateFilter => _selectedDateFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Returns filtered list if a date filter is active, otherwise all records
  List<HealthRecord> get visibleRecords {
    if (_selectedDateFilter == null || _selectedDateFilter!.isEmpty) {
      return List.unmodifiable(_records);
    }
    return _records
        .where((record) => record.date == _selectedDateFilter)
        .toList();
  }

  // Formats a DateTime as 'YYYY-MM-DD', the format stored in the database
  static String formatDate(DateTime date) => AppFormatters.storageDate(date);

  String get todayDateString => formatDate(DateTime.now());

  // Sum multiple entries for today
  List<HealthRecord> get _todayRecords =>
      _records.where((r) => r.date == todayDateString).toList();

  int get todaySteps => _todayRecords.fold(0, (sum, item) => sum + item.steps);

  int get todayCalories =>
      _todayRecords.fold(0, (sum, item) => sum + item.calories);

  int get todayWaterMl =>
      _todayRecords.fold(0, (sum, item) => sum + item.waterMl);

  // Upper limits that catch typing mistakes (e.g. an extra zero) while still allowing very active days.
  static const int maxSteps = 100000;
  static const int maxCalories = 10000;
  static const int maxWaterMl = 10000;

  // Form validation helper (returns error message if invalid, or null if valid).
  String? validateRecordInput({
    required String date,
    required String stepsText,
    required String caloriesText,
    required String waterText,
    DateTime? today,
  }) {
    final trimmedDate = date.trim();
    if (trimmedDate.isEmpty) {
      return 'Please select a date.';
    }

    final parsedDate = DateTime.tryParse(trimmedDate);
    if (parsedDate == null || formatDate(parsedDate) != trimmedDate) {
      return 'Date must be in YYYY-MM-DD format.';
    }

    final now = today ?? DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    if (parsedDate.isAfter(todayOnly)) {
      return 'You cannot add a record for a future date.';
    }

    final steps = int.tryParse(stepsText.trim());
    if (steps == null || steps < 0) {
      return 'Steps must be a valid non-negative number.';
    }
    if (steps > maxSteps) {
      return 'Steps cannot be more than $maxSteps per record.';
    }

    final calories = int.tryParse(caloriesText.trim());
    if (calories == null || calories < 0) {
      return 'Calories must be a valid non-negative number.';
    }
    if (calories > maxCalories) {
      return 'Calories cannot be more than $maxCalories kcal per record.';
    }

    final water = int.tryParse(waterText.trim());
    if (water == null || water < 0) {
      return 'Water intake (ml) must be a valid non-negative number.';
    }
    if (water > maxWaterMl) {
      return 'Water intake cannot be more than $maxWaterMl ml per record.';
    }

    if (steps == 0 && calories == 0 && water == 0) {
      return 'Enter at least one non-zero health metric.';
    }

    return null;
  }

  Future<void> loadRecords() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _records = await _repository.getAllRecords();
      _goals = await _repository.getDailyGoals();
    } catch (e) {
      _errorMessage = 'Failed to load health records: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addRecord({
    required String date,
    required int steps,
    required int calories,
    required int waterMl,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final newRecord = HealthRecord(
        date: date,
        steps: steps,
        calories: calories,
        waterMl: waterMl,
      );
      await _repository.addRecord(newRecord);
      await loadRecords();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save record: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateRecord(HealthRecord updatedRecord) async {
    if (updatedRecord.id == null) {
      _errorMessage = 'Cannot update a record without an ID.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.updateRecord(updatedRecord);
      await loadRecords();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update record: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteRecord(int id) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.deleteRecord(id);
      await loadRecords();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete record: $e';
      _setLoading(false);
      return false;
    }
  }

  void filterByDate(String? date) {
    _selectedDateFilter = (date == null || date.trim().isEmpty)
        ? null
        : date.trim();
    notifyListeners();
  }

  void clearDateFilter() {
    if (_selectedDateFilter != null) {
      _selectedDateFilter = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  GoalSettings _goals = const GoalSettings();
  GoalSettings get goals => _goals;

  double get stepsProgress => _goals.stepsGoal <= 0
      ? 0
      : (todaySteps / _goals.stepsGoal).clamp(0.0, 1.0);

  double get caloriesProgress => _goals.caloriesGoal <= 0
      ? 0
      : (todayCalories / _goals.caloriesGoal).clamp(0.0, 1.0);

  double get waterProgress => _goals.waterGoalMl <= 0
      ? 0
      : (todayWaterMl / _goals.waterGoalMl).clamp(0.0, 1.0);

  bool _isGoalMetForTotals({
    required int steps,
    required int calories,
    required int waterMl,
  }) {
    final metSteps = _goals.stepsGoal > 0 && steps >= _goals.stepsGoal;
    final metCalories =
        _goals.caloriesGoal > 0 && calories >= _goals.caloriesGoal;
    final metWater = _goals.waterGoalMl > 0 && waterMl >= _goals.waterGoalMl;
    return metSteps || metCalories || metWater;
  }

  int get currentStreakDays {
    if (_records.isEmpty) return 0;

    // Sum all records per YYYY-MM-DD date
    final Map<String, ({int steps, int calories, int water})> totalsByDate = {};
    for (final r in _records) {
      final existing =
          totalsByDate[r.date] ?? (steps: 0, calories: 0, water: 0);
      totalsByDate[r.date] = (
        steps: existing.steps + r.steps,
        calories: existing.calories + r.calories,
        water: existing.water + r.waterMl,
      );
    }

    // Start checking from today; if today hasn't hit a goal yet, check from yesterday
    // so an in-progress day doesn't wipe out an active streak prematurely.
    DateTime cursor = DateTime.now();
    final todayStr = formatDate(cursor);
    final todayTotals =
        totalsByDate[todayStr] ?? (steps: 0, calories: 0, water: 0);
    final todayMet = _isGoalMetForTotals(
      steps: todayTotals.steps,
      calories: todayTotals.calories,
      waterMl: todayTotals.water,
    );

    if (!todayMet) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (true) {
      final dateStr = formatDate(cursor);
      final dayTotals = totalsByDate[dateStr];
      if (dayTotals == null) break;

      final met = _isGoalMetForTotals(
        steps: dayTotals.steps,
        calories: dayTotals.calories,
        waterMl: dayTotals.water,
      );
      if (!met) break;

      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<bool> updateDailyGoals({
    required int stepsGoal,
    required int caloriesGoal,
    required int waterGoalMl,
  }) async {
    if (stepsGoal <= 0 || caloriesGoal <= 0 || waterGoalMl <= 0) {
      _errorMessage = 'All daily goals must be greater than 0.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      final updated = GoalSettings(
        stepsGoal: stepsGoal,
        caloriesGoal: caloriesGoal,
        waterGoalMl: waterGoalMl,
      );
      await _repository.saveDailyGoals(updated);
      _goals = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save daily goals: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
