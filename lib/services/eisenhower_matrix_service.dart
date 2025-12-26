// lib/services/eisenhower_matrix_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../config/app_config.dart';

class EisenhowerMatrixService {

  static const bool useMockData = false; // 设为 false 使用真实接口

  static final String baseUrl = AppConfig.baseUrl;

  final http.Client client;

  EisenhowerMatrixService({http.Client? client}) : client = client ?? http.Client();

  // 添加获取token的方法
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getSavedToken(); //获取保存的token
    final userId = await AuthService.getSavedUserId(); // 获取用户ID
    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('✅ 添加认证头，Token: ${token.substring(0, 20)}...');
    } else {
      print('❌ 未找到认证token，请求将发送无认证头');
    }

    // 如果需要用户ID，可以在请求时使用（虽然在大多数情况下，只需要 token 即可）
    if (userId != null) {
      headers['X-User-ID'] = userId.toString(); // 可以将用户ID作为额外头信息传递
      print('✅ 添加用户ID到请求头: $userId');
    }

    return headers;
  }

  // 公告部分，web发内容，只能查看
  Future<List<String>> getCompanyImportantTasks() async {
    try {
      final headers = await _getAuthHeaders();

      print('🚀 请求公司重要任务...');
      final response = await client.get(
        Uri.parse('$baseUrl/company-tasks/important'),
        headers: headers,
      );

      print('📡 响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return List<String>.from(data['tasks'] ?? []);
      } else if (response.statusCode == 401) {
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('加载公司重要任务失败: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 获取个人任务
  Future<List<String>> getPersonalTasks(int userId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await client.get(
        Uri.parse('$baseUrl/personal-task'), //请求个人任务接口
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return List<String>.from(data['personal_tasks'] ?? []);
      } else if (response.statusCode == 401) {
        throw Exception('用户认证失败，请重新登录');
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('加载个人任务失败: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 获取公司派发任务
  Future<List<String>> getCompanyAssignedTasks({String? priority}) async {
    try {

      // 使用 TaskService 接口
      final response = await TaskService.fetchScopedTasks(
        page: 1,
        pageSize: 20, // 获取足够多的任务
        priority: priority ?? '高', // 默认获取高优先级任务
        status: 'pending', // 获取待处理的任务
      );

      // 将任务对象转换为字符串列表
      final tasks = response.tasks.map((task) {
        // 构建任务显示字符串
        List<String> parts = [task.title ?? '未命名任务'];

        return parts.join(' · ');
      }).toList();

      return tasks;
    } catch (e) {
      print('💥 获取公司派发任务异常: $e');
      // 返回默认数据作为降级方案
      return [
        "目前还没有任务哦 ~ ",
      ];
    }
  }

  // 创建个人任务
  Future<List<String>> createPersonalTasks(int userId, List<String> tasks) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await client.post(
        Uri.parse('$baseUrl/personal-task'),
        headers: headers,
        body: json.encode({
          'personal_tasks': tasks,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return List<String>.from(data['created_personal_tasks'] ?? tasks);
      } else if (response.statusCode == 401) {
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('Failed to create personal tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 创建个人任务异常: $e');
      rethrow;
    }
  }
  // 更新个人任务
  Future<List<String>> updatePersonalTasks(int userId, List<String> tasks) async {
    try {
      // === 修改：使用认证头 ===
      final headers = await _getAuthHeaders();

      print('🚀 更新个人任务，用户ID: $userId, 任务: $tasks');
      final response = await client.put(
        Uri.parse('$baseUrl/personal-task'),
        headers: headers, // === 使用认证头 ===
        body: json.encode({
          'personal_tasks': tasks,
        }),
      );

      print('📡 响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 更新个人任务成功: ${data['updated_personal_tasks']}');
        return List<String>.from(data['updated_personal_tasks'] ?? tasks);
      } else if (response.statusCode == 401) {
        print('❌ 认证失败，token可能无效');
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('Failed to update personal tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 更新个人任务异常: $e');
      rethrow;
    }
  }

  // 获取所有公司任务（详细信息）
  Future<Map<String, dynamic>> getAllCompanyTasks() async {
    try {
      // === 修改：使用认证头 ===
      final headers = await _getAuthHeaders();

      print('🚀 请求所有公司任务');
      final response = await client.get(
        Uri.parse('$baseUrl/company-tasks'),
        headers: headers, // === 修改：使用认证头 ===
      );

      print('📡 响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 获取所有公司任务成功');
        return data;
      } else if (response.statusCode == 401) {
        print('❌ 认证失败，token可能无效');
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('Failed to load all company tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 获取所有公司任务异常: $e');
      rethrow;
    }
  }

  // 根据状态筛选任务
  Future<Map<String, dynamic>> getTasksByStatus(String status) async {
    try {
      // === 修改：使用认证头 ===
      final headers = await _getAuthHeaders();

      final response = await client.get(
        Uri.parse('$baseUrl/company-tasks/by-status?status=$status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data;
      } else if (response.statusCode == 401) {
        print('❌ 认证失败，token可能无效');
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('Failed to lcd build/app/outputs/flutter-apk/oad tasks by status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 根据状态筛选任务异常: $e');
      rethrow;
    }
  }

  // 获取个人日志
  // 获取个人日志
  Future<List<String>> getPersonalLogs() async {
    try {
      final headers = await _getAuthHeaders();

      // JSON 返回 "page": 1，说明后端是从 1 开始的
      final response = await client.get(
        Uri.parse('$baseUrl/journals/').replace(queryParameters: {
          'page': '1',
          'pageSize': '10',
        }),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // 1. 解码最外层 JSON
        final Map<String, dynamic> rootMap = json.decode(utf8.decode(response.bodyBytes));

        // 2. 修正取值路径：先取 data，再取 list
        final Map<String, dynamic>? dataMap = rootMap['data'];
        final List<dynamic> journalList = dataMap?['list'] ?? [];

        // 将日志对象转换为字符串列表
        final logs = journalList.map((journal) {
          // 3. 修正字段映射
          final title = journal['todaySummary']?.toString() ?? '无内容';
          final date = journal['log_date']?.toString() ?? '';

          // 解析嵌套的 author_info
          String authorName = '';
          if (journal['author_info'] != null) {
            authorName = journal['author_info']['name']?.toString() ?? '';
          }

          List<String> parts = [title];

          // 添加日期信息
          if (date.isNotEmpty) {
            parts.add('📅$date');
          }

          // 添加作者信息
          if (authorName.isNotEmpty) {
            parts.add('👤$authorName');
          }

          return parts.join(' · ');
        }).toList();

        return logs;
      } else if (response.statusCode == 401) {
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('加载个人日志失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取个人日志异常: $e');
      // 降级数据
      return [
        "接口解析失败 · 📅请检查代码",
        "错误信息 · 👤$e"
      ];
    }
  }

  void dispose() {
    client.close();
  }
}