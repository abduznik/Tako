import '../api/jsonrpc_exception.dart';
import '../api/kanboard_client.dart';
import '../models/board_column.dart';
import '../models/project.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../models/task_attachment.dart';
import '../models/task_comment.dart';
import '../models/task_external_link.dart';
import 'provider_exceptions.dart';
import 'task_provider.dart';

/// Adapts [KanboardClient] to the generic [TaskProvider] contract, translating
/// Kanboard-specific exceptions into the generic provider exception types so
/// the UI layer never needs to know Kanboard is involved.
class KanboardProvider implements TaskProvider {
  final KanboardClient _client;
  final String profileName;

  KanboardProvider({
    required String baseUrl,
    required String username,
    required String password,
    required this.profileName,
  }) : _client = KanboardClient(baseUrl: baseUrl, username: username, password: password);

  @override
  String get displayName => profileName;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on KanboardHttpException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw ProviderAuthException(e.message);
      }
      throw ProviderConnectionException(e.message);
    } on KanboardApiException catch (e) {
      throw ProviderException(e.message);
    }
  }

  @override
  Future<void> verifyConnection() => _guard(() => _client.getMyProjects());

  @override
  Future<String?> getCurrentUserId() => _guard(() => _client.getMe());

  @override
  Future<List<Project>> getProjects() => _guard(() => _client.getMyProjects());

  @override
  Future<String> createProject(String name, {String description = ''}) =>
      _guard(() => _client.createProject(name, description: description));

  @override
  Future<bool> removeProject(String projectId) =>
      _guard(() => _client.removeProject(projectId));

  @override
  Future<List<BoardColumn>> getColumns(String projectId) =>
      _guard(() => _client.getColumns(projectId));

  @override
  Future<List<Task>> getTasks(String projectId) =>
      _guard(() => _client.getAllTasks(projectId));

  @override
  Future<List<Task>> getTasksWithDueDate(String projectId) =>
      _guard(() => _client.getTasksWithDueDate(projectId));

  @override
  Future<Task> getTask(String taskId) => _guard(() => _client.getTask(taskId));

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
  }) =>
      _guard(() => _client.createTask(
            projectId: projectId,
            title: title,
            columnId: columnId,
            swimlaneId: swimlaneId,
            description: description,
            dateDue: dateDue,
            colorId: colorId,
            ownerId: ownerId,
          ));

  @override
  Future<bool> updateTask({
    required String id,
    String? title,
    String? description,
    DateTime? dateDue,
    String? colorId,
    String? ownerId,
    int? priority,
  }) =>
      _guard(() => _client.updateTask(
            id: id,
            title: title,
            colorId: colorId,
            description: description,
            dateDue: dateDue,
            ownerId: ownerId,
            priority: priority,
          ));

  @override
  Future<bool> moveTaskPosition({
    required String taskId,
    required String projectId,
    required String columnId,
    required int position,
    String swimlaneId = '1',
  }) =>
      _guard(() => _client.moveTaskPosition(
            taskId: taskId,
            projectId: projectId,
            columnId: columnId,
            position: position,
            swimlaneId: swimlaneId,
          ));

  @override
  Future<List<Subtask>> getSubtasks(String taskId) =>
      _guard(() => _client.getAllSubtasks(taskId));

  @override
  Future<String> createSubtask({required String taskId, required String title}) =>
      _guard(() => _client.createSubtask(taskId: taskId, title: title));

  @override
  Future<bool> updateSubtask({
    required String id,
    required String taskId,
    String? title,
    SubtaskStatus? status,
  }) =>
      _guard(() => _client.updateSubtask(id: id, taskId: taskId, title: title, status: status));

  @override
  Future<bool> removeSubtask(String subtaskId) =>
      _guard(() => _client.removeSubtask(subtaskId));

  @override
  Future<List<TaskComment>> getComments(String taskId) =>
      _guard(() => _client.getAllComments(taskId));

  @override
  Future<String> createComment({required String taskId, required String content}) =>
      _guard(() async {
        final userId = await _client.getMe() ?? '0';
        return _client.createComment(taskId: taskId, userId: userId, content: content);
      });

  @override
  Future<bool> removeComment(String commentId) => _guard(() => _client.removeComment(commentId));

  @override
  Future<List<TaskExternalLink>> getExternalLinks(String taskId) =>
      _guard(() => _client.getAllExternalTaskLinks(taskId));

  @override
  Future<String> createExternalLink({
    required String taskId,
    required String url,
    required String title,
  }) =>
      _guard(() => _client.createExternalTaskLink(taskId: taskId, url: url, title: title));

  @override
  Future<bool> removeExternalLink({required String taskId, required String linkId}) =>
      _guard(() => _client.removeExternalTaskLink(taskId: taskId, linkId: linkId));

  @override
  Future<List<TaskAttachment>> getAttachments(String taskId) =>
      _guard(() => _client.getAllTaskFiles(taskId));

  @override
  Future<String> createAttachment({
    required String projectId,
    required String taskId,
    required String filename,
    required String base64Blob,
  }) =>
      _guard(() => _client.createTaskFile(
            projectId: projectId,
            taskId: taskId,
            filename: filename,
            base64Blob: base64Blob,
          ));

  @override
  Future<String> downloadAttachment(String fileId) =>
      _guard(() => _client.downloadTaskFile(fileId));

  @override
  Future<bool> removeAttachment(String fileId) =>
      _guard(() => _client.removeTaskFile(fileId));

  @override
  void dispose() => _client.close();
}
