enum SubtaskStatus { todo, inProgress, done }

class Subtask {
  final String id;
  final String taskId;
  final String title;
  final SubtaskStatus status;
  final int position;

  Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.status,
    required this.position,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'].toString(),
      taskId: json['task_id'].toString(),
      title: json['title']?.toString() ?? '',
      status: statusFromInt(int.tryParse(json['status']?.toString() ?? '') ?? 0),
      position: int.tryParse(json['position']?.toString() ?? '') ?? 0,
    );
  }

  static SubtaskStatus statusFromInt(int value) {
    switch (value) {
      case 1:
        return SubtaskStatus.inProgress;
      case 2:
        return SubtaskStatus.done;
      default:
        return SubtaskStatus.todo;
    }
  }

  static int statusToInt(SubtaskStatus status) {
    switch (status) {
      case SubtaskStatus.todo:
        return 0;
      case SubtaskStatus.inProgress:
        return 1;
      case SubtaskStatus.done:
        return 2;
    }
  }
}
