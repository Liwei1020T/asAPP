import 'package:asp_ms/data/models/attendance.dart';
import 'package:asp_ms/data/models/session.dart';

/// 学生某堂课的出勤视图模型（用于家长端）
class StudentSessionAttendance {
  final Session session;
  final AttendanceStatus? status;

  const StudentSessionAttendance({
    required this.session,
    this.status,
  });
}

