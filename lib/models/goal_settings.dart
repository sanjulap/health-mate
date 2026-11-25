class GoalSettings {
  final int stepsGoal;
  final int caloriesGoal;
  final int waterGoalMl;

  const GoalSettings({
    this.stepsGoal = 8000,
    this.caloriesGoal = 500,
    this.waterGoalMl = 2500,
  });

  GoalSettings copyWith({int? stepsGoal, int? caloriesGoal, int? waterGoalMl}) {
    return GoalSettings(
      stepsGoal: stepsGoal ?? this.stepsGoal,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
    );
  }
}
