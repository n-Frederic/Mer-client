enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  final String sqlValue;
  const TaskPriority(this.sqlValue);

  // 辅助方法：从后端字符串快速获取枚举
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

  // 辅助方法：从后端字符串快速获取枚举
  static TaskStatus fromString(String value) {
    return values.firstWhere(
          (e) => e.sqlValue == value,
      orElse: () => TaskStatus.published,
    );
  }
}

class Task {
  // 核心字段，前端使用小驼峰命名
  final String taskId;
  final String title;
  final String description;
  final String creatorId; // 创建人ID

  final TaskPriority priority;
  final TaskStatus status;

  // 时间字段
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
    return Task(
      // 映射 task_id (BIGINT -> String)
      taskId: json['task_id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      creatorId: json['creator_id'].toString(),

      // 枚举映射：将后端字符串映射为 Dart 枚举
      priority: TaskPriority.fromString(json['priority'] as String),
      status: TaskStatus.fromString(json['status'] as String),

      // 时间处理：将 ISO 8601 字符串转换为 DateTime 对象
      startAt: json['start_at'] != null ? DateTime.parse(json['start_at']) : null,
      dueAt: json['due_at'] != null ? DateTime.parse(json['due_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    // 字段名映射回后端所需的 snake_case
    'task_id': taskId,
    'title': title,
    'description': description,
    'creator_id': creatorId,

    // 枚举映射：将 Dart 枚举转换为后端需要的字符串
    'priority': priority.sqlValue,
    'status': status.sqlValue,

    // 时间字段转换为 ISO 8601 字符串
    'start_at': startAt?.toIso8601String(),
    'due_at': dueAt?.toIso8601String(),
  };
}