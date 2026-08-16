import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:tako/app/session.dart';
import 'package:tako/app/theme.dart';
import 'package:tako/app/theme_controller.dart';
import 'package:tako/screens/launch/get_started_screen.dart';
import 'package:tako/storage/app_storage.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String _dir;
  _FakePathProviderPlatform(this._dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir;

  @override
  Future<String?> getApplicationSupportPath() async => _dir;
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = await Directory.systemTemp.createTemp('tako_test_');
  PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);

  setUpAll(() async {
    await AppStorage.init();
  });

  tearDown(() async {
    await AppStorage.profiles.clear();
    await AppStorage.localProjects.clear();
    await AppStorage.localColumns.clear();
    await AppStorage.localTasks.clear();
    await AppStorage.settings.clear();
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Session()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp(
          theme: buildTakoLightTheme(),
          darkTheme: buildTakoDarkTheme(),
          themeMode: themeController.themeMode,
          home: const GetStartedScreen(),
        ),
      ),
    );
  }

  testWidgets('standalone flow: create project shows up on dashboard with column counts',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Continue standalone'), findsOneWidget);
    await tester.tap(find.text('Continue standalone'));
    await tester.pumpAndSettle();

    // Dashboard shows the empty state first.
    expect(find.text('No projects yet'), findsOneWidget);

    // Create a project via the "+" app bar action (disambiguated from the
    // empty-state "New project" button, which also uses Icons.add).
    await tester.tap(find.byTooltip('New project'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My Test Project');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Card appears with the default Kanboard-style columns, all zero-count.
    expect(find.text('My Test Project'), findsOneWidget);
    expect(find.textContaining('Backlog: 0'), findsOneWidget);
    expect(find.textContaining('Done: 0'), findsOneWidget);
  });

  testWidgets('login screen rejects invalid URL before attempting connection',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connect to Kanboard'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Server URL'), 'not a url');
    await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'admin');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'admin');
    await tester.tap(find.text('Connect'));
    await tester.pump();

    expect(find.textContaining('Enter a valid URL'), findsOneWidget);
  });

  testWidgets('theme defaults to dark and the toggle switches to light', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Continue standalone'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();

    final updatedApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(updatedApp.themeMode, ThemeMode.light);
    expect(find.byTooltip('Switch to dark theme'), findsOneWidget);
  });

  testWidgets('board screen loads a standalone project\'s columns and lets a task be added',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue standalone'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New project'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Board Test Project');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Board Test Project'));
    await tester.pumpAndSettle();

    // Default seeded columns render as board group headers.
    expect(find.text('Backlog'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Work in progress'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Add a task via a group footer's "Add task" control, which opens the
    // full new-task form screen.
    await tester.tap(find.text('Add task').first);
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'My board task');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('My board task'), findsOneWidget);
  });
}
