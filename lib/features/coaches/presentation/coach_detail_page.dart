import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/coach_shift.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../../data/repositories/supabase/sessions_repository.dart';
import '../../../data/repositories/supabase/hr_repository.dart';

/// 教练详情页（管理员查看）
class CoachDetailPage extends ConsumerStatefulWidget {
  const CoachDetailPage({super.key, required this.coachId});

  final String coachId;

  @override
  ConsumerState<CoachDetailPage> createState() => _CoachDetailPageState();
}

class _CoachDetailPageState extends ConsumerState<CoachDetailPage> {
  Profile? _coach;
  CoachSessionSummary? _summary;
  List<CoachSessionSummary> _history = [];
  List<Session> _upcoming = [];
  List<CoachShift> _shifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      final sessionsRepo = ref.read(supabaseSessionsRepositoryProvider);
      final hrRepo = ref.read(supabaseHrRepositoryProvider);

      final coach = await authRepo.getProfile(widget.coachId);
      if (coach == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到该教练')),
          );
          context.pop();
        }
        return;
      }

      final now = DateTime.now();
      final summary = await hrRepo.getMonthlySummary(widget.coachId, now);
      final history =
          await hrRepo.getHistorySummaries(widget.coachId, months: 4);
      final upcoming = await sessionsRepo.getUpcomingSessionsForCoach(
        widget.coachId,
        limit: 6,
      );
      final shifts = await hrRepo.getCoachShifts(widget.coachId, now);

      if (mounted) {
        setState(() {
          _coach = coach;
          _summary = summary;
          _history = history;
          _upcoming = upcoming;
          _shifts = shifts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载教练信息失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教练详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coach == null
              ? const Center(child: Text('未找到教练'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(ASSpacing.pagePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: ASSpacing.lg),
                          _buildStats(),
                          const SizedBox(height: ASSpacing.xl),
                          const ASSectionTitle(title: '📅 即将上课'),
                          _buildUpcoming(),
                          const SizedBox(height: ASSpacing.xl),
                          const ASSectionTitle(title: '🕒 最近课时'),
                          _buildShifts(),
                          const SizedBox(height: ASSpacing.xl),
                          const ASSectionTitle(title: '📈 月度历史'),
                          _buildHistory(),
                          const SizedBox(height: ASSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final coach = _coach!;
    return ASCard(
      child: Padding(
        padding: const EdgeInsets.all(ASSpacing.cardPadding),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: ASColors.primary.withOpacity(0.12),
              child: Text(
                coach.fullName.substring(0, 1),
                style: const TextStyle(
                  color: ASColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: ASSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (coach.phoneNumber != null)
                    Text(
                      coach.phoneNumber!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: ASSpacing.xs),
                  Wrap(
                    spacing: ASSpacing.sm,
                    children: [
                      ASTag(label: 'Coach', type: ASTagType.primary),
                      if (coach.ratePerSession != null)
                        ASTag(
                          label: 'RM ${coach.ratePerSession!.toStringAsFixed(0)}/节',
                          type: ASTagType.success,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final summary = _summary;
    final coach = _coach!;
    return Row(
      children: [
        Expanded(
          child: _StatBlock(
            label: '本月课时',
            value: summary?.totalSessions.toString() ?? '--',
            icon: Icons.event_available,
            color: ASColors.primary,
          ),
        ),
        const SizedBox(width: ASSpacing.md),
        Expanded(
          child: _StatBlock(
            label: '预计收入',
            value: summary != null ? 'RM ${summary.totalSalary.toStringAsFixed(0)}' : '--',
            icon: Icons.payments,
            color: ASColors.success,
          ),
        ),
        const SizedBox(width: ASSpacing.md),
        Expanded(
          child: _StatBlock(
            label: '累计课时',
            value: coach.totalClassesAttended.toString(),
            icon: Icons.auto_graph,
            color: ASColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcoming() {
    if (_upcoming.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(ASSpacing.lg),
        child: Text('暂无待上课安排', style: TextStyle(color: ASColors.textSecondary)),
      );
    }

    return Column(
      children: _upcoming.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: ASSpacing.sm),
          child: ASCard(
            child: ListTile(
              title: Text(s.title ?? s.className ?? '课程'),
              subtitle: Text(
                '${DateFormatters.formatDateTime(s.startTime)} - ${DateFormatters.time(s.endTime)} · ${s.venue ?? '待定'}',
              ),
              trailing: ASTag(
                label: s.status == SessionStatus.scheduled ? '待上课' : s.status.name,
                type: ASTagType.info,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShifts() {
    if (_shifts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(ASSpacing.lg),
        child: Text('本月暂无课时记录', style: TextStyle(color: ASColors.textSecondary)),
      );
    }

    return Column(
      children: _shifts.take(5).map((shift) {
        return Padding(
          padding: const EdgeInsets.only(bottom: ASSpacing.sm),
          child: ASCard(
            child: ListTile(
              leading: Icon(
                shift.status == ShiftStatus.completed ? Icons.check_circle : Icons.schedule,
                color: shift.status == ShiftStatus.completed ? ASColors.success : ASColors.textSecondary,
              ),
              title: Text(shift.className ?? '课时'),
              subtitle: Text(
                '${DateFormatters.date(shift.date)} · ${shift.startTime}-${shift.endTime.isNotEmpty ? shift.endTime : '待定'}',
              ),
              trailing: ASTag(
                label: shift.status == ShiftStatus.completed ? '已完成' : '已排班',
                type: shift.status == ShiftStatus.completed ? ASTagType.success : ASTagType.info,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(ASSpacing.lg),
        child: Text('暂无历史数据', style: TextStyle(color: ASColors.textSecondary)),
      );
    }

    return Wrap(
      spacing: ASSpacing.sm,
      runSpacing: ASSpacing.sm,
      children: _history.map((h) {
        final monthLabel = '${h.month.year}-${h.month.month.toString().padLeft(2, '0')}';
        return Container(
          width: 160,
          padding: const EdgeInsets.all(ASSpacing.md),
          decoration: BoxDecoration(
            color: ASColors.backgroundLight,
            borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthLabel, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: ASSpacing.xs),
              Text(
                '${h.totalSessions} 节 · RM ${h.totalSalary.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ASCard(
      child: Padding(
        padding: const EdgeInsets.all(ASSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: ASSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
