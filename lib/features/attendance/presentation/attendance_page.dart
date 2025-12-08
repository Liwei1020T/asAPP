import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/attendance_repository.dart';
import '../../../data/repositories/supabase/sessions_repository.dart';
import '../../../data/repositories/supabase/leave_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../../data/repositories/supabase/student_repository.dart';
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

  // Coach Check-in State
  List<Profile> _coaches = [];
  Profile? _selectedCoach;
  List<CoachShift> _sessionShifts = [];
  bool _isClockLoading = false;

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
      // Load Session
      final session =
          await ref.read(supabaseSessionsRepositoryProvider).getSession(widget.sessionId);

      if (session != null) {
        // Load Students
        final students =
            await ref.read(supabaseAttendanceRepositoryProvider).getStudentsForRollCall(
                  widget.sessionId,
                  session.classId,
                );

        // Load Coaches
        final coaches = await ref.read(supabaseAuthRepositoryProvider).getAllCoaches();
        // Load Admins
        final admins = await ref.read(supabaseAuthRepositoryProvider).getProfilesByRole(UserRole.admin);
        
        // Combine and remove duplicates
        final allStaffMap = {
          for (var p in coaches) p.id: p,
          for (var p in admins) p.id: p,
        };
        final allStaff = allStaffMap.values.toList();
        
        final currentUser = ref.read(currentUserProvider);

        if (mounted) {
          setState(() {
            _session = session;
            _attendanceList = students;
            _coaches = allStaff;
            // Default to assigned coach if available, otherwise current user, otherwise first
            _selectedCoach = allStaff.firstWhere(
              (c) => c.id == session.coachId,
              orElse: () => allStaff.firstWhere(
                (c) => c.id == currentUser?.id,
                orElse: () => allStaff.isNotEmpty ? allStaff.first : currentUser!,
              ),
            );
          });

          // Load shifts for this session
          await _loadSessionShifts();

          _subscribeAttendance();
          _subscribeMembers();
        }
      }
    } catch (e) {
      debugPrint('Error loading attendance data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSessionShifts() async {
    if (_session == null) return;
    try {
      final shifts = await ref.read(supabaseHrRepositoryProvider).getShiftsForSession(_session!.id);
      if (mounted) {
        setState(() {
          _sessionShifts = shifts;
        });
      }
    } catch (_) {}
  }

  void _updateStatus(int index, AttendanceStatus status) {
    final previous = _attendanceList[index];

    setState(() {
      _attendanceList[index] = _attendanceList[index].copyWith(status: status);
    });

    if (status == AttendanceStatus.leave &&
        previous.status != AttendanceStatus.leave) {
      _handleLeaveWithMakeup(previous);
    }
  }

  void _updateCoachNote(int index, String? note) {
    setState(() {
      _attendanceList[index] =
          _attendanceList[index].copyWith(coachNote: note);
    });
  }

  Future<void> _handleLeaveWithMakeup(Attendance attendance) async {
    final session = _session;
    if (session == null) return;

    try {
      await ref.read(supabaseLeaveRepositoryProvider).createLeaveWithMakeup(
            studentId: attendance.studentId,
            sessionId: session.id,
            reason: attendance.coachNote,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请假补课资格生成失败：$e')),
      );
    }
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

      // 统计
      final presentCount =
          _attendanceList.where((a) => a.status == AttendanceStatus.present).length;
      final absentCount =
          _attendanceList.where((a) => a.status == AttendanceStatus.absent).length;
      final leaveCount =
          _attendanceList.where((a) => a.status == AttendanceStatus.leave).length;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('点名提交成功！出席 $presentCount 人，缺席 $absentCount 人，请假 $leaveCount 人'),
            backgroundColor: ASColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // 返回上一页
        // context.pop(); // Allow editing after save
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

  Future<void> _clockInForCoach(Profile coach) async {
    final session = _session;
    if (session == null) return;

    setState(() => _isClockLoading = true);

    try {
      await ref.read(supabaseHrRepositoryProvider).clockInForSession(
            coachId: coach.id,
            sessionId: session.id,
            classId: session.classId,
            className: session.className ?? (session.title ?? ''),
            sessionStartTime: session.startTime,
          );
      await _loadSessionShifts(); // Reload list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 ${coach.fullName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClockLoading = false);
    }
  }

  Future<void> _clockOutForCoach(Profile coach) async {
    final session = _session;
    if (session == null) return;

    setState(() => _isClockLoading = true);

    try {
      await ref.read(supabaseHrRepositoryProvider).clockOutForSession(
            coachId: coach.id,
            sessionId: session.id,
          );
      await _loadSessionShifts(); // Reload list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${coach.fullName} 已完成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('完成失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClockLoading = false);
    }
  }

  Future<void> _showAddStudentDialog() async {
    final student = await showDialog<Student>(
      context: context,
      builder: (context) => _SearchStudentDialog(),
    );

    if (student != null) {
      _addGuestStudent(student);
    }
  }

  void _addGuestStudent(Student student) {
    // Check if already exists
    if (_attendanceList.any((a) => a.studentId == student.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该学生已在列表中')),
      );
      return;
    }

    setState(() {
      _attendanceList.add(Attendance(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}', // Temp ID
        sessionId: widget.sessionId,
        studentId: student.id,
        status: AttendanceStatus.present, // Default to present
        studentName: student.fullName,
        studentAvatarUrl: student.avatarUrl,
      ));
    });
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
          ? const Padding(
              padding: EdgeInsets.all(ASSpacing.pagePadding),
              child: ASSkeletonList(itemCount: 6, hasAvatar: true),
            )
          : Column(
              children: [
                // 课程信息卡片（优化后）
                _buildSessionInfoBar(),

                // 教练打卡区域（优化后）
                _buildCoachCheckInSection(),

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

  /// 优化后的课程信息区域：使用卡片 + 图标 + 清晰排版
  Widget _buildSessionInfoBar() {
    if (_session == null) return const SizedBox();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ASSpacing.pagePadding,
        ASSpacing.pagePadding,
        ASSpacing.pagePadding,
        ASSpacing.sm,
      ),
      child: ASCard(
        padding: const EdgeInsets.all(ASSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧课程图标块
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.class_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: ASSpacing.md),

            // 中间课程信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _session!.className ?? (_session!.title ?? '课程'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ASSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: ASSpacing.xs),
                      Text(
                        DateFormatters.friendlyDate(_session!.startTime),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: ASSpacing.md),
                      Icon(Icons.access_time,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: ASSpacing.xs),
                      Text(
                        DateFormatters.timeRange(
                          _session!.startTime,
                          _session!.endTime,
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: ASSpacing.sm),

            // 右侧操作：补课 + 人数
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _showAddStudentDialog,
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('添加补课'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const SizedBox(height: ASSpacing.xs),
                ASTag(
                  label: '共 ${_attendanceList.length} 人',
                  type: ASTagType.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 优化后的教练打卡区域：卡片 + 列表 + 下拉选择
  Widget _buildCoachCheckInSection() {
    final theme = Theme.of(context);

    // Filter out coaches who are already in the shift list
    final availableCoaches =
        _coaches.where((c) => !_sessionShifts.any((s) => s.coachId == c.id)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ASSpacing.pagePadding,
        0,
        ASSpacing.pagePadding,
        ASSpacing.md,
      ),
      child: ASCard(
        padding: const EdgeInsets.all(ASSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: ASSpacing.sm),
                Text(
                  '教练列表',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ASSpacing.md),

            // 已有打卡记录列表
            if (_sessionShifts.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sessionShifts.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 12),
                itemBuilder: (context, index) {
                  final shift = _sessionShifts[index];
                  final coach = _coaches.firstWhere(
                    (c) => c.id == shift.coachId,
                    orElse: () => Profile(
                      id: shift.coachId,
                      fullName: '未知教练',
                      role: UserRole.coach,
                    ),
                  );
                  final isCompleted = shift.status == ShiftStatus.completed;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ASAvatar(
                      name: coach.fullName,
                      imageUrl: coach.avatarUrl,
                      size: ASAvatarSize.sm,
                    ),
                    title: Text(
                      coach.fullName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      isCompleted
                          ? '已完成 ${DateFormatters.time(shift.clockInAt!)} - ${DateFormatters.time(shift.clockOutAt!)}'
                          : '工作中 · 上班 ${DateFormatters.time(shift.clockInAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCompleted
                            ? ASColors.success
                            : ASColors.warning,
                      ),
                    ),
                    trailing: isCompleted
                        ? const Icon(
                            Icons.check_circle,
                            color: ASColors.success,
                          )
                        : TextButton(
                            onPressed:
                                _isClockLoading ? null : () => _clockOutForCoach(coach),
                            child: const Text('完成'),
                          ),
                  );
                },
              ),

            if (_sessionShifts.isNotEmpty) const SizedBox(height: ASSpacing.md),

            // 新教练打卡
            if (availableCoaches.isNotEmpty && _isSessionActive())
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: availableCoaches
                              .any((c) => c.id == _selectedCoach?.id)
                          ? _selectedCoach?.id
                          : null,
                      decoration: const InputDecoration(
                        labelText: '选择教练',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: availableCoaches
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.fullName),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setState(() {
                            _selectedCoach =
                                _coaches.firstWhere((c) => c.id == id);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: ASSpacing.md),
                  ASPrimaryButton(
                    label: '添加',
                    icon: Icons.add,
                    isLoading: _isClockLoading,
                    onPressed: () {
                      if (_selectedCoach != null) {
                        _clockInForCoach(_selectedCoach!);
                      }
                    },
                  ),
                ],
              )
            else if (!_isSessionActive())
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '不在添加时间范围内',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),

            if (availableCoaches.isEmpty && _sessionShifts.isEmpty)
              Text(
                '暂无人员可添加',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
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

    return ASAnimatedList(
      padding: const EdgeInsets.all(ASSpacing.pagePadding),
      items: _attendanceList,
      itemBuilder: (context, attendance, index) {
        return _StudentAttendanceCard(
          attendance: attendance,
          onStatusChanged: (status) => _updateStatus(index, status),
          onEditNote: () => _showEditNoteDialog(index),
        );
      },
    );
  }

  Future<void> _showEditNoteDialog(int index) async {
    final attendance = _attendanceList[index];
    final controller = TextEditingController(text: attendance.coachNote ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('教练备注'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '例如：迟到 10 分钟；家长临时接走等',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      _updateCoachNote(index, result.isEmpty ? null : result);
    }
  }

  Widget _buildSubmitBar() {
    final presentCount =
        _attendanceList.where((a) => a.status == AttendanceStatus.present).length;
    final theme = Theme.of(context);
    
    // Check if session is active (allow 30 mins before and after)
    final isActive = _isSessionActive();
    final canSubmit = isActive || _session?.status == SessionStatus.completed; // Allow editing if already completed? Or strict time?
    // User request: "Coach can only check in/roll call during class time"
    // Let's interpret strictly for "actions", but maybe allow viewing.
    
    // Actually, if session is completed, maybe we allow editing? 
    // But the request says "only in course time segment".
    // Let's enforce strict time window for ACTIONS.
    
    if (!isActive) {
       return Container(
        padding: const EdgeInsets.all(ASSpacing.pagePadding),
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Row(
            children: [
              Icon(Icons.lock_clock, color: theme.colorScheme.outline),
              const SizedBox(width: ASSpacing.sm),
              Expanded(
                child: Text(
                  '仅能在课程时间段内进行点名',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(ASSpacing.pagePadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ASPrimaryButton(
          label: '保存点名（$presentCount 人出席）',
          onPressed: _submitAttendance,
          isLoading: _isSubmitting,
          isFullWidth: true,
          height: 52,
        ),
      ),
    );
  }

  bool _isSessionActive() {
    // Admins can always take attendance
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.role == UserRole.admin) return true;

    if (_session == null) return false;
    final now = DateTime.now();
    // Strict class hour check as requested
    final start = _session!.startTime;
    final end = _session!.endTime;
    return now.isAfter(start) && now.isBefore(end);
  }
}

/// 学生点名卡片
class _StudentAttendanceCard extends StatelessWidget {
  const _StudentAttendanceCard({
    required this.attendance,
    required this.onStatusChanged,
    required this.onEditNote,
  });

  final Attendance attendance;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ASCard(
      child: Column(
        children: [
          Row(
            children: [
              ASAvatar(
                imageUrl: attendance.studentAvatarUrl,
                name: attendance.studentName ?? 'S',
                size: ASAvatarSize.md,
                showBorder: true,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: ASSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance.studentName ?? '未知学生',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Removed Cumulative Attendance display as requested
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ASSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatusButton(
                  label: '出席',
                  icon: Icons.check,
                  isSelected: attendance.status == AttendanceStatus.present,
                  color: ASColors.success,
                  onTap: () => onStatusChanged(AttendanceStatus.present),
                ),
              ),
              const SizedBox(width: ASSpacing.sm),
              Expanded(
                child: _StatusButton(
                  label: '缺席',
                  icon: Icons.close,
                  isSelected: attendance.status == AttendanceStatus.absent,
                  color: ASColors.error,
                  onTap: () => onStatusChanged(AttendanceStatus.absent),
                ),
              ),
              const SizedBox(width: ASSpacing.sm),
              Expanded(
                child: _StatusButton(
                  label: '请假',
                  icon: Icons.event_busy,
                  isSelected: attendance.status == AttendanceStatus.leave,
                  color: ASColors.warning,
                  onTap: () => onStatusChanged(AttendanceStatus.leave),
                ),
              ),
            ],
          ),
          const SizedBox(height: ASSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEditNote,
              icon: const Icon(Icons.edit_note, size: 18),
              label: Text(
                (attendance.coachNote ?? '').isEmpty ? '添加备注' : '编辑备注',
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
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
          vertical: ASSpacing.sm,
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
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchStudentDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchStudentDialog> createState() =>
      _SearchStudentDialogState();
}

class _SearchStudentDialogState extends ConsumerState<_SearchStudentDialog> {
  final _searchController = TextEditingController();
  List<Student> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _search(query);
      } else {
        setState(() => _results = []);
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final results =
          await ref.read(supabaseStudentRepositoryProvider).searchStudents(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(ASSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '添加补课学生',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ASSpacing.md),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索学生姓名...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: ASSpacing.md),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? const Center(child: Text('输入姓名搜索'))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final student = _results[index];
                            return ListTile(
                              leading: ASAvatar(
                                imageUrl: student.avatarUrl,
                                name: student.fullName,
                                size: ASAvatarSize.sm,
                              ),
                              title: Text(student.fullName),
                              subtitle: Text(student.phoneNumber ?? '无电话'),
                              onTap: () => Navigator.pop(context, student),
                            );
                          },
                        ),
            ),
            const SizedBox(height: ASSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
