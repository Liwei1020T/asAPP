import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach_shift.dart';
import 'supabase_client_provider.dart';

/// Supabase HR 仓库：课时/薪资
class SupabaseHrRepository {
  /// 获取教练指定月份的课时列表
  Future<List<CoachShift>> getCoachShifts(String coachId, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final data = await supabaseClient
        .from('coach_shifts')
        .select()
        .eq('coach_id', coachId)
        .gte('date', start.toIso8601String())
        .lt('date', end.toIso8601String())
        .order('date', ascending: false);

    return (data as List)
        .map((e) => CoachShift.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 实时订阅指定月份的教练课时
  Stream<List<CoachShift>> watchCoachShifts(String coachId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return supabaseClient
        .from('coach_shifts')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .map((e) => CoachShift.fromJson(e as Map<String, dynamic>))
              .where((s) =>
                  s.coachId == coachId &&
                  s.date.isAtSameMomentAs(start) ||
                  (s.date.isAfter(start) && s.date.isBefore(end)))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  /// 月度薪资摘要（使用视图 coach_session_summary）
  Future<CoachSessionSummary?> getMonthlySummary(String coachId, [DateTime? month]) async {
    final targetMonth = DateTime(
      (month ?? DateTime.now()).year,
      (month ?? DateTime.now()).month,
      1,
    );
    final monthKey = targetMonth.toIso8601String();
    final response = await supabaseClient
        .from('coach_session_summary')
        .select()
        .eq('coach_id', coachId)
        .eq('month', monthKey)
        .maybeSingle();
    if (response == null) return null;
    return CoachSessionSummary.fromJson(response as Map<String, dynamic>);
  }

  /// 获取教练历史薪资统计（按月倒序）
  Future<List<CoachSessionSummary>> getHistorySummaries(
    String coachId, {
    int months = 6,
  }) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - months + 1, 1);

    final data = await supabaseClient
        .from('coach_session_summary')
        .select()
        .eq('coach_id', coachId)
        .gte('month', from.toIso8601String())
        .order('month', ascending: false);

    return (data as List)
        .map((e) => CoachSessionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 按课程打卡上班（与具体 session 绑定）
  Future<CoachShift> clockInForSession({
    required String coachId,
    required String sessionId,
    required String classId,
    required String className,
    required DateTime sessionStartTime,
    double? lat,
    double? lng,
  }) async {
    final date = DateTime(sessionStartTime.year, sessionStartTime.month, sessionStartTime.day);
    final now = DateTime.now();
    final pathTime = _formatTime(now);

    // 若已存在该课程的打卡记录，则更新 clock_in 信息
    final existing = await supabaseClient
        .from('coach_shifts')
        .select()
        .eq('coach_id', coachId)
        .eq('session_id', sessionId)
        .maybeSingle();

    if (existing != null) {
      final updated = await supabaseClient
          .from('coach_shifts')
          .update({
            'date': date.toIso8601String(),
            'class_id': classId,
            'class_name': className,
            'start_time': existing['start_time'] ?? pathTime,
            'clock_in_at': now.toIso8601String(),
            'clock_in_lat': lat,
            'clock_in_lng': lng,
          })
          .eq('id', existing['id'])
          .select()
          .single();

      // Ensure actual_coach_id is set
      try {
        await supabaseClient
            .from('sessions')
            .update({'actual_coach_id': coachId})
            .eq('id', sessionId);
      } catch (_) {}

      return CoachShift.fromJson(updated as Map<String, dynamic>);
    }

    // 否则创建新的课时打卡记录
    final row = {
      'coach_id': coachId,
      'session_id': sessionId,
      'class_id': classId,
      'class_name': className,
      'date': date.toIso8601String(),
      'start_time': pathTime,
      'end_time': '',
      'status': ShiftStatus.scheduled.name,
      'clock_in_at': now.toIso8601String(),
      'clock_in_lat': lat,
      'clock_in_lng': lng,
    };

    final inserted = await supabaseClient
        .from('coach_shifts')
        .insert(row)
        .select()
        .single();

    // 更新课程的实际执教教练
    try {
      await supabaseClient
          .from('sessions')
          .update({'actual_coach_id': coachId})
          .eq('id', sessionId);
    } catch (_) {
      // 忽略更新失败，不阻塞打卡
    }

    return CoachShift.fromJson(inserted as Map<String, dynamic>);
  }

  /// 按课程打卡下班（与具体 session 绑定）
  Future<CoachShift> clockOutForSession({
    required String coachId,
    required String sessionId,
    double? lat,
    double? lng,
  }) async {
    final now = DateTime.now();

    // 找到该课程尚未下班的打卡记录
    final openShift = await supabaseClient
        .from('coach_shifts')
        .select()
        .eq('coach_id', coachId)
        .eq('session_id', sessionId)
        .isFilter('clock_out_at', null)
        .order('clock_in_at', ascending: false)
        .limit(1)
        .maybeSingle();

    Map<String, dynamic> shiftRow;

    if (openShift == null) {
      // 若没有找到，则补一条已完成的课时记录，避免阻塞流程
      final row = {
        'coach_id': coachId,
        'session_id': sessionId,
        'date': DateTime(now.year, now.month, now.day).toIso8601String(),
        'start_time': _formatTime(now),
        'end_time': _formatTime(now),
        'status': ShiftStatus.completed.name,
        'clock_in_at': now.toIso8601String(),
        'clock_out_at': now.toIso8601String(),
        'clock_out_lat': lat,
        'clock_out_lng': lng,
      };
      shiftRow = await supabaseClient
          .from('coach_shifts')
          .insert(row)
          .select()
          .single() as Map<String, dynamic>;
    } else {
      shiftRow = await supabaseClient
          .from('coach_shifts')
          .update({
            'clock_out_at': now.toIso8601String(),
            'clock_out_lat': lat,
            'clock_out_lng': lng,
            'end_time': _formatTime(now),
            'status': ShiftStatus.completed.name,
          })
          .eq('id', openShift['id'])
          .select()
          .single() as Map<String, dynamic>;
    }

    // 同步更新 sessions 状态为 completed，写入 completed_at
    try {
      await supabaseClient
          .from('sessions')
          .update({
            'status': 'completed',
            'completed_at': now.toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (_) {
      // 若同步失败，不影响打卡记录本身
    }

    return CoachShift.fromJson(shiftRow);
  }

  /// 打卡上班
  Future<CoachShift> clockIn(String coachId, {double? lat, double? lng}) async {
    final now = DateTime.now();
    final pathTime = _formatTime(now);
    final row = {
      'coach_id': coachId,
      'date': DateTime(now.year, now.month, now.day).toIso8601String(),
      'start_time': pathTime,
      'end_time': '',
      'status': ShiftStatus.scheduled.name,
      'clock_in_at': now.toIso8601String(),
      'clock_in_lat': lat,
      'clock_in_lng': lng,
    };

    final inserted = await supabaseClient
        .from('coach_shifts')
        .insert(row)
        .select()
        .single();
    return CoachShift.fromJson(inserted as Map<String, dynamic>);
  }

  /// 打卡下班
  Future<CoachShift> clockOut(String coachId, {double? lat, double? lng}) async {
    // 找到最近的未结束记录
    final openShift = await supabaseClient
        .from('coach_shifts')
        .select()
        .eq('coach_id', coachId)
        .isFilter('clock_out_at', null)
        .order('clock_in_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (openShift == null) {
      throw Exception('未找到正在进行的打卡记录');
    }

    final now = DateTime.now();
    final updated = await supabaseClient
        .from('coach_shifts')
        .update({
          'clock_out_at': now.toIso8601String(),
          'clock_out_lat': lat,
          'clock_out_lng': lng,
          'end_time': _formatTime(now),
          'status': ShiftStatus.completed.name,
        })
        .eq('id', openShift['id'])
        .select()
        .single();

    return CoachShift.fromJson(updated as Map<String, dynamic>);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

final supabaseHrRepositoryProvider = Provider<SupabaseHrRepository>((ref) {
  return SupabaseHrRepository();
});
