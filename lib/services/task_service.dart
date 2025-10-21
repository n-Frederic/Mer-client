// lib/services/task_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

// 定义一个简单的分页结构，用于返回数据和总数
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
  // TODO: 将 YOUR_BACKEND_API_BASE_URL 替换为你的后端基础地址
  static const String _baseUrl = 'http://localhost:8080/api';

  // ⚠️ 实际应用中：需要从本地安全存储中读取用户的身份验证 Token
  // 这里用一个占位符来模拟
  static String? _authToken = 'TODO_READ_TOKEN_FROM_SECURE_STORAGE';

  // ------------------------------------------------------------------
  // 辅助函数：处理 API 请求的通用逻辑
  // ------------------------------------------------------------------
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
          'Authorization': 'Bearer $_authToken', // 携带 Token 进行身份验证
        },
      );

      // 检查状态码
      if (response.statusCode == 200) {
        // 1. 使用 utf8 解码获取响应字符串
        final String jsonString = utf8.decode(response.bodyBytes);

        try {
          // 2. 解析响应体：将 JSON 字符串解析为 Map
          final Map<String, dynamic> responseData = json.decode(jsonString);

          final List<dynamic> jsonList = responseData['list'] ?? [];

          // 3. 模型映射：使用 Task.fromJson 将每个 Map 转换为 Task 对象
          final List<Task> tasks = jsonList.map((json) => Task.fromJson(json)).toList();

          return TaskListResponse(
            tasks: tasks,
            total: responseData['total'] ?? 0,
            page: responseData['page'] ?? 1,
            pageSize: responseData['pageSize'] ?? 10,
          );
        } catch (e) {
          // 【明确捕获 JSON 解析错误】
          print('JSON 解析失败，服务器返回内容: $jsonString');
          throw Exception('数据解析异常 (请检查服务器返回的JSON格式): $e');
        }

      } else {
        // 处理非 200 状态码
        print('服务器返回非 200 状态码: ${response.statusCode}');
        print('服务器响应体: ${utf8.decode(response.bodyBytes)}');
        throw Exception('无法加载任务列表，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      // 处理网络连接、超时等异常
      print('网络请求错误: $e');
      throw Exception('网络连接失败或底层请求错误');
    }
  }

  //获取个人任务
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

  // 获取全部任务
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