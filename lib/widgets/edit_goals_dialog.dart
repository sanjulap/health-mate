import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/health_controller.dart';

// Dialog for editing the daily steps, calories and water goals.
class EditGoalsDialog extends StatefulWidget {
  const EditGoalsDialog({super.key});

  @override
  State<EditGoalsDialog> createState() => _EditGoalsDialogState();
}

class _EditGoalsDialogState extends State<EditGoalsDialog> {
  late final TextEditingController _stepsCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _waterCtrl;

  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final goals = context.read<HealthController>().goals;
    _stepsCtrl = TextEditingController(text: goals.stepsGoal.toString());
    _caloriesCtrl = TextEditingController(text: goals.caloriesGoal.toString());
    _waterCtrl = TextEditingController(text: goals.waterGoalMl.toString());
  }

  @override
  void dispose() {
    _stepsCtrl.dispose();
    _caloriesCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final steps = int.tryParse(_stepsCtrl.text.trim()) ?? 0;
    final calories = int.tryParse(_caloriesCtrl.text.trim()) ?? 0;
    final water = int.tryParse(_waterCtrl.text.trim()) ?? 0;

    if (steps <= 0 || calories <= 0 || water <= 0) {
      setState(() => _error = 'Each goal must be greater than 0.');
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    final controller = context.read<HealthController>();
    final saved = await controller.updateDailyGoals(
      stepsGoal: steps,
      caloriesGoal: calories,
      waterGoalMl: water,
    );

    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSaving = false;
        _error = controller.errorMessage ?? 'Failed to save goals.';
      });
    }
  }

  Widget _goalField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      enabled: !_isSaving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily Health Goals'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _goalField(_stepsCtrl, 'Daily Steps Goal'),
            const SizedBox(height: 12),
            _goalField(_caloriesCtrl, 'Daily Calories Goal (kcal)'),
            const SizedBox(height: 12),
            _goalField(_waterCtrl, 'Daily Water Goal (ml)'),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFE5484D), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
