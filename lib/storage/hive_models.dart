import 'package:hive/hive.dart';

part 'hive_models.g.dart';

/// Metadata for a saved connection profile. The actual password is never
/// stored here — see [SecureCredentialStore] — only whether one is saved.
@HiveType(typeId: 0)
class ConnectionProfileHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String baseUrl;

  @HiveField(3)
  String username;

  @HiveField(4)
  bool rememberMe;

  @HiveField(5)
  bool hasSavedPassword;

  ConnectionProfileHive({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.username,
    required this.rememberMe,
    required this.hasSavedPassword,
  });
}

/// A locally-created project, used in standalone (no-provider) mode.
@HiveType(typeId: 1)
class LocalProjectHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  bool isActive;

  LocalProjectHive({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });
}

/// A locally-created column, used in standalone (no-provider) mode.
@HiveType(typeId: 2)
class LocalColumnHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  String title;

  @HiveField(3)
  int position;

  @HiveField(4)
  int taskLimit;

  LocalColumnHive({
    required this.id,
    required this.projectId,
    required this.title,
    required this.position,
    required this.taskLimit,
  });
}

/// A locally-created task, used in standalone (no-provider) mode.
@HiveType(typeId: 3)
class LocalTaskHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  String columnId;

  @HiveField(3)
  String swimlaneId;

  @HiveField(4)
  String title;

  @HiveField(5)
  String description;

  @HiveField(6)
  int position;

  @HiveField(7)
  String colorId;

  @HiveField(8)
  DateTime? dateDue;

  @HiveField(9)
  String? ownerId;

  @HiveField(10)
  int priority;

  @HiveField(11)
  DateTime? dateCreation;

  LocalTaskHive({
    required this.id,
    required this.projectId,
    required this.columnId,
    required this.swimlaneId,
    required this.title,
    required this.description,
    required this.position,
    required this.colorId,
    this.dateDue,
    this.ownerId,
    this.priority = 0,
    this.dateCreation,
  });
}

/// A locally-created subtask, used in standalone (no-provider) mode.
@HiveType(typeId: 5)
class LocalSubtaskHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  String title;

  @HiveField(3)
  int status;

  @HiveField(4)
  int position;

  LocalSubtaskHive({
    required this.id,
    required this.taskId,
    required this.title,
    required this.status,
    required this.position,
  });
}

/// A locally-created comment, used in standalone (no-provider) mode.
@HiveType(typeId: 6)
class LocalCommentHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime dateCreation;

  LocalCommentHive({
    required this.id,
    required this.taskId,
    required this.content,
    required this.dateCreation,
  });
}

/// A locally-created external link, used in standalone (no-provider) mode.
@HiveType(typeId: 7)
class LocalExternalLinkHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String url;

  LocalExternalLinkHive({
    required this.id,
    required this.taskId,
    required this.title,
    required this.url,
  });
}

/// A locally-attached file, used in standalone (no-provider) mode. The
/// content is stored as a base64 blob directly in Hive — simplest option
/// for local-only usage, matching how Kanboard itself transports files.
@HiveType(typeId: 8)
class LocalAttachmentHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  String name;

  @HiveField(3)
  bool isImage;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String base64Blob;

  LocalAttachmentHive({
    required this.id,
    required this.taskId,
    required this.name,
    required this.isImage,
    required this.date,
    required this.base64Blob,
  });
}

/// A cached snapshot of the last-synced data from a remote provider, so the
/// dashboard has something to show while offline. Stored as loosely-typed
/// JSON-ish maps rather than provider-specific types, since the cache just
/// needs to round-trip through [Project.fromJson]-shaped data.
@HiveType(typeId: 4)
class CachedProviderDataHive extends HiveObject {
  @HiveField(0)
  String profileId;

  @HiveField(1)
  List<Map<dynamic, dynamic>> projects;

  @HiveField(2)
  DateTime lastSyncedAt;

  CachedProviderDataHive({
    required this.profileId,
    required this.projects,
    required this.lastSyncedAt,
  });
}
