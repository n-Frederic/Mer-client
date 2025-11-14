// lib/models/user.dart

class User {
  final int userId;
  final int? teamId;
  final int? roleId;
  final String name;
  final String? username;
  final String email;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.userId,
    this.teamId,
    this.roleId,
    required this.name,
    this.username,
    required this.email,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }


  factory User.fromJson(Map<String, dynamic> json) {

    final teamData = json['team'] as Map<String, dynamic>?;
    final roleData = json['role'] as Map<String, dynamic>?;

    return User(

      userId: _parseToInt(json['userId'] ?? json['user_id'])!,
      name: json['name'] as String,
      username: json['username'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,

      teamId: _parseToInt(teamData?['team_id'] ?? json['team_id']),

      roleId: _parseToInt(roleData?['role_id'] ?? json['role_id']),

      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {

    'user_id': userId,
    'name': name,
    'username': username,
    'email': email,
    'phone': phone,
    'team_id': teamId,
    'role_id': roleId,
  };
}