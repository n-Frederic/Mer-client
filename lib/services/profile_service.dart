// lib/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

class ProfileService {
  static final String baseUrl = AppConfig.baseUrl + "/user";

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

      print('🔍 获取用户个人信息...');
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      print('📡 个人信息响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 获取用户信息成功');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('获取个人信息失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ 获取用户信息失败: $e');
      rethrow;
    }
  }


  // 更新用户个人信息
  static Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final headers = await _getAuthHeaders();

      print('💾 更新用户个人信息...');
      print('📦 发送的数据: $profileData');

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: json.encode(profileData),
      );

      print('📡 更新信息响应状态码: ${response.statusCode}');
      print('📡 更新信息响应体: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ 更新用户信息成功');
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
      print('❌ 更新用户信息失败: $e');
      rethrow;
    }
  }
  // 【新增】获取单个用户详情
  // (调用 GET /api/user/{userId})
  static Future<Map<String, dynamic>> fetchUserById(String userId) async {
    try {
      final headers = await _getAuthHeaders(); // 复用您已有的认证方法

      print('🔍 获取用户详情 (ID: $userId)...');
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'), // $baseUrl 已经是 /api/user
        headers: headers,
      );

      print('📡 用户详情响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['ok'] == true && data.containsKey('user')) {
          print('✅ 获取用户 (ID: $userId) 成功');
          return data['user']; // <-- 返回 "user" 嵌套对象
        } else {
          throw Exception(data['error'] ?? '无法解析用户数据');
        }
      } else if (response.statusCode == 401) {
        throw Exception('用户认证失败，请重新登录');
      } else {
        throw Exception('获取用户 (ID: $userId) 失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 获取用户 (ID: $userId) 失败: $e');
      rethrow;
    }
  }
  // 【新增】获取权限内用户列表 (用于成员筛选)
  // (调用 GET /api/user/scoped)
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

      // ⚠️ 注意：您文档中的 URL 是 /api/users (复数)，
      //    但您的 ProfileService baseUrl 是 /api/user (单数)。
      //    我们假设 baseUrl 是 /api，接口是 /user/scoped
      final uri = Uri.parse('$baseUrl/scoped').replace(queryParameters: params);
      // (如果 ProfileService.baseUrl 已经是 /api/user,
      //  那么 Uri.parse('$baseUrl/../user/scoped') )

      print('🔍 获取权限内用户列表...');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 获取权限内用户列表成功');
        return data['data']; // 返回 data 嵌套对象 { list: [...], total: ... }
      } else {
        throw Exception('获取权限内用户列表失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 获取权限内用户列表失败: $e');
      rethrow;
    }
  }

  // 【新增】获取所有部门
  // (调用 GET /api/departments)
  static Future<List<dynamic>> fetchDepartments() async {
    try {
      final headers = await _getAuthHeaders();
      // 假设 departments 接口在 /api/departments
      final uri = Uri.parse('${baseUrl}/../departments');

      print('🔍 获取部门列表...');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 获取部门列表成功');
        return data['list']; // 返回 list 数组
      } else {
        throw Exception('获取部门列表失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 获取部门列表失败: $e');
      rethrow;
    }
  }

  // 【新增】获取团队 (按部门级联)
  // (调用 GET /api/teams)
  static Future<List<dynamic>> fetchTeams({String? departmentId}) async {
    try {
      final headers = await _getAuthHeaders();
      // 假设 teams 接口在 /api/teams
      final uri = Uri.parse('${baseUrl}/../teams');

      final Map<String, String> params = {};
      if (departmentId != null) {
        params['department_id'] = departmentId;
      }

      print('🔍 获取团队列表 (部门ID: $departmentId)...');
      final response = await http.get(
          uri.replace(queryParameters: params),
          headers: headers
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 获取团队列表成功');
        return data['list']; // 返回 list 数组
      } else {
        throw Exception('获取团队列表失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 获取团队列表失败: $e');
      rethrow;
    }
  }
}