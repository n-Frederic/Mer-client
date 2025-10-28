// lib/models/task.dart

import 'user.dart';

// --- Enums (TaskPriority, TaskStatus) 保持不变 ---
enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  final String sqlValue;
  const TaskPriority(this.sqlValue);

  static TaskPriority fromString(String? value) {
    return values.firstWhere(
          (e) => e.sqlValue == value,
      orElse: () => TaskPriority.medium,
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

  static TaskStatus fromString(String? value) {
    return values.firstWhere(
          (e) => e.sqlValue == value,
      orElse: () => TaskStatus.published,
    );
  }
}

// --- 【已修正】 Task 类 ---
class Task {
  final String taskId;
  final String title;
  final String description;
  final User? creator; // <-- 【修正】允许 creator 为空

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
    this.creator, // <-- 【修正】
    required this.priority,
    required this.status,
    this.startAt,
    this.dueAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {

    // 【修正】安全地解析 'creator' 对象
    final creatorData = json['creator'] as Map<String, dynamic>?;
    final User? creator = (creatorData != null)
        ? User.fromJson(creatorData)
        : null;

    return Task(
      taskId: json['taskId'].toString(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',

      creator: creator, // <-- 【修正】

      priority: TaskPriority.fromString(json['priority'] as String?),
      status: TaskStatus.fromString(json['status'] as String?),

      startAt: json['startAt'] != null ? DateTime.parse(json['startAt']) : null,
      dueAt: json['dueAt'] != null ? DateTime.parse(json['dueAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'creator': creator?.toJson(),
    'priority': priority.sqlValue,
    'status': status.sqlValue,
    'start_at': startAt?.toIso8601String(),
    'due_at': dueAt?.toIso8601String(),
  };
}