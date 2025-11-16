import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/comment.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class CommentService {
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

  // 1. 获取评论列表 (GET /api/comments)
  static Future<CommentListResponse> fetchComments({
    required String ownerType,
    required String ownerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final headers = await _getAuthHeaders();
    final Map<String, String> params = {
      'ownerType': ownerType,
      'ownerId': ownerId,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse('$baseUrl/comments').replace(queryParameters: params);
    print('CommentService: [fetchComments] 请求: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);
      print('CommentService: [fetchComments] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 200) {
        return CommentListResponse.fromJson(json.decode(jsonString));
      } else {
        throw Exception('无法加载评论列表: ${response.statusCode}');
      }
    } catch (e) {
      print('CommentService: [fetchComments] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }

  // 2. 创建评论 (POST /api/comments)
  static Future<Comment> createComment({
    required String ownerType,
    required String ownerId,
    required String content,
  }) async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/comments');

    final body = json.encode({
      'ownerType': ownerType,
      'ownerId': ownerId,
      'content': content,
      // 'authorId' 将由后端从 Token 中提取
    });

    print('CommentService: [createComment] 请求: $uri');

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String jsonString = utf8.decode(response.bodyBytes);
      print('CommentService: [createComment] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 201) { // 201 Created
        final responseData = json.decode(jsonString);
        // 根据 API 文档, 新评论在 "data" 键中
        if (responseData['code'] == 201 && responseData['data'] != null) {
          return Comment.fromJson(responseData['data']);
        } else {
          throw Exception('创建评论失败: 响应格式错误');
        }
      } else {
        throw Exception('创建评论失败: ${response.statusCode}');
      }
    } catch (e) {
      print('CommentService: [createComment] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }

  // 3. 删除评论 (DELETE /api/comments/{commentId})
  static Future<bool> deleteComment(String commentId) async {
    final headers = await _getAuthHeaders();
    // 假设删除接口也需要结尾的斜杠 (如果不需要，请移除它)
    final uri = Uri.parse('$baseUrl/comments/$commentId/');

    print('CommentService: [deleteComment] 请求: $uri');

    try {
      final response = await http.delete(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);
      print('CommentService: [deleteComment] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 200) {
        final responseData = json.decode(jsonString);
        return responseData['code'] == 200;
      } else {
        throw Exception('删除评论失败: ${response.statusCode}');
      }
    } catch (e) {
      print('CommentService: [deleteComment] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }
}