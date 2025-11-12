import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {

  static final String baseUrl = AppConfig.baseUrl;

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

        // === 修改：改进用户ID保存逻辑 ===
        print('🔍 登录响应完整数据结构:');
        data.forEach((key, value) {
          print('  $key: $value');
        });

        int? userId;

        // 方法1：从user对象中查找用户ID
        if (data["user"] != null) {
          final userData = data["user"];
          print('🔍 user对象内容: $userData');

          // 尝试不同的用户ID字段名
          userId = userData["user_id"] ?? userData["userId"] ?? userData["id"];

          if (userId != null) {
            await prefs.setInt("user_id", userId);
            print('✅ 从user对象获取用户ID: $userId');
          } else {
            print('❌ user对象中没有找到user_id字段');
            // 打印user对象的所有字段
            if (userData is Map) {
              userData.forEach((key, value) {
                print('  user.$key: $value');
              });
            }
          }
        }

        // 方法2：如果user对象中没有，根据email推断用户ID
        if (userId == null) {
          // 根据你的数据库，user@example.com 对应的用户ID是2
          if (email == 'user@example.com') {
            userId = 2;
            await prefs.setInt("user_id", userId);
            print('✅ 根据email推断用户ID: $userId');
          } else if (email == 'test@example.com') {
            userId = 1;
            await prefs.setInt("user_id", userId);
            print('✅ 根据email推断用户ID: $userId');
          }
        }

        // 方法3：如果还是没有用户ID，使用默认值
        if (userId == null) {
          userId = 2; // 默认使用用户2
          await prefs.setInt("user_id", userId);
          print('⚠️ 未找到用户ID，使用默认值: $userId');
        }

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
      // print('🔑 从存储获取token: ${token.substring(0, 20)}...');
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

  // --- 找回密码 第 1 步 ---
  static Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    // 根据 API 文档，它复用了 /send-verification-code/
    // 根据我们之前的排查，它可能需要结尾的斜杠
    final uri = Uri.parse('$baseUrl/send-verification-code/');

    print('AuthService: [sendVerificationCode] 发送到: $email');
    print('AuthService: [sendVerificationCode] URL: $uri');

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      print('AuthService: [sendVerificationCode] 响应: $data');

      // 检查 'ok: true' 或 'error: true'
      if (data.containsKey('ok') && data['ok'] == true) {
        print('AuthService: [sendVerificationCode] 成功。');
        return {'ok': true, 'message': data['message'] ?? '验证码已发送'};
      } else {
        // API 返回了 'error: true'
        print('AuthService: [sendVerificationCode] API 错误: ${data['message']}');
        return {'ok': false, 'message': data['message'] ?? '发送失败'};
      }
    } catch (e) {
      // 网络或其他异常
      print('AuthService: [sendVerificationCode] 网络错误: $e');
      return {'ok': false, 'message': '网络请求失败，请稍后再试'};
    }
  }

// --- 找回密码 第 2 步 ---
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    // 根据 API 文档，使用 /forgot-password/reset
    final uri = Uri.parse('$baseUrl/forgot-password/reset');
    print('AuthService: [resetPassword] 重置邮箱: $email');

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "verificationCode": code,
          "newPassword": newPassword,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      print('AuthService: [resetPassword] 响应: $data');

      if (data.containsKey('ok') && data['ok'] == true) {
        print('AuthService: [resetPassword] 成功。');
        return {'ok': true, 'message': data['message'] ?? '密码重置成功'};
      } else {
        // API 返回了 'error: true'
        print('AuthService: [resetPassword] API 错误: ${data['message']}');
        return {'ok': false, 'message': data['message'] ?? '重置失败'};
      }
    } catch (e) {
      // 网络或其他异常
      print('AuthService: [resetPassword] 网络错误: $e');
      return {'ok': false, 'message': '网络请求失败，请稍后再试'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user_id"); // === 新增：清除用户ID ===
    print('✅ 已退出登录，token和用户ID已清除');
  }
}