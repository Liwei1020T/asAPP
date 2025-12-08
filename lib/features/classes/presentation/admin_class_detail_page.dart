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
import '../../../data/repositories/supabase/classes_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../../data/repositories/supabase/sessions_repository.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../../data/repositories/supabase/student_repository.dart';
import '../../../data/repositories/supabase/venues_repository.dart';
import 'select_student_dialog.dart';
import 'batch_schedule_dialog.dart';

/// 管理员 - 班级详情页
class AdminClassDetailPage extends ConsumerStatefulWidget {
  const AdminClassDetailPage({super.key, required this.classId});

  final String classId;

  @override
  ConsumerState<AdminClassDetailPage> createState() => _AdminClassDetailPageState();
}

class _AdminClassDetailPageState extends ConsumerState<AdminClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ClassGroup? _classGroup;
  List<Student> _students = [];
  List<Session> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update AppBar actions
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final classesRepo = ref.read(supabaseClassesRepositoryProvider);
      final studentRepo = ref.read(supabaseStudentRepositoryProvider);
      final sessionsRepo = ref.read(supabaseSessionsRepositoryProvider);

      // 班级信息
      final classGroup = await classesRepo.getClass(widget.classId);
      if (classGroup == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到该班级')),
          );
          context.pop();
        }
        return;
      }

      // 学生列表（基于 students 表）
      final studentIds =
          await classesRepo.getStudentIdsForClass(widget.classId);
      final students = <Student>[];
      for (final id in studentIds) {
        final student = await studentRepo.getStudentById(id);
        if (student != null) students.add(student);
      }

      // 课程列表
      final sessions = await sessionsRepo.getSessionsForClass(widget.classId);

      if (mounted) {
        setState(() {
          _classGroup = classGroup;
          _students = students;
          _sessions = sessions;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_classGroup?.name ?? '班级详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 1) {
                return IconButton(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: '批量排课',
                  onPressed: _showBatchScheduleDialog,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: '学员 Students'),
            Tab(text: '课程 Sessions'),
          ],
        ),
      ),
      body: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              child: Column(
                children: const [
                  ASSkeletonCard(height: 140),
                  SizedBox(height: ASSpacing.md),
                  ASSkeletonList(itemCount: 3, hasAvatar: true),
                ],
              ),
            )
          : Column(
              children: [
                // 班级信息卡片
                _buildClassInfoCard(),
                
                // 标签页内容
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStudentsTab(),
                      _buildSessionsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return _tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: _showCreateSessionDialog,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  icon: const Icon(Icons.add),
                  label: const Text('排课'),
                )
              : FloatingActionButton.extended(
                  onPressed: _showAddStudentDialog,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  icon: const Icon(Icons.person_add),
                  label: const Text('添加学员'),
                );
        },
      ),
    );
  }

  Widget _buildClassInfoCard() {
    if (_classGroup == null) return const SizedBox();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(ASSpacing.pagePadding),
      color: theme.colorScheme.surface,
      child: ASCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_classGroup!.level != null) ...[
                  ASLevelTag(level: _classGroup!.level!),
                  const SizedBox(width: ASSpacing.sm),
                ],
                ASTag(
                  label: _classGroup!.isActive ? 'Active' : 'Inactive',
                  type: _classGroup!.isActive ? ASTagType.success : ASTagType.normal,
                ),
              ],
            ),
            const SizedBox(height: ASSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.schedule,
                    label: '上课时间',
                    value: _getScheduleText(),
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.location_on,
                    label: '场地',
                    value: _classGroup!.defaultVenue ?? '未设定',
                  ),
                ),
              ],
            ),
            const SizedBox(height: ASSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.people,
                    label: '学员数',
                    value: '${_students.length} / ${_classGroup!.capacity ?? '∞'}',
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.event,
                    label: '已上课程',
                    value: '${_sessions.where((s) => s.status == SessionStatus.completed).length}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getScheduleText() {
    if (_classGroup?.defaultDayOfWeek == null) return '未设定';
    
    final day = DateFormatters.weekdayFromZeroIndex(_classGroup!.defaultDayOfWeek!);
    final startTime = _classGroup!.defaultStartTime ?? '';
    final endTime = _classGroup!.defaultEndTime ?? '';
    
    if (startTime.isEmpty) return day;
    return '$day $startTime-$endTime';
  }

  Future<void> _showBatchScheduleDialog() async {
    if (_classGroup == null) return;
    final result = await BatchScheduleDialog.show(context, _classGroup!);
    if (result == true) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('批量排课成功')),
        );
      }
    }
  }

  Future<void> _showCreateSessionDialog() async {
    if (_classGroup == null) return;
    final session = await _CreateSessionDialog.show(
      context,
      classGroup: _classGroup!,
      existingSessions: _sessions,
    );
    if (session == null) return;

    await ref.read(supabaseSessionsRepositoryProvider).createSession(session);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('排课成功')),
      );
    }
  }

  Future<void> _showAddStudentDialog() async {
    final students = await SelectStudentDialog.show(context, _students);
    if (students == null || students.isEmpty || _classGroup == null) return;

    final repo = ref.read(supabaseClassesRepositoryProvider);
    for (final student in students) {
      await repo.addStudentToClass(_classGroup!.id, student.id);
    }
    
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加 ${students.length} 名学员')),
      );
    }
  }

  Future<void> _removeStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除学员'),
        content: Text('确定将 ${student.fullName} 移出该班级吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('移除', style: TextStyle(color: ASColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || _classGroup == null) return;

    await ref
        .read(supabaseClassesRepositoryProvider)
        .removeStudentFromClass(_classGroup!.id, student.id);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已移除 ${student.fullName}')),
      );
    }
  }

  Widget _buildStudentsTab() {
    if (_students.isEmpty) {
      return const ASEmptyState(
        type: ASEmptyStateType.noData,
        title: '暂无学员',
        description: '可在班级详情中添加学生',
        icon: Icons.people_outline,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ASSpacing.pagePadding),
      child: ASStaggeredColumn(
        children: _students.map((student) => _StudentCard(
          student: student,
          onRemove: () => _removeStudent(student),
        )).toList(),
      ),
    );
  }

  Widget _buildSessionsTab() {
    final stream =
        ref.read(supabaseSessionsRepositoryProvider).watchSessionsForClass(widget.classId);

    return StreamBuilder<List<Session>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(ASSpacing.pagePadding),
            child: ASSkeletonList(itemCount: 4, hasAvatar: false),
          );
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const ASEmptyState(
            type: ASEmptyStateType.noData,
            title: '暂无课程',
            description: '创建课程后将显示在这里',
            icon: Icons.event_outlined,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(ASSpacing.pagePadding),
          child: ASStaggeredColumn(
            children: sessions.map((session) {
              final currentUser = ref.read(currentUserProvider);
              final canManage = currentUser?.role == UserRole.admin ||
                  (currentUser?.role == UserRole.coach && session.coachId == currentUser?.id);

              return _SessionCard(
                session: session,
                onEdit: () => _showEditSessionDialog(session),
                onDelete: () => _deleteSession(session),
                onTap: () => context.push('/attendance/${session.id}'),
                canManage: canManage,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _showEditSessionDialog(Session session) async {
    final currentUser = ref.read(currentUserProvider);
    final canManage = currentUser?.role == UserRole.admin ||
        (currentUser?.role == UserRole.coach && session.coachId == currentUser?.id);
    if (!canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无权操作')),
      );
      return;
    }

    final updated = await _CreateSessionDialog.show(
      context,
      classGroup: _classGroup!,
      existingSessions: _sessions.where((s) => s.id != session.id).toList(),
      initialSession: session,
    );
    if (updated == null) return;

    await ref
        .read(supabaseSessionsRepositoryProvider)
        .updateSession(updated.copyWith(id: session.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('课程已更新')),
      );
    }
  }

  Future<void> _deleteSession(Session session) async {
    final currentUser = ref.read(currentUserProvider);
    final canManage = currentUser?.role == UserRole.admin ||
        (currentUser?.role == UserRole.coach && session.coachId == currentUser?.id);
    if (!canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无权操作')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定删除「${session.title ?? '课程'}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: ASColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(supabaseSessionsRepositoryProvider)
        .deleteSession(session.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('课程已删除')),
      );
    }
  }
}

/// 信息项组件
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: ASSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 学员卡片
class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.onRemove});

  final Student student;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ASCard(
      child: Row(
        children: [
          ASAvatar(
            name: student.fullName,
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
                  student.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ASSpacing.xs),
                Text(
                  '${student.age ?? '-'}岁 · '
                  '${student.gender ?? '未知'} · '
                  '${getStudentLevelName(student.level)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: ASColors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// 课程卡片
class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onEdit,
    required this.onDelete,
    required this.canManage,
    this.onTap,
  });

  final Session session;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canManage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(theme);

    return ASCard(
      padding: EdgeInsets.zero, // Remove default padding for InkWell
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Match card radius
        child: Padding(
          padding: const EdgeInsets.all(ASSpacing.md), // Re-add padding
          child: Row(
            children: [
          // 日期指示
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${session.startTime.day}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  DateFormatters.weekday(session.startTime.weekday),
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ASSpacing.md),
          // 课程信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title ?? '常规训练',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ASSpacing.xs),
                Text(
                  DateFormatters.timeRange(session.startTime, session.endTime),
                  style: theme.textTheme.bodySmall,
                ),
                if (session.venue != null && session.venue!.isNotEmpty)
                  Text(
                    session.venue!,
                    style: theme.textTheme.bodySmall,
                  ),
                // Coach name display removed
              ],
            ),
          ),
          // 状态标签
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ASTag(
                label: _getStatusText(),
                type: _getStatusTagType(),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('编辑')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('删除', style: TextStyle(color: ASColors.error)),
                    ),
                  ],
                ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ThemeData theme) {
    switch (session.status) {
      case SessionStatus.completed:
        return ASColors.success;
      case SessionStatus.cancelled:
        return ASColors.error;
      case SessionStatus.scheduled:
        return theme.colorScheme.primary;
    }
  }

  String _getStatusText() {
    switch (session.status) {
      case SessionStatus.completed:
        return '已完成';
      case SessionStatus.cancelled:
        return '已取消';
      case SessionStatus.scheduled:
        return '待进行';
    }
  }

  ASTagType _getStatusTagType() {
    switch (session.status) {
      case SessionStatus.completed:
        return ASTagType.success;
      case SessionStatus.cancelled:
        return ASTagType.error;
      case SessionStatus.scheduled:
        return ASTagType.primary;
    }
  }
}

