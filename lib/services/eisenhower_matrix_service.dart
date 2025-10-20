// lib/services/eisenhower_matrix_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class EisenhowerMatrixService {

  static const bool useMockData = false; // 设为 false 使用真实接口

  // static const String _baseUrl = "http://10.0.2.2:8080/api"; // Android 模拟器
  static const String _baseUrl = "http://localhost:8080/api"; // 替换为实际后端地址
// static const String _baseUrl = "http://192.168.x.x:8080/api"; // 局域网真机测试（替换为您的电脑IP

  final http.Client client;

  EisenhowerMatrixService({http.Client? client}) : client = client ?? http.Client();

  // 获取公司重要任务
  Future<List<String>> getCompanyImportantTasks() async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/company-tasks/important'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['tasks'] ?? []);
      } else {
        throw Exception('Failed to load company important tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading company important tasks: $e');
      rethrow;
    }
  }

  // 获取公司派发任务（根据优先级筛选）
  Future<List<String>> getCompanyAssignedTasks({String priority = '高'}) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/company-tasks/by-priority?priority=$priority'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['tasks'] ?? []);
      } else {
        throw Exception('Failed to load company assigned tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading company assigned tasks: $e');
      rethrow;
    }
  }

  // 获取个人任务
  Future<List<String>> getPersonalTasks(int userId) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/personal-task/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['personal_tasks'] ?? []);
      } else if (response.statusCode == 404) {
        // 如果没有找到个人任务，返回空列表，由调用方决定是否创建默认任务
        return [];
      } else {
        throw Exception('Failed to load personal tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading personal tasks: $e');
      rethrow;
    }
  }

  // 创建个人任务
  Future<List<String>> createPersonalTasks(int userId, List<String> tasks) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/personal-task/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'personal_tasks': tasks,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['created_personal_tasks'] ?? tasks);
      } else {
        throw Exception('Failed to create personal tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating personal tasks: $e');
      rethrow;
    }
  }

  // 更新个人任务
  Future<List<String>> updatePersonalTasks(int userId, List<String> tasks) async {
    try {
      final response = await client.put(
        Uri.parse('$_baseUrl/personal-task/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'personal_tasks': tasks,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['updated_personal_tasks'] ?? tasks);
      } else {
        throw Exception('Failed to update personal tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating personal tasks: $e');
      rethrow;
    }
  }

  // 获取所有公司任务（详细信息）
  Future<Map<String, dynamic>> getAllCompanyTasks() async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/company-tasks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load all company tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading all company tasks: $e');
      rethrow;
    }
  }

  // 根据状态筛选任务
  Future<Map<String, dynamic>> getTasksByStatus(String status) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/company-tasks/by-status?status=$status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load tasks by status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading tasks by status: $e');
      rethrow;
    }
  }

  void dispose() {
    client.close();
  }
}