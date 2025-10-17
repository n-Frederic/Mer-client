// role.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

class Role {
  // 对应 role_id (int, auto_increment)
  final int roleId;

  // 对应 name (varchar(100), unique)
  final String name;

  // 对应 description (text, nullable)
  final String? description;

  Role({
    required this.roleId,
    required this.name,
    this.description,
  });

  // ------------------------------------------------------------------
  // 1. 从 JSON 映射 (后端 -> 前端)
  // ------------------------------------------------------------------
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      // role_id 是 INT 类型
      roleId: json['role_id'] as int,
      name: json['name'] as String,
      // description 是可空 TEXT
      description: json['description'] as String?,
    );
  }

  // ------------------------------------------------------------------
  // 2. 转换为 JSON (前端 -> 后端)
  // ------------------------------------------------------------------
  Map<String, dynamic> toJson() => {
    // 创建角色时 role_id 可能不需要发送
    'role_id': roleId,
    'name': name,
    'description': description,
  };
}