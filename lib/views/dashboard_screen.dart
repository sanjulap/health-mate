import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/health_controller.dart';
import '../utils/formatters.dart';
import 'main_navigation_screen.dart';
import '../widgets/edit_goals_dialog.dart';
import '../widgets/metric_summary_card.dart';
import '../widgets/steps_gradient_card.dart';
import '../widgets/streak_summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HealthController>();
    final navState = MainNavigationScreen.of(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.loadRecords,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Today – ${AppFormatters.longDate(controller.todayDateString)}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              if (controller.isLoading && controller.allRecords.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // 1. STEPS CARD
                StepsGradientCard(
                  stepsText: AppFormatters.number(controller.todaySteps),
                ),
                const SizedBox(height: 14),

                // 2. CALORIES & WATER CARDS
                Row(
                  children: [
                    Expanded(
                      child: MetricSummaryCard(
                        title: 'Calories Burned',
                        valueText: AppFormatters.number(
                          controller.todayCalories,
                        ),
                        unitText: 'kcal',
                        icon: Icons.local_fire_department,
                        accentColor: const Color(0xFFE5484D),
                        backgroundColor: const Color(0xFFFFF1F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricSummaryCard(
                        title: 'Water Intake',
                        valueText: AppFormatters.number(
                          controller.todayWaterMl,
                        ),
                        unitText: 'ml',
                        icon: Icons.water_drop,
                        accentColor: const Color(0xFF1D7AFC),
                        backgroundColor: const Color(0xFFEFF6FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 3. CURRENT STREAK & QUICK TOTALS CARD
                StreakSummaryCard(
                  recordCount: controller.allRecords.length,
                  streakDays: controller.currentStreakDays,
                  stepsProgress: controller.stepsProgress,
                  caloriesProgress: controller.caloriesProgress,
                  waterProgress: controller.waterProgress,
                  onEditGoals: () => _showEditGoalsDialog(context),
                ),
                const SizedBox(height: 20),
                // 4. PRIMARY ACTION BUTTONS
                FilledButton.icon(
                  onPressed: () => navState?.openAddRecord(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add new record'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => navState?.switchTab(1),
                  icon: const Icon(Icons.history),
                  label: const Text('View History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditGoalsDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const EditGoalsDialog(),
    );
  }
}
