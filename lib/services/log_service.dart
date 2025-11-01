// lib/services/log_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/log.dart';
import 'auth_service.dart';

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
  // 确保这个 _baseUrl 与您的 TaskService 一致
  static const String _baseUrl = 'http://10.0.2.2:8080/api';

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
      params['memberIds'] = memberIds.join(','); // 转换为 "1002,1003"
    }
    if (keyword != null && keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }

    final uri = Uri.parse('$_baseUrl/journals/scoped').replace(queryParameters: params);

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

        // 假设 API 成功时返回的 JSON 结构与 TaskListResponse 类似
        // { "list": [...], "total": ..., "page": ..., "pageSize": ... }
        final List<dynamic> jsonList = responseData['list'] ?? [];

        final List<Log> logs = jsonList.map((json) => Log.fromJson(json)).toList();

        return LogListResponse(
          logs: logs,
          total: responseData['total'] ?? 0,
          page: responseData['page'] ?? 1,
          pageSize: responseData['pageSize'] ?? 10,
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

// (我们还可以在这里添加 createLog 等方法)
}