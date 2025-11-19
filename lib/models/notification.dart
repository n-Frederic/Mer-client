import 'dart:convert';

class NotificationItem {
  final String id;        // 对应 notif_id
  final String type;      // 对应 type
  final String title;     // 对应 title
  final String message;   // 对应 body
  final String ownerId;   // 对应 relevent_id (注意拼写)
  final bool isRead;      // 对应 is_read
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.ownerId,
    required this.isRead,
    required this.createdAt,
  });

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) { return DateTime.now(); }
    }
    return DateTime.now();
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      // 【适配】notif_id
      id: (json['notif_id'] ?? json['notification_id'] ?? '').toString(),

      type: json['type'] as String? ?? 'unknown',
      title: json['title'] as String? ?? '无标题',

      // 【适配】body -> message
      message: json['body'] as String? ?? json['message'] as String? ?? '',

      // 【适配】relevent_id (后端拼写) -> ownerId
      ownerId: (json['relevent_id'] ?? json['relevant_id'] ?? '').toString(),

      // 【适配】is_read (0/1 或 boolean)
      isRead: (json['is_read'] == 1 || json['is_read'] == true),

      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }
}

class NotificationListResponse {
  final List<NotificationItem> notifications;
  final int total;

  NotificationListResponse({
    required this.notifications,
    required this.total,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    // 适配你的 { "data": { "list": [...] }, "ok": true } 结构
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final List<dynamic> jsonList = data['list'] ?? [];

    final notifications = jsonList
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return NotificationListResponse(
      notifications: notifications,
      total: data['total'] as int? ?? 0,
    );
  }
}