class TaskAttachment {
  final String id;
  final String taskId;
  final String name;
  final bool isImage;
  final int size;
  final DateTime date;

  TaskAttachment({
    required this.id,
    required this.taskId,
    required this.name,
    required this.isImage,
    required this.size,
    required this.date,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    final dateSeconds = int.tryParse(json['date']?.toString() ?? '') ?? 0;
    return TaskAttachment(
      id: json['id'].toString(),
      taskId: json['task_id'].toString(),
      name: json['name']?.toString() ?? '',
      isImage: json['is_image']?.toString() == '1',
      size: int.tryParse(json['size']?.toString() ?? '') ?? 0,
      date: dateSeconds > 0
          ? DateTime.fromMillisecondsSinceEpoch(dateSeconds * 1000)
          : DateTime.now(),
    );
  }
}
