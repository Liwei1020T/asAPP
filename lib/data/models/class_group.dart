/// 班级模型
class ClassGroup {
  final String id;
  final String name;
  final String? level;
  final String? defaultVenue;
  final int? defaultDayOfWeek; // 0=周日, 1=周一, ..., 6=周六
  final String? defaultStartTime; // HH:mm 格式
  final String? defaultEndTime;
  final int? capacity;
  final String? defaultCoachId;
  final bool isActive;

  const ClassGroup({
    required this.id,
    required this.name,
    this.level,
    this.defaultVenue,
    this.defaultDayOfWeek,
    this.defaultStartTime,
    this.defaultEndTime,
    this.capacity,
    this.defaultCoachId,
    this.isActive = true,
  });

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    return ClassGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as String?,
      defaultVenue: json['default_venue'] as String?,
      defaultDayOfWeek: json['default_day_of_week'] as int?,
      defaultStartTime: json['default_start_time'] as String?,
      defaultEndTime: json['default_end_time'] as String?,
      capacity: json['capacity'] as int?,
      defaultCoachId: json['default_coach_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'default_venue': defaultVenue,
      'default_day_of_week': defaultDayOfWeek,
      'default_start_time': defaultStartTime,
      'default_end_time': defaultEndTime,
      'capacity': capacity,
      'default_coach_id': defaultCoachId,
      'is_active': isActive,
    };
  }

  ClassGroup copyWith({
    String? id,
    String? name,
    String? level,
    String? defaultVenue,
    int? defaultDayOfWeek,
    String? defaultStartTime,
    String? defaultEndTime,
    int? capacity,
    String? defaultCoachId,
    bool? isActive,
  }) {
    return ClassGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      defaultVenue: defaultVenue ?? this.defaultVenue,
      defaultDayOfWeek: defaultDayOfWeek ?? this.defaultDayOfWeek,
      defaultStartTime: defaultStartTime ?? this.defaultStartTime,
      defaultEndTime: defaultEndTime ?? this.defaultEndTime,
      capacity: capacity ?? this.capacity,
      defaultCoachId: defaultCoachId ?? this.defaultCoachId,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// 班级成员关系
class ClassMembership {
  final String classId;
  final String studentId;
  final DateTime joinedAt;
  final bool isActive;

  const ClassMembership({
    required this.classId,
    required this.studentId,
    required this.joinedAt,
    this.isActive = true,
  });

  factory ClassMembership.fromJson(Map<String, dynamic> json) {
    return ClassMembership(
      classId: json['class_id'] as String,
      studentId: json['student_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'student_id': studentId,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
