import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/log.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

// 定义日志列表的响应结构
class LogListResponse {
  final List<Log> logs;
  final int total;
  final int page;
  final int pageSize;

  LogListResponse({
    required this.logs,
    required this.total,
    required this.page,
    required this.pageSize,
  });
}

class LogService {
  static final String baseUrl = AppConfig.baseUrl;

  // 调用 GET /api/journals/scoped
  static Future<LogListResponse> fetchScopedLogs({
    required String mode,
    List<String>? memberIds,
    String? timeFilter,
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证');
    }

    // 构建查询参数
    final Map<String, String> params = {
      'mode': mode,
      'timeFilter': timeFilter ?? 'all',
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (mode == 'member' && memberIds != null && memberIds.isNotEmpty) {
      params['memberIds'] = memberIds.join(',');
    }
    if (keyword != null && keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }

    final uri = Uri.parse('$baseUrl/journals/scoped').replace(queryParameters: params);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['data'] == null) {
          throw Exception('响应格式错误: 未找到 "data" 字段');
        }
        final Map<String, dynamic> data = responseData['data'];
        final List<dynamic> jsonList = data['list'] ?? [];

        final List<Log> logs = jsonList.map((json) => Log.fromJson(json)).toList();

        return LogListResponse(
          logs: logs,
          total: data['total'] ?? 0,
          page: data['page'] ?? 1,
          pageSize: data['pageSize'] ?? 10,
        );

      } else {
        throw Exception('无法加载日志列表，服务器响应码: ${response.statusCode}');
      }
    } catch (e, s) {
      print('LogService 捕获到原始错误: $e');
      print('LogService 原始堆栈: $s');
      throw Exception('LogService 请求失败: $e');
    }
  }

  static Future<String> createLog({
    required String todaySummary,
    required String tomorrowPlan,
    required String helpNeeded,
    required List<String> taskId,
  }) async {
    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证');
    }

    final uri = Uri.parse('$baseUrl/journals/');
    final DateTime now = DateTime.now();
    final String formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final Map<String, dynamic> body = {
      'todaySummary': todaySummary,
      'tomorrowPlan': tomorrowPlan,
      'helpNeeded': helpNeeded,
      "log_date": formattedDate,
      'taskIds': taskId,
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData['ok'] == true && responseData.containsKey('id')) {
          return responseData['id'].toString(); // 返回新日志的 ID
        } else {
          throw Exception('创建日志失败: ${responseData['message'] ?? '未知错误'}');
        }
      } else {
        print('createLog 失败，请求的 URL: $uri');
        throw Exception('创建日志失败，服务器响应码: ${response.statusCode}');
      }
    } catch (e) {
      print('LogService 捕获到原始错误 (createLog): $e');
      throw Exception('LogService 请求失败: $e');
    }
  }

  static Future<Log> fetchLogById(String logId) async {

    final authToken = await AuthService.getSavedToken();
    if (authToken == null) {
      throw Exception('用户未认证');
    }

    final uri = Uri.parse('$baseUrl/journals/$logId');
    print('LogService: [fetchLogById] 请求: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final String jsonString = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(jsonString);

        // (根据你的 API 文档, 完整数据在 'data' 键中)
        if (responseData['code'] == 200 && responseData['data'] != null) {
          // (使用我们已更新的 Log.fromJson)
          return Log.fromJson(responseData['data']);
        } else {
          // (如果404或后端返回错误)
          if (responseData.containsKey('message')) {
            throw Exception('无法解析日志详情: ${responseData['message']}');
          }
          throw Exception('无法解析日志详情: 响应格式错误');
        }
      } else {
        throw Exception('无法加载日志详情，服务器响应码: ${response.statusCode}');
      }
    } catch (e, s) {
      print('LogService: [fetchLogById] 捕获到原始错误: $e');
      print('LogService: [fetchLogById] 原始堆栈: $s');
      throw Exception('LogService 请求失败: $e');
    }
  }

}