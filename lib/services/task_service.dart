import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/task.dart';
import '../models/task_list_response.dart';
import 'package:shared_preferences/shared_preferences.dart';


class TaskService {
  // static const String _baseUrl = 'http://10.0.2.2:8080/api';
  static const String _baseUrl = "http://127.0.0.1:8080/api";

  // 辅助函数：处理 API 请求的通用逻辑
  static Future<TaskListResponse> _fetchTasks(String path, {Map<String, String>? params}) async {
    final authToken = await AuthService.getSavedToken();

    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // 后端从 token 识别用户
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
          print('JSON解析失败，服务器返回内容: ${utf8.decode(response.bodyBytes)}');
          throw Exception('数据解析异常: $e');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('无法加载任务列表，服务器响应码: ${response.statusCode}');
      }
    } catch (e, s) {
      print('TaskService 捕获到原始错误: $e');
      print('TaskService 原始堆栈: $s');
      throw Exception('TaskService 请求失败: $e');
    }
  }

  // 获取个人任务
  static Future<TaskListResponse> fetchPersonalTasks({
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

    return _fetchTasks('/tasks/personal', params: params);
  }

  // 获取权限内全部任务
  static Future<TaskListResponse> fetchScopedTasks({
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

    return _fetchTasks('/tasks/myView', params: params);
  }

  // 获取单个任务详情
  static Future<Task> fetchTaskById(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$_baseUrl/tasks/$taskId');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['ok'] == true && responseData.containsKey('task')) {
          return Task.fromJson(responseData['task']);
        } else {
          throw Exception(responseData['error'] ?? '无法解析任务详情');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('无法加载任务详情，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (fetchTaskById): $e');
      throw Exception('TaskService 请求失败: $e');
    }
  }
}