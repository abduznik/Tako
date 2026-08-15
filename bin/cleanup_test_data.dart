// Removes projects created by tako_cli.dart / watchdog_cli.dart test runs
// (those named with the "Tako CLI Test " / "Tako Watchdog Test " prefixes
// used by those scripts), so repeated test runs don't accumulate clutter
// on a real Kanboard instance.
//
// Usage:
//   dart run bin/cleanup_test_data.dart <baseUrl> <username> <password> [--dry-run]

import 'dart:io';

import 'package:tako/api/jsonrpc_exception.dart';
import 'package:tako/api/kanboard_client.dart';

const _testProjectPrefixes = ['Tako CLI Test ', 'Tako Watchdog Test '];

Future<void> main(List<String> args) async {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final dryRun = args.contains('--dry-run');

  if (positional.length != 3) {
    stderr.writeln(
      'Usage: dart run bin/cleanup_test_data.dart <baseUrl> <username> <password> [--dry-run]',
    );
    exit(64);
  }

  final client = KanboardClient(
    baseUrl: positional[0],
    username: positional[1],
    password: positional[2],
  );

  try {
    final projects = await client.getAllProjects();
    final toRemove = projects
        .where((p) => _testProjectPrefixes.any((prefix) => p.name.startsWith(prefix)))
        .toList();

    if (toRemove.isEmpty) {
      print('No test projects found. Nothing to clean up.');
      return;
    }

    print('Found ${toRemove.length} test project(s):');
    for (final p in toRemove) {
      print('  $p');
    }

    if (dryRun) {
      print('');
      print('--dry-run: not removing anything.');
      return;
    }

    print('');
    for (final p in toRemove) {
      final ok = await client.removeProject(p.id);
      print('${ok ? 'Removed' : 'FAILED to remove'} project ${p.id} ("${p.name}")');
    }
  } on KanboardApiException catch (e) {
    stderr.writeln('Kanboard API error: $e');
    exit(1);
  } on KanboardHttpException catch (e) {
    stderr.writeln('HTTP/transport error: $e');
    exit(1);
  } finally {
    client.close();
  }
}
