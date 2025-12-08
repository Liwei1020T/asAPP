import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import 'supabase_client_provider.dart';

/// Supabase 请假与补课资格仓库
class SupabaseLeaveRepository {
  /// 学员请假并自动生成补课资格
  ///
  /// 约定：
  /// - 默认补课资格 1 次，默认有效期为课程开始后 30 天
  /// - 若已存在相同 (student_id, session_id) 的记录，则不会重复创建
  Future<void> createLeaveWithMakeup({
    required String studentId,
    required String sessionId,
    String? reason,
    DateTime? expiresAt,
    int maxUses = 1,
  }) async {
    // 查询课程以获取 class_id 与开始时间
    final sessionRow = await supabaseClient
        .from('sessions')
        .select('id, class_id, start_time')
        .eq('id', sessionId)
        .maybeSingle();

    if (sessionRow == null) {
      throw Exception('未找到课程');
    }

    final session = Session.fromJson({
      'id': sessionRow['id'],
      'class_id': sessionRow['class_id'],
      'start_time': sessionRow['start_time'],
      'end_time': sessionRow['start_time'],
      'status': SessionStatus.scheduled.name,
      'is_payable': true,
    });

    final defaultExpiry = expiresAt ??
        session.startTime.add(const Duration(days: 30));

    // 请假记录：使用 upsert，避免重复
    final leaveRows = await supabaseClient
        .from('leave_requests')
        .upsert(
      {
        'student_id': studentId,
        'session_id': sessionId,
        'reason': reason,
        'status': 'approved',
        'need_makeup': true,
        'expires_at': defaultExpiry.toIso8601String(),
        'max_uses': maxUses,
      },
      onConflict: 'student_id,session_id',
    )
        .select()
        .limit(1);

    final leave = (leaveRows as List).first as Map<String, dynamic>;
    final leaveId = leave['id'] as String;

    // 补课资格：同样按 (student_id, source_session_id) 去重
    await supabaseClient.from('session_makeup_rights').upsert(
      {
        'student_id': studentId,
        'source_session_id': sessionId,
        'class_id': session.classId,
        'leave_request_id': leaveId,
        'status': 'active',
        'max_uses': maxUses,
        'used_count': 0,
        'expires_at': defaultExpiry.toIso8601String(),
      },
      onConflict: 'student_id,source_session_id',
    );

    // 同步一条 attendance 记录为请假状态，方便点名页展示
    await supabaseClient.from('attendance').upsert(
      {
        'session_id': sessionId,
        'student_id': studentId,
        'status': 'leave',
      },
      onConflict: 'session_id,student_id',
    );
  }
}

final supabaseLeaveRepositoryProvider = Provider<SupabaseLeaveRepository>((ref) {
  return SupabaseLeaveRepository();
});

