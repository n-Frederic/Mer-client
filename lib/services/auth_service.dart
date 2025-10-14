import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://10.0.2.2:8080/api";

  static Future<String?> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data.containsKey("error") && data["error"] == true) {
        final message = data["message"] ?? "登录失败，未知错误";
        print("登录失败: $message");
        return null;
      }

      final token = data["token"];
      final user = data["user"];

      if (token == null) {
        print("登录成功但未返回 token");
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("auth_token", token);

      return token;
    } else {
      print("HTTP 登录请求失败，状态码: ${response.statusCode}");
      return null;
    }
  }

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
  }
}