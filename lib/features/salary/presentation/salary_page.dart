import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/animations.dart';
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
        title: const Text('薪资统计 Salary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<CoachShift>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              child: Column(
                children: [
                  const ASSkeletonStatCard(),
                  const SizedBox(height: ASSpacing.lg),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMonthSelector(),
                Padding(
                  padding: const EdgeInsets.all(ASSpacing.pagePadding),
                  child: _buildSalarySummary(currentUser, totalSalary, totalSessions),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (todayShifts.isNotEmpty) ...[
                        const ASSectionTitle(title: '今日打卡'),
                        const SizedBox(height: ASSpacing.sm),
                        _buildTodayShifts(todayShifts),
                        const SizedBox(height: ASSpacing.xl),
                      ],
                      const ASSectionTitle(title: '课时明细'),
                      const SizedBox(height: ASSpacing.md),
                      shifts.isEmpty ? _buildEmptyState() : _buildShiftsList(shifts),
                    ],
                  ),
                ),
                const SizedBox(height: ASSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(ASSpacing.md),
      color: ASColors.primary.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          const SizedBox(width: ASSpacing.md),
          Text(
            DateFormatters.month(_selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: ASSpacing.md),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedMonth.isBefore(DateTime.now())
                ? () => _changeMonth(1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySummary(Profile? currentUser, double totalSalary, int totalSessions) {
    final rate = currentUser?.ratePerSession ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? ASColorsDark.textSecondary : ASColors.textSecondary;

    return ASCard(
      animate: true,
      child: Column(
        children: [
          // 总金额
          Container(
            padding: const EdgeInsets.symmetric(vertical: ASSpacing.lg),
            child: Column(
              children: [
                Text(
                  'RM ${totalSalary.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: ASColors.primary,
                  ),
                ),
                const SizedBox(height: ASSpacing.xs),
                Text(
                  '${DateFormatters.month(_selectedMonth)} 预计收入',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // 统计数据
          Padding(
            padding: const EdgeInsets.all(ASSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: '已上课时',
                    value: '$totalSessions',
                    unit: '节',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: ASColors.divider,
                ),
                Expanded(
                  child: _StatColumn(
                    label: '课时单价',
                    value: 'RM ${rate.toStringAsFixed(0)}',
                    unit: '',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return ASCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: shifts.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: ASSpacing.sm),
            child: Row(
              children: [
                Icon(
                  s.status == ShiftStatus.completed ? Icons.check_circle : Icons.schedule,
                  color: s.status == ShiftStatus.completed ? ASColors.success : ASColors.info,
                  size: 18,
                ),
                const SizedBox(width: ASSpacing.sm),
                Expanded(
                  child: Text(
                    '${s.className ?? '课程'} · ${s.startTime}-${s.endTime.isNotEmpty ? s.endTime : '--'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  s.clockInAt != null ? DateFormatters.time(s.clockInAt!) : '',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? ASColorsDark.textHint : ASColors.textHint;
    final secondaryColor = isDark ? ASColorsDark.textSecondary : ASColors.textSecondary;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ASSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 64, color: hintColor)
                .animate()
                .fadeIn(duration: ASAnimations.normal)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: ASSpacing.md),
            Text(
              '本月暂无课时记录',
              style: TextStyle(
                fontSize: 16,
                color: secondaryColor,
              ),
            ).animate().fadeIn(duration: ASAnimations.normal, delay: 100.ms),
          ],
        ),
      ),
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
              child: Text(
                DateFormatters.friendlyDate(dateObj),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ASColors.textSecondary,
                ),
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

/// 统计列
class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: ASColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: ASSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: ASColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 课时卡片
class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift});

  final CoachShift shift;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ASSpacing.sm),
      padding: const EdgeInsets.all(ASSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        border: Border.all(color: ASColors.divider),
      ),
      child: Row(
        children: [
          // 状态图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 20,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shift.startTime} - ${shift.endTime}',
                  style: Theme.of(context).textTheme.bodySmall,
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
