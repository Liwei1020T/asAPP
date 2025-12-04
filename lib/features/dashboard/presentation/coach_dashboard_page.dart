import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../../data/repositories/supabase/notice_repository.dart';
import '../../../data/repositories/supabase/sessions_repository.dart';
import '../../../data/repositories/supabase/hr_repository.dart';
import '../../../data/repositories/supabase/classes_repository.dart';
import '../../notices/presentation/notice_detail_sheet.dart';

/// 教练仪表板 - 现代化重构版
class CoachDashboardPage extends ConsumerStatefulWidget {
  const CoachDashboardPage({super.key});

  @override
  ConsumerState<CoachDashboardPage> createState() => _CoachDashboardPageState();
}

class _CoachDashboardPageState extends ConsumerState<CoachDashboardPage> {
  bool _isClockedIn = false;
  bool _isClockLoading = false;
  CoachShift? _currentShift;
  String? _locationHint;
  List<CoachShift> _todayShifts = [];

  @override
  void initState() {
    super.initState();
    _loadClockState();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Dashboard'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.sports_tennis, size: 24, color: theme.colorScheme.primary),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: ASSpacing.md),
            child: ASAvatar(
              imageUrl: currentUser?.avatarUrl,
              name: currentUser?.fullName ?? 'C',
              size: ASAvatarSize.sm,
              showBorder: true,
              onTap: _showProfileMenu,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ASStaggeredColumn(
            animate: true,
            children: [
              // 公告板块
              const ASSectionTitle(
                title: '📢 公告 Notices',
              ),
              _buildNoticesSection(),

              // 操作区域
              const ASSectionTitle(
                title: '⚡ 操作 Actions',
              ),
              _buildActionsSection(isDark),

              // 今日课程
              const ASSectionTitle(
                title: '📅 今日班级 Today\'s Classes',
              ),
              _buildTodayClassesSection(),

              // 即将上课
              const ASSectionTitle(
                title: '⏭️ 即将到来的课程 Upcoming',
              ),
              _buildUpcomingClassesSection(),

              // 统计数据
              const ASSectionTitle(
                title: '📊 统计 Stats',
              ),
              _buildStatsSection(isDark),

              const SizedBox(height: ASSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    // 刷新数据
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
  }

  void _showProfileMenu() {
    final theme = Theme.of(context);
    ASBottomSheet.show(
      context: context,
      title: '个人中心',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('个人资料'),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('退出登录', style: TextStyle(color: theme.colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              ref.read(supabaseAuthRepositoryProvider).signOut();
              ref.read(currentUserProvider.notifier).setUser(null);
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  /// 公告区块
  Widget _buildNoticesSection() {
    return FutureBuilder<List<Notice>>(
      future: _fetchCoachNotices(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 260,
                margin: const EdgeInsets.only(right: ASSpacing.md),
                child: const ASSkeletonNoticeCard(),
              ),
            ),
          );
        }

        final notices = snapshot.data!;
        if (notices.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(ASSpacing.lg),
            child: const ASEmptyState(
              type: ASEmptyStateType.noData,
              title: '暂无公告',
              description: '稍后再来看看最新消息',
            ),
          );
        }

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return _NoticeCard(
                notice: notice,
                onTap: () => NoticeDetailSheet.show(context, notice),
              ).animate(delay: (index * 50).ms).fadeIn().slideX();
            },
          ),
        );
      },
    );
  }

