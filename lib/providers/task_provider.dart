import '../models/board_column.dart';
import '../models/project.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../models/task_attachment.dart';
import '../models/task_comment.dart';
import '../models/task_external_link.dart';

/// Backend-agnostic interface the UI and local storage layers depend on.
///
/// Kanboard is the first implementation ([KanboardProvider]), and fully
/// offline/standalone usage is another ([LocalProvider]) — both implement
/// this same contract so the UI never branches on which backend is active.
abstract class TaskProvider {
  /// Human-readable name shown in the UI (e.g. the connection profile name,
  /// or "Standalone").
  String get displayName;

  /// Verifies the provider is reachable and credentials (if any) are valid.
  /// Should throw [ProviderAuthException]/[ProviderConnectionException] on
  /// failure rather than returning false, so callers get a clear reason.
  Future<void> verifyConnection();

  /// The id of the currently authenticated user (or a fixed local id in
  /// standalone mode), used to default new tasks to "assigned to me".
  Future<String?> getCurrentUserId();

  Future<List<Project>> getProjects();

  Future<String> createProject(String name, {String description = ''});

  Future<bool> removeProject(String projectId);

  Future<List<BoardColumn>> getColumns(String projectId);

  Future<List<Task>> getTasks(String projectId);

  /// Tasks in [projectId] that have a due date set, for deadline-based
  /// notification polling.
  Future<List<Task>> getTasksWithDueDate(String projectId);

  Future<Task> getTask(String taskId);

  Future<String> createTask({
    required String projectId,
    required String title,
    String? columnId,
    String? swimlaneId,
    String description = '',
    DateTime? dateDue,
    String? colorId,
    String? ownerId,
  });

  Future<bool> updateTask({
    required String id,
    String? title,
    String? description,
    DateTime? dateDue,
    String? colorId,
    String? ownerId,
    int? priority,
  });

  Future<bool> moveTaskPosition({
    required String taskId,
    required String projectId,
    required String columnId,
    required int position,
    String swimlaneId = '1',
  });

  Future<List<Subtask>> getSubtasks(String taskId);

  Future<String> createSubtask({required String taskId, required String title});

  Future<bool> updateSubtask({
    required String id,
    required String taskId,
    String? title,
    SubtaskStatus? status,
  });

  Future<bool> removeSubtask(String subtaskId);

  Future<List<TaskComment>> getComments(String taskId);

  Future<String> createComment({required String taskId, required String content});

  Future<bool> removeComment(String commentId);

  Future<List<TaskExternalLink>> getExternalLinks(String taskId);

  Future<String> createExternalLink({
    required String taskId,
    required String url,
    required String title,
  });

  Future<bool> removeExternalLink({required String taskId, required String linkId});

  Future<List<TaskAttachment>> getAttachments(String taskId);

  Future<String> createAttachment({
    required String projectId,
    required String taskId,
    required String filename,
    required String base64Blob,
  });

  /// Returns the file's content as a base64 string.
  Future<String> downloadAttachment(String fileId);

  Future<bool> removeAttachment(String fileId);

  /// Release any held resources (HTTP clients, etc).
  void dispose();
}
