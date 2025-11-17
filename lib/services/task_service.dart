import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../models/task.dart';
import '../models/task_report.dart';
import '../models/task_list_response.dart';
import '../config/app_config.dart';
import '../models/task_user.dart';

class TaskService {
  static final String baseUrl = AppConfig.baseUrl;

  // 获取认证头信息
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getSavedToken();
    if (token == null) {
      throw Exception('用户未登录，请重新登录');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 辅助函数：处理 API 请求的通用逻辑
  static Future<TaskListResponse> _fetchTasks(String path, {Map<String, String>? params}) async {
    final authToken = await AuthService.getSavedToken();

    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);

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

    final uri = Uri.parse('$baseUrl/tasks/$taskId');

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

  // 创建任务
  static Future<Map<String, dynamic>> createTask({
    required int userId,
    required String title,
    required String description,
    required DateTime dueAt,
    required List<String> tags,
    required List<int> assigneeIds,
    String priority = "medium",
    String status = "published"
  }) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final url = Uri.parse("$baseUrl/tasks");

    final body = jsonEncode({
      "title": title,
      "description": description,
      "dueAt": dueAt.toUtc().toIso8601String(),
      "priority": priority,
      "assigneeIds": assigneeIds,
      "tags": tags,
      "status": status
    });

    print('📤 创建任务请求 URL: $url');
    print('📤 创建任务请求体: $body');
    print('🔑 使用Token: ${authToken.substring(0, 20)}...');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      print('📥 创建任务响应状态码: ${response.statusCode}');
      print('📥 创建任务响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception("创建任务失败: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print('💥 创建任务请求异常: $e');
      throw Exception("创建任务请求失败: $e");
    }
  }

  // 在 TaskService 中修改 fetchTaskAssigneesList 方法
  static Future<List<TaskUser>> fetchTaskAssigneesList(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/assignerAndDesignee/$taskId');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 获取任务指派者响应状态码: ${response.statusCode}');
      print('📥 获取任务指派者响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['code'] == 200 && responseData.containsKey('data')) {
          final data = responseData['data'];
          List<dynamic> assigneesJson = [];

          // 根据实际响应结构调整
          if (data.containsKey('assignees') && data['assignees'] is List) {
            assigneesJson = data['assignees'];
          }

          return assigneesJson.map((json) => TaskUser.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message'] ?? '无法解析任务分配信息');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('无法加载任务分配信息，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (fetchTaskAssigneesList): $e');
      throw Exception('获取任务分配信息失败: $e');
    }
  }

  // 更新任务状态
  static Future<bool> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId/status');

    final body = jsonEncode({
      'status': newStatus.sqlValue,
    });

    try {
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      print('📥 更新任务状态响应状态码: ${response.statusCode}');
      print('📥 更新任务状态响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['ok'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('更新任务状态失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (updateTaskStatus): $e');
      throw Exception('更新任务状态失败: $e');
    }
  }

  // 审批任务报告（新增）
  static Future<bool> approveTaskReport(String taskId) async {
    return await updateTaskStatus(taskId, TaskStatus.completed);
  }

  // 拒绝任务报告（新增）
  static Future<bool> rejectTaskReport(String taskId) async {
    return await updateTaskStatus(taskId, TaskStatus.published);
  }

  // 更新任务信息（新增）
  static Future<bool> updateTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime dueAt,
    required List<String> tags,
    required List<int> assigneeIds,
    required String priority,
  }) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId');

    final body = jsonEncode({
      "title": title,
      "description": description,
      "dueAt": dueAt.toUtc().toIso8601String(),
      "priority": priority,
      "assigneeIds": assigneeIds,
      "tags": tags,
    });

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      print('📥 更新任务响应状态码: ${response.statusCode}');
      print('📥 更新任务响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['ok'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('更新任务失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (updateTask): $e');
      throw Exception('更新任务失败: $e');
    }
  }

  // 删除任务（新增）
  static Future<bool> deleteTask(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 删除任务响应状态码: ${response.statusCode}');
      print('📥 删除任务响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['ok'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('删除任务失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (deleteTask): $e');
      throw Exception('删除任务失败: $e');
    }
  }

  // 获取任务统计信息（新增）
  static Future<Map<String, dynamic>> getTaskStatistics() async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/statistics');

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

        if (responseData['ok'] == true) {
          return responseData['data'] ?? {};
        } else {
          throw Exception(responseData['error'] ?? '无法解析任务统计信息');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('无法加载任务统计信息，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (getTaskStatistics): $e');
      throw Exception('获取任务统计信息失败: $e');
    }
  }

}