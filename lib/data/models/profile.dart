/// 用户角色枚举
enum UserRole {
  admin,
  coach,
  parent,
  student,
}

/// 用户 Profile 模型
class Profile {
  final String id;
  final String fullName;
  final UserRole role;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? parentId; // 学生关联的家长ID
  final double? ratePerSession; // 教练每节课费率
  final int totalClassesAttended;

  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.avatarUrl,
    this.parentId,
    this.ratePerSession,
    this.totalClassesAttended = 0,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      parentId: json['parent_id'] as String?,
      ratePerSession: json['rate_per_session'] != null
          ? (json['rate_per_session'] as num).toDouble()
          : null,
      totalClassesAttended: json['total_classes_attended'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role.name,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'parent_id': parentId,
      'rate_per_session': ratePerSession,
      'total_classes_attended': totalClassesAttended,
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    UserRole? role,
    String? phoneNumber,
    String? avatarUrl,
    String? parentId,
    double? ratePerSession,
    int? totalClassesAttended,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      parentId: parentId ?? this.parentId,
      ratePerSession: ratePerSession ?? this.ratePerSession,
      totalClassesAttended: totalClassesAttended ?? this.totalClassesAttended,
    );
  }
}
