class SessionMakeupRight {
  final String id;
  final String studentId;
  final String sourceSessionId;
  final String classId;
  final String? leaveRequestId;
  final String status;
  final int maxUses;
  final int usedCount;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SessionMakeupRight({
    required this.id,
    required this.studentId,
    required this.sourceSessionId,
    required this.classId,
    this.leaveRequestId,
    this.status = 'active',
    this.maxUses = 1,
    this.usedCount = 0,
    this.expiresAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory SessionMakeupRight.fromJson(Map<String, dynamic> json) {
    return SessionMakeupRight(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      sourceSessionId: json['source_session_id'] as String,
      classId: json['class_id'] as String,
      leaveRequestId: json['leave_request_id'] as String?,
      status: json['status'] as String? ?? 'active',
      maxUses: json['max_uses'] as int? ?? 1,
      usedCount: json['used_count'] as int? ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'source_session_id': sourceSessionId,
      'class_id': classId,
      'leave_request_id': leaveRequestId,
      'status': status,
      'max_uses': maxUses,
      'used_count': usedCount,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

