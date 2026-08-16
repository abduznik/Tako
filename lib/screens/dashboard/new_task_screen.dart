import 'package:flutter/material.dart';

import '../../models/board_column.dart';
import '../../models/task_color.dart';

class NewTaskResult {
  final String title;
  final String description;
  final String colorId;
  final String columnId;
  final DateTime? dateDue;

  NewTaskResult({
    required this.title,
    required this.description,
    required this.colorId,
    required this.columnId,
    this.dateDue,
  });
}

/// Full task creation form, modeled on Kanboard's "New task" page: title,
/// markdown-style description, color, column, and due date. Pushed as a
/// screen rather than a cramped dialog so there's room to breathe.
class NewTaskScreen extends StatefulWidget {
  final List<BoardColumn> columns;
  final String initialColumnId;

  const NewTaskScreen({
    super.key,
    required this.columns,
    required this.initialColumnId,
  });

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedColorId;
  late String _selectedColumnId;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _selectedColorId = TaskColor.defaultColor;
    _selectedColumnId = widget.initialColumnId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _dueDate != null
          ? TimeOfDay.fromDateTime(_dueDate!)
          : const TimeOfDay(hour: 17, minute: 0),
    );
    if (!mounted) return;

    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 17,
        time?.minute ?? 0,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(NewTaskResult(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      colorId: _selectedColorId,
      columnId: _selectedColumnId,
      dateDue: _dueDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New task'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              final mainColumn = _buildMainFields(theme);
              final sideColumn = _buildSideFields(theme);

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...mainColumn,
                    const SizedBox(height: 24),
                    ...sideColumn,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: mainColumn,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: sideColumn,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMainFields(ThemeData theme) {
    return [
      TextFormField(
        controller: _titleController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Title'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
        onFieldSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Description',
          alignLabelWithHint: true,
        ),
        minLines: 8,
        maxLines: 16,
      ),
    ];
  }

  List<Widget> _buildSideFields(ThemeData theme) {
    return [
      Text('Color', style: theme.textTheme.labelLarge),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _selectedColorId,
        items: TaskColor.all
            .map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(c.label),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _selectedColorId = value);
        },
      ),
      const SizedBox(height: 20),
      Text('Column', style: theme.textTheme.labelLarge),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _selectedColumnId,
        items: widget.columns
            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.title)))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _selectedColumnId = value);
        },
      ),
      const SizedBox(height: 20),
      Text('Due date', style: theme.textTheme.labelLarge),
      const SizedBox(height: 8),
      InkWell(
        onTap: _pickDueDate,
        child: InputDecorator(
          decoration: InputDecoration(
            suffixIcon: _dueDate != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _dueDate = null),
                  )
                : const Icon(Icons.event_outlined),
          ),
          child: Text(
            _dueDate != null ? _formatDateTime(_dueDate!) : 'Not set',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    ];
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
