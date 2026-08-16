class Task {
  final String id;
  final String title;
  final String projectId;
  final String columnId;
  final String swimlaneId;
  final int position;
  final String colorId;
  final String description;
  final DateTime? dateDue;
  final String? ownerId;
  final String? creatorId;
  final int priority;
  final bool isActive;
  final DateTime? dateCreation;
  final DateTime? dateStarted;
  final DateTime? dateModification;
  final DateTime? dateCompleted;

  Task({
    required this.id,
    required this.title,
    required this.projectId,
    required this.columnId,
    required this.swimlaneId,
    required this.position,
    required this.colorId,
    required this.description,
    this.dateDue,
    this.ownerId,
    this.creatorId,
    this.priority = 0,
    this.isActive = true,
    this.dateCreation,
    this.dateStarted,
    this.dateModification,
    this.dateCompleted,
  });

  /// Kanboard returns most date fields as Unix epoch seconds (0/null means
  /// "not set").
  static DateTime? _parseEpochSeconds(dynamic value) {
    if (value == null) return null;
    final seconds = int.tryParse(value.toString());
    if (seconds == null || seconds == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  static String? _parseNullableId(dynamic value) {
    final str = value?.toString();
    return (str != null && str.isNotEmpty && str != '0') ? str : null;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      projectId: json['project_id'].toString(),
      columnId: json['column_id'].toString(),
      swimlaneId: json['swimlane_id'].toString(),
      position: int.parse(json['position'].toString()),
      colorId: (json['color_id']?.toString().isNotEmpty ?? false)
          ? json['color_id'].toString()
          : 'yellow',
      description: json['description']?.toString() ?? '',
      dateDue: _parseEpochSeconds(json['date_due']),
      ownerId: _parseNullableId(json['owner_id']),
      creatorId: _parseNullableId(json['creator_id']),
      priority: int.tryParse(json['priority']?.toString() ?? '') ?? 0,
      isActive: json['is_active']?.toString() != '0',
      dateCreation: _parseEpochSeconds(json['date_creation']),
      dateStarted: _parseEpochSeconds(json['date_started']),
      dateModification: _parseEpochSeconds(json['date_modification']),
      dateCompleted: _parseEpochSeconds(json['date_completed']),
    );
  }

  @override
  String toString() =>
      'Task(id: $id, title: "$title", projectId: $projectId, columnId: $columnId, position: $position, dateDue: $dateDue)';
}
