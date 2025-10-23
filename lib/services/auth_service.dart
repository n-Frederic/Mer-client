import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  
  // static const String baseUrl = "http://10.61.237.155:8080/api";
  static const String baseUrl = "http://10.0.2.2:8080/api"; // Android 模拟器


  static Future<String?> login(String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/login");
      print('🔐 尝试登录: $email');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print('📡 登录响应状态码: ${response.statusCode}');
      print('📡 登录响应体: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // 检查错误字段
        if (data.containsKey("error") && data["error"] == true) {
          final message = data["message"] ?? "登录失败，未知错误";
          print("❌ 登录失败: $message");
          return null;
        }

        // 获取token
        final token = data["token"];
        if (token == null) {
          print("❌ 登录成功但未返回 token");
          print("完整响应数据: $data");
          return null;
        }

        // 保存token和用户信息
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);

        // === 新增：保存用户ID ===
        if (data["user"] != null && data["user"]["user_id"] != null) {
          await prefs.setInt("user_id", data["user"]["user_id"]);
          print('✅ 用户ID已保存: ${data["user"]["user_id"]}');
        }
        // === 新增结束 ===

        print('✅ 登录成功，token已保存: ${token.substring(0, 20)}...');
        return token;
      } else {
        print("❌ HTTP 登录请求失败，状态码: ${response.statusCode}");
        print("响应体: ${utf8.decode(response.bodyBytes)}");
        return null;
      }
    } catch (e) {
      print('💥 登录异常: $e');
      return null;
    }
  }

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token != null) {
      print('🔑 从存储获取token: ${token.substring(0, 20)}...');
    } else {
      print('🔑 存储中未找到token');
    }
    return token;
  }

  // === 新增：获取用户ID的方法 ===
  static Future<int?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    if (userId != null) {
      print('👤 从存储获取用户ID: $userId');
    } else {
      print('👤 存储中未找到用户ID');
    }
    return userId;
  }
  // === 新增结束 ===

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user_id"); // === 新增：清除用户ID ===
    print('✅ 已退出登录，token和用户ID已清除');
  }
}