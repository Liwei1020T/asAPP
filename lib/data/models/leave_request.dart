class LeaveRequest {
  final String id;
  final String studentId;
  final String sessionId;
  final String? reason;
  final String status;
  final bool needMakeup;
  final DateTime? expiresAt;
  final int maxUses;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? processedAt;

  const LeaveRequest({
    required this.id,
    required this.studentId,
    required this.sessionId,
    this.reason,
    this.status = 'approved',
    this.needMakeup = true,
    this.expiresAt,
    this.maxUses = 1,
    this.createdBy,
    required this.createdAt,
    this.processedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      sessionId: json['session_id'] as String,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'approved',
      needMakeup: json['need_makeup'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      maxUses: json['max_uses'] as int? ?? 1,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'session_id': sessionId,
      'reason': reason,
      'status': status,
      'need_makeup': needMakeup,
      'expires_at': expiresAt?.toIso8601String(),
      'max_uses': maxUses,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }
}

