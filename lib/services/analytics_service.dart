import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

class AnalyticsService {
  static final String baseUrl = AppConfig.baseUrl;

  // 获取认证头
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getSavedToken();
    if (token == null) {
      throw Exception('用户未登录');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. 获取本周图表数据
  // (调用 GET /api/analytics/chart-data)
  static Future<List<dynamic>> fetchChartData() async {
    final headers = await _getAuthHeaders();

    // (根据你的 API, 此接口不带参数)
    final uri = Uri.parse('$baseUrl/analytics/chart-data');
    print('AnalyticsService: [fetchChartData] 请求: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);
      print('AnalyticsService: [fetchChartData] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 200) {
        final responseData = json.decode(jsonString);
        // (根据你提供的 JSON: { "ok": true, "data": [...] })
        if (responseData['ok'] == true && responseData['data'] != null) {
          return responseData['data'] as List<dynamic>;
        } else {
          throw Exception('获取图表数据失败: 响应格式错误');
        }
      } else {
        throw Exception('无法加载图表数据: ${response.statusCode}');
      }
    } catch (e) {
      print('AnalyticsService: [fetchChartData] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchPersonality() async {
    final headers = await _getAuthHeaders();

    final uri = Uri.parse('$baseUrl/analytics/personality');
    print('AnalyticsService: [fetchPersonality] 请求: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);
      print('AnalyticsService: [fetchPersonality] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 200) {
        final responseData = json.decode(jsonString);
        return responseData;
      } else {
        throw Exception('无法加载 MBTI 分析: ${response.statusCode}');
      }
    } catch (e) {
      print('AnalyticsService: [fetchPersonality] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchSummary() async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/analytics/summary');
    print('AnalyticsService: [fetchSummary] 请求: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);
      print('AnalyticsService: [fetchSummary] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 200) {
        final responseData = json.decode(jsonString);

        return responseData;

      } else {
        throw Exception('无法加载 AI 总结: ${response.statusCode}');
      }
    } catch (e) {
      print('AnalyticsService: [fetchSummary] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchFortune() async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/analytics/fortune');
    print('AnalyticsService: [fetchFortune] 请求: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);
      print('AnalyticsService: [fetchFortune] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 200) {
        // (API 直接返回数据对象，例如 { "analysis": "...", "suggestion": {...} })
        return json.decode(jsonString);
      } else {
        throw Exception('无法加载运势: ${response.statusCode}');
      }
    } catch (e) {
      print('AnalyticsService: [fetchFortune] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }
}