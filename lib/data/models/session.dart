/// 课程状态枚举
enum SessionStatus {
  scheduled,
  completed,
  cancelled,
}

/// 课程（单次上课）模型
class Session {
  final String id;
  final String classId;
  final String coachId;
  final String? title;
  final String? venue;
  final String? venueId;
  final DateTime startTime;
  final DateTime endTime;
  final SessionStatus status;
  final bool isPayable;
  final String? actualCoachId;
  final DateTime? completedAt;

  // 关联数据（可选，用于UI展示）
  final String? className;
  final String? coachName;

  const Session({
    required this.id,
    required this.classId,
    required this.coachId,
    this.title,
    this.venue,
    this.venueId,
    required this.startTime,
    required this.endTime,
    this.status = SessionStatus.scheduled,
    this.isPayable = true,
    this.actualCoachId,
    this.completedAt,
    this.className,
    this.coachName,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      coachId: json['coach_id'] as String,
      title: json['title'] as String?,
      venue: json['venue'] as String?,
      venueId: json['venue_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      isPayable: json['is_payable'] as bool? ?? true,
      actualCoachId: json['actual_coach_id'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      className: json['class_name'] as String?,
      coachName: json['coach_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'coach_id': coachId,
      'title': title,
      'venue': venue,
      'venue_id': venueId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status.name,
      'is_payable': isPayable,
      'actual_coach_id': actualCoachId,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Session copyWith({
    String? id,
    String? classId,
    String? coachId,
    String? title,
    String? venue,
    String? venueId,
    DateTime? startTime,
    DateTime? endTime,
    SessionStatus? status,
    bool? isPayable,
    String? actualCoachId,
    DateTime? completedAt,
    String? className,
    String? coachName,
  }) {
    return Session(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      coachId: coachId ?? this.coachId,
      title: title ?? this.title,
      venue: venue ?? this.venue,
      venueId: venueId ?? this.venueId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      isPayable: isPayable ?? this.isPayable,
      actualCoachId: actualCoachId ?? this.actualCoachId,
      completedAt: completedAt ?? this.completedAt,
      className: className ?? this.className,
      coachName: coachName ?? this.coachName,
    );
  }

  /// 是否是今天的课程
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  /// 是否已经开始
  bool get hasStarted => DateTime.now().isAfter(startTime);

  /// 是否已经结束
  bool get hasEnded => DateTime.now().isAfter(endTime);
}
