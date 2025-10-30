// lib/services/eisenhower_matrix_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class EisenhowerMatrixService {

  static const bool useMockData = false; // 设为 false 使用真实接口

  static const String _baseUrl = "http://127.0.0.1:8080/api";
  // static const String _baseUrl = "http://10.0.2.2:8080/api"; // Android 模拟器
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

  // 获取公司重要任务
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

  // 获取公司派发任务（根据优先级筛选）
  Future<List<String>> getCompanyAssignedTasks({String priority = '高'}) async {
    try {
      // === 修改：使用认证头 ===
      final headers = await _getAuthHeaders();

      print('🚀 请求公司派发任务，优先级: $priority');
      final response = await client.get(
        Uri.parse('$_baseUrl/company-tasks/by-priority?priority=$priority'),
        headers: headers, // === 修改：使用认证头 ===
      );

      print('📡 响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 获取公司派发任务成功: ${data['tasks']}');
        return List<String>.from(data['tasks'] ?? []);
      } else if (response.statusCode == 401) {
        print('❌ 认证失败，token可能无效');
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('Failed to load company assigned tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 获取公司派发任务异常: $e');
      rethrow;
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

  void dispose() {
    client.close();
  }
}