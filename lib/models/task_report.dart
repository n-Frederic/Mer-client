// lib/models/task_report.dart
import 'dart:convert';

class TaskReport {
  final String id;
  final String taskId;
  final String content;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> attachments; // 改为列表存储多个附件
  final DateTime createdAt;
  final String createdBy;
  final String? reporterName;

  TaskReport({
    required this.id,
    required this.taskId,
    required this.content,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.attachments,
    required this.createdAt,
    required this.createdBy,
    this.reporterName,
  });

  factory TaskReport.fromJson(Map<String, dynamic> json) {
    // 处理附件字段，支持字符串数组或JSON字符串
    List<String> attachments = [];
    if (json['attachments'] != null) {
      if (json['attachments'] is String) {
        try {
          final List<dynamic> attachmentList = jsonDecode(json['attachments']);
          attachments = attachmentList.map((e) => e.toString()).toList();
        } catch (e) {
          attachments = [json['attachments']];
        }
      } else if (json['attachments'] is List) {
        attachments = (json['attachments'] as List).map((e) => e.toString()).toList();
      }
    }

    return TaskReport(
      id: json['report_id']?.toString() ?? json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      content: json['content'] ?? '',
      latitude: (json['latitude'] is String)
          ? double.tryParse(json['latitude']) ?? 0.0
          : (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] is String)
          ? double.tryParse(json['longitude']) ?? 0.0
          : (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      attachments: attachments,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      createdBy: json['reporter_id']?.toString() ?? json['created_by'] ?? '',
      reporterName: json['reporter_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'content': content,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'attachments': jsonEncode(attachments),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'reporter_name': reporterName,
    };
  }
}