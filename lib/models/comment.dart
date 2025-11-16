import 'dart:convert';

class AuthorInfo {
  final String userId;
  final String name;

  AuthorInfo({required this.userId, required this.name});

  factory AuthorInfo.fromJson(Map<String, dynamic> json) {
    return AuthorInfo(
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      name: json['name'] as String? ?? '未知作者',
    );
  }
}

class Comment {
  final String commentId;
  final String ownerType;
  final String ownerId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final AuthorInfo authorInfo;

  Comment({
    required this.commentId,
    required this.ownerType,
    required this.ownerId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.authorInfo,
  });

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) return DateTime.parse(dateValue);
    return DateTime.now();
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: (json['commentId'] ?? json['comment_id'] ?? '').toString(),
      ownerType: json['ownerType'] as String? ?? 'unknown',
      ownerId: (json['ownerId'] ?? json['owner_id'] ?? '').toString(),
      authorId: (json['authorId'] ?? json['author_id'] ?? '').toString(),
      content: json['content'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      authorInfo: AuthorInfo.fromJson(
          json['authorInfo'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// 辅助类, 用于解析 GET /api/comments 的响应
class CommentListResponse {
  final List<Comment> comments;
  final int total;
  final int page;
  final int pageSize;

  CommentListResponse({
    required this.comments,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory CommentListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> jsonList = json['list'] ?? [];
    final List<Comment> comments =
    jsonList.map((item) => Comment.fromJson(item)).toList();

    return CommentListResponse(
      comments: comments,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
    );
  }
}