  Future<List<Notice>> _fetchCoachNotices() async {
    try {
      return await ref.read(supabaseNoticeRepositoryProvider).fetchNotices(
            audiences: [NoticeAudience.coach, NoticeAudience.all],
            limit: 30,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载公告失败：$e')),
        );
      }
      return [];
    }
  }

  Future<List<Session>> _fetchTodaySessions(String coachId) async {
    try {
      final sessionsRepo = ref.read(supabaseSessionsRepositoryProvider);
      final sessions = await sessionsRepo.getAllTodaySessions();
      return sessions;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载今日课程失败：$e')),
        );
      }
      return [];
    }
  }

  Future<List<Session>> _fetchUpcomingSessions(String coachId) async {
    try {
      final sessionsRepo = ref.read(supabaseSessionsRepositoryProvider);
      final sessions = await sessionsRepo.getAllUpcomingSessions(limit: 6);
      return sessions;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载即将开始的课程失败：$e')),
        );
      }
      return [];
    }
  }

  Future<int> _fetchMonthlyCompleted(String coachId) async {
    if (coachId.isEmpty) return 0;
    try {
      return await ref
          .read(supabaseSessionsRepositoryProvider)
          .getMonthlyCompletedSessionsCount(coachId);
    } catch (_) {
      return 0;
    }
  }

  DateTime _combineDateAndTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// 操作区块
  Widget _buildActionsSection(bool isDark) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
      child: Row(
        children: [
          // 提示卡片：打卡已迁移到课程点名页面
          Expanded(
            child: ASCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: ASSpacing.sm),
                      const Text(
                        '上课打卡',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ASSpacing.sm),
                  Text(
                    '请在每节课的点名页面自动打卡，薪资将按课程统计。',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: ASSpacing.md),
          if (_todayShifts.isNotEmpty)
            Expanded(
              child: ASCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('今日打卡', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: ASSpacing.sm),
                    ..._todayShifts.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: ASSpacing.xs),
                          child: Row(
                            children: [
                              Icon(
                                s.status == ShiftStatus.completed ? Icons.check_circle : Icons.schedule,
                                size: 16,
                                color: s.status == ShiftStatus.completed ? ASColors.success : ASColors.info,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${s.startTime}-${s.endTime.isNotEmpty ? s.endTime : '--'} ${s.className ?? ''}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleClockInOut() async {
    setState(() => _isClockLoading = true);
    
    try {
      if (_isClockedIn) {
        await _clockOut();
      } else {
        await _clockIn();
      }
    } finally {
      if (mounted) {
        setState(() => _isClockLoading = false);
      }
    }
  }

  Future<void> _clockIn() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      _locationHint = '定位中...（若拒绝将不记录定位）';
      final position = await _getLocation();
      final shift = await ref
          .read(supabaseHrRepositoryProvider)
          .clockIn(currentUser.id, lat: position?.latitude, lng: position?.longitude);
      setState(() {
        _isClockedIn = true;
        _currentShift = shift;
        _locationHint = null;
        _upsertTodayShift(shift);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打卡成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        _locationHint = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打卡失败：$e')),
        );
      }
    }
  }

  Future<void> _clockOut() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      _locationHint = '定位中...';
      final position = await _getLocation();
      final shift = await ref
          .read(supabaseHrRepositoryProvider)
          .clockOut(currentUser.id, lat: position?.latitude, lng: position?.longitude);
      setState(() {
        _isClockedIn = false;
        _currentShift = shift;
        _locationHint = null;
        _upsertTodayShift(shift);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下班打卡成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        _locationHint = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下班打卡失败：$e')),
        );
      }
    }
  }

  Future<Position?> _getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationHint = '定位未开启';
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationHint = '未授权定位，已按无定位处理';
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (_) {
      _locationHint = '定位失败';
      return null;
    }
  }

  Future<void> _loadClockState() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    try {
      final shifts = await ref
          .read(supabaseHrRepositoryProvider)
          .getCoachShifts(currentUser.id, DateTime.now());
      _applyShiftState(shifts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载打卡状态失败：$e')),
        );
      }
    }
  }

  void _applyShiftState(List<CoachShift> shifts) {
    final todayKey = DateTime.now();
    _todayShifts = shifts.where((s) {
      final d = s.date;
      return d.year == todayKey.year && d.month == todayKey.month && d.day == todayKey.day;
    }).toList()
      ..sort((a, b) => (b.clockInAt ?? b.date).compareTo(a.clockInAt ?? a.date));

    final open = shifts.where((s) => s.clockOutAt == null).toList();
    setState(() {
      if (open.isNotEmpty) {
        _currentShift = open.first;
        _isClockedIn = true;
      } else {
        _isClockedIn = false;
        _currentShift = null;
      }
    });
  }

  void _upsertTodayShift(CoachShift shift) {
    final now = DateTime.now();
    if (!(shift.date.year == now.year &&
        shift.date.month == now.month &&
        shift.date.day == now.day)) return;

    _todayShifts.removeWhere((s) => s.id == shift.id);
    _todayShifts.insert(0, shift);
  }

  /// 今日课程区块
  Widget _buildTodayClassesSection() {
    final currentUser = ref.watch(currentUserProvider);
    
    return FutureBuilder<List<Session>>(
      future: _fetchTodaySessions(currentUser?.id ?? ''),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(ASSpacing.pagePadding),
            child: Column(
              children: List.generate(
                2,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: ASSpacing.md),
                  child: const ASSkeletonSessionCard(),
                ),
              ),
            ),
          );
        }

        final sessions = snapshot.data!;
        if (sessions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(ASSpacing.pagePadding),
            child: const ASEmptyState(
              type: ASEmptyStateType.noData,
              title: '今天没有课程安排',
              description: '保持关注，新的课程会出现在这里',
              icon: Icons.event_available,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
          child: Column(
            children: sessions.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: ASSpacing.md),
              child: _SessionCard(
                session: entry.value,
                onEnterAttendance: () async {
                  await context.push('/attendance/${entry.value.id}');
                  if (mounted) setState(() {});
                },
              ).animate(delay: (entry.key * 50).ms).fadeIn().slideY(begin: 0.1, end: 0),
            )).toList(),
          ),
        );
      },
    );
  }

  /// 即将上课区块
  Widget _buildUpcomingClassesSection() {
    final currentUser = ref.watch(currentUserProvider);

    return FutureBuilder<List<Session>>(
      future: _fetchUpcomingSessions(currentUser?.id ?? ''),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(ASSpacing.pagePadding),
            child: Column(
              children: List.generate(
                2,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: ASSpacing.md),
                  child: const ASSkeletonSessionCard(),
                ),
              ),
            ),
          );
        }

        final sessions = snapshot.data!;
        if (sessions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(ASSpacing.pagePadding),
            child: const ASEmptyState(
              type: ASEmptyStateType.noData,
              title: '暂无即将开始的课程',
              description: '待排课后会显示在这里',
              icon: Icons.upcoming,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
          child: Column(
            children: sessions.asMap().entries.map((entry) {
              final session = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: ASSpacing.md),
                child: _SessionCard(
                  session: session,
                  onEnterAttendance: () async {
                    await context.push('/attendance/${session.id}');
                    if (mounted) setState(() {});
                  },
                ).animate(delay: (entry.key * 50).ms).fadeIn().slideY(begin: 0.1, end: 0),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 统计区块
  Widget _buildStatsSection(bool isDark) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    final hintColor = theme.hintColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
      child: Column(
        children: [
          Row(
            children: [
              // 本月课程数
              Expanded(
                child: FutureBuilder<int>(
                  future: _fetchMonthlyCompleted(currentUser?.id ?? ''),
                  builder: (context, snapshot) {
                    return ASStatCard(
                      title: '本月已上课数',
                      subtitle: 'Sessions This Month',
                      value: snapshot.data ?? 0,
                      icon: Icons.schedule,
                      color: ASColors.primary,
                    );
                  },
                ),
              ),
              const SizedBox(width: ASSpacing.md),
              // 预计收入
              Expanded(
                child: FutureBuilder<CoachSessionSummary?>(
                  future: currentUser == null
                      ? Future.value(null)
                      : ref
                          .read(supabaseHrRepositoryProvider)
                          .getMonthlySummary(currentUser.id),
                  builder: (context, snapshot) {
                    final summary = snapshot.data;
                    return ASStatCard(
                      title: '本月预计收入',
                      subtitle: 'Estimated Income',
                      valueText: 'RM ${summary?.totalSalary.toStringAsFixed(0) ?? '0'}',
                      icon: Icons.account_balance_wallet,
                      color: ASColors.success,
                      trend: summary == null ? '计算中' : '',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: ASSpacing.md),
          // 查看详细薪资按钮
          ASCard(
            onTap: () => context.push('/salary'),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ASColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet, 
                      color: ASColors.success),
                ),
                const SizedBox(width: ASSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '薪资明细',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '查看完整课时和收入记录',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: hintColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 公告卡片
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice, 
    required this.onTap,
  });

  final Notice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: ASSpacing.md),
      child: ASCard(
        onTap: onTap,
        borderColor: notice.isUrgent ? ASColors.error : null,
        borderWidth: notice.isUrgent ? 2 : 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    notice.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (notice.isUrgent)
                  const ASTag(label: '紧急', type: ASTagType.urgent),
              ],
            ),
            const SizedBox(height: ASSpacing.sm),
            Expanded(
              child: Text(
                notice.content,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: ASSpacing.sm),
            Text(
              DateFormatters.relativeTime(notice.createdAt),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// 课程卡片
class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.session,
    this.onEnterAttendance,
  });

  final Session session;
  final Future<void> Function()? onEnterAttendance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    
    return ASCard(
      child: Row(
        children: [
          // 左侧时间标识
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: session.status == SessionStatus.completed
                  ? ASColors.success
                  : ASColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: ASSpacing.md),
          // 课程信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.className ?? session.title ?? '课程',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ASSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: secondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatters.date(session.startTime),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: ASSpacing.md),
                    Icon(Icons.access_time, size: 14, color: secondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatters.timeRange(session.startTime, session.endTime),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: ASSpacing.md),
                    Icon(Icons.location_on, size: 14, color: secondaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.venue ?? '',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 点名按钮
          if (session.status == SessionStatus.scheduled)
            ASSmallButton(
              label: '签到点名',
              icon: Icons.checklist,
              onPressed: () async {
                if (onEnterAttendance != null) {
                  await onEnterAttendance!();
                } else {
                  await context.push('/attendance/${session.id}');
                }
              },
            )
          else
            const ASTag(label: '已完成', type: ASTagType.success),
        ],
      ),
    );
  }
}
