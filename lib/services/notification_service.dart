import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class NotificationService {
  static final String baseUrl = AppConfig.baseUrl;

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getSavedToken();
    if (token == null) throw Exception('用户未登录');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<NotificationListResponse> fetchNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final headers = await _getAuthHeaders();
    final Map<String, String> params = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: params);
    print('NotificationService: [fetchNotifications] 请求: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final responseData = json.decode(jsonString);
        if (responseData['ok'] == true) {
          return NotificationListResponse.fromJson(responseData);
        } else {
          throw Exception('获取通知失败: ${responseData['message']}');
        }
      } else {
        throw Exception('无法加载通知: ${response.statusCode}');
      }
    } catch (e) {
      print('NotificationService: [fetchNotifications] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }

  static Future<bool> markAsRead(String notifId) async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/notifications/$notifId/read');

    print('NotificationService: [markAsRead] 请求: $uri');

    try {

      final response = await http.put(
        uri,
        headers: headers,
        body: "{}",
      );

      final String jsonString = utf8.decode(response.bodyBytes);
      print('NotificationService: [markAsRead] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 200) {
        final responseData = json.decode(jsonString);
        return responseData['ok'] == true;
      } else {
        print('标记已读失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('标记已读错误: $e');
      return false;
    }
  }
}