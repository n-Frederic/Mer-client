import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/task.dart';
import '../models/task_report.dart';
import '../models/task_list_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'dart:io'; // 添加 File 导入
import 'package:geolocator/geolocator.dart'; // 添加 Position 导入

class TaskService {
  static final String baseUrl = AppConfig.baseUrl;

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

  // 获取任务派发人员
  static Future<Map<String, dynamic>> fetchTaskAssignees(String taskId) async {
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

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['code'] == 200 && responseData.containsKey('data')) {
          return responseData['data'];
        } else {
          throw Exception(responseData['message'] ?? '无法解析任务分配信息');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('无法加载任务分配信息，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (fetchTaskAssignees): $e');
      throw Exception('获取任务分配信息失败: $e');
    }
  }



  // 【新增】获取任务的报告记录
  static Future<List<TaskReport>> fetchTaskReports(String taskId) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId/reports');

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

        if (responseData['ok'] == true && responseData.containsKey('reports')) {
          final List<dynamic> reportsJson = responseData['reports'];
          return reportsJson.map((json) => TaskReport.fromJson(json)).toList();
        } else {
          // 如果没有报告记录，返回空列表
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else if (response.statusCode == 404) {
        // 没有找到报告记录，返回空列表
        return [];
      } else {
        throw Exception('无法加载报告记录，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (fetchTaskReports): $e');
      // 出错时返回空列表而不是抛出异常
      return [];
    }
  }

  // 【新增】创建任务报告
  static Future<Map<String, dynamic>> createTaskReport({
    required String taskId,
    required File? photo,
    required Position location,
    required String content,
    String? address,
  }) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证，请先登录');
    }

    final uri = Uri.parse('$baseUrl/tasks/$taskId/reports');

    // 创建 multipart 请求
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $authToken';

    // 添加文本字段
    request.fields['content'] = content;
    request.fields['address'] = address ?? '北京市朝阳区';

    // 添加位置信息作为额外字段
    request.fields['latitude'] = location.latitude.toString();
    request.fields['longitude'] = location.longitude.toString();

    // 添加图片文件
    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'attachments',
        photo.path,
        filename: 'report_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📥 创建报告响应状态码: ${response.statusCode}');
      print('📥 创建报告响应体: $responseBody');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);

        if (responseData['ok'] == true) {
          return {
            'success': true,
            'message': '报告提交成功',
            'report': responseData['report'],
          };
        } else {
          throw Exception(responseData['error'] ?? '报告提交失败');
        }
      } else if (response.statusCode == 401) {
        throw Exception('认证失败或Token过期，请重新登录');
      } else {
        throw Exception('报告提交失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService 捕获到原始错误 (createTaskReport): $e');
      throw Exception('报告提交请求失败: $e');
    }
  }

  // 【新增】更新任务状态
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
}