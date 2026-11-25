import 'package:flutter_test/flutter_test.dart';
import 'package:health_mate/models/health_record.dart';

void main() {
  group('HealthRecord', () {
    const record = HealthRecord(
      id: 7,
      date: '2026-11-20',
      steps: 7850,
      calories: 420,
      waterMl: 2000,
    );

    test('toMap uses the health_records column names', () {
      expect(record.toMap(), {
        'id': 7,
        'date': '2026-11-20',
        'steps': 7850,
        'calories': 420,
        'water': 2000,
      });
    });

    test('toMap leaves out id for a new record so SQLite can generate it', () {
      const newRecord = HealthRecord(
        date: '2026-11-20',
        steps: 1,
        calories: 1,
        waterMl: 1,
      );
      expect(newRecord.toMap().containsKey('id'), isFalse);
    });

    test('fromMap reads a database row back into the same values', () {
      final restored = HealthRecord.fromMap(record.toMap());
      expect(restored.id, 7);
      expect(restored.date, '2026-11-20');
      expect(restored.steps, 7850);
      expect(restored.calories, 420);
      expect(restored.waterMl, 2000);
    });

    test('fromMap falls back to safe defaults for missing columns', () {
      final restored = HealthRecord.fromMap({'id': 3});
      expect(restored.date, '');
      expect(restored.steps, 0);
      expect(restored.calories, 0);
      expect(restored.waterMl, 0);
    });

    test('copyWith changes only the given fields', () {
      final updated = record.copyWith(steps: 9000);
      expect(updated.steps, 9000);
      expect(updated.id, record.id);
      expect(updated.date, record.date);
      expect(updated.calories, record.calories);
      expect(updated.waterMl, record.waterMl);
    });
  });
}
