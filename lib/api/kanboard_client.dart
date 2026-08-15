import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/board_column.dart';
import '../models/project.dart';
import '../models/task.dart';
import 'jsonrpc_exception.dart';

/// Generic JSON-RPC 2.0 client for the Kanboard API.
///
/// Reusable across CLI tooling and the Flutter UI — holds no
/// CLI-specific assumptions.
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

  Future<int> createProject(String name, {String description = ''}) async {
    final result = await _call('createProject', {
      'name': name,
      'description': description,
    });
    return int.parse(result.toString());
  }

  Future<bool> removeProject(int projectId) async {
    final result = await _call('removeProject', {'project_id': projectId});
    return result == true || result.toString() == 'true';
  }

  // ---- Board / Columns ----

  Future<Map<String, dynamic>> getBoard(int projectId) async {
    final result = await _call('getBoard', {'project_id': projectId});
    return result as Map<String, dynamic>;
  }

  Future<List<BoardColumn>> getColumns(int projectId) async {
    final result =
        await _call('getColumns', {'project_id': projectId}) as List<dynamic>? ?? [];
    return result
        .map((c) => BoardColumn.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ---- Tasks ----

  Future<Task> getTask(int taskId) async {
    final result = await _call('getTask', {'task_id': taskId});
    return Task.fromJson(result as Map<String, dynamic>);
  }

  Future<List<Task>> getAllTasks(int projectId, {int statusId = 1}) async {
    final result = await _call('getAllTasks', {
      'project_id': projectId,
      'status_id': statusId,
    }) as List<dynamic>? ?? [];
    return result
        .map((t) => Task.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<int> createTask({
    required int projectId,
    required String title,
    int? columnId,
    int? swimlaneId,
    String description = '',
    DateTime? dateDue,
  }) async {
    final result = await _call('createTask', {
      'project_id': projectId,
      'title': title,
      if (columnId != null) 'column_id': columnId,
      if (swimlaneId != null) 'swimlane_id': swimlaneId,
      'description': description,
      if (dateDue != null) 'date_due': _formatDateDue(dateDue),
    });
    return int.parse(result.toString());
  }

  Future<bool> updateTask({
    required int id,
    String? title,
    String? description,
    DateTime? dateDue,
  }) async {
    final result = await _call('updateTask', {
      'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dateDue != null) 'date_due': _formatDateDue(dateDue),
    });
    return result == true || result.toString() == 'true';
  }

  Future<bool> moveTaskPosition({
    required int taskId,
    required int projectId,
    required int columnId,
    required int position,
    int swimlaneId = 1,
  }) async {
    final result = await _call('moveTaskPosition', {
      'project_id': projectId,
      'task_id': taskId,
      'column_id': columnId,
      'position': position,
      'swimlane_id': swimlaneId,
    });
    return result == true || result.toString() == 'true';
  }

  /// Kanboard's JSON-RPC API has no `getOverdueTasks` method — overdue
  /// detection is a server-side cron/email feature, not exposed over RPC.
  /// This fetches open tasks for a project and returns only those that have
  /// a `date_due` set, for client-side deadline filtering.
  Future<List<Task>> getTasksWithDueDate(int projectId, {int statusId = 1}) async {
    final tasks = await getAllTasks(projectId, statusId: statusId);
    return tasks.where((t) => t.dateDue != null).toList();
  }

  void close() => _httpClient.close();
}
