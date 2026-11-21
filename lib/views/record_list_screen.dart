import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/health_controller.dart';
import '../models/health_record.dart';
import '../widgets/health_record_card.dart';
import 'add_edit_record_screen.dart';

class RecordListScreen extends StatelessWidget {
  const RecordListScreen({super.key});

  Future<void> _pickFilterDate(
    BuildContext context,
    HealthController controller,
  ) async {
    final initial =
        DateTime.tryParse(controller.selectedDateFilter ?? '') ??
        DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked != null) {
      controller.filterByDate(HealthController.formatDate(picked));
    }
  }

  Future<void> _openAddScreen(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddEditRecordScreen()));
  }

  Future<void> _openEditScreen(
    BuildContext context,
    HealthRecord record,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditRecordScreen(record: record)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HealthController controller,
    HealthRecord record,
  ) async {
    if (record.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Delete the health record for ${record.date}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5484D),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final deleted = await controller.deleteRecord(record.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted
                  ? 'Record deleted.'
                  : (controller.errorMessage ?? 'Could not delete record.'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HealthController>();
    final records = controller.visibleRecords;
    final activeFilter = controller.selectedDateFilter;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddScreen(context),
        tooltip: 'Add record',
        // Swap Icon(Icons.add) for a custom icon if desired
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Health Records',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                activeFilter != null
                    ? 'Showing records for $activeFilter'
                    : 'All logged daily activities (${records.length})',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 14),

              // FILTER CONTROLS
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Dates'),
                    selected: activeFilter == null,
                    onSelected: (_) => controller.clearDateFilter(),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      activeFilter != null
                          ? 'Date: $activeFilter'
                          : 'Filter by Date',
                    ),
                    onPressed: () => _pickFilterDate(context, controller),
                  ),
                  if (activeFilter != null)
                    ActionChip(
                      avatar: const Icon(Icons.close, size: 18),
                      label: const Text('Clear'),
                      onPressed: controller.clearDateFilter,
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // RECORD LIST / EMPTY STATE
              Expanded(
                child: controller.isLoading && records.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              activeFilter != null
                                  ? 'No records found for $activeFilter.'
                                  : 'No health records yet.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (activeFilter != null)
                              OutlinedButton(
                                onPressed: controller.clearDateFilter,
                                child: const Text('Show All Dates'),
                              )
                            else
                              FilledButton.icon(
                                onPressed: () => _openAddScreen(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Record'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 84),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final item = records[index];
                            return HealthRecordCard(
                              record: item,
                              onEdit: () => _openEditScreen(context, item),
                              onDelete: () =>
                                  _confirmDelete(context, controller, item),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
