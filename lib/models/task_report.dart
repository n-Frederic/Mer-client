// lib/models/task_report.dart
import 'dart:convert';

class TaskReport {
  final String id;
  final String taskId;
  final String content;
  final String address;
  final List<String> attachments;
  final DateTime createdAt;
  final String createdBy;
  final String? reporterName;
  final ReportStatus status;
  final String? rejectReason;

  // 新增审批相关字段
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;

  TaskReport({
    required this.id,
    required this.taskId,
    required this.content,
    required this.address,
    required this.attachments,
    required this.createdAt,
    required this.createdBy,
    this.reporterName,
    required this.status,
    this.rejectReason,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
  });

  factory TaskReport.fromJson(Map<String, dynamic> json) {
    // 处理附件字段
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

    // 处理状态字段
    ReportStatus status = ReportStatus.submitted;
    if (json['status'] != null) {
      try {
        status = ReportStatus.values.firstWhere(
              (e) => e.value == json['status'],
          orElse: () => ReportStatus.submitted,
        );
      } catch (e) {
        status = ReportStatus.submitted;
      }
    }

    // 处理日期字段
    DateTime? parseDateTime(dynamic dateValue) {
      if (dateValue == null) return null;
      try {
        return DateTime.parse(dateValue.toString());
      } catch (e) {
        return null;
      }
    }

    return TaskReport(
      id: json['report_id']?.toString() ?? json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      content: json['content'] ?? '',
      address: json['address'] ?? '',
      attachments: attachments,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      createdBy: json['reporter_id']?.toString() ?? json['created_by'] ?? '',
      reporterName: json['reporter_name'] ?? '',
      status: status,
      rejectReason: json['reject_reason'],

      // 新增审批字段
      approvedBy: json['approved_by']?.toString(),
      approvedAt: parseDateTime(json['approved_at']),
      rejectedBy: json['rejected_by']?.toString(),
      rejectedAt: parseDateTime(json['rejected_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'content': content,
      'address': address,
      'attachments': jsonEncode(attachments),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'reporter_name': reporterName,
      'status': status.value,
      'reject_reason': rejectReason,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_by': rejectedBy,
      'rejected_at': rejectedAt?.toIso8601String(),
    };
  }

  // 添加一个便捷方法，用于创建新的已审批报告
  TaskReport copyWithApproved({required String approvedBy, DateTime? approvedAt}) {
    return TaskReport(
      id: id,
      taskId: taskId,
      content: content,
      address: address,
      attachments: attachments,
      createdAt: createdAt,
      createdBy: createdBy,
      reporterName: reporterName,
      status: ReportStatus.approved,
      rejectReason: rejectReason,
      approvedBy: approvedBy,
      approvedAt: approvedAt ?? DateTime.now(),
      rejectedBy: rejectedBy,
      rejectedAt: rejectedAt,
    );
  }

  // 添加一个便捷方法，用于创建新的已拒绝报告
  TaskReport copyWithRejected({
    required String rejectedBy,
    required String rejectReason,
    DateTime? rejectedAt
  }) {
    return TaskReport(
      id: id,
      taskId: taskId,
      content: content,
      address: address,
      attachments: attachments,
      createdAt: createdAt,
      createdBy: createdBy,
      reporterName: reporterName,
      status: ReportStatus.rejected,
      rejectReason: rejectReason,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      rejectedBy: rejectedBy,
      rejectedAt: rejectedAt ?? DateTime.now(),
    );
  }
}

enum ReportStatus {
  pending('pending', '待提交'),
  submitted('submitted', '已提交'),
  approved('approved', '已通过'),
  rejected('rejected', '已拒绝');

  final String value;
  final String description;

  const ReportStatus(this.value, this.description);
}