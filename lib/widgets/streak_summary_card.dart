import 'package:flutter/material.dart';

class StreakSummaryCard extends StatelessWidget {
  final int recordCount;
  final int streakDays;
  final double stepsProgress;
  final double caloriesProgress;
  final double waterProgress;
  final VoidCallback? onEditGoals;

  const StreakSummaryCard({
    super.key,
    required this.recordCount,
    required this.streakDays,
    required this.stepsProgress,
    required this.caloriesProgress,
    required this.waterProgress,
    this.onEditGoals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Current Streak',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onEditGoals != null) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onEditGoals,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 14,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Goals',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$recordCount logged entries in database',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                _MiniProgressRow(
                  label: 'Steps',
                  progress: stepsProgress.clamp(0.0, 1.0),
                  color: const Color(0xFF7B61FF),
                ),
                const SizedBox(height: 8),
                _MiniProgressRow(
                  label: 'Calories',
                  progress: caloriesProgress.clamp(0.0, 1.0),
                  color: const Color(0xFFE5484D),
                ),
                const SizedBox(height: 8),
                _MiniProgressRow(
                  label: 'Water',
                  progress: waterProgress.clamp(0.0, 1.0),
                  color: const Color(0xFF1D7AFC),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$streakDays',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  streakDays == 1 ? 'day' : 'days',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProgressRow extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;

  const _MiniProgressRow({
    required this.label,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
