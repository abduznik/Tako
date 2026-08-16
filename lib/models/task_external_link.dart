class TaskExternalLink {
  final String id;
  final String taskId;
  final String title;
  final String url;

  TaskExternalLink({
    required this.id,
    required this.taskId,
    required this.title,
    required this.url,
  });

  factory TaskExternalLink.fromJson(Map<String, dynamic> json) {
    return TaskExternalLink(
      id: json['id'].toString(),
      taskId: json['task_id'].toString(),
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}
