// lib/models/task.dart

import 'user.dart';
import '../models/task_user.dart';

class TaskRelatedLog {
  final String logId;
  final String title;

  TaskRelatedLog({
    required this.logId,
    required this.title,
  });

  factory TaskRelatedLog.fromJson(Map<String, dynamic> json) {
    return TaskRelatedLog(
      logId: (json['log_id'] ?? json['logId'] ?? '').toString(),
      title: json['title']?.toString() ?? '未命名日志',
    );
  }
}

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
  published('Published'), //已发布
  reported('Reported'),  //已经提交
  completed('Completed'),  //已审核
  closed('Closed'); //完成

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
  final User? creator;

  final TaskPriority priority;
  final TaskStatus status;

  final DateTime? startAt;
  final DateTime? dueAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<TaskUser> assignees;
  final List<String> tags;
  final List<TaskRelatedLog> relatedLogs;

  Task({
    required this.taskId,
    required this.title,
    this.description = '',
    this.creator,
    required this.priority,
    required this.status,
    this.startAt,
    this.dueAt,
    this.createdAt,
    this.updatedAt,
    required this.assignees,
    required this.tags,
    this.relatedLogs = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {

    final creatorData = json['creator'] as Map<String, dynamic>?;
    final User? creator = (creatorData != null)
        ? User.fromJson(creatorData)
        : null;

    // 处理 assignees 字段
    List<TaskUser> assignees = [];
    if (json['assignees'] != null && json['assignees'] is List) {
      assignees = (json['assignees'] as List)
          .map((assigneeJson) => TaskUser.fromJson(assigneeJson))
          .toList();
    }


    // 处理 tags 字段
    List<String> tags = [];
    if (json['tags'] != null && json['tags'] is List) {
      tags = (json['tags'] as List).cast<String>();
    } else if (json['tags'] is String) {
      // 如果 tags 是逗号分隔的字符串
      final tagsString = json['tags'] as String;
      if (tagsString.isNotEmpty) {
        tags = tagsString.split(',').map((tag) => tag.trim()).toList();
      }
    }

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

      // 添加 assignees 和 tags 的初始化
      assignees: assignees,
      tags: tags,

      relatedLogs: (json['related_logs'] as List?)
          ?.map((logJson) => TaskRelatedLog.fromJson(logJson as Map<String, dynamic>))
          .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'title': title,
    'description': description,
    'creator': creator?.toJson(),
    'priority': priority.sqlValue,
    'status': status.sqlValue,
    'start_at': startAt?.toIso8601String(),
    'due_at': dueAt?.toIso8601String(),
    'assignees': assignees.map((assignee) => assignee.toJson()).toList(),
    'tags': tags,
    'related_logs': relatedLogs.map((log) => {
      'log_id': log.logId,
      'title': log.title,
    }).toList(),
  };
}