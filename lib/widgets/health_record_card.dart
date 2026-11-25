import 'package:flutter/material.dart';

import '../models/health_record.dart';
import '../utils/formatters.dart';

class HealthRecordCard extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HealthRecordCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date + Edit/Delete buttons
          Row(
            children: [
              const Icon(Icons.event, size: 18, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppFormatters.cardDate(record.date),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit record',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Color(0xFFE5484D),
                ),
                tooltip: 'Delete record',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const Divider(height: 18),
          _RecordMetricRow(
            icon: Icons.directions_walk,
            color: const Color(0xFF7B61FF),
            label: 'Steps',
            value: '${AppFormatters.number(record.steps)} steps',
          ),
          const SizedBox(height: 10),
          _RecordMetricRow(
            icon: Icons.local_fire_department,
            color: const Color(0xFFE5484D),
            label: 'Calories Burned',
            value: '${AppFormatters.number(record.calories)} kcal',
          ),
          const SizedBox(height: 10),
          _RecordMetricRow(
            icon: Icons.water_drop,
            color: const Color(0xFF1D7AFC),
            label: 'Water Intake',
            value: '${AppFormatters.number(record.waterMl)} ml',
          ),
        ],
      ),
    );
  }
}

class _RecordMetricRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _RecordMetricRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
