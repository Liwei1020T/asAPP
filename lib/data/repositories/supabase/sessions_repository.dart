import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session.dart';
import '../../models/attendance.dart';
import '../../models/student_session_attendance.dart';
import 'supabase_client_provider.dart';

/// Supabase 课程/排课仓库
class SupabaseSessionsRepository {
  /// 教练今天的课程
  Future<List<Session>> getTodaySessionsForCoach(String coachId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final data = await supabaseClient
        .from('sessions')
        .select()
        .or('coach_id.eq.$coachId,actual_coach_id.eq.$coachId')
        .gte('start_time', start.toIso8601String())
        .lt('start_time', end.toIso8601String())
        .not('status', 'eq', SessionStatus.cancelled.name)
        .order('start_time', ascending: true);

    return data.map((e) => _mapSession(e)).toList();
  }

  /// 教练即将到来的课程（包含今天之后）
  Future<List<Session>> getUpcomingSessionsForCoach(String coachId, {int limit = 5}) async {
    final now = DateTime.now().toIso8601String();
    final data = await supabaseClient
        .from('sessions')
        .select()
        .or('coach_id.eq.$coachId,actual_coach_id.eq.$coachId')
        .not('status', 'eq', SessionStatus.cancelled.name)
        .gt('start_time', now)
        .order('start_time', ascending: true)
        .limit(limit);

    return data.map((e) => _mapSession(e)).toList();
  }

  /// 获取所有今天的课程（不分教练）
  Future<List<Session>> getAllTodaySessions() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final data = await supabaseClient
        .from('sessions')
        .select()
        .gte('start_time', start.toIso8601String())
        .lt('start_time', end.toIso8601String())
        .not('status', 'eq', SessionStatus.cancelled.name)
        .order('start_time', ascending: true);

