import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class AnalyticsService {
  static final String baseUrl = AppConfig.baseUrl;

  // --- 【缓存 Keys】 ---
  static const String _kFortuneDataKey = 'daily_fortune_data';
  static const String _kFortuneDateKey = 'daily_fortune_date';
  static const String _kMBTIDataKey = 'daily_mbti_data';     // 【新增】MBTI 数据缓存 Key
  static const String _kMBTIDateKey = 'daily_mbti_date';     // 【新增】MBTI 日期缓存 Key

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

  // 1. 获取本周图表数据 (实时获取，不缓存，保证数据准确性)
  static Future<List<dynamic>> fetchChartData() async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/analytics/chart-data');
    print('AnalyticsService: [fetchChartData] 请求: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final responseData = json.decode(jsonString);
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

  // 2. 获取本周 AI 总结和关键词 (实时获取，或者你也可以按需添加缓存)
  static Future<Map<String, dynamic>> fetchSummary() async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/analytics/summary');
    print('AnalyticsService: [fetchSummary] 请求: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);

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

  // 3. 获取 MBTI 职场性格分析 (【修改】带本地缓存：一天只生成一次)
  static Future<Map<String, dynamic>> fetchPersonality() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 获取今天的日期字符串
    final String today = DateTime.now().toIso8601String().split('T')[0];

    // 2. 检查缓存
    final String? cachedDate = prefs.getString(_kMBTIDateKey);
    final String? cachedDataString = prefs.getString(_kMBTIDataKey);

    if (cachedDate == today && cachedDataString != null) {
      print('AnalyticsService: [fetchPersonality] 使用本地缓存 (日期: $today)');
      return json.decode(cachedDataString) as Map<String, dynamic>;
    }

    // 3. 缓存无效或过期，调用 API
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/analytics/personality');
    print('AnalyticsService: [fetchPersonality] 请求 API: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        // 4. 保存新数据到缓存
        await prefs.setString(_kMBTIDateKey, today);
        await prefs.setString(_kMBTIDataKey, jsonString);

        return json.decode(jsonString);
      } else {
        throw Exception('无法加载 MBTI 分析: ${response.statusCode}');
      }
    } catch (e) {
      print('AnalyticsService: [fetchPersonality] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }

  // 4. 获取运势分析 (带本地缓存：一天只生成一次)
  static Future<Map<String, dynamic>> fetchFortune() async {
    final prefs = await SharedPreferences.getInstance();

    final String today = DateTime.now().toIso8601String().split('T')[0];

    final String? cachedDate = prefs.getString(_kFortuneDateKey);
    final String? cachedDataString = prefs.getString(_kFortuneDataKey);

    if (cachedDate == today && cachedDataString != null) {
      print('AnalyticsService: [fetchFortune] 使用本地缓存 (日期: $today)');
      return json.decode(cachedDataString) as Map<String, dynamic>;
    }

    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/analytics/fortune');
    print('AnalyticsService: [fetchFortune] 请求 API: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);
      print('AnalyticsService: [fetchFortune] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 200) {
        await prefs.setString(_kFortuneDateKey, today);
        await prefs.setString(_kFortuneDataKey, jsonString);

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