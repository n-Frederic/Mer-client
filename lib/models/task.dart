enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  final String sqlValue;
  const TaskPriority(this.sqlValue);

  static TaskPriority fromString(String value) {
    return values.firstWhere(
          (e) => e.sqlValue == value,
      orElse: () => TaskPriority.low,
    );
  }
}

enum TaskStatus {
  published('Published'),
  assigned('Assigned'),
  inProgress('InProgress'),
  reported('Reported'),
  completed('Completed'),
  closed('Closed');

  final String sqlValue;
  const TaskStatus(this.sqlValue);

  static TaskStatus fromString(String value) {
    return values.firstWhere(
          (e) => e.sqlValue == value,
      orElse: () => TaskStatus.published,
    );
  }
}

class Task {
  final String taskId;
  final String title;
  final String description;
  final String creatorId;

  final TaskPriority priority;
  final TaskStatus status;

  final DateTime? startAt;
  final DateTime? dueAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.taskId,
    required this.title,
    this.description = '',
    required this.creatorId,
    required this.priority,
    required this.status,
    this.startAt,
    this.dueAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final creatorJson = json['creator'] as Map<String, dynamic>?;
    final creatorId = creatorJson?['id']?.toString() ?? '0';

    return Task(
      taskId: json['taskId'].toString(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      creatorId: creatorId,

      priority: TaskPriority.fromString(json['priority'] as String),
      status: TaskStatus.fromString(json['status'] as String),

      startAt: json['startAt'] != null ? DateTime.parse(json['startAt']) : null,
      dueAt: json['dueAt'] != null ? DateTime.parse(json['dueAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'task_id': taskId,
    'title': title,
    'description': description,
    'creator_id': creatorId,

    'priority': priority.sqlValue,
    'status': status.sqlValue,

    'start_at': startAt?.toIso8601String(),
    'due_at': dueAt?.toIso8601String(),
  };
}