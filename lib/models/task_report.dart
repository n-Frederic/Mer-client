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
    // 处理附件字段 - 添加智能解析
    List<String> attachments = _parseAttachments(json['attachments']);

    print('📊 附件解析结果:');
    print('  原始数据: ${json['attachments']}');
    print('  解析后: $attachments');
    print('  数量: ${attachments.length}');

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

  /// 智能解析附件数据
  static List<String> _parseAttachments(dynamic attachmentsData) {
    if (attachmentsData == null) {
      return [];
    }

    print('🔍 解析附件数据: $attachmentsData');
    print('🔍 数据类型: ${attachmentsData.runtimeType}');

    // 1. 如果是字符串
    if (attachmentsData is String) {
      final str = attachmentsData.trim();

      // 空值检查
      if (str.isEmpty || str == '[]' || str == 'null' || str == '""') {
        return [];
      }

      // 情况1: 竖线分隔 (您数据库的格式)
      if (str.contains('|')) {
        final List<String> urls = str.split('|')
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList();
        print('✅ 竖线分隔解析: $urls');
        return urls;
      }

      // 情况2: JSON数组字符串
      if (str.startsWith('[') && str.endsWith(']')) {
        try {
          // 移除方括号
          var content = str.substring(1, str.length - 1);
          // 移除引号和空格
          content = content.replaceAll('"', '').replaceAll("'", '').trim();

          if (content.isEmpty) {
            return [];
          }

          // 按逗号分割
          final urls = content.split(',').map((url) => url.trim()).toList();
          print('✅ JSON数组解析: $urls');
          return urls;
        } catch (e) {
          print('❌ JSON解析失败: $e');
          return [str];
        }
      }

      // 情况3: 逗号分隔
      if (str.contains(',')) {
        final List<String> urls = str.split(',')
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList();
        print('✅ 逗号分隔解析: $urls');
        return urls;
      }

      // 情况4: 单个URL
      print('✅ 单个URL: [$str]');
      return [str];
    }

    // 2. 如果是数组
    if (attachmentsData is List) {
      final List<String> urls = [];
      for (var item in attachmentsData) {
        if (item is String) {
          urls.add(item);
        } else {
          urls.add(item.toString());
        }
      }
      print('✅ 数组格式: $urls');
      return urls;
    }

    // 3. 其他类型
    print('❌ 无法解析的类型: ${attachmentsData.runtimeType}');
    return [];
  }

  /// 判断是否为图片
  static bool isImage(String url) {
    try {
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.jpg') ||
          lowerUrl.endsWith('.jpeg') ||
          lowerUrl.endsWith('.png') ||
          lowerUrl.endsWith('.gif') ||
          lowerUrl.endsWith('.bmp') ||
          lowerUrl.endsWith('.webp') ||
          lowerUrl.contains('.jpg') ||
          lowerUrl.contains('.jpeg') ||
          lowerUrl.contains('.png');
    } catch (e) {
      return false;
    }
  }

  /// 从URL提取文件名
  static String getFileName(String url) {
    try {
      return url.split('/').last;
    } catch (e) {
      return url;
    }
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