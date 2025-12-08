import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/sessions_repository.dart';
import '../../../data/repositories/supabase/leave_repository.dart';

class ParentChildAttendancePage extends ConsumerStatefulWidget {
  const ParentChildAttendancePage({
    super.key,
    required this.child,
  });

  final Student child;

  @override
  ConsumerState<ParentChildAttendancePage> createState() =>
      _ParentChildAttendancePageState();
}

class _ParentChildAttendancePageState
    extends ConsumerState<ParentChildAttendancePage> {
  bool _isLoading = true;
  List<StudentSessionAttendance> _items = [];
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(supabaseSessionsRepositoryProvider);
      final items = await repo.getMonthlySessionsForStudent(
        widget.child.id,
        monthStart: _currentMonth,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载课表失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('出勤明细 · ${widget.child.fullName}'),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                      1,
                    );
                  });
                  _loadData();
                },
              ),
              Text(
                DateFormatters.month(_currentMonth),
                style: theme.textTheme.bodyMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                      1,
                    );
                  });
                  _loadData();
                },
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(ASSpacing.pagePadding),
                child: ASSkeletonList(itemCount: 6, hasAvatar: false),
              )
            : _items.isEmpty
                ? const Center(
                    child: ASEmptyState(
                      type: ASEmptyStateType.noData,
                      title: '本月暂无课表',
                      description: '课程排好后，这里会显示每一节课的出勤状态',
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.all(ASSpacing.pagePadding),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: ASSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final session = item.session;
                      final status = item.status;
                      final now = DateTime.now();
                      final isFuture =
                          session.startTime.isAfter(now);
                      final canRequestLeave =
                          isFuture && status == null;

                      final statusText = _statusText(status);
                      final statusColor = _statusColor(theme, status);

                      return ASCard(
                        padding: const EdgeInsets.all(ASSpacing.md),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.className ??
                                            (session.title ??
                                                '课程'),
                                        style: theme.textTheme
                                            .titleMedium
                                            ?.copyWith(
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: ASSpacing.xs),
                                      Text(
                                        '${DateFormatters.date(session.startTime)} · ${DateFormatters.timeRange(session.startTime, session.endTime)}',
                                        style: theme
                                            .textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: ASSpacing.sm),
                                ASTag(
                                  label: statusText,
                                  type: _statusTagType(status),
                                ),
                              ],
                            ),
                            if (canRequestLeave)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: ASSpacing.sm,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _requestLeave(item),
                                    icon: const Icon(
                                      Icons.event_busy,
                                      size: 18,
                                    ),
                                    label: const Text('请假'),
                                  ),
                                ),
                              )
                            else if (status ==
                                AttendanceStatus.leave)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: ASSpacing.sm,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '已请假',
                                    style: theme
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                      color: ASColors.warning,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Color _statusColor(ThemeData theme, AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return ASColors.success;
      case AttendanceStatus.absent:
        return ASColors.error;
      case AttendanceStatus.late:
        return ASColors.warning;
      case AttendanceStatus.leave:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _statusText(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return '出席';
      case AttendanceStatus.absent:
        return '缺席';
      case AttendanceStatus.late:
        return '迟到';
      case AttendanceStatus.leave:
        return '请假';
      default:
        return '未点名';
    }
  }

  ASTagType _statusTagType(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return ASTagType.success;
      case AttendanceStatus.absent:
        return ASTagType.error;
      case AttendanceStatus.late:
        return ASTagType.warning;
      case AttendanceStatus.leave:
        return ASTagType.primary;
      default:
        return ASTagType.normal;
    }
  }

  Future<void> _requestLeave(
    StudentSessionAttendance item,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('请假说明'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '可选：简单说明请假原因',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('提交'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(supabaseLeaveRepositoryProvider)
          .createLeaveWithMakeup(
        studentId: widget.child.id,
        sessionId: item.session.id,
        reason: controller.text.trim().isEmpty
            ? null
            : controller.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已提交请假')),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请假失败：$e')),
      );
    }
  }
}
