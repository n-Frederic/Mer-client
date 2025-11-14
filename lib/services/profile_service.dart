// lib/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

class ProfileService {
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

  // 获取用户个人信息
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getAuthHeaders();

      print('ProfileService: [getUserProfile] 获取用户个人信息...');
      final response = await http.get(
        // 显式添加 /user
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
      );

      print('ProfileService: [getUserProfile] 个人信息响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('ProfileService: [getUserProfile] 获取用户信息成功');
        return data; // 假设此接口直接返回 { ok: true, user: {...} }
      } else if (response.statusCode == 401) {
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('获取个人信息失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ProfileService: [getUserProfile] 获取用户信息失败: $e');
      rethrow;
    }
  }


  // 更新用户个人信息
  static Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final headers = await _getAuthHeaders();

      print('ProfileService: [updateUserProfile] 更新用户个人信息...');
      print('ProfileService: [updateUserProfile] 发送的数据: $profileData');

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
        body: json.encode(profileData),
      );

      print('ProfileService: [updateUserProfile] 更新信息响应状态码: ${response.statusCode}');
      print('ProfileService: [updateUserProfile] 更新信息响应体: ${response.body}');

      if (response.statusCode == 200) {
        print('ProfileService: [updateUserProfile] 更新用户信息成功');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('用户认证失败，请重新登录');
      } else {
        // 尝试解析错误信息
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? '更新失败';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('更新个人信息失败: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('ProfileService: [updateUserProfile] 更新用户信息失败: $e');
      rethrow;
    }
  }

  // 获取单个用户详情 (GET /api/user/{userId})
  static Future<Map<String, dynamic>> fetchUserById(String userId) async {
    try {
      final headers = await _getAuthHeaders();

      print('ProfileService: [fetchUserById] 获取用户详情 (ID: $userId)...');
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: headers,
      );

      final String jsonString = utf8.decode(response.bodyBytes);
      print('ProfileService: [fetchUserById] 原始 JSON 响应: $jsonString');

      if (response.statusCode == 200) {
        final data = json.decode(jsonString);

        print('ProfileService: [fetchUserById] 获取用户 (ID: $userId) 成功');
        return data;

      } else if (response.statusCode == 401) {
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('获取用户 (ID: $userId) 失败: ${response.statusCode}');
      }
    } catch (e) {
      print('ProfileService: [fetchUserById] 获取用户 (ID: $userId) 失败: $e');
      rethrow;
    }
  }

  // 获取权限内用户列表 (用于成员筛选) (GET /api/tasks/assignees)
  static Future<Map<String, dynamic>> fetchScopedUsers({
    String? keyword,
    String? departmentId,
    String? teamId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final Map<String, String> params = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
      if (departmentId != null) params['department_id'] = departmentId;
      if (teamId != null) params['team_id'] = teamId;

      final uri = Uri.parse('$baseUrl/tasks/assignees').replace(queryParameters: params);

      print('ProfileService: [fetchScopedUsers] 获取权限内用户列表...');
      print('ProfileService: [fetchScopedUsers] 请求: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // --- 【⬇️ 关键修复 ⬇️】 ---
        // (根据你提供的 JSON，我们必须检查 'ok' 和 'data' 键)
        if (data['ok'] == true && data.containsKey('data')) {
          print('ProfileService: [fetchScopedUsers] 获取权限内用户列表成功');

          // 返回 'data' 嵌套对象 { list: [...], total: ... }
          // log_view.dart 的 FutureBuilder 将会接收到这个 'data' 对象
          return data['data'] as Map<String, dynamic>;

        } else {
          // (如果 'ok' 或 'data' 键不存在，则抛出此错误)
          throw Exception('获取用户失败: ${data['message'] ?? '响应格式错误'}');
        }
        // --- 【⬆️ 修复结束 ⬆️】 ---

      } else {
        throw Exception('获取权限内用户列表失败: ${response.statusCode}');
      }
    } catch (e) {
      print('ProfileService: [fetchScopedUsers] 获取权限内用户列表失败: $e');
      rethrow;
    }
  }

  // 获取所有部门 (GET /api/departments)
  static Future<List<dynamic>> fetchDepartments() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$baseUrl/department');

      print('ProfileService: [fetchDepartments] 获取部门列表...');
      print('ProfileService: [fetchDepartments] 请求: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (data['ok'] == true && data.containsKey('data')) {
          print('ProfileService: [fetchDepartments] 获取部门列表成功');
          return data['data'] as List<dynamic>;
        } else {
          throw Exception('获取部门列表失败: ${data['message'] ?? '响应格式错误'}');
        }

      } else {
        throw Exception('获取部门列表失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('ProfileService: [fetchDepartments] 获取部门列表失败: $e');
      rethrow;
    }
  }

  // 获取团队 (按部门级联) (GET /api/teams)
  static Future<List<dynamic>> fetchTeams({String? departmentId}) async {
    try {
      final headers = await _getAuthHeaders();

      // 移除了 '../' 技巧
      final uri = Uri.parse('$baseUrl/team/teams');

      final Map<String, String> params = {};
      if (departmentId != null) {
        params['department_id'] = departmentId;
      }

      print('ProfileService: [fetchTeams] 获取团队列表 (部门ID: $departmentId)...');
      final response = await http.get(
          uri.replace(queryParameters: params),
          headers: headers
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // 添加了与 API 文档一致的健壮解析
        if (data['ok'] == true && data.containsKey('list')) {
          print('ProfileService: [fetchTeams] 获取团队列表成功');
          return data['list']; // 返回 list 数组
        } else {
          throw Exception('获取团队列表失败: ${data['message'] ?? '响应格式错误'}');
        }
      } else {
        throw Exception('获取团队列表失败: ${response.statusCode}');
      }
    } catch (e) {
      print('ProfileService: [fetchTeams] 获取团队列表失败: $e');
      rethrow;
    }
  }
}