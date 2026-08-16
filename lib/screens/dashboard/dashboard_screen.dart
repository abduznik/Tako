import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session.dart';
import '../../app/theme_controller.dart';
import '../../models/board_column.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/project_card.dart';
import '../login/login_screen.dart';
import 'board_screen.dart';
import 'my_tasks_view.dart';
import 'new_project_dialog.dart';
import 'task_detail_screen.dart';

enum _NavSection { overview, myProjects, myTasks }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _NavSection _section = _NavSection.overview;

  List<Project> _projects = [];
  final Map<String, List<BoardColumn>> _columnsByProject = {};
  final Map<String, List<Task>> _tasksByProject = {};
  bool _isLoading = true;
  String? _loadError;
  int _lastSeenNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProjects());
    context.read<Session>().addListener(_onSessionChanged);
    _lastSeenNotificationCount = context.read<Session>().notifications.length;
  }

  @override
  void dispose() {
    context.read<Session>().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final notifications = context.read<Session>().notifications;
    if (notifications.length > _lastSeenNotificationCount && mounted) {
      final newest = notifications.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newest.toString()),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    _lastSeenNotificationCount = notifications.length;
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final provider = context.read<Session>().provider;
    try {
      final projects = await provider.getProjects();
      final columnsByProject = <String, List<BoardColumn>>{};
      final tasksByProject = <String, List<Task>>{};

      for (final project in projects) {
        columnsByProject[project.id] = await provider.getColumns(project.id);
        tasksByProject[project.id] = await provider.getTasks(project.id);
      }

      if (!mounted) return;
      setState(() {
        _projects = projects;
        _columnsByProject
          ..clear()
          ..addAll(columnsByProject);
        _tasksByProject
          ..clear()
          ..addAll(tasksByProject);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load projects: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createProject() async {
    final name = await showNewProjectDialog(context);
    if (name == null || name.isEmpty) return;
    if (!mounted) return;
    final provider = context.read<Session>().provider;
    await provider.createProject(name);
    await _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final isWide = MediaQuery.of(context).size.width >= 900;

    final destinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Overview'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder),
        label: Text('My Projects'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.check_circle_outline),
        selectedIcon: Icon(Icons.check_circle),
        label: Text('My Tasks'),
      ),
    ];

    final body = Column(
      children: [
        if (session.offlineBannerMessage != null)
          MaterialBanner(
            content: Text(session.offlineBannerMessage!),
            leading: const Icon(Icons.cloud_off_outlined),
            actions: [
              TextButton(
                onPressed: session.dismissOfflineBanner,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(child: _buildContent()),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.view_kanban, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Tako'),
          ],
        ),
        actions: [
          Consumer<ThemeController>(
            builder: (context, themeController, _) => IconButton(
              tooltip: themeController.isDark ? 'Switch to light theme' : 'Switch to dark theme',
              icon: Icon(themeController.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
              onPressed: themeController.toggle,
            ),
          ),
          const NotificationBell(),
          IconButton(
            tooltip: 'New project',
            icon: const Icon(Icons.add),
            onPressed: _createProject,
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) => _onAccountMenuSelected(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(session.provider.displayName),
              ),
              const PopupMenuDivider(),
              if (session.isStandalone)
                const PopupMenuItem(
                  value: 'connect',
                  child: Text('Connect to Kanboard'),
                )
              else
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Log out'),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                radius: 16,
                child: Text(_avatarInitial(session)),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    for (var i = 0; i < _NavSection.values.length; i++)
                      ListTile(
                        leading: destinations[i].icon,
                        title: (destinations[i].label as Text),
                        selected: _section.index == i,
                        onTap: () {
                          setState(() => _section = _NavSection.values[i]);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
            ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _section.index,
                  onDestinationSelected: (i) =>
                      setState(() => _section = _NavSection.values[i]),
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }

  String _avatarInitial(Session session) {
    final name = session.provider.displayName;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _onAccountMenuSelected(BuildContext context, String value) async {
    if (value == 'connect') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (value == 'logout') {
      await context.read<Session>().logOut();
      await _loadProjects();
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 40, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadProjects, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    switch (_section) {
      case _NavSection.overview:
      case _NavSection.myProjects:
        return _buildProjectsGrid();
      case _NavSection.myTasks:
        return _buildMyTasks();
    }
  }

  Widget _buildProjectsGrid() {
    if (_projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_outlined,
                  size: 40, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              const Text('No projects yet'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _createProject,
                icon: const Icon(Icons.add),
                label: const Text('New project'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisExtent: 220,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          return ProjectCard(
            project: project,
            columns: _columnsByProject[project.id] ?? const [],
            tasks: _tasksByProject[project.id] ?? const [],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BoardScreen(project: project),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyTasks() {
    return MyTasksView(
      tasksByProject: _tasksByProject,
      columnsByProject: _columnsByProject,
      projects: _projects,
      onOpenTask: (task, project) async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(
              taskId: task.id,
              columns: _columnsByProject[project.id] ?? const [],
            ),
          ),
        );
        await _loadProjects();
      },
    );
  }
}
