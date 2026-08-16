import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session.dart';
import '../../models/board_column.dart';
import '../../models/column_theme.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../widgets/task_card.dart';
import 'new_task_screen.dart';
import 'task_detail_screen.dart';

/// Kanban board for a single project, backed by drag_and_drop_lists. Works
/// identically against a Kanboard-connected provider or the standalone
/// local provider — both implement the same TaskProvider contract.
class BoardScreen extends StatefulWidget {
  final Project project;

  const BoardScreen({super.key, required this.project});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  List<BoardColumn> _columns = [];
  final Map<String, List<Task>> _tasksByColumn = {};
  bool _isLoading = true;
  String? _loadError;
  String? _recentlyMovedTaskId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final provider = context.read<Session>().provider;
    try {
      final columns = await provider.getColumns(widget.project.id);
      final tasks = await provider.getTasks(widget.project.id);
      final sortedColumns = [...columns]..sort((a, b) => a.position.compareTo(b.position));

      final tasksByColumn = <String, List<Task>>{};
      for (final column in sortedColumns) {
        final columnTasks = tasks.where((t) => t.columnId == column.id).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
        tasksByColumn[column.id] = columnTasks;
      }

      if (!mounted) return;
      setState(() {
        _columns = sortedColumns;
        _tasksByColumn
          ..clear()
          ..addAll(tasksByColumn);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load board: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) async {
    final fromColumn = _columns[oldListIndex];
    final toColumn = _columns[newListIndex];
    final task = _tasksByColumn[fromColumn.id]![oldItemIndex];

    setState(() {
      _tasksByColumn[fromColumn.id]!.removeAt(oldItemIndex);
      _tasksByColumn[toColumn.id]!.insert(newItemIndex, task);
      _recentlyMovedTaskId = task.id;
    });
    // Briefly outline the dropped card so it's easy to spot among other
    // tasks in the destination column, then let the outline fade away.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _recentlyMovedTaskId != task.id) return;
      setState(() => _recentlyMovedTaskId = null);
    });

    final provider = context.read<Session>().provider;
    try {
      await provider.moveTaskPosition(
        taskId: task.id,
        projectId: widget.project.id,
        columnId: toColumn.id,
        position: newItemIndex + 1,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not move task: $e')),
      );
      await _load();
    }
  }

  Future<void> _addTask(String columnId) async {
    final result = await Navigator.of(context).push<NewTaskResult>(
      MaterialPageRoute(
        builder: (_) => NewTaskScreen(columns: _columns, initialColumnId: columnId),
      ),
    );
    if (result == null || result.title.isEmpty) return;
    if (!mounted) return;

    final provider = context.read<Session>().provider;
    // New tasks default to "assigned to me" so nothing lands unowned.
    final currentUserId = await provider.getCurrentUserId();
    await provider.createTask(
      projectId: widget.project.id,
      title: result.title,
      description: result.description,
      columnId: result.columnId,
      colorId: result.colorId,
      dateDue: result.dateDue,
      ownerId: currentUserId,
    );
    await _load();
  }

  Future<void> _openTaskDetail(String taskId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: taskId, columns: _columns),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name)),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_columns.isEmpty) {
      return const Center(child: Text('This project has no columns yet'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Divide the available width evenly across all columns so they
        // always fill the screen, rather than a fixed per-column width
        // that leaves empty space or requires horizontal scrolling.
        const minColumnWidth = 240.0;
        const spacing = 12.0;
        final columnCount = _columns.length;
        final evenWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;
        final columnWidth = evenWidth < minColumnWidth ? minColumnWidth : evenWidth;

        return DragAndDropLists(
          axis: Axis.horizontal,
          listWidth: columnWidth,
          listPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          listInnerDecoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          lastItemTargetHeight: 80,
          itemDragOnLongPress: false,
          // Visible "picked up" look for the card following the cursor —
          // this Container wraps the TaskCard itself, so the outline must
          // be a real border (a boxShadow gets hidden behind the card's
          // own opaque background) — and a dimmed placeholder in the list
          // where it would land.
          itemDecorationWhileDragging: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          itemGhostOpacity: 0.3,
          onItemReorder: _onItemReorder,
          onListReorder: (_, _) {}, // Column reordering isn't supported yet.
          children: [
            for (var i = 0; i < _columns.length; i++) _buildColumn(theme, i),
          ],
        );
      },
    );
  }

  DragAndDropList _buildColumn(ThemeData theme, int index) {
    final column = _columns[index];
    final tasks = _tasksByColumn[column.id] ?? const [];
    final background = ColumnTheme.headerBackground(context, index, _columns.length);
    final foreground = ColumnTheme.headerForeground(context, index, _columns.length);
    final accent = ColumnTheme.accentColor(context, index, _columns.length);

    return DragAndDropList(
      header: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border(
            bottom: BorderSide(color: accent.withValues(alpha: 0.6), width: 2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                column.title,
                style: theme.textTheme.titleSmall?.copyWith(color: foreground),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, size: 20, color: foreground),
              tooltip: 'Add task',
              onPressed: () => _addTask(column.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
      contentsWhenEmpty: const SizedBox.shrink(),
      children: [
        for (final task in tasks)
          DragAndDropItem(
            // A plain GestureDetector(onTap: ...) would compete with the
            // package's own Draggable for the same pointer. Listener only
            // observes pointer events without entering the gesture arena,
            // and Draggable only claims the pointer once it moves past its
            // slop threshold, so a stationary press-and-release still
            // reaches onPointerUp here.
            child: _ClickToOpenDetector(
              onClick: () => _openTaskDetail(task.id),
              child: TaskCard(
                task: task,
                highlighted: task.id == _recentlyMovedTaskId,
              ),
            ),
          ),
      ],
    );
  }
}

class _ClickToOpenDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onClick;

  const _ClickToOpenDetector({required this.child, required this.onClick});

  @override
  State<_ClickToOpenDetector> createState() => _ClickToOpenDetectorState();
}

class _ClickToOpenDetectorState extends State<_ClickToOpenDetector> {
  Offset? _downPosition;
  bool _movedPastSlop = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _downPosition = event.position;
        _movedPastSlop = false;
      },
      onPointerMove: (event) {
        final start = _downPosition;
        if (start != null && (event.position - start).distance >= kTouchSlop) {
          _movedPastSlop = true;
        }
      },
      onPointerUp: (event) {
        // Draggable claims the gesture once the pointer moves past its own
        // slop threshold, but this Listener still sees every pointer event
        // regardless. Only treat it as a click if the pointer never moved
        // far enough to have been a drag — checking the running max
        // distance (not just start-vs-end) so dragging out and back to the
        // same spot still counts as a drag, not a click.
        if (!_movedPastSlop) {
          widget.onClick();
        }
      },
      child: widget.child,
    );
  }
}
