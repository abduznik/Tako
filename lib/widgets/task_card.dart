import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_color.dart';
import 'bidi_text.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool highlighted;

  const TaskCard({super.key, required this.task, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = task.dateDue;
    final isOverdue = due != null && due.isBefore(DateTime.now());
    final color = TaskColor.byId(task.colorId);
    final fill = color.fillColor(context);
    final foreground = color.foregroundColor(context);
    final titleDirection = detectTextDirection(task.title);
    final outlineColor = highlighted ? theme.colorScheme.primary : color.accent.withValues(alpha: 0.55);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: outlineColor, width: highlighted ? 2 : 1),
        boxShadow: [
          if (highlighted)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 8,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            BidiText(
              task.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              BidiText(
                task.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foreground.withValues(alpha: 0.8),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (due != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: titleDirection,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: isOverdue ? theme.colorScheme.error : foreground.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverdue ? theme.colorScheme.error : foreground.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
