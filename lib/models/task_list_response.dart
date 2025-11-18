// lib/models/task_list_response.dart
import 'task.dart';

class TaskListResponse {
  final List<Task> tasks;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore; // 新增字段

  TaskListResponse({
    required this.tasks,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore, // 必填参数
  });

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    final List<Task> tasks = (json['list'] as List<dynamic>?)
        ?.map((item) => Task.fromJson(item))
        .toList() ?? [];

    final int page = json['page'] ?? 1;
    final int pageSize = json['pageSize'] ?? 10;
    final int total = json['total'] ?? 0;

    // 计算是否还有更多数据
    final bool hasMore = (page * pageSize) < total;

    return TaskListResponse(
      tasks: tasks,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
    );
  }
}