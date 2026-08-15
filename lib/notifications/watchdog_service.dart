import 'dart:async';

import '../api/jsonrpc_exception.dart';
import '../api/kanboard_client.dart';
import '../models/project.dart';
import 'alert_store.dart';
import 'notification_event.dart';

/// Polls Kanboard tasks for deadline-based events (overdue / due-soon) and
/// emits [NotificationEvent]s, deduped so the same task+type+due-date only
/// fires once.
///
/// Scope is either an explicit list of project IDs, or `null` to watch all
/// projects visible to the authenticated user (re-resolved every poll, so
/// newly created/removed projects are picked up automatically).
///
/// Network/API failures during a poll are logged via [onError] and do not
/// stop the watchdog — it simply retries on the next scheduled interval.
class WatchdogService {
  final KanboardClient client;
  final List<int>? projectIds;
  final Duration pollInterval;
  final Duration dueSoonWindow;
  final void Function(NotificationEvent event) onEvent;
  final void Function(Object error) onError;
  final AlertStore? alertStore;

  Timer? _timer;
  bool _polling = false;

  /// In-memory dedupe, always active. [alertStore] additionally persists
  /// this across restarts when provided.
  final Set<String> _alertedThisSession = {};

  final Map<int, String> _projectNames = {};

  WatchdogService({
    required this.client,
    required this.onEvent,
    this.projectIds,
    this.onError = _defaultOnError,
    this.alertStore,
    this.pollInterval = const Duration(seconds: 30),
    this.dueSoonWindow = const Duration(minutes: 5),
  });

  static void _defaultOnError(Object error) {
    // ignore: avoid_print
    print('⚠️  Watchdog poll error (will retry next interval): $error');
  }

  bool get isRunning => _timer != null;

  Future<void> start() async {
    if (_timer != null) return;
    await alertStore?.load();
    unawaited(_pollOnce());
    _timer = Timer.periodic(pollInterval, (_) => unawaited(_pollOnce()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pollOnce() async {
    if (_polling) return;
    _polling = true;
    try {
      final ids = projectIds ?? await _resolveAllProjectIds();
      final now = DateTime.now();

      for (final projectId in ids) {
        final projectName = await _resolveProjectName(projectId);
        final tasks = await client.getTasksWithDueDate(projectId);

        for (final task in tasks) {
          final due = task.dateDue;
          if (due == null) continue;

          NotificationEventType? type;
          if (due.isBefore(now)) {
            type = NotificationEventType.overdue;
          } else if (due.difference(now) <= dueSoonWindow) {
            type = NotificationEventType.dueSoon;
          }
          if (type == null) continue;

          final key = '${task.id}:${type.name}:${due.millisecondsSinceEpoch}';
          if (_alertedThisSession.contains(key)) continue;
          if (alertStore?.hasFired(key) ?? false) continue;
          _alertedThisSession.add(key);
          await alertStore?.markFired(key, now);

          onEvent(NotificationEvent(
            taskId: task.id,
            projectId: projectId,
            taskTitle: task.title,
            projectName: projectName,
            dueDate: due,
            type: type,
          ));
        }
      }
    } on KanboardApiException catch (e) {
      onError(e);
    } on KanboardHttpException catch (e) {
      onError(e);
    } catch (e) {
      onError(e);
    } finally {
      _polling = false;
    }
  }

  Future<List<int>> _resolveAllProjectIds() async {
    final projects = await client.getAllProjects();
    for (final p in projects) {
      _projectNames[p.id] = p.name;
    }
    return projects.map((p) => p.id).toList();
  }

  Future<String> _resolveProjectName(int projectId) async {
    final cached = _projectNames[projectId];
    if (cached != null) return cached;
    final projects = await client.getAllProjects();
    for (final Project p in projects) {
      _projectNames[p.id] = p.name;
    }
    return _projectNames[projectId] ?? 'Project #$projectId';
  }
}
