class Task {
  final int id;
  final String title;
  final int projectId;
  final int columnId;
  final int swimlaneId;
  final int position;
  final int colorId;
  final String description;
  final DateTime? dateDue;

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
  });

  /// Kanboard returns `date_due` as Unix epoch seconds (0 means "not set").
  static DateTime? _parseEpochSeconds(dynamic value) {
    if (value == null) return null;
    final seconds = int.tryParse(value.toString());
    if (seconds == null || seconds == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? '',
      projectId: int.parse(json['project_id'].toString()),
      columnId: int.parse(json['column_id'].toString()),
      swimlaneId: int.parse(json['swimlane_id'].toString()),
      position: int.parse(json['position'].toString()),
      colorId: int.tryParse(json['color_id']?.toString() ?? '') ?? 0,
      description: json['description']?.toString() ?? '',
      dateDue: _parseEpochSeconds(json['date_due']),
    );
  }

  @override
  String toString() =>
      'Task(id: $id, title: "$title", projectId: $projectId, columnId: $columnId, position: $position, dateDue: $dateDue)';
}
