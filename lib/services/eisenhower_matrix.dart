// 导图部分四个矩阵窗口的接口
import 'dart:convert';
import 'package:http/http.dart' as http;


class TaskService {
  static const String baseUrl = "http://10.0.2.2:8080/api";

  // 基础请求头（不需要认证）
  static Map<String, String> get _headers {
    return {
      "Content-Type": "application/json",
    };
  }

  // 获取公司重要事项（只读）
  static Future<List<String>> getCompanyImportantTasks() async {
    try {
      final url = Uri.parse("$baseUrl/company-important-tasks/");

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> tasks = [];

        if (data['tasks'] != null) {
          for (var task in data['tasks']) {
            tasks.add(task.toString());
          }
        }
        return tasks;
      } else {
        throw Exception('Failed to load company important tasks');
      }
    } catch (e) {
      print('Error fetching company important tasks: $e');
      return [];
    }
  }

  // 获取公司派发任务（只读）
  static Future<List<String>> getCompanyAssignedTasks() async {
    try {
      final url = Uri.parse("$baseUrl/company-assigned-tasks/");

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> tasks = [];

        if (data['tasks'] != null) {
          for (var task in data['tasks']) {
            tasks.add(Map<String, dynamic>.from(task));
          }
        }
        return tasks;
      } else {
        throw Exception('Failed to load company assigned tasks');
      }
    } catch (e) {
      print('Error fetching company assigned tasks: $e');
      return [];
    }
  }

  // 获取个人重要事项（可编辑）
  static Future<List<String>> getPersonalImportantTasks() async {
    try {
      final url = Uri.parse("$baseUrl/personal-important-tasks/");

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> tasks = [];

        if (data['tasks'] != null) {
          for (var task in data['tasks']) {
            tasks.add(task.toString());
          }
        }
        return tasks;
      } else {
        throw Exception('Failed to load personal important tasks');
      }
    } catch (e) {
      print('Error fetching personal important tasks: $e');
      return [];
    }
  }

  // 获取个人日志（只读）
  static Future<List<String>> getPersonalLogs() async {
    try {
      final url = Uri.parse("$baseUrl/personal-logs/");

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> logs = [];

        if (data['logs'] != null) {
          for (var log in data['logs']) {
            logs.add(Map<String, dynamic>.from(log));
          }
        }
        return logs;
      } else {
        throw Exception('Failed to load personal logs');
      }
    } catch (e) {
      print('Error fetching personal logs: $e');
      return [];
    }
  }

  // 更新个人重要事项
  static Future<bool> updatePersonalImportantTasks(List<String> tasks) async {
    try {
      final url = Uri.parse("$baseUrl/personal-important-tasks/");

      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode({"tasks": tasks}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating personal important tasks: $e');
      return false;
    }
  }
}
}