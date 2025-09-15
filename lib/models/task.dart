enum TaskPriority { low, medium, high }
enum TaskStatus { pending, inProgress, completed }

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final String assignee;
  final DateTime dueDate;
  final double progress;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.assignee,
    required this.dueDate,
    required this.progress,
  });
}
