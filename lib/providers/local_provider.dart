import 'package:uuid/uuid.dart';

import '../models/board_column.dart';
import '../models/project.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../models/task_attachment.dart';
import '../models/task_color.dart';
import '../models/task_comment.dart';
import '../models/task_external_link.dart';
import '../storage/app_storage.dart';
import '../storage/hive_models.dart';
import 'provider_exceptions.dart';
import 'task_provider.dart';

/// Fully offline [TaskProvider] backed by local Hive boxes, used when no
/// remote provider is connected ("standalone mode"). Implements the same
/// contract as [KanboardProvider] so the UI never has to special-case it.
class LocalProvider implements TaskProvider {
  static const _uuid = Uuid();

  static const _defaultColumnTitles = ['Backlog', 'Ready', 'Work in progress', 'Done'];

  /// Standalone mode has exactly one implicit local user.
  static const localUserId = 'local-user';

  @override
  String get displayName => 'Standalone';

  @override
  Future<void> verifyConnection() async {
    // Always available — there's nothing to connect to.
  }

  @override
  Future<String?> getCurrentUserId() async => localUserId;

  @override
  Future<List<Project>> getProjects() async {
    return AppStorage.localProjects.values
        .map((p) => Project(
              id: p.id,
              name: p.name,
              isActive: p.isActive,
              description: p.description,
            ))
        .toList();
  }

  @override
  Future<String> createProject(String name, {String description = ''}) async {
    final id = _uuid.v4();
    await AppStorage.localProjects.put(
      id,
      LocalProjectHive(id: id, name: name, description: description, isActive: true),
    );

    for (var i = 0; i < _defaultColumnTitles.length; i++) {
      final columnId = _uuid.v4();
      await AppStorage.localColumns.put(
        columnId,
        LocalColumnHive(
          id: columnId,
          projectId: id,
          title: _defaultColumnTitles[i],
          position: i + 1,
          taskLimit: 0,
        ),
      );
    }

    return id;
  }

  @override
  Future<bool> removeProject(String projectId) async {
    await AppStorage.localProjects.delete(projectId);

    final columnsToRemove = AppStorage.localColumns.values
        .where((c) => c.projectId == projectId)
        .map((c) => c.id)
        .toList();
    await AppStorage.localColumns.deleteAll(columnsToRemove);

    final tasksToRemove = AppStorage.localTasks.values
        .where((t) => t.projectId == projectId)
        .map((t) => t.id)
        .toList();
    await AppStorage.localTasks.deleteAll(tasksToRemove);

    return true;
  }

  @override
  Future<List<BoardColumn>> getColumns(String projectId) async {
    final columns = AppStorage.localColumns.values
        .where((c) => c.projectId == projectId)
        .map((c) => BoardColumn(
              id: c.id,
              title: c.title,
              position: c.position,
              projectId: c.projectId,
              taskLimit: c.taskLimit,
            ))
        .toList();
    columns.sort((a, b) => a.position.compareTo(b.position));
    return columns;
  }

  @override
  Future<List<Task>> getTasks(String projectId) async {
    return AppStorage.localTasks.values
        .where((t) => t.projectId == projectId)
        .map(_toTask)
        .toList();
  }

  @override
  Future<List<Task>> getTasksWithDueDate(String projectId) async {
    final tasks = await getTasks(projectId);
    return tasks.where((t) => t.dateDue != null).toList();
  }

  @override
  Future<Task> getTask(String taskId) async {
    final hive = AppStorage.localTasks.get(taskId);
    if (hive == null) {
      throw ProviderException('Task $taskId not found');
    }
    return _toTask(hive);
  }

  @override
  Future<String> createTask({
    required String projectId,
    required String title,
    String? columnId,
    String? swimlaneId,
    String description = '',
    DateTime? dateDue,
    String? colorId,
    String? ownerId,
  }) async {
    String? resolvedColumnId = columnId;
    if (resolvedColumnId == null) {
      final columns = await getColumns(projectId);
      resolvedColumnId = columns.isNotEmpty ? columns.first.id : null;
    }
    if (resolvedColumnId == null) {
      throw ProviderException('Project $projectId has no columns to place the task in');
    }

    final id = _uuid.v4();
    final existingInColumn = AppStorage.localTasks.values
        .where((t) => t.projectId == projectId && t.columnId == resolvedColumnId)
        .length;

    await AppStorage.localTasks.put(
      id,
      LocalTaskHive(
        id: id,
        projectId: projectId,
        columnId: resolvedColumnId,
        swimlaneId: swimlaneId ?? '1',
        title: title,
        description: description,
        position: existingInColumn + 1,
        colorId: colorId ?? TaskColor.defaultColor,
        dateDue: dateDue,
        ownerId: ownerId,
        dateCreation: DateTime.now(),
      ),
    );
    return id;
  }

  @override
  Future<bool> updateTask({
    required String id,
    String? title,
    String? description,
    DateTime? dateDue,
    String? colorId,
    String? ownerId,
    int? priority,
  }) async {
    final hive = AppStorage.localTasks.get(id);
    if (hive == null) return false;
    if (title != null) hive.title = title;
    if (description != null) hive.description = description;
    if (dateDue != null) hive.dateDue = dateDue;
    if (colorId != null) hive.colorId = colorId;
    if (ownerId != null) hive.ownerId = ownerId;
    if (priority != null) hive.priority = priority;
    await hive.save();
    return true;
  }

