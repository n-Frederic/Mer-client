// models/task_user.dart
class TaskUser {
  final String userId;
  final String name;
  final String? email;
  final String? avatar;

  TaskUser({
    required this.userId,
    required this.name,
    this.email,
    this.avatar,
  });

  factory TaskUser.fromJson(Map<String, dynamic> json) {
    return TaskUser(
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '未知用户',
      email: json['email'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}