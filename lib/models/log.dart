class Log {
  // 核心 ID
  final String logId;     // 对应 log_id (bigint, NO Null)
  final String userId;    // 对应 user_id (bigint, NO Null)
  final String? taskId;   // 对应 task_id (bigint, YES Null)

  // 核心内容
  final String title;     // 对应 title (varchar, NO Null)
  final String? content;  // 对应 content (text, YES Null)
  final String? summary;  // 对应 summary (varchar, YES Null)

  // 属性
  final DateTime logDate; // 对应 log_date (date, NO Null)
  final String viewType;  // 对应 view_type (enum, NO Null)
  final String? mood;     // 对应 mood (varchar, YES Null)

  // 时间戳
  final DateTime createdAt; // 对应 created_at (datetime, NO Null)
  final DateTime updatedAt; // 对应 updated_at (datetime, NO Null)

  // (我们忽略了那个重复的 'date' (varchar) 字段，因为它似乎是 'log_date' 的错误副本)

  Log({
    required this.logId,
    required this.userId,
    this.taskId,
    required this.title,
    this.content,
    this.summary,
    required this.logDate,
    required this.viewType,
    this.mood,
    required this.createdAt,
    required this.updatedAt,
  });

  // 辅助函数，用于安全解析日期
  static DateTime _parseDateTime(String? dateStr) {
    // 假设非空日期总是有效的
    return DateTime.parse(dateStr!);
  }

  static DateTime? _parseNullableDateTime(String? dateStr) {
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  // 工厂构造函数，用于从 API (JSON) 创建 Log 对象
  // 假设 JSON 键与数据库字段名 (snake_case) 一致
  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      logId: json['log_id'].toString(),
      userId: json['user_id'].toString(),
      taskId: json['task_id']?.toString(),

      title: json['title'] as String,
      content: json['content'] as String?,
      summary: json['summary'] as String?,

      // 'log_date' 是 Date 类型 (YYYY-MM-DD)， 'created_at' 是 Datetime
      logDate: _parseDateTime(json['log_date']),
      viewType: json['view_type'] as String,
      mood: json['mood'] as String?,

      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }
}