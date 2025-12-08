/// 课时状态枚举
enum ShiftStatus {
  scheduled,  // 已排班，待上课
  completed,  // 已完成
  cancelled,  // 已取消
}

/// 教练课时记录模型
class CoachShift {
  final String id;
  final String coachId;
  final String? sessionId;
  final String? classId;
  final String? className;
  final DateTime date;
  final String startTime;
  final String endTime;
  final ShiftStatus status;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final double? clockInLat;
  final double? clockInLng;
  final double? clockOutLat;
  final double? clockOutLng;

  const CoachShift({
    required this.id,
    required this.coachId,
    this.sessionId,
    this.classId,
    this.className,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = ShiftStatus.scheduled,
    this.clockInAt,
    this.clockOutAt,
    this.clockInLat,
    this.clockInLng,
    this.clockOutLat,
    this.clockOutLng,
  });

  factory CoachShift.fromJson(Map<String, dynamic> json) {
    return CoachShift(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      sessionId: json['session_id'] as String?,
      classId: json['class_id'] as String?,
      className: json['class_name'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      status: ShiftStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ShiftStatus.scheduled,
      ),
      clockInAt: json['clock_in_at'] != null
          ? DateTime.parse(json['clock_in_at'] as String)
          : null,
      clockOutAt: json['clock_out_at'] != null
          ? DateTime.parse(json['clock_out_at'] as String)
          : null,
      clockInLat: json['clock_in_lat'] != null
          ? (json['clock_in_lat'] as num).toDouble()
          : null,
      clockInLng: json['clock_in_lng'] != null
          ? (json['clock_in_lng'] as num).toDouble()
          : null,
      clockOutLat: json['clock_out_lat'] != null
          ? (json['clock_out_lat'] as num).toDouble()
          : null,
      clockOutLng: json['clock_out_lng'] != null
          ? (json['clock_out_lng'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'session_id': sessionId,
      'class_id': classId,
      'class_name': className,
      'date': date.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'status': status.name,
      'clock_in_at': clockInAt?.toIso8601String(),
      'clock_out_at': clockOutAt?.toIso8601String(),
      'clock_in_lat': clockInLat,
      'clock_in_lng': clockInLng,
      'clock_out_lat': clockOutLat,
      'clock_out_lng': clockOutLng,
    };
  }

  /// 是否已打卡下班
  bool get isClockedOut => clockOutAt != null;
}

/// 教练月度课时统计（来自 VIEW coach_session_summary）
class CoachSessionSummary {
  final String coachId;
  final DateTime month; // 月份第一天
  final int totalSessions;
  final double ratePerSession;
  final double totalSalary;

  const CoachSessionSummary({
    required this.coachId,
    required this.month,
    required this.totalSessions,
    required this.ratePerSession,
    required this.totalSalary,
  });

  factory CoachSessionSummary.fromJson(Map<String, dynamic> json) {
    return CoachSessionSummary(
      coachId: json['coach_id'] as String,
      month: DateTime.parse(json['month'] as String),
      totalSessions: json['total_sessions'] as int,
      ratePerSession: (json['rate_per_session'] as num).toDouble(),
      totalSalary: (json['total_salary'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coach_id': coachId,
      'month': month.toIso8601String(),
      'total_sessions': totalSessions,
      'rate_per_session': ratePerSession,
      'total_salary': totalSalary,
    };
  }
}
