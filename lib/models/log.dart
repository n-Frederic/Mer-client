// lib/models/log.dart
import 'dart:convert';

class RelatedTask {
  final int taskId;
  final String title;

  RelatedTask({required this.taskId, required this.title});

  factory RelatedTask.fromJson(Map<String, dynamic> json) {
    return RelatedTask(
      // 确保从正确的键名 "task_id" 和 "title" 读取
      taskId: json['task_id'] as int,
      title: json['title'] as String? ?? '无标题任务',
    );
  }
}

class Log {
  final String logId;
  final String userId;
  final List<String> taskIds;
  final DateTime logDate;

  final String? todaySummary;
  final String? tomorrowPlan;
  final String? helpNeeded;
  final String? status;

  final List<String> tags;
  final List<RelatedTask> relatedTasks;

  final DateTime createdAt;
  final DateTime updatedAt;

  Log({
    required this.logId,
    required this.userId,
    this.taskIds = const [],
    required this.logDate,
    this.todaySummary,
    this.tomorrowPlan,
    this.helpNeeded,
    this.status,
    this.tags = const [],
    required this.relatedTasks,
    required this.createdAt,
    required this.updatedAt,
  });

  // 【修正】支持多种日期格式：String、int（时间戳）、null
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now(); // 如果为 null，返回当前时间
    }
    if (dateValue is int) {
      // 如果是时间戳（秒），转换为毫秒
      return DateTime.fromMillisecondsSinceEpoch(
        dateValue > 1000000000000 ? dateValue : dateValue * 1000,
      );
    }
    if (dateValue is String) {
      return DateTime.parse(dateValue);
    }
    // 如果都不匹配，返回当前时间
    return DateTime.now();
  }

  static List<String> _parseTaskIds(dynamic jsonField) {
    if (jsonField == null) return [];
    if (jsonField is List) {
      return jsonField.map((e) => e.toString()).toList();
    }
    if (jsonField is String) {
      try {
        final List<dynamic> list = json.decode(jsonField);
        return list.map((e) => e.toString()).toList();
      } catch (e) { return []; }
    }
    return [];
  }

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      // 【修正】确保所有 ID 字段都转换为 String
      logId: (json['log_id'] ?? json['logId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      taskIds: _parseTaskIds(json['task_id'] ?? json['taskId']),
      logDate: _parseDateTime(json['log_date'] ?? json['logDate']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      // 【修正】安全地转换字符串字段
      todaySummary: json['todaySummary']?.toString(),
      tomorrowPlan: json['tomorrowPlan']?.toString(),
      helpNeeded: json['helpNeeded']?.toString(),
      status: json['status']?.toString(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((t) => t.toString())
          .toList() ?? [],
      relatedTasks: (json['related_tasks'] as List? ?? [])
        .map((taskJson) => RelatedTask.fromJson(taskJson as Map<String, dynamic>))
        .toList(),
    );
  }
}