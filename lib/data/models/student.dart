/// 学员等级
enum StudentLevel {
  beginner,     // 初学者
  elementary,   // 基础
  intermediate, // 中级
  advanced,     // 高级
  professional, // 专业
}

/// 学员状态
enum StudentStatus {
  active,       // 活跃
  inactive,     // 不活跃
  graduated,    // 结业
  suspended,    // 暂停
}

/// 学员模型
class Student {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? gender;
  final String? phoneNumber;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? parentId;
  final String? parentName;
  final List<String> classIds;
  final StudentLevel level;
  final StudentStatus status;
  final DateTime enrollmentDate;
  final int remainingSessions;
  final int totalSessions;
  final double attendanceRate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Student({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.birthDate,
    this.gender,
    this.phoneNumber,
    this.emergencyContact,
    this.emergencyPhone,
    this.parentId,
    this.parentName,
    this.classIds = const [],
    this.level = StudentLevel.beginner,
    this.status = StudentStatus.active,
    required this.enrollmentDate,
    this.remainingSessions = 0,
    this.totalSessions = 0,
    this.attendanceRate = 0.0,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// 计算年龄
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// 是否活跃
  bool get isActive => status == StudentStatus.active;

  /// 课时余额百分比
  double get sessionBalancePercent {
    if (totalSessions == 0) return 0.0;
    return remainingSessions / totalSessions;
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String?,
      phoneNumber: json['phone_number'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      emergencyPhone: json['emergency_phone'] as String?,
      parentId: json['parent_id'] as String?,
      parentName: json['parent_name'] as String?,
      classIds: json['class_ids'] != null
          ? List<String>.from(json['class_ids'])
          : [],
      level: StudentLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => StudentLevel.beginner,
      ),
      status: StudentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StudentStatus.active,
      ),
      enrollmentDate: json['enrollment_date'] != null
          ? DateTime.parse(json['enrollment_date'] as String)
          : DateTime.now(),
      remainingSessions: json['remaining_sessions'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      attendanceRate: json['attendance_rate'] != null
          ? (json['attendance_rate'] as num).toDouble()
          : 0.0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'phone_number': phoneNumber,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'parent_id': parentId,
      'parent_name': parentName,
      'class_ids': classIds,
      'level': level.name,
      'status': status.name,
      'enrollment_date': enrollmentDate.toIso8601String(),
      'remaining_sessions': remainingSessions,
      'total_sessions': totalSessions,
      'attendance_rate': attendanceRate,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Student copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    DateTime? birthDate,
    String? gender,
    String? phoneNumber,
    String? emergencyContact,
    String? emergencyPhone,
    String? parentId,
    String? parentName,
    List<String>? classIds,
    StudentLevel? level,
    StudentStatus? status,
    DateTime? enrollmentDate,
    int? remainingSessions,
    int? totalSessions,
    double? attendanceRate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      classIds: classIds ?? this.classIds,
      level: level ?? this.level,
      status: status ?? this.status,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      remainingSessions: remainingSessions ?? this.remainingSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 学员等级显示名称
String getStudentLevelName(StudentLevel level) {
  switch (level) {
    case StudentLevel.beginner:
      return '初学者';
    case StudentLevel.elementary:
      return '基础';
    case StudentLevel.intermediate:
      return '中级';
    case StudentLevel.advanced:
      return '高级';
    case StudentLevel.professional:
      return '专业';
  }
}

/// 学员状态显示名称
String getStudentStatusName(StudentStatus status) {
  switch (status) {
    case StudentStatus.active:
      return '活跃';
    case StudentStatus.inactive:
      return '不活跃';
    case StudentStatus.graduated:
      return '结业';
    case StudentStatus.suspended:
      return '暂停';
  }
}
