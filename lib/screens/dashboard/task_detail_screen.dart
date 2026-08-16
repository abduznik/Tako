import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/session.dart';
import '../../models/board_column.dart';
import '../../models/subtask.dart';
import '../../models/task.dart';
import '../../models/task_attachment.dart';
import '../../models/task_color.dart';
import '../../models/task_comment.dart';
import '../../models/task_external_link.dart';
import '../../models/task_priority.dart';
import '../../widgets/bidi_text.dart';

/// Task detail screen: view + edit all standard Kanboard fields, plus
/// subtasks. Opened via single-click from My Tasks or double-click from
/// the board. Comments/links/attachments/activity stream are a follow-up.
class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final List<BoardColumn> columns;

  const TaskDetailScreen({super.key, required this.taskId, required this.columns});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  List<Subtask> _subtasks = [];
  List<TaskComment> _comments = [];
  List<TaskExternalLink> _externalLinks = [];
  List<TaskAttachment> _attachments = [];
  bool _isLoading = true;
  String? _loadError;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploading = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedColorId;
  late String _selectedColumnId;
  late int _selectedPriority;
  DateTime? _dueDate;

  final _newSubtaskController = TextEditingController();
  final _newCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newSubtaskController.dispose();
    _newCommentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final provider = context.read<Session>().provider;
    try {
      final task = await provider.getTask(widget.taskId);
      final subtasks = await provider.getSubtasks(widget.taskId);
      final comments = await provider.getComments(widget.taskId);
      final externalLinks = await provider.getExternalLinks(widget.taskId);
      final attachments = await provider.getAttachments(widget.taskId);
      if (!mounted) return;
      setState(() {
        _task = task;
        _subtasks = subtasks;
        _comments = comments;
        _externalLinks = externalLinks;
        _attachments = attachments;
        _titleController.text = task.title;
        _descriptionController.text = task.description;
        _selectedColorId = task.colorId;
        _selectedColumnId = task.columnId;
        _selectedPriority = task.priority;
        _dueDate = task.dateDue;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load task: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final provider = context.read<Session>().provider;
    try {
      await provider.updateTask(
        id: widget.taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        colorId: _selectedColorId,
        dateDue: _dueDate,
        priority: _selectedPriority,
      );
      if (_selectedColumnId != _task!.columnId) {
        await provider.moveTaskPosition(
          taskId: widget.taskId,
          projectId: _task!.projectId,
          columnId: _selectedColumnId,
          position: 1,
        );
      }
      if (!mounted) return;
      setState(() => _isEditing = false);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      initialTime:
          _dueDate != null ? TimeOfDay.fromDateTime(_dueDate!) : const TimeOfDay(hour: 17, minute: 0),
    );
    if (!mounted) return;
    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time?.hour ?? 17, time?.minute ?? 0);
    });
  }

  Future<void> _addSubtask() async {
    final title = _newSubtaskController.text.trim();
    if (title.isEmpty) return;
    final provider = context.read<Session>().provider;
    await provider.createSubtask(taskId: widget.taskId, title: title);
    _newSubtaskController.clear();
    await _load();
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    final provider = context.read<Session>().provider;
    final nextStatus =
        subtask.status == SubtaskStatus.done ? SubtaskStatus.todo : SubtaskStatus.done;
    await provider.updateSubtask(id: subtask.id, taskId: widget.taskId, status: nextStatus);
    await _load();
  }

  Future<void> _removeSubtask(Subtask subtask) async {
    final provider = context.read<Session>().provider;
    await provider.removeSubtask(subtask.id);
    await _load();
  }

  Future<void> _addComment() async {
    final content = _newCommentController.text.trim();
    if (content.isEmpty) return;
    final provider = context.read<Session>().provider;
    await provider.createComment(taskId: widget.taskId, content: content);
    _newCommentController.clear();
    await _load();
  }

  Future<void> _removeComment(TaskComment comment) async {
    final provider = context.read<Session>().provider;
    await provider.removeComment(comment.id);
    await _load();
  }

  Future<void> _addExternalLink() async {
    final result = await showDialog<({String title, String url})>(
      context: context,
      builder: (context) => const _AddExternalLinkDialog(),
    );
    if (result == null || !mounted) return;
    final provider = context.read<Session>().provider;
    await provider.createExternalLink(
      taskId: widget.taskId,
      url: result.url,
      title: result.title,
    );
    await _load();
  }

  Future<void> _removeExternalLink(TaskExternalLink link) async {
    final provider = context.read<Session>().provider;
    await provider.removeExternalLink(taskId: widget.taskId, linkId: link.id);
    await _load();
  }

  Future<void> _openExternalLink(TaskExternalLink link) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _addAttachment() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty || !mounted) return;
    final file = files.single;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() => _isUploading = true);
    try {
      final provider = context.read<Session>().provider;
      await provider.createAttachment(
        projectId: _task!.projectId,
        taskId: widget.taskId,
        filename: file.name,
        base64Blob: base64Encode(bytes),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload file: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _openAttachment(TaskAttachment attachment) async {
    final provider = context.read<Session>().provider;
    try {
      final base64Blob = await provider.downloadAttachment(attachment.id);
      final bytes = base64Decode(base64Blob);
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${attachment.id}_${attachment.name}';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await OpenFilex.open(filePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open attachment: $e')),
      );
    }
  }

  Future<void> _removeAttachment(TaskAttachment attachment) async {
    final provider = context.read<Session>().provider;
    await provider.removeAttachment(attachment.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_task != null ? 'Task #${_task!.id}' : 'Task'),
        actions: [
          if (!_isLoading && _loadError == null)
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              )
            else
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => setState(() => _isEditing = true),
              ),
        ],
      ),
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

    final task = _task!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          final mainColumn = _buildMainColumn(theme, task);
          final sideColumn = _buildSideColumn(theme, task);

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...mainColumn, const SizedBox(height: 24), ...sideColumn],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: mainColumn),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sideColumn),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildMainColumn(ThemeData theme, Task task) {
    return [
      if (_isEditing)
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Title'),
        )
      else
        BidiText(task.title, style: theme.textTheme.headlineSmall),
      const SizedBox(height: 20),
      Text('Description', style: theme.textTheme.labelLarge),
      const SizedBox(height: 8),
      if (_isEditing)
        TextFormField(
          controller: _descriptionController,
          minLines: 6,
          maxLines: 12,
          decoration: const InputDecoration(alignLabelWithHint: true),
        )
      else
        BidiText(
          task.description.isEmpty ? '(no description)' : task.description,
          style: theme.textTheme.bodyMedium,
        ),
      const SizedBox(height: 24),
      _buildSubtasksSection(theme),
      const SizedBox(height: 24),
      _buildAttachmentsSection(theme),
      const SizedBox(height: 24),
      _buildExternalLinksSection(theme),
      const SizedBox(height: 24),
      _buildCommentsSection(theme),
    ];
  }

  Widget _buildAttachmentsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Attachments (${_attachments.length})', style: theme.textTheme.labelLarge),
            const Spacer(),
            TextButton.icon(
              onPressed: _isUploading ? null : _addAttachment,
              icon: _isUploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file, size: 18),
              label: const Text('Attach a document'),
            ),
          ],
        ),
        if (_attachments.isEmpty)
          Text('No attachments', style: theme.textTheme.bodySmall)
        else
          for (final attachment in _attachments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                attachment.isImage ? Icons.image_outlined : Icons.description_outlined,
                color: theme.colorScheme.outline,
              ),
              title: Text(attachment.name),
              subtitle: Text(_formatFileSize(attachment.size)),
              onTap: () => _openAttachment(attachment),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Remove attachment',
                onPressed: () => _removeAttachment(attachment),
              ),
            ),
      ],
    );
  }

  Widget _buildExternalLinksSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('External links (${_externalLinks.length})', style: theme.textTheme.labelLarge),
            const Spacer(),
            TextButton.icon(
              onPressed: _addExternalLink,
              icon: const Icon(Icons.add_link, size: 18),
              label: const Text('Add external link'),
            ),
          ],
        ),
        if (_externalLinks.isEmpty)
          Text('No external links', style: theme.textTheme.bodySmall)
        else
          for (final link in _externalLinks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.link, color: theme.colorScheme.outline),
              title: Text(link.title.isEmpty ? link.url : link.title),
              subtitle: link.title.isEmpty ? null : Text(link.url),
              onTap: () => _openExternalLink(link),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Remove link',
                onPressed: () => _removeExternalLink(link),
              ),
            ),
      ],
    );
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comments (${_comments.length})', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        for (final comment in _comments)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        comment.authorName,
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(comment.content, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: 'Remove comment',
                  onPressed: () => _removeComment(comment),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newCommentController,
                decoration: const InputDecoration(isDense: true, hintText: 'Add a comment'),
                onSubmitted: (_) => _addComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.send_outlined), onPressed: _addComment),
          ],
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildSubtasksSection(ThemeData theme) {
    final done = _subtasks.where((s) => s.status == SubtaskStatus.done).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subtasks ($done/${_subtasks.length})', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        for (final subtask in _subtasks)
          _SubtaskRow(
            subtask: subtask,
            onToggle: () => _toggleSubtask(subtask),
            onRemove: () => _removeSubtask(subtask),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newSubtaskController,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Add a sub-task',
                ),
                onSubmitted: (_) => _addSubtask(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.add), onPressed: _addSubtask),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildSideColumn(ThemeData theme, Task task) {
    return [
      Text('Status', style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      Text(task.isActive ? 'Open' : 'Closed', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      Text('Color', style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      if (_isEditing)
        DropdownButtonFormField<String>(
          initialValue: _selectedColorId,
          items: TaskColor.all
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
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
        )
      else
        Text(TaskColor.byId(task.colorId).label, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      Text('Priority', style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      if (_isEditing)
        DropdownButtonFormField<int>(
          initialValue: _selectedPriority,
          items: List.generate(
            TaskPriority.labels.length,
            (i) => DropdownMenuItem(value: i, child: Text(TaskPriority.labelFor(i))),
          ),
          onChanged: (value) {
            if (value != null) setState(() => _selectedPriority = value);
          },
        )
      else
        Text(TaskPriority.labelFor(task.priority), style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      Text('Column', style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      if (_isEditing)
        DropdownButtonFormField<String>(
          initialValue: _selectedColumnId,
          items: widget.columns
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.title)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedColumnId = value);
          },
        )
      else
        Text(
          widget.columns.firstWhere(
            (c) => c.id == task.columnId,
            orElse: () => BoardColumn(
              id: task.columnId,
              title: 'Unknown',
              position: 0,
              projectId: task.projectId,
              taskLimit: 0,
            ),
          ).title,
          style: theme.textTheme.bodyMedium,
        ),
      const SizedBox(height: 16),
      Text('Due date', style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      if (_isEditing)
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
            child: Text(_dueDate != null ? _formatDateTime(_dueDate!) : 'Not set'),
          ),
        )
      else
        Text(
          task.dateDue != null ? _formatDateTime(task.dateDue!) : 'Not set',
          style: theme.textTheme.bodyMedium,
        ),
      const SizedBox(height: 16),
      if (task.dateCreation != null) ...[
        Text('Created', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(_formatDateTime(task.dateCreation!), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
      ],
      if (task.dateModification != null) ...[
        Text('Modified', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(_formatDateTime(task.dateModification!), style: theme.textTheme.bodyMedium),
      ],
    ];
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _SubtaskRow extends StatelessWidget {
  final Subtask subtask;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _SubtaskRow({required this.subtask, required this.onToggle, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = subtask.status == SubtaskStatus.done;

    return Row(
      children: [
        Checkbox(value: done, onChanged: (_) => onToggle()),
        Expanded(
          child: Text(
            subtask.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: done ? TextDecoration.lineThrough : null,
              color: done ? theme.colorScheme.outline : null,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: onRemove,
          tooltip: 'Remove sub-task',
        ),
      ],
    );
  }
}

class _AddExternalLinkDialog extends StatefulWidget {
  const _AddExternalLinkDialog();

  @override
  State<_AddExternalLinkDialog> createState() => _AddExternalLinkDialogState();
}

class _AddExternalLinkDialogState extends State<_AddExternalLinkDialog> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    Navigator.of(context).pop((title: _titleController.text.trim(), url: url));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add external link'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL', hintText: 'https://…'),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
