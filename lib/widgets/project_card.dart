import 'package:flutter/material.dart';

import '../models/board_column.dart';
import '../models/column_theme.dart';
import '../models/project.dart';
import '../models/task.dart';
import 'bidi_text.dart';

/// A project summary card: name plus a per-column task count chip row.
/// Same widget regardless of whether the data came from Kanboard or local
/// standalone storage.
///
/// Content is wrapped in a scroll view rather than assuming it always fits
/// the grid tile's fixed height — a long title or many columns should
/// scroll inside the card instead of overflowing/overlapping.
class ProjectCard extends StatelessWidget {
  final Project project;
  final List<BoardColumn> columns;
  final List<Task> tasks;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.columns,
    required this.tasks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedColumns = [...columns]..sort((a, b) => a.position.compareTo(b.position));

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BidiText(
                        project.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                  ],
                ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  BidiText(
                    project.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                if (sortedColumns.isEmpty)
                  Text('No columns yet', style: theme.textTheme.bodySmall)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedColumns.asMap().entries.map((entry) {
                      final index = entry.key;
                      final column = entry.value;
                      final count = tasks.where((t) => t.columnId == column.id).length;
                      final accent = ColumnTheme.accentColor(context, index, sortedColumns.length);
                      return Chip(
                        label: Text('${column.title}: $count'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Color.alphaBlend(
                          accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.28 : 0.16),
                          theme.colorScheme.surfaceContainerHighest,
                        ),
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
