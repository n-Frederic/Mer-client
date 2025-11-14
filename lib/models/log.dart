import 'dart:convert';

// 【新增】此类用于解析 "related_tasks" 数组中的对象
class RelatedTask {
  final int taskId;
  final String title;

  RelatedTask({required this.taskId, required this.title});

  factory RelatedTask.fromJson(Map<String, dynamic> json) {
    return RelatedTask(
      // 确保从正确的键名 "task_id" 和 "title" 读取
      taskId: json['task_id'] as int? ?? 0,
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
  final List<RelatedTask> relatedTasks; // <-- 【新增】

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
    required this.relatedTasks, // <-- 【新增】
    required this.createdAt,
    required this.updatedAt,
  });

  // (辅助函数 _parseDateTime 和 _parseTaskIds 保持不变)
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }
    if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        dateValue > 1000000000000 ? dateValue : dateValue * 1000,
      );
    }
    if (dateValue is String) {
      // 【修正】增加对空字符串的判断
      if (dateValue.isEmpty) return DateTime.now();
      return DateTime.parse(dateValue);
    }
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
      logId: (json['log_id'] ?? json['logId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      taskIds: _parseTaskIds(json['task_id'] ?? json['taskId']),
      logDate: _parseDateTime(json['log_date'] ?? json['logDate']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),

      todaySummary: json['todaySummary']?.toString() ?? json['today_summary']?.toString(), // (同时支持两种命名)
      tomorrowPlan: json['tomorrowPlan']?.toString() ?? json['tomorrow_plan']?.toString(),
      helpNeeded: json['helpNeeded']?.toString() ?? json['help_needed']?.toString(),

      status: json['status']?.toString(),

      tags: (json['tags'] as List<dynamic>?)
          ?.map((t) => t.toString())
          .toList() ?? [],

      // 【新增】添加这一行来解析 related_tasks
      relatedTasks: (json['related_tasks'] as List? ?? [])
          .map((taskJson) => RelatedTask.fromJson(taskJson as Map<String, dynamic>))
          .toList(),
    );
  }
}