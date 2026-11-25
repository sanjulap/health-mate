import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/health_controller.dart';
import '../models/health_record.dart';

class AddEditRecordScreen extends StatefulWidget {
  final HealthRecord? record;

  const AddEditRecordScreen({super.key, this.record});

  bool get isEditing => record != null;

  @override
  State<AddEditRecordScreen> createState() => _AddEditRecordScreenState();
}

class _AddEditRecordScreenState extends State<AddEditRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _stepsController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _waterController;

  String? _validationError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.record;
    _dateController = TextEditingController(
      text: existing?.date ?? HealthController.formatDate(DateTime.now()),
    );
    _stepsController = TextEditingController(
      text: existing != null ? existing.steps.toString() : '',
    );
    _caloriesController = TextEditingController(
      text: existing != null ? existing.calories.toString() : '',
    );
    _waterController = TextEditingController(
      text: existing != null ? existing.waterMl.toString() : '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    // Records cannot be logged for future days, so today is the last selectable date.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final parsed = DateTime.tryParse(_dateController.text.trim()) ?? today;
    final initialDate = parsed.isAfter(today) ? today : parsed;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: today,
    );

    if (picked != null) {
      setState(() {
        _dateController.text = HealthController.formatDate(picked);
        _validationError = null;
      });
    }
  }

  Future<void> _handleSave() async {
    final controller = context.read<HealthController>();

    final error = controller.validateRecordInput(
      date: _dateController.text,
      stepsText: _stepsController.text,
      caloriesText: _caloriesController.text,
      waterText: _waterController.text,
    );

    if (error != null) {
      setState(() {
        _validationError = error;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _isSubmitting = true;
    });

    final steps = int.parse(_stepsController.text.trim());
    final calories = int.parse(_caloriesController.text.trim());
    final waterMl = int.parse(_waterController.text.trim());
    final date = _dateController.text.trim();

    bool success;
    if (widget.isEditing) {
      final updated = widget.record!.copyWith(
        date: date,
        steps: steps,
        calories: calories,
        waterMl: waterMl,
      );
      success = await controller.updateRecord(updated);
    } else {
      success = await controller.addRecord(
        date: date,
        steps: steps,
        calories: calories,
        waterMl: waterMl,
      );
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Record updated.' : 'Health record saved.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _validationError =
            controller.errorMessage ??
            'Could not save record. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Health Record' : 'Add Health Record';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // DATE FIELD (tap to pick date)
                const Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: InputDecoration(
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // STEPS FIELD
                const Text(
                  'Steps',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _stepsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (_validationError != null) {
                      setState(() => _validationError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. 7000',
                    suffixIcon: const Icon(
                      Icons.directions_walk,
                      color: Color(0xFF7B61FF),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // CALORIES BURNED FIELD
                const Text(
                  'Calories Burned (kcal)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (_validationError != null) {
                      setState(() => _validationError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. 420',
                    suffixIcon: const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFE5484D),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // WATER INTAKE FIELD
                const Text(
                  'Water Intake (ml)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _waterController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (_validationError != null) {
                      setState(() => _validationError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. 2000',
                    suffixIcon: const Icon(
                      Icons.water_drop,
                      color: Color(0xFF1D7AFC),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // VALIDATION MESSAGE BOX
                if (_validationError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5484D).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFE5484D),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(
                              color: Color(0xFFB42318),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // SAVE BUTTON
                FilledButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Record',
                          style: TextStyle(fontSize: 15),
                        ),
                ),
                const SizedBox(height: 10),

                // CANCEL BUTTON
                OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
