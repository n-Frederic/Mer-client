// lib/models/task_report.dart
import 'dart:convert';

class TaskReport {
  final int reportId;
  final int taskId;
  final int reporterId;
  final String content;
  final String address;
  final List<String> attachments;
  final DateTime createdAt;

  TaskReport({
    required this.reportId,
    required this.taskId,
    required this.reporterId,
    required this.content,
    required this.address,
    required this.attachments,
    required this.createdAt,
  });

  factory TaskReport.fromJson(Map<String, dynamic> json) {
    // 处理 attachments 字段，可能是 JSON 字符串或列表
    List<String> attachments = [];
    if (json['attachments'] != null) {
      if (json['attachments'] is String) {
        try {
          final List<dynamic> attachmentsJson = jsonDecode(json['attachments']);
          attachments = attachmentsJson.map((item) => item.toString()).toList();
        } catch (e) {
          // 如果解析失败，当作单个字符串处理
          attachments = [json['attachments']];
        }
      } else if (json['attachments'] is List) {
        attachments = (json['attachments'] as List).map((item) => item.toString()).toList();
      }
    }

    return TaskReport(
      reportId: int.parse(json['report_id']?.toString() ?? '0'),
      taskId: int.parse(json['task_id']?.toString() ?? '0'),
      reporterId: int.parse(json['reporter_id']?.toString() ?? '0'),
      content: json['content'] ?? '',
      address: json['address'] ?? '',
      attachments: attachments,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'task_id': taskId,
      'reporter_id': reporterId,
      'content': content,
      'address': address,
      'attachments': jsonEncode(attachments),
      'created_at': createdAt.toIso8601String(),
    };
  }
}