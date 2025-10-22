// lib/services/task_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

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
}

class TaskService {
  static const String _baseUrl = "http://10.0.2.2:8080/api";

  // TODO:改成动态获取
  static String? _authToken = '3d46fc55-863b-40fd-b13d-d3b73cad0798';

  static Future<TaskListResponse> _fetchTasks(String path, {Map<String, String>? params}) async {
    if (_authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);

        try {
          final Map<String, dynamic> responseData = json.decode(jsonString);

          final List<dynamic> jsonList = responseData['list'] ?? [];

          final List<Task> tasks = jsonList.map((json) => Task.fromJson(json)).toList();

          return TaskListResponse(
            tasks: tasks,
            total: responseData['total'] ?? 0,
            page: responseData['page'] ?? 1,
            pageSize: responseData['pageSize'] ?? 10,
          );
        } catch (e) {
          print('JSON 解析失败，服务器返回内容: $jsonString');
          throw Exception('数据解析异常: $e');
        }

      } else {
        print('服务器返回非 200 状态码: ${response.statusCode}');
        print('服务器响应体: ${utf8.decode(response.bodyBytes)}');
        throw Exception('无法加载任务列表，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('网络请求错误: $e');
      throw Exception('网络连接失败或底层请求错误');
    }
  }

  static Future<TaskListResponse> fetchPersonalTasks({
    required String userId,
    int page = 1,
    int pageSize = 10,
    String? status,
    String? priority,
  }) {
    final Map<String, String> params = {
      'userId': userId,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;

    return _fetchTasks('/tasks/personal', params: params);
  }

  static Future<TaskListResponse> fetchAllTasks({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? priority,
  }) {
    final Map<String, String> params = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;

    return _fetchTasks('/tasks/all', params: params);
  }
}