    return data.map((e) => _mapSession(e)).toList();
  }

  /// 获取所有即将到来的课程（不分教练）
  Future<List<Session>> getAllUpcomingSessions({int limit = 5}) async {
    final now = DateTime.now().toIso8601String();
    final data = await supabaseClient
        .from('sessions')
        .select()
        .not('status', 'eq', SessionStatus.cancelled.name)
        .gt('start_time', now)
        .order('start_time', ascending: true)
        .limit(limit);

    return data.map((e) => _mapSession(e)).toList();
  }

  /// 获取单个课程
  Future<Session?> getSession(String sessionId) async {
    final data = await supabaseClient
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (data == null) return null;
    return _mapSession(data);
  }

  /// 获取班级所有课程
  Future<List<Session>> getSessionsForClass(String classId) async {
    final data = await supabaseClient
        .from('sessions')
        .select()
        .eq('class_id', classId)
        .order('start_time', ascending: false);
    return data.map((e) => _mapSession(e)).toList();
  }

  /// 获取某学生可用的补课课次：
  /// - 所有班级的未来课程（不限制当前是否在该班）
  /// - 未被取消
  Future<List<Session>> getMakeupCandidateSessionsForStudent(
    String _studentId,
  ) async {
    final now = DateTime.now().toIso8601String();

    final sessionsData = await supabaseClient
        .from('sessions')
        .select()
        .gt('start_time', now)
        .not('status', 'eq', SessionStatus.cancelled.name)
        .order('start_time', ascending: true);

    final rows = sessionsData as List;
    return rows
        .map((e) => _mapSession(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取某学生指定月份的课程列表及出勤状态（用于家长端）
  Future<List<StudentSessionAttendance>> getMonthlySessionsForStudent(
    String studentId, {
    required DateTime monthStart,
  }) async {
    // 1. 查该学生所在的班级
    final memberships = await supabaseClient
        .from('class_memberships')
        .select('class_id')
        .eq('student_id', studentId)
        .eq('is_active', true);
    final membershipList = memberships as List;
    if (membershipList.isEmpty) return [];

    final classIds = membershipList
        .map((e) => (e as Map<String, dynamic>)['class_id'] as String)
        .toList();

    // 当月时间范围
    final startOfMonth = DateTime(monthStart.year, monthStart.month, 1);
    final startOfNextMonth =
        DateTime(monthStart.year, monthStart.month + 1, 1);

    // 2. 查当月这些班级的所有 sessions
    final sessionsData = await supabaseClient
        .from('sessions')
        .select()
        .inFilter('class_id', classIds)
        .gte('start_time', startOfMonth.toIso8601String())
        .lt('start_time', startOfNextMonth.toIso8601String())
        .order('start_time', ascending: true);

    final sessionRows = sessionsData as List;
    if (sessionRows.isEmpty) return [];

    final sessions = sessionRows
        .map((e) => _mapSession(e as Map<String, dynamic>))
        .toList();
    final sessionIds = sessions.map((s) => s.id).toList();

    // 3. 查该学生在这些 sessions 上的出勤记录
    final attendanceData = await supabaseClient
        .from('attendance')
        .select('session_id, status')
        .eq('student_id', studentId)
        .inFilter('session_id', sessionIds);

    final attendanceList = attendanceData as List;
    final statusBySessionId = <String, AttendanceStatus>{};
    for (final row in attendanceList) {
      final map = row as Map<String, dynamic>;
      final sid = map['session_id'] as String;
      final statusStr = map['status'] as String?;
      if (statusStr == null) continue;
      final status = AttendanceStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => AttendanceStatus.present,
      );
      statusBySessionId[sid] = status;
    }

    // 4. 组合视图模型
    return sessions
        .map(
          (s) => StudentSessionAttendance(
            session: s,
            status: statusBySessionId[s.id],
          ),
        )
        .toList();
  }

  /// 实时订阅班级课程
  Stream<List<Session>> watchSessionsForClass(String classId) {
    return supabaseClient
        .from('sessions')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .map((e) => _mapSession(e as Map<String, dynamic>))
              .where((s) => s.classId == classId)
              .toList();
          list.sort((a, b) => b.startTime.compareTo(a.startTime));
          return list;
        });
  }

  /// 教练本月已完成课程数
  Future<int> getMonthlyCompletedSessionsCount(String coachId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final response = await supabaseClient
        .from('sessions')
        .select('id')
        .eq('coach_id', coachId)
        .eq('status', SessionStatus.completed.name)
        .gte('completed_at', start);
    final rows = response as List;
    return rows.length;
  }

  /// 检查时间冲突（同班级或同教练的排课）
  Future<bool> hasTimeConflict({
    required String classId,
    required DateTime start,
    required DateTime end,
    String? coachId,
  }) async {
    var query = supabaseClient
        .from('sessions')
        .select('id')
        .lt('start_time', end.toIso8601String())
        .gt('end_time', start.toIso8601String())
        .eq('class_id', classId);

    if (coachId != null && coachId.isNotEmpty) {
      query = query.or('coach_id.eq.$coachId,actual_coach_id.eq.$coachId');
    }

    final res = await query;
    final rows = res as List;
    return rows.isNotEmpty;
  }

  /// 创建课程（排课）
  Future<Session> createSession(Session session) async {
    // 使用数据库默认 UUID：插入时不传 id
    final payload = session.toJson();
    payload.remove('id');

    final inserted = await supabaseClient
        .from('sessions')
        .insert(payload)
        .select()
        .single();
    return _mapSession(inserted as Map<String, dynamic>);
  }

  Future<Session> updateSession(Session session) async {
    final payload = session.toJson();
    final updated = await supabaseClient
        .from('sessions')
        .update(payload)
        .eq('id', session.id)
        .select()
        .single();
    return _mapSession(updated as Map<String, dynamic>);
  }

  Future<void> deleteSession(String sessionId) async {
    await supabaseClient.from('sessions').delete().eq('id', sessionId);
  }

  Session _mapSession(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      coachId: json['coach_id'] as String?,
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
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      className: json['class_name'] as String?,
      coachName: json['coach_name'] as String?,
    );
  }
}

/// Supabase Sessions Repository Provider
final supabaseSessionsRepositoryProvider = Provider<SupabaseSessionsRepository>((ref) {
  return SupabaseSessionsRepository();
});