/// 排课对话框
class _CreateSessionDialog extends ConsumerStatefulWidget {
  const _CreateSessionDialog({
    required this.classGroup,
    required this.existingSessions,
    this.initialSession,
  });

  final ClassGroup classGroup;
  final List<Session> existingSessions;
  final Session? initialSession;

  static Future<Session?> show(
    BuildContext context, {
    required ClassGroup classGroup,
    required List<Session> existingSessions,
    Session? initialSession,
  }) {
    return showDialog<Session>(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _CreateSessionDialog(
            classGroup: classGroup,
            existingSessions: existingSessions,
            initialSession: initialSession,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends ConsumerState<_CreateSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _venueController;
  DateTime _date = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isPayable = true;
  bool _isSubmitting = false;
  String? _coachId;
  List<Profile> _coaches = [];
  String? _errorText;
  List<Venue> _venues = [];
  Venue? _selectedVenue;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialSession?.title ?? widget.classGroup.name);
    _venueController = TextEditingController(
      text: widget.initialSession?.venue ?? widget.classGroup.defaultVenue ?? '场地待定',
    );
    _coachId = widget.initialSession?.coachId ?? widget.classGroup.defaultCoachId;
    _selectedVenue = null;
    final startRef = widget.initialSession?.startTime;
    final endRef = widget.initialSession?.endTime;
    if (startRef != null) {
      _date = DateTime(startRef.year, startRef.month, startRef.day);
      _startTime = TimeOfDay.fromDateTime(startRef);
    } else if (widget.classGroup.defaultStartTime != null) {
      final parts = widget.classGroup.defaultStartTime!.split(':');
      _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (endRef != null) {
      _endTime = TimeOfDay.fromDateTime(endRef);
    } else if (widget.classGroup.defaultEndTime != null) {
      final parts = widget.classGroup.defaultEndTime!.split(':');
      _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    _isPayable = widget.initialSession?.isPayable ?? true;
    _loadCoaches();
    _loadVenues();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Coach dropdown removed as per request to decouple session from coach

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '排课',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '课程标题',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入标题' : null,
            ),
            const SizedBox(height: 12),
            // coachDropdown removed
            const SizedBox(height: 12),
            DropdownButtonFormField<Venue>(
              value: _selectedVenue,
              decoration: const InputDecoration(
                labelText: '场地',
                border: OutlineInputBorder(),
              ),
              items: _venues
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedVenue = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormatters.date(_date)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStartTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_formatTime(_startTime, '开始时间')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEndTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(_formatTime(_endTime, '结束时间')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isPayable,
                  onChanged: (v) => setState(() => _isPayable = v ?? true),
                ),
                const Text('计薪课时'),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.check),
                label: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.initialSession == null ? '创建' : '保存'),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: ASSpacing.sm),
              Text(
                _errorText!,
                style: const TextStyle(color: ASColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 16, minute: 0),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  String _formatTime(TimeOfDay? t, String placeholder) {
    if (t == null) return placeholder;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      setState(() => _errorText = '请选择时间段');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      setState(() {
        _isSubmitting = false;
        _errorText = '结束时间必须晚于开始时间';
      });
      return;
    }

    // 冲突检查（Supabase 优先）
    try {
      final conflict = await ref.read(supabaseSessionsRepositoryProvider).hasTimeConflict(
            classId: widget.classGroup.id,
            start: start,
            end: end,
            coachId: _coachId,
          );
      if (conflict) {
        setState(() {
          _isSubmitting = false;
          _errorText = '与现有课程时间冲突';
        });
        return;
      }
    } catch (_) {
      final hasConflict = widget.existingSessions.any((s) {
        if (DateFormatters.date(s.startTime) != DateFormatters.date(start)) return false;
        final sStart = s.startTime;
        final sEnd = s.endTime;
        return start.isBefore(sEnd) && end.isAfter(sStart);
      });
      if (hasConflict) {
        setState(() {
          _isSubmitting = false;
          _errorText = '与现有课程时间冲突';
        });
        return;
      }
    }

    final session = Session(
      id: widget.initialSession?.id ?? '', // Supabase 会生成 UUID
      classId: widget.classGroup.id,
      coachId: null, // Decoupled from coach
      title: _titleController.text.trim(),
      venue: _selectedVenue?.name ?? _venueController.text.trim(),
      venueId: _selectedVenue?.id,
      startTime: start,
      endTime: end,
      status: widget.initialSession?.status ?? SessionStatus.scheduled,
      isPayable: _isPayable,
      className: widget.classGroup.name,
      coachName: null,
    );

    setState(() => _isSubmitting = false);
    Navigator.pop(context, session);
  }

  Future<void> _loadCoaches() async {
    try {
      final coaches = await ref.read(supabaseAuthRepositoryProvider).getAllCoaches();
      setState(() => _coaches = coaches);
    } catch (_) {
      setState(() => _coaches = []);
    }
    if (_coaches.isNotEmpty && _coachId == null && widget.initialSession == null) {
      // If creating new session and class has default coach, use it.
      // Otherwise leave it null (No Coach).
      _coachId = widget.classGroup.defaultCoachId;
    }
  }

  Future<void> _loadVenues() async {
    try {
      final venues = await ref.read(supabaseVenuesRepositoryProvider).fetchVenues();
      setState(() => _venues = venues);
    } catch (_) {
      _venues = [];
    }
    if (_venues.isNotEmpty && _selectedVenue == null) {
      final initialVenueId = widget.initialSession?.venueId;
      final match = initialVenueId != null
          ? _venues.firstWhere(
              (v) => v.id == initialVenueId,
              orElse: () => _venues.first,
            )
          : _venues.first;
      setState(() => _selectedVenue = match);
    }
  }
}
