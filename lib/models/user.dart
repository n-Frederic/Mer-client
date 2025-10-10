class User {
  // 核心身份字段
  final String userId;
  final String name;
  final String username;
  final String? email; // 邮箱和电话允许为空
  final String? phone;

  // 组织与权限关联字段
  final String teamId;  // 所属团队ID
  final String roleId;  // 所属角色ID

  // 时间戳
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.userId,
    required this.name,
    required this.username,
    this.email,
    this.phone,
    required this.teamId,
    required this.roleId,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // BIGINT 字段映射为 Dart String
    return User(
      userId: json['user_id'].toString(),
      name: json['name'] as String,
      username: json['username'] as String,

      // 可空字段安全读取
      email: json['email'] as String?,
      phone: json['phone'] as String?,

      // 关联 ID 字段映射
      teamId: json['team_id'].toString(),
      roleId: json['role_id'].toString(),

      // 时间处理
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    // 字段名映射回后端所需的 snake_case
    'user_id': userId,
    'name': name,
    'username': username,
    'email': email,
    'phone': phone,

    // 关联 ID 字段
    'team_id': teamId,
    'role_id': roleId,

    // 时间字段（通常创建/更新用户时，这些时间戳由后端处理）
    // 如果需要发送，则转换为 ISO 8601 字符串：
    // 'updated_at': updatedAt?.toIso8601String(),
  };
}