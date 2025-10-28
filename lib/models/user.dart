class User {
  final String userId;
  final String name;
  final String? username;
  final String email;
  final String? phone;

  final String? teamId;
  final String? roleId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.userId,
    required this.name,
    this.username,
    required this.email,
    this.phone,
    this.teamId,
    this.roleId,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final teamData = json['team'] as Map<String, dynamic>?;
    final roleData = json['role'] as Map<String, dynamic>?;

    return User(
      userId: (json['userId'] ?? json['user_id']).toString(),
      name: json['name'] as String,
      username: json['username'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      teamId: teamData?['team_id']?.toString() ?? json['team_id']?.toString(),
      roleId: roleData?['role_id']?.toString() ?? json['role_id']?.toString(),
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