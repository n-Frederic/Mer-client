// lib/services/eisenhower_matrix_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class EisenhowerMatrixService {

  static const bool useMockData = false; // 设为 false 使用真实接口

  // static const String _baseUrl = "http://127.0.0.1:8080/api";
  static const String _baseUrl = "http://10.0.2.2:8080/api"; // Android 模拟器
  // static const String _baseUrl = "http://10.61.237.155:8080/api"; // 替换为实际后端地址

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
        Uri.parse('$_baseUrl/company-tasks/important'),
        headers: headers,
      );

      print('📡 响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 获取公司重要任务成功: ${data['tasks']}');
        return List<String>.from(data['tasks'] ?? []);
      } else if (response.statusCode == 401) {
        print('❌ 认证失败，token可能无效');
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('加载公司重要任务失败: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 获取公司重要任务异常: $e');
      rethrow;
    }
  }

  // 获取个人任务
  Future<List<String>> getPersonalTasks(int userId) async {
    try {
      final headers = await _getAuthHeaders();

      print('🚀 请求个人任务，用户ID: $userId');
      final response = await client.get(
        Uri.parse('$_baseUrl/personal-task'), //请求个人任务接口
        headers: headers,
      );

      print('📡 响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 获取个人任务成功: ${data['personal_tasks']}');
        return List<String>.from(data['personal_tasks'] ?? []);
      } else if (response.statusCode == 401) {
        print('❌ 认证失败，token可能无效');
        throw Exception('用户认证失败，请重新登录');
      } else if (response.statusCode == 404) {
        print('ℹ️ 未找到个人任务');
        return [];
      } else {
        throw Exception('加载个人任务失败: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 获取个人任务异常: $e');
      rethrow;
    }
  }

  // 获取公司派发任务
  Future<List<String>> getCompanyAssignedTasks({String? priority}) async {
    try {
      print('🚀 请求公司派发任务，优先级: $priority');

      // 使用 TaskService 接口
      final response = await TaskService.fetchScopedTasks(
        page: 1,
        pageSize: 20, // 获取足够多的任务
        priority: priority ?? '高', // 默认获取高优先级任务
        status: 'pending', // 获取待处理的任务
      );

      print('📡 获取到 ${response.tasks.length} 个任务');

      // 将任务对象转换为字符串列表
      final tasks = response.tasks.map((task) {
        // 构建任务显示字符串
        List<String> parts = [task.title ?? '未命名任务'];

        return parts.join(' · ');
      }).toList();

      print('✅ 获取公司派发任务成功: ${tasks.length} 个任务');
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
      // === 修改：使用认证头 ===
      final headers = await _getAuthHeaders();

      print('🚀 创建个人任务，用户ID: $userId, 任务: $tasks');
      final response = await client.post(
        Uri.parse('$_baseUrl/personal-task'),
        headers: headers, // === 修改：使用认证头 ===
        body: json.encode({
          'personal_tasks': tasks,
        }),
      );

      print('📡 响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 创建个人任务成功: ${data['created_personal_tasks']}');
        return List<String>.from(data['created_personal_tasks'] ?? tasks);
      } else if (response.statusCode == 401) {
        print('❌ 认证失败，token可能无效');
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
        Uri.parse('$_baseUrl/personal-task'),
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
        Uri.parse('$_baseUrl/company-tasks'),
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

      print('🚀 根据状态筛选任务，状态: $status');
      final response = await client.get(
        Uri.parse('$_baseUrl/company-tasks/by-status?status=$status'),
        headers: headers, // === 修改：使用认证头 ===
      );

      print('📡 响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 根据状态筛选任务成功');
        return data;
      } else if (response.statusCode == 401) {
        print('❌ 认证失败，token可能无效');
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('Failed to load tasks by status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 根据状态筛选任务异常: $e');
      rethrow;
    }
  }

  // 获取个人日志
  Future<List<String>> getPersonalLogs() async {
    try {
      final headers = await _getAuthHeaders();

      print('🚀 请求个人日志列表...');
      final response = await client.get(
        Uri.parse('$_baseUrl/journals/').replace(queryParameters: {
          'page': '1',
          'pageSize': '10', // 获取最近10条日志
        }),
        headers: headers,
      );

      print('📡 个人日志响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> journalList = data['list'] ?? [];

        // 将日志对象转换为字符串列表
        final logs = journalList.map((journal) {
          final title = journal['title']?.toString() ?? '无标题日志';
          final date = journal['date']?.toString() ?? '';
          final authorName = journal['authorName']?.toString() ?? '';

          List<String> parts = [title];

          // 添加日期信息
          if (date.isNotEmpty) {
            parts.add('📅$date');
          }

          // 添加作者信息（如果不是当前用户）
          if (authorName.isNotEmpty) {
            parts.add('👤$authorName');
          }

          return parts.join(' · ');
        }).toList();

        print('✅ 获取个人日志成功: ${logs.length} 条日志');
        return logs;
      } else if (response.statusCode == 401) {
        print('❌ 认证失败，token可能无效');
        throw Exception('用户认证失败，请重新登录');
      } else if (response.statusCode == 404) {
        print('ℹ️ 未找到个人日志');
        return [];
      } else {
        throw Exception('加载个人日志失败: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 获取个人日志异常: $e');
      // 返回默认数据作为降级方案
      return [
        "项目进展汇报 · 📅2024-01-15",
        "技术学习总结 · 📅2024-01-14",
        "团队协作记录 · 📅2024-01-13",
        "问题解决方案 · 📅2024-01-12"
      ];
    }
  }

  void dispose() {
    client.close();
  }
}