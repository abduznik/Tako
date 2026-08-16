class BoardColumn {
  final String id;
  final String title;
  final int position;
  final String projectId;
  final int taskLimit;

  BoardColumn({
    required this.id,
    required this.title,
    required this.position,
    required this.projectId,
    required this.taskLimit,
  });

  factory BoardColumn.fromJson(Map<String, dynamic> json) {
    return BoardColumn(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      position: int.parse(json['position'].toString()),
      projectId: json['project_id'].toString(),
      taskLimit: int.tryParse(json['task_limit']?.toString() ?? '') ?? 0,
    );
  }

  @override
  String toString() =>
      'BoardColumn(id: $id, title: "$title", position: $position)';
}
