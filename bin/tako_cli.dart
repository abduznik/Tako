// Plain-Dart CLI runner that exercises KanboardClient end to end against a
// live Kanboard instance. No Flutter dependencies.
//
// Usage:
//   dart run bin/tako_cli.dart <baseUrl> <username> <password>
//
// Example:
//   dart run bin/tako_cli.dart https://kanboard.example.com/jsonrpc.php admin admin

import 'dart:io';

import 'package:tako/api/jsonrpc_exception.dart';
import 'package:tako/api/kanboard_client.dart';

void section(String title) {
  print('');
  print('=== $title ===');
}

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run bin/tako_cli.dart <baseUrl> <username> <password>',
    );
    exit(64);
  }

  final baseUrl = args[0];
  final username = args[1];
  final password = args[2];

  final client = KanboardClient(
    baseUrl: baseUrl,
    username: username,
    password: password,
  );

  try {
    section('getMyProjects');
    final myProjects = await client.getMyProjects();
    if (myProjects.isEmpty) {
      print('(no projects visible to this user)');
    } else {
      for (final p in myProjects) {
        print(p);
      }
    }

    section('createProject');
    final projectName = 'Tako CLI Test ${DateTime.now().toIso8601String()}';
    final newProjectId = await client.createProject(projectName);
    print('Created project "$projectName" with id $newProjectId');

    section('getColumns');
    final columns = await client.getColumns(newProjectId);
    for (final c in columns) {
      print(c);
    }
    if (columns.length < 2) {
      print(
        'Warning: fewer than 2 columns on new project; moveTaskPosition demo may be a no-op.',
      );
    }

    section('createTask');
    final firstColumnId = columns.isNotEmpty ? columns.first.id : null;
    final newTaskId = await client.createTask(
      projectId: newProjectId,
      title: 'Tako CLI Test Task',
      columnId: firstColumnId,
      description: 'Created by tako_cli.dart to validate the API layer.',
    );
    print('Created task with id $newTaskId');

    section('getTask (after create)');
    final createdTask = await client.getTask(newTaskId);
    print(createdTask);

    section('getAllTasks');
    final allTasks = await client.getAllTasks(newProjectId);
    for (final t in allTasks) {
      print(t);
    }

    if (columns.length >= 2) {
      section('moveTaskPosition');
      final targetColumn = columns[1];
      final moved = await client.moveTaskPosition(
        taskId: newTaskId,
        projectId: newProjectId,
        columnId: targetColumn.id,
        position: 1,
      );
      print('moveTaskPosition returned: $moved');

      section('getTask (after move)');
      final movedTask = await client.getTask(newTaskId);
      print(movedTask);
      if (movedTask.columnId == targetColumn.id) {
        print('Confirmed: task moved to column ${targetColumn.id}');
      } else {
        print(
          'Warning: task columnId is ${movedTask.columnId}, expected ${targetColumn.id}',
        );
      }
    } else {
      section('moveTaskPosition');
      print('Skipped: project does not have at least 2 columns.');
    }

    section('Done');
    print('All calls completed successfully.');
  } on KanboardApiException catch (e) {
    stderr.writeln('');
    stderr.writeln('Kanboard API returned an error:');
    stderr.writeln('  $e');
    exit(1);
  } on KanboardHttpException catch (e) {
    stderr.writeln('');
    stderr.writeln('HTTP/transport error talking to Kanboard:');
    stderr.writeln('  $e');
    exit(1);
  } catch (e) {
    stderr.writeln('');
    stderr.writeln('Unexpected error:');
    stderr.writeln('  $e');
    exit(1);
  } finally {
    client.close();
  }
}
