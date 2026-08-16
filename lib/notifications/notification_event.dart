enum NotificationEventType { overdue, dueSoon }

class NotificationEvent {
  final String taskId;
  final String projectId;
  final String taskTitle;
  final String projectName;
  final DateTime dueDate;
  final NotificationEventType type;
  final DateTime firedAt;

  NotificationEvent({
    required this.taskId,
    required this.projectId,
    required this.taskTitle,
    required this.projectName,
    required this.dueDate,
    required this.type,
    DateTime? firedAt,
  }) : firedAt = firedAt ?? DateTime.now();

  String get label => type == NotificationEventType.overdue ? 'OVERDUE' : 'DUE_SOON';

  String get icon => '🔔';

  String describeRelativeDue() {
    final diff = DateTime.now().difference(dueDate);
    if (type == NotificationEventType.overdue) {
      return 'was due ${_humanizeDuration(diff)} ago';
    }
    return 'is due in ${_humanizeDuration(-diff)}';
  }

  static String _humanizeDuration(Duration d) {
    final abs = d.abs();
    if (abs.inMinutes < 1) return '${abs.inSeconds}s';
    if (abs.inHours < 1) return '${abs.inMinutes}m';
    if (abs.inDays < 1) return '${abs.inHours}h ${abs.inMinutes.remainder(60)}m';
    return '${abs.inDays}d ${abs.inHours.remainder(24)}h';
  }

  @override
  String toString() =>
      '$icon [$label] Task "$taskTitle" in project "$projectName" ${describeRelativeDue()}';
}
