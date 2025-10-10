enum LogMood {
  excellent('excellent'),
  good('good'),
  normal('normal'),
  bad('bad');

  // 用于与后端数据库的字符串值进行映射
  final String sqlValue;
  const LogMood(this.sqlValue);

  // 辅助方法：从后端字符串快速获取枚举
  static LogMood fromString(String value) {
    return values.firstWhere(
          (e) => e.sqlValue == value,
      orElse: () => LogMood.normal,
    );
  }
}

class LogEntry {
  // 核心字段，前端使用小驼峰命名
  final String logId;
  final String userId;       // 记录作者
  final String? taskId;      // 可关联任务ID (可空)

  final String title;
  final String content;
  final DateTime logDate;    // 日志日期
  final LogMood mood;
  final List<String> tags;   // 关键词列表 (对应 LogKeyword 关联表)

  // 数据库自动生成的时间戳
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LogEntry({
    required this.logId,
    required this.userId,
    this.taskId,
    required this.title,
    required this.content,
    required this.logDate,
    required this.mood,
    required this.tags,
    this.createdAt,
    this.updatedAt,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      // 映射 log_id (BIGINT -> String)
      logId: json['log_id'].toString(),
      userId: json['user_id'].toString(),
      taskId: json['task_id']?.toString(),

      title: json['title'] as String,
      content: json['content'] as String,

      // log_date 假设后端返回日期字符串
      logDate: DateTime.parse(json['log_date']),

      // 枚举映射：将后端字符串转换为 Dart 枚举
      mood: LogMood.fromString(json['mood'] as String),

      // 假设 tags 字段包含一个字符串列表 (后端可能需要特殊处理 LogKeyword 表)
      tags: List<String>.from(json['tags'] ?? []),

      // 时间戳
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    // 字段名映射回后端所需的 snake_case
    'log_id': logId,
    'user_id': userId,
    'task_id': taskId,
    'title': title,
    'content': content,

    // 日期只发送日期部分 (YYYY-MM-DD)
    'log_date': logDate.toIso8601String().substring(0, 10),

    // 枚举映射：将 Dart 枚举转换为后端需要的字符串
    'mood': mood.sqlValue,
    'tags': tags,

    // 创建/更新时一般不需要发送这些时间戳
  };
}