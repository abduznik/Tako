import 'package:hive_flutter/hive_flutter.dart';

import 'hive_models.dart';

/// Initializes Hive and exposes typed box accessors. Call [init] once at
/// app startup before touching any box getter.
class AppStorage {
  static const _profilesBoxName = 'connection_profiles';
  static const _settingsBoxName = 'app_settings';
  static const _localProjectsBoxName = 'local_projects';
  static const _localColumnsBoxName = 'local_columns';
  static const _localTasksBoxName = 'local_tasks';
  static const _localSubtasksBoxName = 'local_subtasks';
  static const _localCommentsBoxName = 'local_comments';
  static const _localExternalLinksBoxName = 'local_external_links';
  static const _localAttachmentsBoxName = 'local_attachments';
  static const _cacheBoxName = 'provider_cache';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    Hive.registerAdapter(ConnectionProfileHiveAdapter());
    Hive.registerAdapter(LocalProjectHiveAdapter());
    Hive.registerAdapter(LocalColumnHiveAdapter());
    Hive.registerAdapter(LocalTaskHiveAdapter());
    Hive.registerAdapter(LocalSubtaskHiveAdapter());
    Hive.registerAdapter(LocalCommentHiveAdapter());
    Hive.registerAdapter(LocalExternalLinkHiveAdapter());
    Hive.registerAdapter(LocalAttachmentHiveAdapter());
    Hive.registerAdapter(CachedProviderDataHiveAdapter());

    await Future.wait([
      Hive.openBox<ConnectionProfileHive>(_profilesBoxName),
      Hive.openBox(_settingsBoxName),
      Hive.openBox<LocalProjectHive>(_localProjectsBoxName),
      Hive.openBox<LocalColumnHive>(_localColumnsBoxName),
      Hive.openBox<LocalTaskHive>(_localTasksBoxName),
      Hive.openBox<LocalSubtaskHive>(_localSubtasksBoxName),
      Hive.openBox<LocalCommentHive>(_localCommentsBoxName),
      Hive.openBox<LocalExternalLinkHive>(_localExternalLinksBoxName),
      Hive.openBox<LocalAttachmentHive>(_localAttachmentsBoxName),
      Hive.openBox<CachedProviderDataHive>(_cacheBoxName),
    ]);

    _initialized = true;
  }

  static Box<ConnectionProfileHive> get profiles =>
      Hive.box<ConnectionProfileHive>(_profilesBoxName);

  static Box get settings => Hive.box(_settingsBoxName);

  static Box<LocalProjectHive> get localProjects =>
      Hive.box<LocalProjectHive>(_localProjectsBoxName);

  static Box<LocalColumnHive> get localColumns =>
      Hive.box<LocalColumnHive>(_localColumnsBoxName);

  static Box<LocalTaskHive> get localTasks =>
      Hive.box<LocalTaskHive>(_localTasksBoxName);

  static Box<LocalSubtaskHive> get localSubtasks =>
      Hive.box<LocalSubtaskHive>(_localSubtasksBoxName);

  static Box<LocalCommentHive> get localComments =>
      Hive.box<LocalCommentHive>(_localCommentsBoxName);

  static Box<LocalExternalLinkHive> get localExternalLinks =>
      Hive.box<LocalExternalLinkHive>(_localExternalLinksBoxName);

  static Box<LocalAttachmentHive> get localAttachments =>
      Hive.box<LocalAttachmentHive>(_localAttachmentsBoxName);

  static Box<CachedProviderDataHive> get providerCache =>
      Hive.box<CachedProviderDataHive>(_cacheBoxName);

  // ---- Convenience settings keys ----

  static const _lastActiveProfileIdKey = 'last_active_profile_id';

  static String? get lastActiveProfileId =>
      settings.get(_lastActiveProfileIdKey) as String?;

  static Future<void> setLastActiveProfileId(String? profileId) {
    return settings.put(_lastActiveProfileIdKey, profileId);
  }

  static const _dueSoonDaysKey = 'my_tasks_due_soon_days';
  static const defaultDueSoonDays = 3;

  static int get dueSoonDays =>
      (settings.get(_dueSoonDaysKey) as int?) ?? defaultDueSoonDays;

  static Future<void> setDueSoonDays(int days) {
    return settings.put(_dueSoonDaysKey, days);
  }
}
