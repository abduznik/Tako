// CLI test scenario for the notification/watchdog layer.
//
// Creates a temporary test project, creates a task due ~40s in the future,
// starts the WatchdogService, and waits for it to fire a "due_soon" and
// then an "overdue" notification for that task before exiting.
//
// Usage:
//   dart run bin/watchdog_cli.dart <baseUrl> <username> <password>

import 'dart:async';
import 'dart:io';

import 'package:tako/notifications/alert_store.dart';
import 'package:tako/notifications/notification_event.dart';
import 'package:tako/notifications/watchdog_service.dart';
import 'package:tako/providers/kanboard_provider.dart';
import 'package:tako/providers/provider_exceptions.dart';

void section(String title) {
  print('');
  print('=== $title ===');
}

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run bin/watchdog_cli.dart <baseUrl> <username> <password>',
    );
    exit(64);
  }

  final provider = KanboardProvider(
    baseUrl: args[0],
    username: args[1],
    password: args[2],
    profileName: 'Kanboard',
  );

  final completer = Completer<void>();
  var sawDueSoon = false;
  var sawOverdue = false;

  try {
    section('Setup');
    final projectName = 'Tako Watchdog Test ${DateTime.now().toIso8601String()}';
    final projectId = await provider.createProject(projectName);
    print('Created project "$projectName" with id $projectId');

    final columns = await provider.getColumns(projectId);
    final firstColumnId = columns.isNotEmpty ? columns.first.id : null;

    // Due soon (< 5 min window) immediately, overdue ~40s from now.
    final dueDate = DateTime.now().add(const Duration(seconds: 40));
    final taskId = await provider.createTask(
      projectId: projectId,
      title: 'Watchdog Test Task',
      columnId: firstColumnId,
      description: 'Created by watchdog_cli.dart to validate deadline notifications.',
      dateDue: dueDate,
    );
    print('Created task $taskId with due date $dueDate (local)');

    section('Starting watchdog (polling every 5s for this test)');
    final alertStore = AlertStore('.tako/alert_history.json');
    final watchdog = WatchdogService(
      provider: provider,
      projectIds: [projectId],
      pollInterval: const Duration(seconds: 5),
      dueSoonWindow: const Duration(minutes: 5),
      alertStore: alertStore,
      onEvent: (NotificationEvent event) {
        print(event);
        if (event.type == NotificationEventType.dueSoon) sawDueSoon = true;
        if (event.type == NotificationEventType.overdue) sawOverdue = true;
        if (sawDueSoon && sawOverdue && !completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (Object error) {
        print('⚠️  Poll error (will retry next interval): $error');
      },
    );
    await watchdog.start();

    // Safety timeout so the CLI scenario can't hang forever.
    await completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        print('');
        print('Timed out waiting for both due_soon and overdue events.');
      },
    );
    watchdog.stop();

    section('Result');
    print('due_soon fired: $sawDueSoon');
    print('overdue fired: $sawOverdue');

    if (sawDueSoon && sawOverdue) {
      print('Watchdog test scenario PASSED.');
    } else {
      stderr.writeln('Watchdog test scenario FAILED (missing expected events).');
      exit(1);
    }
  } on ProviderAuthException catch (e) {
    stderr.writeln('Kanboard auth error: $e');
    exit(1);
  } on ProviderConnectionException catch (e) {
    stderr.writeln('Kanboard connection error: $e');
    exit(1);
  } on ProviderException catch (e) {
    stderr.writeln('Kanboard API error: $e');
    exit(1);
  } finally {
    provider.dispose();
  }
}
