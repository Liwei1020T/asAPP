import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/hr_repository.dart';
import '../../auth/application/auth_providers.dart';

/// 教练薪资统计页面
class SalaryPage extends ConsumerStatefulWidget {
  const SalaryPage({super.key});

  @override
  ConsumerState<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends ConsumerState<SalaryPage> {
  DateTime _selectedMonth = DateTime.now();

  // 计算总金额
  double _calcTotalSalary(List<CoachShift> shifts, Profile? user) {
    final rate = user?.ratePerSession ?? 0.0;
    final completed = shifts.where((s) => s.status == ShiftStatus.completed).length;
    return completed * rate;
  }

  // 计算总课时
  int _calcTotalSessions(List<CoachShift> shifts) {
    return shifts.where((s) => s.status == ShiftStatus.completed).length;
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final stream = currentUser == null
        ? const Stream<List<CoachShift>>.empty()
        : ref.read(supabaseHrRepositoryProvider).watchCoachShifts(currentUser.id, _selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('薪资统计'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<CoachShift>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(ASSpacing.pagePadding),
              child: Column(
                children: [
                  ASSkeletonStatCard(),
                  SizedBox(height: ASSpacing.lg),
                  ASSkeletonList(itemCount: 4, hasAvatar: false),
                ],
              ),
            );
          }

          final shifts = snapshot.data ?? [];
          final todayShifts = _filterToday(shifts);
          final totalSalary = _calcTotalSalary(shifts, currentUser);
          final totalSessions = _calcTotalSessions(shifts);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(ASSpacing.pagePadding),
            child: ASStaggeredColumn(
              children: [
                _buildMonthSelector(),
                const SizedBox(height: ASSpacing.lg),
                _buildSalarySummary(currentUser, totalSalary, totalSessions),
                const SizedBox(height: ASSpacing.xl),
                if (todayShifts.isNotEmpty) ...[
                  ASSectionTitle(
                    title: '今日打卡',
                    subtitle: 'Today\'s Shifts',
                    animate: true,
                  ),
                  const SizedBox(height: ASSpacing.sm),
                  _buildTodayShifts(todayShifts),
                  const SizedBox(height: ASSpacing.xl),
                ],
                ASSectionTitle(
                  title: '课时明细',
                  subtitle: 'Session Details',
                  animate: true,
                ),
                const SizedBox(height: ASSpacing.md),
                shifts.isEmpty ? _buildEmptyState() : _buildShiftsList(shifts),
                const SizedBox(height: ASSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    final theme = Theme.of(context);
    return ASCard(
      padding: const EdgeInsets.symmetric(
        horizontal: ASSpacing.lg,
        vertical: ASSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          Column(
            children: [
              Text(
                DateFormatters.month(_selectedMonth),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '${_selectedMonth.year}年',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedMonth.isBefore(DateTime.now())
                ? () => _changeMonth(1)
                : null,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySummary(Profile? currentUser, double totalSalary, int totalSessions) {
    final rate = currentUser?.ratePerSession ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ASStatCard(
          title: '本月预计收入',
          valueText: 'RM ${totalSalary.toStringAsFixed(2)}',
          subtitle: '基于已完成课时计算',
          icon: Icons.account_balance_wallet,
          color: ASColors.success,
        ),
        const SizedBox(height: ASSpacing.md),
        Row(
          children: [
            Expanded(
              child: ASStatCard(
                title: '已上课时',
                value: totalSessions,
                subtitle: '本月完成',
                icon: Icons.event_available,
                color: ASColors.primary,
              ),
            ),
            const SizedBox(width: ASSpacing.md),
            Expanded(
              child: ASStatCard(
                title: '课时单价',
                valueText: 'RM ${rate.toStringAsFixed(0)}',
                subtitle: '基础费率',
                icon: Icons.payments,
                color: ASColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<CoachShift> _filterToday(List<CoachShift> shifts) {
    final now = DateTime.now();
    return shifts.where((s) {
      return s.date.year == now.year && s.date.month == now.month && s.date.day == now.day;
    }).toList()
      ..sort((a, b) => (b.clockInAt ?? b.date).compareTo(a.clockInAt ?? a.date));
  }

  Widget _buildTodayShifts(List<CoachShift> shifts) {
    final theme = Theme.of(context);
    return ASCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: shifts.map((s) {
          final isCompleted = s.status == ShiftStatus.completed;
          return Container(
            margin: const EdgeInsets.only(bottom: ASSpacing.sm),
            padding: const EdgeInsets.all(ASSpacing.sm),
            decoration: BoxDecoration(
              color: isCompleted ? ASColors.success.withValues(alpha: 0.05) : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted ? ASColors.success.withValues(alpha: 0.2) : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.schedule,
                  color: isCompleted ? ASColors.success : ASColors.info,
                  size: 20,
                ),
                const SizedBox(width: ASSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.className ?? '课程',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${s.startTime} - ${s.endTime.isNotEmpty ? s.endTime : '--'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (s.clockInAt != null)
                  ASTag(
                    label: '打卡: ${DateFormatters.time(s.clockInAt!)}',
                    type: ASTagType.success,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const ASEmptyState(
      type: ASEmptyStateType.noData,
      title: '本月暂无课时记录',
      description: '完成授课后这里会展示收入明细',
      icon: Icons.event_busy,
    );
  }

  Widget _buildShiftsList(List<CoachShift> shifts) {
    // 按日期分组
    final groupedShifts = <String, List<CoachShift>>{};
    for (final shift in shifts) {
      final dateKey = DateFormatters.date(shift.date);
      groupedShifts.putIfAbsent(dateKey, () => []).add(shift);
    }

    final sortedDates = groupedShifts.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedDates.map((date) {
        final dayShifts = groupedShifts[date]!;
        final dateObj = DateTime.parse(date);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期标题
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ASSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: ASColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatters.friendlyDate(dateObj),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ASColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 当日课时
            ...dayShifts.map((shift) => _ShiftCard(shift: shift)),
            const SizedBox(height: ASSpacing.md),
          ],
        );
      }).toList(),
    );
  }
}

/// 课时卡片
class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift});

  final CoachShift shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ASCard(
      padding: const EdgeInsets.all(ASSpacing.md),
      child: Row(
        children: [
          // 状态图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: ASSpacing.md),

          // 课程信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.className ?? '未知班级',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${shift.startTime} - ${shift.endTime}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 状态标签
          ASTag(
            label: _getStatusText(),
            type: _getTagType(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (shift.status) {
      case ShiftStatus.completed:
        return ASColors.success;
      case ShiftStatus.scheduled:
        return ASColors.info;
      case ShiftStatus.cancelled:
        return ASColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (shift.status) {
      case ShiftStatus.completed:
        return Icons.check_circle;
      case ShiftStatus.scheduled:
        return Icons.schedule;
      case ShiftStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText() {
    switch (shift.status) {
      case ShiftStatus.completed:
        return '已完成';
      case ShiftStatus.scheduled:
        return '待上课';
      case ShiftStatus.cancelled:
        return '已取消';
    }
  }

  ASTagType _getTagType() {
    switch (shift.status) {
      case ShiftStatus.completed:
        return ASTagType.success;
      case ShiftStatus.scheduled:
        return ASTagType.info;
      case ShiftStatus.cancelled:
        return ASTagType.error;
    }
  }
}
