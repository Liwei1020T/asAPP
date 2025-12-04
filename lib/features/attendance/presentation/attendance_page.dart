import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/attendance_repository.dart';
import '../../../data/repositories/supabase/sessions_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../../data/repositories/supabase/hr_repository.dart';

/// 点名页面
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  Session? _session;
  List<Attendance> _attendanceList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  StreamSubscription<List<Attendance>>? _attendanceSub;
  StreamSubscription<List<String>>? _membersSub;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 加载课程信息（Supabase）
      final session =
          await ref.read(supabaseSessionsRepositoryProvider).getSession(widget.sessionId);

      if (session != null) {
        // 加载学生列表
        final students =
          await ref.read(supabaseAttendanceRepositoryProvider).getStudentsForRollCall(
                widget.sessionId,
                session.classId,
              );

        if (mounted) {
          setState(() {
            _session = session;
            _attendanceList = students;
            _isLoading = false;
          });
          // 进入点名页即为本节课打卡上班
          await _clockInForSession();
          _subscribeAttendance();
          _subscribeMembers();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    }
  }

  void _updateStatus(int index, AttendanceStatus status) {
    setState(() {
      _attendanceList[index] = _attendanceList[index].copyWith(status: status);
    });
  }

  void _subscribeAttendance() {
    _attendanceSub?.cancel();
    _attendanceSub = ref
        .read(supabaseAttendanceRepositoryProvider)
        .watchAttendanceForSession(widget.sessionId)
        .listen((rows) {
      if (!mounted) return;
      setState(() {
        for (final row in rows) {
          final idx = _attendanceList.indexWhere((a) => a.studentId == row.studentId);
          if (idx >= 0) {
            // 用实时状态更新本地记录，保留学生信息
            _attendanceList[idx] = _attendanceList[idx].copyWith(
              status: row.status,
              coachNote: row.coachNote,
              aiFeedback: row.aiFeedback,
            );
          }
        }
      });
    });
  }

  void _subscribeMembers() {
    _membersSub?.cancel();
    final classId = _session?.classId;
    if (classId == null) return;
    _membersSub = ref
        .read(supabaseAttendanceRepositoryProvider)
        .watchClassMemberIds(classId)
        .listen((_) => _reloadStudents());
  }

  Future<void> _reloadStudents() async {
    final classId = _session?.classId;
    if (classId == null) return;
    try {
      final students = await ref
          .read(supabaseAttendanceRepositoryProvider)
          .getStudentsForRollCall(widget.sessionId, classId);
      if (mounted) {
        setState(() {
          _attendanceList = students;
        });
      }
    } catch (_) {
      // 静默失败，保持现有列表
    }
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(supabaseAttendanceRepositoryProvider)
          .submitAttendance(widget.sessionId, _attendanceList);
      // 点名提交成功后，为本节课打卡下班
      await _clockOutForSession();

      // 统计
      final presentCount = _attendanceList.where((a) => a.status == AttendanceStatus.present).length;
      final absentCount = _attendanceList.where((a) => a.status == AttendanceStatus.absent).length;
      final leaveCount = _attendanceList.where((a) => a.status == AttendanceStatus.leave).length;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('点名提交成功！出席 $presentCount 人，缺席 $absentCount 人，请假 $leaveCount 人'),
            backgroundColor: ASColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // 返回上一页
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：$e'),
            backgroundColor: ASColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _clockInForSession() async {
    final session = _session;
    final currentUser = ref.read(currentUserProvider);
    if (session == null || currentUser == null) return;

    try {
      await ref.read(supabaseHrRepositoryProvider).clockInForSession(
            coachId: currentUser.id,
            sessionId: session.id,
            classId: session.classId,
            className: session.className ?? (session.title ?? ''),
            sessionStartTime: session.startTime,
          );
    } catch (_) {
      // 打卡失败不阻塞点名流程，静默处理或按需增加提示
    }
  }

  Future<void> _clockOutForSession() async {
    final session = _session;
    final currentUser = ref.read(currentUserProvider);
    if (session == null || currentUser == null) return;

    try {
      await ref.read(supabaseHrRepositoryProvider).clockOutForSession(
            coachId: currentUser.id,
            sessionId: session.id,
          );
    } catch (_) {
      // 下班打卡失败同样不影响点名结果
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('点名 · ${_session?.className ?? ''}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              child: ASSkeletonList(itemCount: 6, hasAvatar: true),
            )
          : Column(
              children: [
                // 课程信息条
                _buildSessionInfoBar(),
                
                // 学生列表
                Expanded(
                  child: _buildStudentList(),
                ),
                
                // 底部提交按钮
                _buildSubmitBar(),
              ],
            ),
    );
  }

  Widget _buildSessionInfoBar() {
    if (_session == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ASSpacing.pagePadding,
        vertical: ASSpacing.md,
      ),
      color: ASColors.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: ASColors.primary),
          const SizedBox(width: ASSpacing.sm),
          Text(
            DateFormatters.friendlyDate(_session!.startTime),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: ASSpacing.lg),
          Icon(Icons.access_time, size: 16, color: ASColors.primary),
          const SizedBox(width: ASSpacing.sm),
          Text(
            DateFormatters.timeRange(_session!.startTime, _session!.endTime),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          ASTag(
            label: '共 ${_attendanceList.length} 人',
            type: ASTagType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_attendanceList.isEmpty) {
      return const ASEmptyState(
        type: ASEmptyStateType.noData,
        title: '暂无学生',
        description: '请检查班级成员或稍后再试',
        icon: Icons.people_outline,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(ASSpacing.pagePadding),
      itemCount: _attendanceList.length,
      separatorBuilder: (_, __) => const SizedBox(height: ASSpacing.md),
      itemBuilder: (context, index) {
        final attendance = _attendanceList[index];
        return _StudentAttendanceCard(
          attendance: attendance,
          animationIndex: index,
          onStatusChanged: (status) => _updateStatus(index, status),
        );
      },
    );
  }

  Widget _buildSubmitBar() {
    final presentCount = _attendanceList.where((a) => a.status == AttendanceStatus.present).length;

    return Container(
      padding: const EdgeInsets.all(ASSpacing.pagePadding),
      decoration: BoxDecoration(
        color: ASColors.surface,
        boxShadow: [
          BoxShadow(
            color: ASColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ASPrimaryButton(
          label: '提交点名（$presentCount 人出席）',
          onPressed: _submitAttendance,
          isLoading: _isSubmitting,
          isFullWidth: true,
          height: 52,
        ),
      ),
    );
  }
}

/// 学生点名卡片
class _StudentAttendanceCard extends StatelessWidget {
  const _StudentAttendanceCard({
    required this.attendance,
    required this.onStatusChanged,
    this.animationIndex = 0,
  });

  final Attendance attendance;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return ASCard(
      animate: true,
      animationIndex: animationIndex,
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 24,
            backgroundColor: ASColors.info.withValues(alpha: 0.1),
            backgroundImage: attendance.studentAvatarUrl != null
                ? NetworkImage(attendance.studentAvatarUrl!)
                : null,
            child: attendance.studentAvatarUrl == null
                ? Text(
                    (attendance.studentName ?? 'S').substring(0, 1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ASColors.info,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: ASSpacing.md),

          // 学生信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.studentName ?? '未知学生',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ASSpacing.xs),
                Text(
                  '累计出席 ${attendance.studentTotalAttended ?? 0} 次',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // 状态按钮组
          Row(
            children: [
              _StatusButton(
                label: '出席',
                icon: Icons.check,
                isSelected: attendance.status == AttendanceStatus.present,
                color: ASColors.present,
                onTap: () => onStatusChanged(AttendanceStatus.present),
              ),
              const SizedBox(width: ASSpacing.sm),
              _StatusButton(
                label: '缺席',
                icon: Icons.close,
                isSelected: attendance.status == AttendanceStatus.absent,
                color: ASColors.absent,
                onTap: () => onStatusChanged(AttendanceStatus.absent),
              ),
              const SizedBox(width: ASSpacing.sm),
              _StatusButton(
                label: '请假',
                icon: Icons.event_busy,
                isSelected: attendance.status == AttendanceStatus.leave,
                color: ASColors.leave,
                onTap: () => onStatusChanged(AttendanceStatus.leave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 状态按钮
class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: ASSpacing.sm,
          vertical: ASSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          border: Border.all(
            color: color,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
