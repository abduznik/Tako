import 'package:flutter/material.dart';

import '../../models/board_column.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../models/task_color.dart';
import '../../storage/app_storage.dart';
import '../../widgets/bidi_text.dart';

enum _Bucket { overdue, dueSoon, upcoming, noDueDate }

class _TaskWithProject {
  final Task task;
  final Project project;
  _TaskWithProject(this.task, this.project);
}

/// A date-focused view across every project's tasks: sorted by how close
/// the deadline is (closest first), grouped into Overdue / Due soon /
/// Upcoming / No due date, with a project filter and text search — built
/// for juggling several unrelated deadline-heavy projects (e.g. multiple
/// courses) at once rather than browsing project-by-project.
class MyTasksView extends StatefulWidget {
  final Map<String, List<Task>> tasksByProject;
  final Map<String, List<BoardColumn>> columnsByProject;
  final List<Project> projects;
  final void Function(Task task, Project project) onOpenTask;

  const MyTasksView({
    super.key,
    required this.tasksByProject,
    required this.columnsByProject,
    required this.projects,
    required this.onOpenTask,
  });

  @override
  State<MyTasksView> createState() => _MyTasksViewState();
}

class _MyTasksViewState extends State<MyTasksView> {
  final Set<String> _selectedProjectIds = {};
  String _query = '';
  late int _dueSoonDays;

  @override
  void initState() {
    super.initState();
    _dueSoonDays = AppStorage.dueSoonDays;
  }

  Duration get _dueSoonWindow => Duration(days: _dueSoonDays);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsById = {for (final p in widget.projects) p.id: p};

    var all = widget.tasksByProject.entries
        .expand((entry) => entry.value
            .where((t) => projectsById.containsKey(entry.key))
            .map((t) => _TaskWithProject(t, projectsById[entry.key]!)))
        .toList();

    if (_selectedProjectIds.isNotEmpty) {
      all = all.where((tp) => _selectedProjectIds.contains(tp.project.id)).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      all = all.where((tp) => tp.task.title.toLowerCase().contains(q)).toList();
    }

    final now = DateTime.now();
    final buckets = <_Bucket, List<_TaskWithProject>>{
      for (final b in _Bucket.values) b: [],
    };
    for (final tp in all) {
      buckets[_bucketFor(tp.task, now)]!.add(tp);
    }
    for (final list in buckets.values) {
      list.sort((a, b) {
        final aDue = a.task.dateDue;
        final bDue = b.task.dateDue;
        if (aDue == null && bDue == null) return 0;
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        return aDue.compareTo(bDue);
      });
    }

    if (widget.projects.isEmpty) {
      return const Center(child: Text('No projects yet'));
    }

    return Column(
      children: [
        _buildFilterBar(theme),
        Expanded(
          child: all.isEmpty
              ? const Center(child: Text('No matching tasks'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    for (final bucket in _Bucket.values)
                      if (buckets[bucket]!.isNotEmpty)
                        _buildBucketSection(theme, bucket, buckets[bucket]!),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 20),
                    hintText: 'Search tasks',
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Categorization settings',
                icon: const Icon(Icons.tune),
                onPressed: _openSettings,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.projects.map((project) {
              final selected = _selectedProjectIds.contains(project.id);
              return FilterChip(
                label: Text(project.name),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedProjectIds.add(project.id);
                    } else {
                      _selectedProjectIds.remove(project.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBucketSection(
    ThemeData theme,
    _Bucket bucket,
    List<_TaskWithProject> tasks,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              Icon(_bucketIcon(bucket), size: 18, color: _bucketColor(theme, bucket)),
              const SizedBox(width: 8),
              Text(
                '${_bucketLabel(bucket)} (${tasks.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: _bucketColor(theme, bucket),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        for (final tp in tasks)
          _MyTaskRow(
            task: tp.task,
            project: tp.project,
            onTap: () => widget.onOpenTask(tp.task, tp.project),
          ),
      ],
    );
  }

  Future<void> _openSettings() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _DueSoonSettingsDialog(initialDays: _dueSoonDays),
    );
    if (result == null) return;
    setState(() => _dueSoonDays = result);
    await AppStorage.setDueSoonDays(result);
  }

  _Bucket _bucketFor(Task task, DateTime now) {
    final due = task.dateDue;
    if (due == null) return _Bucket.noDueDate;
    if (due.isBefore(now)) return _Bucket.overdue;
    if (due.difference(now) <= _dueSoonWindow) return _Bucket.dueSoon;
    return _Bucket.upcoming;
  }

  String _bucketLabel(_Bucket bucket) {
    switch (bucket) {
      case _Bucket.overdue:
        return 'Overdue';
      case _Bucket.dueSoon:
        return 'Due soon (within $_dueSoonDays ${_dueSoonDays == 1 ? 'day' : 'days'})';
      case _Bucket.upcoming:
        return 'Upcoming';
      case _Bucket.noDueDate:
        return 'No due date';
    }
  }

  IconData _bucketIcon(_Bucket bucket) {
    switch (bucket) {
      case _Bucket.overdue:
        return Icons.error_outline;
      case _Bucket.dueSoon:
        return Icons.schedule_outlined;
      case _Bucket.upcoming:
        return Icons.event_outlined;
      case _Bucket.noDueDate:
        return Icons.inbox_outlined;
    }
  }

  Color _bucketColor(ThemeData theme, _Bucket bucket) {
    switch (bucket) {
      case _Bucket.overdue:
        return theme.colorScheme.error;
      case _Bucket.dueSoon:
        return theme.colorScheme.primary;
      case _Bucket.upcoming:
        return theme.colorScheme.outline;
      case _Bucket.noDueDate:
        return theme.colorScheme.outline;
    }
  }
}

class _MyTaskRow extends StatelessWidget {
  final Task task;
  final Project project;
  final VoidCallback onTap;

  const _MyTaskRow({required this.task, required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = TaskColor.byId(task.colorId);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.fillColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  BidiText(
                    task.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: color.foregroundColor(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  BidiText(
                    project.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.foregroundColor(context).withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (task.dateDue != null) ...[
              const SizedBox(width: 12),
              Text(
                _formatDue(task.dateDue!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.foregroundColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDue(DateTime due) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${due.year}-${two(due.month)}-${two(due.day)}';
  }
}

/// Lets the "Due soon" boundary be tuned — Overdue and No due date stay
/// structural (a task either has passed its deadline or doesn't have one),
/// but how many days out counts as "soon" is a matter of personal pacing.
class _DueSoonSettingsDialog extends StatefulWidget {
  final int initialDays;

  const _DueSoonSettingsDialog({required this.initialDays});

  @override
  State<_DueSoonSettingsDialog> createState() => _DueSoonSettingsDialogState();
}

class _DueSoonSettingsDialogState extends State<_DueSoonSettingsDialog> {
  static const _options = [1, 2, 3, 5, 7, 14, 30];
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = _options.contains(widget.initialDays) ? widget.initialDays : 3;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Categorization settings'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A task is grouped under "Due soon" when its deadline is within '
              'this many days from now. Overdue and undated tasks always get '
              'their own group.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selected,
              decoration: const InputDecoration(labelText: 'Due soon within'),
              items: _options
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d ${d == 1 ? 'day' : 'days'}')))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selected = value);
              },
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
