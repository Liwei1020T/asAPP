/// 出勤状态枚举
enum AttendanceStatus {
  present, // 出席
  absent, // 缺席
  late, // 迟到
  leave, // 请假
}

/// 出勤记录模型
class Attendance {
  final String id;
  final String sessionId;
  final String studentId;
  final AttendanceStatus status;
  final String? coachNote;
  final String? aiFeedback;

  // 关联数据（可选，用于UI展示）
  final String? studentName;
  final String? studentAvatarUrl;
  final int? studentTotalAttended;

  const Attendance({
    required this.id,
    required this.sessionId,
    required this.studentId,
    this.status = AttendanceStatus.present,
    this.coachNote,
    this.aiFeedback,
    this.studentName,
    this.studentAvatarUrl,
    this.studentTotalAttended,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      studentId: json['student_id'] as String,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.present,
      ),
      coachNote: json['coach_note'] as String?,
      aiFeedback: json['ai_feedback'] as String?,
      studentName: json['student_name'] as String?,
      studentAvatarUrl: json['student_avatar_url'] as String?,
      studentTotalAttended: json['student_total_attended'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'student_id': studentId,
      'status': status.name,
      'coach_note': coachNote,
      'ai_feedback': aiFeedback,
    };
  }

  Attendance copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    AttendanceStatus? status,
    String? coachNote,
    String? aiFeedback,
    String? studentName,
    String? studentAvatarUrl,
    int? studentTotalAttended,
  }) {
    return Attendance(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      coachNote: coachNote ?? this.coachNote,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      studentName: studentName ?? this.studentName,
      studentAvatarUrl: studentAvatarUrl ?? this.studentAvatarUrl,
      studentTotalAttended: studentTotalAttended ?? this.studentTotalAttended,
    );
  }
}

/// 学生出勤统计
class StudentAttendanceSummary {
  final String studentId;
  final String studentName;
  final int totalSessions;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int leaveCount;

  const StudentAttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.totalSessions,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.leaveCount,
  });

  /// 出勤率
  double get attendanceRate {
    if (totalSessions == 0) return 0;
    return (presentCount + lateCount) / totalSessions;
  }
}
