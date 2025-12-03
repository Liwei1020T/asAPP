import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/attendance.dart';
import 'supabase_client_provider.dart';

/// Supabase 出勤仓库
class SupabaseAttendanceRepository {
  /// 获取课程的出勤记录（包含学生信息）
  Future<List<Attendance>> getStudentsForRollCall(String sessionId, String classId) async {
    // 已有出勤记录
    final existing = await supabaseClient
        .from('attendance')
        .select()
        .eq('session_id', sessionId);

    // 班级成员（student_id 指向 students.id）
    final memberships = await supabaseClient
        .from('class_memberships')
        .select('student_id')
        .eq('class_id', classId)
        .eq('is_active', true);
    final studentIds = (memberships as List)
        .map((e) => (e as Map<String, dynamic>)['student_id'] as String)
        .toList();

    // 补全学生信息（来自 students 表）
    List<Map<String, dynamic>> students = [];
    if (studentIds.isNotEmpty) {
      final response = await supabaseClient
          .from('students')
          .select('id, full_name, avatar_url')
          .inFilter('id', studentIds);
      students = (response as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    final studentMap = {for (final s in students) s['id'] as String: s};

    final attendanceByStudent = <String, Attendance>{};
    for (final item in existing) {
      final studentId = item['student_id'] as String;
      final student = studentMap[studentId] ?? {};
      attendanceByStudent[studentId] = Attendance.fromJson({
        ...item,
        'student_name': student['full_name'],
        'student_avatar_url': student['avatar_url'],
        'student_total_attended': null,
      });
    }

    final result = <Attendance>[];
    for (final id in studentIds) {
      if (attendanceByStudent.containsKey(id)) {
        result.add(attendanceByStudent[id]!);
      } else {
        final student = studentMap[id] ?? {};
        result.add(
          Attendance(
            id: 'att-$sessionId-$id',
            sessionId: sessionId,
            studentId: id,
            status: AttendanceStatus.present,
            studentName: student['full_name'] as String?,
            studentAvatarUrl: student['avatar_url'] as String?,
            studentTotalAttended: null,
          ),
        );
      }
    }

    return result;
  }

  /// 实时订阅某堂课的出勤记录（仅返回 attendance 表字段）
  Stream<List<Attendance>> watchAttendanceForSession(String sessionId) {
    return supabaseClient
        .from('attendance')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
              .where((a) => a.sessionId == sessionId)
              .toList();
          return list;
        });
  }

  /// 实时订阅班级成员（仅返回 student_id 列，供点名页检测新增/移除）
  Stream<List<String>> watchClassMemberIds(String classId) {
    return supabaseClient
        .from('class_memberships')
        .stream(primaryKey: ['class_id', 'student_id'])
        .map((rows) => rows
            .where((e) =>
                (e as Map<String, dynamic>)['class_id'] == classId &&
                (e)['is_active'] == true)
            .map((e) => (e as Map<String, dynamic>)['student_id'] as String)
            .toList());
  }

  /// 提交/更新点名
  Future<void> submitAttendance(String sessionId, List<Attendance> attendanceList) async {
    // 对于新建的出勤记录（本地临时 id 形如 att-...），不传 id，使用数据库默认 UUID
    final rows = attendanceList.map((a) {
      final row = a.toJson();
      final id = row['id'] as String?;
      if (id != null && id.startsWith('att-')) {
        row.remove('id');
      }
      return row;
    }).toList();

    await supabaseClient.from('attendance').upsert(rows);
  }

  /// 获取学生本月出勤统计
  Future<StudentAttendanceSummary> getMonthlyAttendanceSummary(String studentId, String studentName) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1).toIso8601String();
      final data = await supabaseClient
          .from('attendance')
          .select('status')
          .eq('student_id', studentId)
          .gte('created_at', start) as List;

      int present = 0, absent = 0, late = 0, leave = 0;
      for (final row in data) {
        switch (row['status']) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
          case 'leave':
            leave++;
            break;
          default:
        }
      }

      final total = data.length;
      return StudentAttendanceSummary(
        studentId: studentId,
        studentName: studentName,
        totalSessions: total,
        presentCount: present,
        absentCount: absent,
        lateCount: late,
        leaveCount: leave,
      );
    } catch (_) {
      // 若表结构与过滤不匹配则返回空统计，防止阻塞 UI
      return StudentAttendanceSummary(
        studentId: studentId,
        studentName: studentName,
        totalSessions: 0,
        presentCount: 0,
        absentCount: 0,
        lateCount: 0,
        leaveCount: 0,
      );
    }
  }
}

final supabaseAttendanceRepositoryProvider = Provider<SupabaseAttendanceRepository>((ref) {
  return SupabaseAttendanceRepository();
});
