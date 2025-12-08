class SessionReplacement {
  final String id;
  final String studentId;
  final String sourceSessionId;
  final String targetSessionId;
  final String? makeupRightId;
  final String status;
  final String? createdBy;
  final DateTime createdAt;

  const SessionReplacement({
    required this.id,
    required this.studentId,
    required this.sourceSessionId,
    required this.targetSessionId,
    this.makeupRightId,
    this.status = 'booked',
    this.createdBy,
    required this.createdAt,
  });

  factory SessionReplacement.fromJson(Map<String, dynamic> json) {
    return SessionReplacement(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      sourceSessionId: json['source_session_id'] as String,
      targetSessionId: json['target_session_id'] as String,
      makeupRightId: json['makeup_right_id'] as String?,
      status: json['status'] as String? ?? 'booked',
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'source_session_id': sourceSessionId,
      'target_session_id': targetSessionId,
      'makeup_right_id': makeupRightId,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

