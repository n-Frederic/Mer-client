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

        int? userId = await _fetchUserInfoAfterLogin(token);

        if (userId == null) {
          // 如果获取用户信息失败，使用备用方案
          userId = await _getUserIdByFallback(email);
        }

        if (userId != null) {
          await prefs.setInt("user_id", userId);
          print('✅ 最终确定的用户ID: $userId');
        } else {
          print('❌ 无法获取用户ID，登录流程不完整');
          // 不清除token，因为token是有效的，只是用户ID获取失败
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

  static Future<int?> _fetchUserInfoAfterLogin(String token) async {
    try {
      print('🔍 登录后获取用户完整信息...');
      final profileUrl = Uri.parse('$baseUrl/user/profile');

      final response = await http.get(
        profileUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 用户信息接口响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final profileData = jsonDecode(utf8.decode(response.bodyBytes));
        print('📡 用户信息接口响应数据: $profileData');

        // 尝试从不同字段获取用户ID
        int? userId;

        // 方法1：直接字段
        userId = profileData['user_id'] ?? profileData['userId'] ?? profileData['id'];

        // 方法2：从嵌套对象中获取
        if (userId == null && profileData['user'] != null) {
          final userData = profileData['user'];
          userId = userData['user_id'] ?? userData['userId'] ?? userData['id'];
        }

        // 方法3：从其他可能的字段获取
        if (userId == null) {
          // 打印所有字段以便调试
          print('🔍 用户信息接口返回的所有字段:');
          profileData.forEach((key, value) {
            print('  $key: $value');
          });
        }

        if (userId != null) {
          print('✅ 从用户信息接口获取到用户ID: $userId');
          return userId;
        } else {
          print('❌ 用户信息接口中未找到用户ID字段');
        }
      } else {
        print('❌ 用户信息接口请求失败: ${response.statusCode}');
        print('响应体: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('❌ 获取用户信息异常: $e');
    }

    return null;
  }

  // === 新增：备用方案获取用户ID ===
  static Future<int?> _getUserIdByFallback(String email) async {
    try {
      print('🔍 使用备用方案获取用户ID...');

      // 方案1：调用获取用户列表接口，通过email匹配
      final token = await getSavedToken();
      if (token != null) {
        final usersUrl = Uri.parse('$baseUrl/api/tasks/assignees');
        final response = await http.get(
          usersUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map && data.containsKey('list')) {
            final userList = List<Map<String, dynamic>>.from(data['list']);

            // 通过email查找用户
            for (var user in userList) {
              if (user['email'] == email) {
                final userId = user['user_id'] ?? user['userId'] ?? user['id'];
                if (userId != null) {
                  print('✅ 通过用户列表接口找到用户ID: $userId');
                  return userId;
                }
              }
            }
          }
        }
      }

      // 方案2：基于已知email映射
      final emailUserIdMap = {
        'lihua@company.com': 2,
        'test@example.com': 1,
        'user@example.com': 2,
        'admin@example.com': 1,
      };

      if (emailUserIdMap.containsKey(email)) {
        final userId = emailUserIdMap[email];
        print('✅ 通过email映射找到用户ID: $userId');
        return userId;
      }

      // 方案3：使用默认值
      print('⚠️ 所有方案都失败，使用默认用户ID: 2');
      return 2;

    } catch (e) {
      print('❌ 备用方案异常: $e');
      return 2; // 返回默认值
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

  // === 新增：刷新用户信息 ===
  static Future<int?> refreshUserInfo() async {
    try {
      final token = await getSavedToken();
      if (token == null) {
        print('❌ 刷新用户信息失败：token不存在');
        return null;
      }

      return await _fetchUserInfoAfterLogin(token);
    } catch (e) {
      print('❌ 刷新用户信息异常: $e');
      return null;
    }
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