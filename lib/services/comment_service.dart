import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pandora_app/services/profile_service.dart';

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

    // 1. 准备参数
    final Map<String, String> params = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (ownerType == 'journal' || ownerType == 'log') {
      params['logId'] = ownerId;
    } else {
      params['taskId'] = ownerId;
    }

    final uri = Uri.parse('$baseUrl/comments').replace(queryParameters: params);
    print('CommentService: [fetchComments] 请求: $uri');

    try {
      final response = await http.get(uri, headers: headers);
      final String jsonString = utf8.decode(response.bodyBytes);
      print('CommentService: [fetchComments] 响应 (${response.statusCode}): $jsonString');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(jsonString);

        if (responseData['code'] == 200 && responseData['data'] != null) {
          final data = responseData['data'];
          final List<dynamic> commentsJson = data['comments'] ?? [];

          final List<Comment> comments = commentsJson.map((item) {
            return Comment.fromJson(item as Map<String, dynamic>);
          }).toList();

          return CommentListResponse(
            comments: comments,
            total: data['total'] ?? 0,
            page: data['page'] ?? 1,
            pageSize: data['pageSize'] ?? 10,
          );
        } else {
          throw Exception('获取评论失败: ${responseData['message'] ?? '响应格式错误'}');
        }
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
    required String ownerId, // (这里的 ownerId 是被评论对象 ID)
    required String content,
  }) async {
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$baseUrl/comments');

    final userId = await AuthService.getSavedUserId();
    if (userId == null) {
      throw Exception('无法获取当前用户ID');
    }

    final Map<String, dynamic> bodyMap = {
      // 1. 评论内容
      'content': content,
      // 2. 评论者 ID (后端叫 'ownerId')
      'ownerId': userId,
    };

    // 3. 被评论对象 ID (根据类型决定键名)
    if (ownerType == 'journal' || ownerType == 'log') {
      bodyMap['logId'] = ownerId; // 日志 ID
    } else {
      bodyMap['taskId'] = ownerId; // 任务 ID
    }
    final body = json.encode(bodyMap);
    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String jsonString = utf8.decode(response.bodyBytes);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(jsonString);

        if ((responseData['code'] == 201 || responseData['code'] == 200) && responseData['data'] != null) {
          final data = responseData['data'];

          final String authorIdStr = (data['ownerId'] ?? userId).toString();
          String authorName = '我';
          if (authorIdStr.isNotEmpty) {
            try {
              final userProfile = await ProfileService.fetchUserById(authorIdStr);
              if (userProfile.containsKey('name')) {
                authorName = userProfile['name'];
              }
            } catch (e) { /* ignore */ }
          }

          return Comment(
            commentId: (data['commentId'] ?? '').toString(),
            ownerType: ownerType,
            ownerId: (data['logId'] ?? data['taskId'] ?? ownerId).toString(),
            authorId: authorIdStr,
            content: data['content'] ?? '',
            createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
            authorInfo: AuthorInfo(
              userId: authorIdStr,
              name: authorName,
            ),
          );
        } else {
          throw Exception('创建评论失败: ${responseData['message'] ?? '响应格式错误'}');
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
  // 在 lib/services/comment_service.dart -> CommentService 类中...

  static Future<bool> deleteComment(String commentId) async {
    final headers = await _getAuthHeaders();

    final userId = await AuthService.getSavedUserId();
    if (userId == null) {
      throw Exception('无法获取当前用户ID');
    }

    final Map<String, String> params = {
      'userId': userId.toString()
    };

    final uri = Uri.parse('$baseUrl/comments/$commentId').replace(queryParameters: params);
    try {
      final response = await http.delete(
        uri,
        headers: headers,
      );

      final String jsonString = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final responseData = json.decode(jsonString);
        return responseData['code'] == 200;
      } else {
        if (response.statusCode == 403) {
          throw Exception('无权删除此评论');
        }
        throw Exception('删除评论失败: ${response.statusCode}');
      }
    } catch (e) {
      print('CommentService: [deleteComment] 错误: $e');
      throw Exception('请求失败: $e');
    }
  }
}