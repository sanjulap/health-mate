import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/health_controller.dart';
import 'main_navigation_screen.dart';
import '../widgets/metric_summary_card.dart';
import '../widgets/steps_gradient_card.dart';
import '../widgets/streak_summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

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
                'Today – ${controller.todayDateString}',
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
                  stepsText: _formatNumber(controller.todaySteps),
                ),
                const SizedBox(height: 14),

                // 2. CALORIES & WATER CARDS
                Row(
                  children: [
                    Expanded(
                      child: MetricSummaryCard(
                        title: 'Calories Burned',
                        valueText: _formatNumber(controller.todayCalories),
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
                        valueText: _formatNumber(controller.todayWaterMl),
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
                  onEditGoals: () => _showEditGoalsDialog(context, controller),
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

  Future<void> _showEditGoalsDialog(
    BuildContext context,
    HealthController controller,
  ) async {
    final stepsCtrl = TextEditingController(
      text: controller.goals.stepsGoal.toString(),
    );
    final caloriesCtrl = TextEditingController(
      text: controller.goals.caloriesGoal.toString(),
    );
    final waterCtrl = TextEditingController(
      text: controller.goals.waterGoalMl.toString(),
    );

    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Daily Health Goals'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: stepsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Daily Steps Goal',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: caloriesCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Daily Calories Goal (kcal)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: waterCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Daily Water Goal (ml)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        dialogError!,
                        style: const TextStyle(
                          color: Color(0xFFE5484D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final s = int.tryParse(stepsCtrl.text.trim()) ?? 0;
                    final c = int.tryParse(caloriesCtrl.text.trim()) ?? 0;
                    final w = int.tryParse(waterCtrl.text.trim()) ?? 0;

                    if (s <= 0 || c <= 0 || w <= 0) {
                      setDialogState(() {
                        dialogError = 'Each goal must be greater than 0.';
                      });
                      return;
                    }

                    final saved = await controller.updateDailyGoals(
                      stepsGoal: s,
                      caloriesGoal: c,
                      waterGoalMl: w,
                    );

                    if (dialogContext.mounted) {
                      if (saved) {
                        Navigator.of(dialogContext).pop();
                      } else {
                        setDialogState(() {
                          dialogError =
                              controller.errorMessage ??
                              'Failed to save goals.';
                        });
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    stepsCtrl.dispose();
    caloriesCtrl.dispose();
    waterCtrl.dispose();
  }
}
