class HealthRecord {
  final int? id;
  final String date; // yyyy-mm-dd
  final int steps;
  final int calories;
  final int waterMl;

  const HealthRecord({
    this.id,
    required this.date,
    required this.steps,
    required this.calories,
    required this.waterMl,
  });

  // convert database row into dart object
  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'] as int?,
      date: (map['date'] as String?) ?? '',
      steps: (map['steps'] as int?) ?? 0,
      calories: (map['calories'] as int?) ?? 0,
      waterMl: (map['water'] as int?) ?? 0,
    );
  }

  // convert a dart object into a map that SQLite can store
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'steps': steps,
      'calories': calories,
      'water': waterMl,
    };
  }

  HealthRecord copyWith({
    int? id,
    String? date,
    int? steps,
    int? calories,
    int? waterMl,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      waterMl: waterMl ?? this.waterMl,
    );
  }
}
