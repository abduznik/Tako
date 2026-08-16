import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/board_column.dart';
import '../models/project.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../models/task_attachment.dart';
import '../models/task_comment.dart';
import '../models/task_external_link.dart';
import 'jsonrpc_exception.dart';

/// Generic JSON-RPC 2.0 client for the Kanboard API.
///
/// Reusable across CLI tooling and the Flutter UI — holds no
/// CLI-specific assumptions. Kanboard's wire format uses numeric ids;
/// this client converts to/from String at its public boundary so callers
/// (including [KanboardProvider]) never need to know that.
class KanboardClient {
  final String baseUrl;
  final String username;
  final String password;
  final http.Client _httpClient;

  int _requestId = 0;

  KanboardClient({
    required this.baseUrl,
    required this.username,
    required this.password,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  String get _basicAuthHeader =>
      'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  /// Kanboard accepts `date_due` on write as a "yyyy-MM-dd HH:mm" string and
  /// interprets it as UTC regardless of server/client local timezone
  /// (confirmed against a live instance: a wall-clock-local string was
  /// stored as if it were UTC). It returns the value on read as Unix epoch
  /// seconds — see [Task.fromJson]. So we always format in UTC on write.
  static String _formatDateDue(DateTime dateTime) {
    final utc = dateTime.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-${two(utc.day)} '
        '${two(utc.hour)}:${two(utc.minute)}';
  }

  Future<dynamic> _call(String method, [Map<String, dynamic>? params]) async {
    _requestId += 1;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'id': _requestId,
      'params': params ?? {},
    });

    http.Response response;
    try {
      response = await _httpClient.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _basicAuthHeader,
        },
        body: body,
      );
    } catch (e) {
      throw KanboardHttpException(message: 'Network error calling $method: $e');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw KanboardHttpException(
        statusCode: response.statusCode,
        message: 'Authentication failed calling $method (check username/password)',
      );
    }
    if (response.statusCode != 200) {
      throw KanboardHttpException(
        statusCode: response.statusCode,
        message: 'Unexpected HTTP status calling $method: ${response.body}',
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw KanboardHttpException(
        message: 'Invalid JSON response calling $method: ${response.body}',
      );
    }

    if (decoded.containsKey('error')) {
      throw KanboardApiException.fromJson(
        decoded['error'] as Map<String, dynamic>,
      );
    }

    return decoded['result'];
  }

  // ---- User ----

  /// Returns the authenticated user's id, or null if it can't be
  /// determined (e.g. app-level token auth with no bound user).
  Future<String?> getMe() async {
    final result = await _call('getMe') as Map<String, dynamic>?;
    final id = result?['id']?.toString();
    return (id != null && id.isNotEmpty && id != '0') ? id : null;
  }

  // ---- Projects ----

  Future<List<Project>> getMyProjects() async {
    final result = await _call('getMyProjects') as List<dynamic>? ?? [];
    return result
        .map((p) => Project.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<List<Project>> getAllProjects() async {
    final result = await _call('getAllProjects') as List<dynamic>? ?? [];
    return result
        .map((p) => Project.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<String> createProject(String name, {String description = ''}) async {
    final result = await _call('createProject', {
      'name': name,
      'description': description,
    });
    return result.toString();
  }

  Future<bool> removeProject(String projectId) async {
    final result = await _call('removeProject', {'project_id': int.parse(projectId)});
    return result == true || result.toString() == 'true';
  }

  // ---- Board / Columns ----

  Future<Map<String, dynamic>> getBoard(String projectId) async {
    final result = await _call('getBoard', {'project_id': int.parse(projectId)});
    return result as Map<String, dynamic>;
  }

  Future<List<BoardColumn>> getColumns(String projectId) async {
    final result = await _call('getColumns', {'project_id': int.parse(projectId)})
            as List<dynamic>? ??
        [];
    return result
        .map((c) => BoardColumn.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ---- Tasks ----

  Future<Task> getTask(String taskId) async {
    final result = await _call('getTask', {'task_id': int.parse(taskId)});
    return Task.fromJson(result as Map<String, dynamic>);
  }

  Future<List<Task>> getAllTasks(String projectId, {int statusId = 1}) async {
    final result = await _call('getAllTasks', {
      'project_id': int.parse(projectId),
      'status_id': statusId,
    }) as List<dynamic>? ?? [];
    return result
        .map((t) => Task.fromJson(t as Map<String, dynamic>))
        .toList();
  }

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
    final result = await _call('createTask', {
      'project_id': int.parse(projectId),
      'title': title,
      if (columnId != null) 'column_id': int.parse(columnId),
      if (swimlaneId != null) 'swimlane_id': int.parse(swimlaneId),
      'description': description,
      if (dateDue != null) 'date_due': _formatDateDue(dateDue),
      if (colorId != null) 'color_id': colorId,
      if (ownerId != null) 'owner_id': int.parse(ownerId),
    });
    return result.toString();
  }

  Future<bool> updateTask({
    required String id,
    String? title,
    String? description,
    DateTime? dateDue,
    String? colorId,
    String? ownerId,
    int? priority,
  }) async {
    final result = await _call('updateTask', {
      'id': int.parse(id),
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dateDue != null) 'date_due': _formatDateDue(dateDue),
      if (colorId != null) 'color_id': colorId,
      if (ownerId != null) 'owner_id': int.parse(ownerId),
      if (priority != null) 'priority': priority,
    });
    return result == true || result.toString() == 'true';
  }

  // ---- Subtasks ----

  Future<List<Subtask>> getAllSubtasks(String taskId) async {
    final result = await _call('getAllSubtasks', {'task_id': int.parse(taskId)})
            as List<dynamic>? ??
        [];
    return result
        .map((s) => Subtask.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<String> createSubtask({
    required String taskId,
    required String title,
  }) async {
    final result = await _call('createSubtask', {
      'task_id': int.parse(taskId),
      'title': title,
    });
    return result.toString();
  }

  Future<bool> updateSubtask({
    required String id,
    required String taskId,
    String? title,
    SubtaskStatus? status,
  }) async {
    final result = await _call('updateSubtask', {
      'id': int.parse(id),
      'task_id': int.parse(taskId),
      if (title != null) 'title': title,
      if (status != null) 'status': Subtask.statusToInt(status),
    });
    return result == true || result.toString() == 'true';
  }

  Future<bool> removeSubtask(String subtaskId) async {
    final result = await _call('removeSubtask', {'subtask_id': int.parse(subtaskId)});
    return result == true || result.toString() == 'true';
  }

  Future<bool> moveTaskPosition({
    required String taskId,
    required String projectId,
    required String columnId,
    required int position,
    String swimlaneId = '1',
  }) async {
    final result = await _call('moveTaskPosition', {
      'project_id': int.parse(projectId),
      'task_id': int.parse(taskId),
      'column_id': int.parse(columnId),
      'position': position,
      'swimlane_id': int.parse(swimlaneId),
    });
    return result == true || result.toString() == 'true';
  }

  /// Kanboard's JSON-RPC API has no `getOverdueTasks` method — overdue
  /// detection is a server-side cron/email feature, not exposed over RPC.
  /// This fetches open tasks for a project and returns only those that have
  /// a `date_due` set, for client-side deadline filtering.
  Future<List<Task>> getTasksWithDueDate(String projectId, {int statusId = 1}) async {
    final tasks = await getAllTasks(projectId, statusId: statusId);
    return tasks.where((t) => t.dateDue != null).toList();
  }

  // ---- Comments ----

  Future<List<TaskComment>> getAllComments(String taskId) async {
    final result = await _call('getAllComments', {'task_id': int.parse(taskId)})
            as List<dynamic>? ??
        [];
    return result
        .map((c) => TaskComment.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<String> createComment({
    required String taskId,
    required String userId,
    required String content,
  }) async {
    final result = await _call('createComment', {
      'task_id': int.parse(taskId),
      'user_id': int.parse(userId),
      'content': content,
    });
    return result.toString();
  }

  Future<bool> removeComment(String commentId) async {
    final result = await _call('removeComment', {'comment_id': int.parse(commentId)});
    return result == true || result.toString() == 'true';
  }

  // ---- External links ----

  Future<List<TaskExternalLink>> getAllExternalTaskLinks(String taskId) async {
    final result = await _call('getAllExternalTaskLinks', {'task_id': int.parse(taskId)})
            as List<dynamic>? ??
        [];
    return result
        .map((l) => TaskExternalLink.fromJson(l as Map<String, dynamic>))
        .toList();
  }

  Future<String> createExternalTaskLink({
    required String taskId,
    required String url,
    required String title,
  }) async {
    final result = await _call('createExternalTaskLink', {
      'task_id': int.parse(taskId),
      'url': url,
      'title': title,
      'dependency': 'related',
      'type': 'weblink',
    });
    return result.toString();
  }

  Future<bool> removeExternalTaskLink({
    required String taskId,
    required String linkId,
  }) async {
    final result = await _call('removeExternalTaskLink', {
      'task_id': int.parse(taskId),
      'link_id': int.parse(linkId),
    });
    return result == true || result.toString() == 'true';
  }

  // ---- Attachments ----

  Future<List<TaskAttachment>> getAllTaskFiles(String taskId) async {
    final result = await _call('getAllTaskFiles', {'task_id': int.parse(taskId)})
            as List<dynamic>? ??
        [];
    return result
        .map((f) => TaskAttachment.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  Future<String> createTaskFile({
    required String projectId,
    required String taskId,
    required String filename,
    required String base64Blob,
  }) async {
    final result = await _call('createTaskFile', {
      'project_id': int.parse(projectId),
      'task_id': int.parse(taskId),
      'filename': filename,
      'blob': base64Blob,
    });
    return result.toString();
  }

  /// Returns the file's content as a base64 string.
  Future<String> downloadTaskFile(String fileId) async {
    final result = await _call('downloadTaskFile', {'file_id': int.parse(fileId)});
    return result.toString();
  }

  Future<bool> removeTaskFile(String fileId) async {
    final result = await _call('removeTaskFile', {'file_id': int.parse(fileId)});
    return result == true || result.toString() == 'true';
  }

  void close() => _httpClient.close();
}
