class TaskComment {
  final String id;
  final String taskId;
  final String content;
  final String authorName;
  final DateTime dateCreation;

  TaskComment({
    required this.id,
    required this.taskId,
    required this.content,
    required this.authorName,
    required this.dateCreation,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    final dateSeconds = int.tryParse(json['date_creation']?.toString() ?? '') ?? 0;
    final name = json['name']?.toString();
    final username = json['username']?.toString();
    return TaskComment(
      id: json['id'].toString(),
      taskId: json['task_id'].toString(),
      content: json['comment']?.toString() ?? '',
      authorName: (name != null && name.isNotEmpty) ? name : (username ?? 'Unknown'),
      dateCreation: dateSeconds > 0
          ? DateTime.fromMillisecondsSinceEpoch(dateSeconds * 1000)
          : DateTime.now(),
    );
  }
}