  @override
  Future<bool> moveTaskPosition({
    required String taskId,
    required String projectId,
    required String columnId,
    required int position,
    String swimlaneId = '1',
  }) async {
    final hive = AppStorage.localTasks.get(taskId);
    if (hive == null) return false;
    hive.columnId = columnId;
    hive.position = position;
    hive.swimlaneId = swimlaneId;
    await hive.save();
    return true;
  }

  @override
  Future<List<Subtask>> getSubtasks(String taskId) async {
    final subtasks = AppStorage.localSubtasks.values
        .where((s) => s.taskId == taskId)
        .map(_toSubtask)
        .toList();
    subtasks.sort((a, b) => a.position.compareTo(b.position));
    return subtasks;
  }

  @override
  Future<String> createSubtask({required String taskId, required String title}) async {
    final id = _uuid.v4();
    final existing =
        AppStorage.localSubtasks.values.where((s) => s.taskId == taskId).length;
    await AppStorage.localSubtasks.put(
      id,
      LocalSubtaskHive(
        id: id,
        taskId: taskId,
        title: title,
        status: 0,
        position: existing + 1,
      ),
    );
    return id;
  }

  @override
  Future<bool> updateSubtask({
    required String id,
    required String taskId,
    String? title,
    SubtaskStatus? status,
  }) async {
    final hive = AppStorage.localSubtasks.get(id);
    if (hive == null) return false;
    if (title != null) hive.title = title;
    if (status != null) hive.status = Subtask.statusToInt(status);
    await hive.save();
    return true;
  }

  @override
  Future<bool> removeSubtask(String subtaskId) async {
    await AppStorage.localSubtasks.delete(subtaskId);
    return true;
  }

  @override
  Future<List<TaskComment>> getComments(String taskId) async {
    final comments = AppStorage.localComments.values
        .where((c) => c.taskId == taskId)
        .map((c) => TaskComment(
              id: c.id,
              taskId: c.taskId,
              content: c.content,
              authorName: 'You',
              dateCreation: c.dateCreation,
            ))
        .toList();
    comments.sort((a, b) => a.dateCreation.compareTo(b.dateCreation));
    return comments;
  }

  @override
  Future<String> createComment({required String taskId, required String content}) async {
    final id = _uuid.v4();
    await AppStorage.localComments.put(
      id,
      LocalCommentHive(id: id, taskId: taskId, content: content, dateCreation: DateTime.now()),
    );
    return id;
  }

  @override
  Future<bool> removeComment(String commentId) async {
    await AppStorage.localComments.delete(commentId);
    return true;
  }

  @override
  Future<List<TaskExternalLink>> getExternalLinks(String taskId) async {
    return AppStorage.localExternalLinks.values
        .where((l) => l.taskId == taskId)
        .map((l) => TaskExternalLink(id: l.id, taskId: l.taskId, title: l.title, url: l.url))
        .toList();
  }

  @override
  Future<String> createExternalLink({
    required String taskId,
    required String url,
    required String title,
  }) async {
    final id = _uuid.v4();
    await AppStorage.localExternalLinks.put(
      id,
      LocalExternalLinkHive(id: id, taskId: taskId, title: title, url: url),
    );
    return id;
  }

  @override
  Future<bool> removeExternalLink({required String taskId, required String linkId}) async {
    await AppStorage.localExternalLinks.delete(linkId);
    return true;
  }

  @override
  Future<List<TaskAttachment>> getAttachments(String taskId) async {
    return AppStorage.localAttachments.values
        .where((a) => a.taskId == taskId)
        .map((a) => TaskAttachment(
              id: a.id,
              taskId: a.taskId,
              name: a.name,
              isImage: a.isImage,
              size: (a.base64Blob.length * 3) ~/ 4,
              date: a.date,
            ))
        .toList();
  }

  @override
  Future<String> createAttachment({
    required String projectId,
    required String taskId,
    required String filename,
    required String base64Blob,
  }) async {
    final id = _uuid.v4();
    final lower = filename.toLowerCase();
    final isImage = lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
    await AppStorage.localAttachments.put(
      id,
      LocalAttachmentHive(
        id: id,
        taskId: taskId,
        name: filename,
        isImage: isImage,
        date: DateTime.now(),
        base64Blob: base64Blob,
      ),
    );
    return id;
  }

  @override
  Future<String> downloadAttachment(String fileId) async {
    final hive = AppStorage.localAttachments.get(fileId);
    if (hive == null) throw ProviderException('Attachment $fileId not found');
    return hive.base64Blob;
  }

  @override
  Future<bool> removeAttachment(String fileId) async {
    await AppStorage.localAttachments.delete(fileId);
    return true;
  }

  @override
  void dispose() {}

  Task _toTask(LocalTaskHive h) => Task(
        id: h.id,
        title: h.title,
        projectId: h.projectId,
        columnId: h.columnId,
        swimlaneId: h.swimlaneId,
        position: h.position,
        colorId: h.colorId,
        description: h.description,
        dateDue: h.dateDue,
        ownerId: h.ownerId,
        priority: h.priority,
        dateCreation: h.dateCreation,
      );

  Subtask _toSubtask(LocalSubtaskHive h) => Subtask(
        id: h.id,
        taskId: h.taskId,
        title: h.title,
        status: Subtask.statusFromInt(h.status),
        position: h.position,
      );
}
