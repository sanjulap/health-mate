import '../database/database_helper.dart';
import '../models/health_record.dart';
import '../models/goal_settings.dart';

class HealthRepository {
  final DatabaseHelper _dbHelper;

  HealthRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> addRecord(HealthRecord record) {
    return _dbHelper.insertRecord(record);
  }

  Future<List<HealthRecord>> getAllRecords() {
    return _dbHelper.getAllRecords();
  }

  Future<List<HealthRecord>> getRecordsByDate(String date) {
    return _dbHelper.getRecordsByDate(date);
  }

  Future<int> updateRecord(HealthRecord record) {
    return _dbHelper.updateRecord(record);
  }

  Future<int> deleteRecord(int id) {
    return _dbHelper.deleteRecord(id);
  }

  Future<GoalSettings> getDailyGoals() async {
    final map = await _dbHelper.getDailyGoals();
    if (map == null) return const GoalSettings();
    return GoalSettings(
      stepsGoal: map['steps_goal'] ?? 8000,
      caloriesGoal: map['calories_goal'] ?? 500,
      waterGoalMl: map['water_goal'] ?? 2500,
    );
  }

  Future<void> saveDailyGoals(GoalSettings goals) {
    return _dbHelper.saveDailyGoals(
      stepsGoal: goals.stepsGoal,
      caloriesGoal: goals.caloriesGoal,
      waterGoalMl: goals.waterGoalMl,
    );
  }
}
