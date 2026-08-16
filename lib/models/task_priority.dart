/// Kanboard's task priority is a plain integer with no fixed enum on the
/// wire; the default UI labels 0-3 as below.
class TaskPriority {
  static const labels = ['Low', 'Normal', 'High', 'Urgent'];

  static String labelFor(int value) {
    if (value < 0 || value >= labels.length) return 'Priority $value';
    return labels[value];
  }
}
