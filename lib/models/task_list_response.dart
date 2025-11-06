// lib/models/task_list_response.dart
import 'task.dart';

class TaskListResponse {
  final List<Task> tasks;
  final int total;
  final int page;
  final int pageSize;

  TaskListResponse({
    required this.tasks,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    return TaskListResponse(
      tasks: (json['list'] as List<dynamic>?)
          ?.map((item) => Task.fromJson(item))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}