// lib/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProfileService {
  static const String baseUrl = 'http://127.0.0.1:8080/api/user';

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
}