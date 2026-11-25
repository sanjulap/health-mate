import 'package:health_mate/controllers/health_controller.dart';
import 'package:health_mate/models/goal_settings.dart';
import 'package:health_mate/models/health_record.dart';
import 'package:health_mate/repositories/health_repository.dart';

String daysAgo(int days) =>
    HealthController.formatDate(DateTime.now().subtract(Duration(days: days)));

class FakeHealthRepository implements HealthRepository {
  FakeHealthRepository({
    List<HealthRecord>? records,
    this.goals = const GoalSettings(),
  }) {
    for (final r in records ?? const <HealthRecord>[]) {
      _records.add(r.copyWith(id: _nextId++));
    }
  }

  final List<HealthRecord> _records = [];
  GoalSettings goals;
  int _nextId = 1;
  bool failWrites = false;
  bool failReads = false;

  List<HealthRecord> get stored => List.unmodifiable(_records);

  void _checkWrite() {
    if (failWrites) throw Exception('disk full');
  }

  @override
  Future<int> addRecord(HealthRecord record) async {
    _checkWrite();
    final id = _nextId++;
    _records.add(record.copyWith(id: id));
    return id;
  }

  @override
  Future<List<HealthRecord>> getAllRecords() async {
    if (failReads) throw Exception('database locked');
    final sorted = [..._records]
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.id!.compareTo(a.id!);
      });
    return sorted;
  }

  @override
  Future<List<HealthRecord>> getRecordsByDate(String date) async =>
      (await getAllRecords()).where((r) => r.date == date).toList();

  @override
  Future<int> updateRecord(HealthRecord record) async {
    _checkWrite();
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index == -1) return 0;
    _records[index] = record;
    return 1;
  }

  @override
  Future<int> deleteRecord(int id) async {
    _checkWrite();
    final before = _records.length;
    _records.removeWhere((r) => r.id == id);
    return before - _records.length;
  }

  @override
  Future<GoalSettings> getDailyGoals() async => goals;

  @override
  Future<void> saveDailyGoals(GoalSettings goals) async {
    _checkWrite();
    this.goals = goals;
  }
}
