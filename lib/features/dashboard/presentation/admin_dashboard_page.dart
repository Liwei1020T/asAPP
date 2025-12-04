import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../../data/models/notice.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../data/repositories/supabase/supabase_client_provider.dart';
import '../../../data/models/profile.dart';
import 'widgets/dashboard_widgets.dart';

/// 管理员仪表板 - 现代化重构版
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final padding = ASResponsive.getPagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: ASSpacing.md),
            child: ASAvatar(
              imageUrl: currentUser?.avatarUrl,
              name: currentUser?.fullName ?? 'Admin',
              size: ASAvatarSize.sm,
              showBorder: true,
              onTap: () => _showProfileMenu(context, ref),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: ASResponsiveBuilder(
          mobile: _buildMobileLayout(context, ref),
          desktop: _buildDesktopLayout(context, ref),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/students'),
        icon: const Icon(Icons.add),
        label: const Text('添加学员'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return ASStaggeredColumn(
      animate: true,
      children: [
        _buildHero(context, ref),
        _buildStatsOverview(context, ref, isMobile: true),
        const SizedBox(height: ASSpacing.md),
        const QuickActions(),
        const SizedBox(height: ASSpacing.md),
        _buildChartSection(context),
        const SizedBox(height: ASSpacing.md),
        _buildRecentActivitySection(context, ref),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(context, ref),
        const SizedBox(height: ASSpacing.lg),
        
        // Row 1: KPI Cards
        _buildStatsOverview(context, ref, isMobile: false),
        const SizedBox(height: ASSpacing.lg),

        // Row 2: Chart + Quick Actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildChartSection(context),
            ),
            const SizedBox(width: ASSpacing.lg),
            const Expanded(
              flex: 1,
              child: QuickActions(),
            ),
          ],
        ),
        const SizedBox(height: ASSpacing.lg),

        // Row 3: Recent Activity + Upcoming (Placeholder for now)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildRecentActivitySection(context, ref),
            ),
            const SizedBox(width: ASSpacing.lg),
            Expanded(
              flex: 1,
              child: ASCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '即将开始的课程',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: ASSpacing.md),
                    const ASEmptyState(
                      type: ASEmptyStateType.noData, 
                      title: '暂无课程',
                      description: '今天没有安排课程',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    return ASHeroSection(
      title: '欢迎回来，${currentUser?.fullName ?? 'Admin'}',
      subtitle: '这里是您的学院概览',
      avatar: ASAvatar(
        name: currentUser?.fullName ?? 'Admin',
        size: ASAvatarSize.lg,
        showBorder: true,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => context.push('/students'),
          icon: const Icon(Icons.add),
          label: const Text('添加学员'),
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: _loadWeeklyAttendanceTrend(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ASSkeletonCard(height: 240);
        }

        return SimpleLineChart(
          title: '本周学员出勤趋势',
          data: snapshot.data!,
          height: 240,
        );
      },
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近活动',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ASSpacing.md),
        _buildRecentActivityList(context, ref),
      ],
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
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

  Widget _buildStatsOverview(BuildContext context, WidgetRef ref, {required bool isMobile}) {
    final theme = Theme.of(context);
    final future = Future.wait<_CountTrend>([
      _loadClassStat(),
      _loadProfileStat(UserRole.student),
      _loadProfileStat(UserRole.coach),
    ]);

    final skeleton = isMobile 
      ? Column(
          children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: ASSpacing.md),
            child: const ASSkeletonStatCard(),
          )),
        )
      : Row(
          children: List.generate(3, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i > 0 ? ASSpacing.md : 0),
              child: const ASSkeletonStatCard(),
            ),
          )),
        );

    return FutureBuilder<List<_CountTrend>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ASSkeletonTransition(
            isLoading: true,
            skeleton: skeleton,
            child: const SizedBox.shrink(),
          );
        }

        final stats = snapshot.data!;
        final classStat = stats[0];
        final studentStat = stats[1];
        final coachStat = stats[2];

        final cards = [
          ASStatCard(
            title: '活跃班级',
            value: classStat.count,
            subtitle: '学院活跃班级总览',
            icon: Icons.class_,
            color: theme.colorScheme.primary,
            trend: classStat.trend,
            trendDirection: _resolveTrendDirection(classStat.trend),
          ),
          ASStatCard(
            title: '学员总数',
            value: studentStat.count,
            subtitle: '已注册学员',
            icon: Icons.people,
            color: theme.colorScheme.tertiary,
            trend: studentStat.trend,
            trendDirection: _resolveTrendDirection(studentStat.trend),
          ),
          ASStatCard(
            title: '教练团队',
            value: coachStat.count,
            subtitle: '在册教练',
            icon: Icons.sports,
            color: Colors.green,
            trend: coachStat.trend,
            trendDirection: _resolveTrendDirection(coachStat.trend),
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: ASSpacing.md),
              cards[1],
              const SizedBox(height: ASSpacing.md),
              cards[2],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: ASSpacing.md),
            Expanded(child: cards[1]),
            const SizedBox(width: ASSpacing.md),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivityList(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stream = supabaseClient
        .from('notices')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20)
        .map((rows) => rows
            .map((e) => Notice.fromJson(e as Map<String, dynamic>))
            .toList());

    return StreamBuilder<List<Notice>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const ASSkeletonCard(height: 200);
        }

        final notices = snapshot.data ?? [];
        if (notices.isEmpty) {
          return ASCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ASSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, color: theme.hintColor),
                  const SizedBox(width: ASSpacing.sm),
                  Text('暂无最近活动', style: TextStyle(color: theme.hintColor)),
                ],
              ),
            ),
          );
        }

        return ASCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notices.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final notice = notices[index];
              final color = notice.isUrgent 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.primary;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.campaign, color: color, size: 20),
                ),
                title: Text(
                  notice.title,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  DateFormatters.relativeTime(notice.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: ASSpacing.lg, vertical: ASSpacing.xs),
              );
            },
          ),
        );
      },
    );
  }
}

class _CountTrend {
  final int count;
  final String trend;
  const _CountTrend(this.count, this.trend);
}

ASTrendDirection _resolveTrendDirection(String trend) {
  final text = trend.trim();
  if (text.startsWith('-')) return ASTrendDirection.down;
  if (text.contains('无') || text.contains('0')) return ASTrendDirection.flat;
  return ASTrendDirection.up;
}

Future<_CountTrend> _loadClassStat() async {
  // 总活跃班级数
  final classRows =
      await supabaseClient.from('class_groups').select('id, is_active');
  final classList = classRows as List;
  final activeCount = classList
      .where((e) => (e as Map<String, dynamic>)['is_active'] == true)
      .length;

  // 本周有上课的班级数（根据 sessions.start_time 统计不同 class_id）
  final now = DateTime.now();
  final startOfWeek =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));

  final sessionRows = await supabaseClient
      .from('sessions')
      .select('class_id, start_time')
      .gte('start_time', startOfWeek.toIso8601String())
      .lt('start_time', endOfWeek.toIso8601String());
  final sessionList = sessionRows as List;
  final classesThisWeek = sessionList
      .map((e) => (e as Map<String, dynamic>)['class_id'] as String?)
      .whereType<String>()
      .toSet()
      .length;

  final trend = '本周有 $classesThisWeek 班上课';
  return _CountTrend(activeCount, trend);
}

Future<_CountTrend> _loadProfileStat(UserRole role) async {
  List list;
  if (role == UserRole.student) {
    final rows = await supabaseClient
        .from('students')
        .select('id, created_at');
    list = rows as List;
  } else {
    final rows = await supabaseClient
        .from('profiles')
        .select('id, role, created_at')
        .eq('role', role.name);
    list = rows as List;
  }
  final total = list.length;

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  int newThisMonth = 0;
  for (final row in list) {
    final map = row as Map<String, dynamic>;
    final createdAtStr = map['created_at'] as String?;
    if (createdAtStr == null) continue;
    final createdAt = DateTime.parse(createdAtStr);
    if (!createdAt.isBefore(startOfMonth)) {
      newThisMonth++;
    }
  }

  final label = newThisMonth > 0 ? '+$newThisMonth 本月' : '本月无新增';
  return _CountTrend(total, label);
}

Future<List<double>> _loadWeeklyAttendanceTrend() async {
  final now = DateTime.now();
  // Get start of week (Monday)
  final startOfWeek = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));

  // 1. Fetch sessions for this week
  final sessionRows = await supabaseClient
      .from('sessions')
      .select('id, start_time')
      .gte('start_time', startOfWeek.toIso8601String())
      .lt('start_time', endOfWeek.toIso8601String());
  
  final sessions = sessionRows as List;
  if (sessions.isEmpty) return List.filled(7, 0.0);

  final sessionIds = sessions.map((e) => e['id']).toList();

  // 2. Fetch attendance for these sessions (present only)
  final attendanceRows = await supabaseClient
      .from('attendance')
      .select('session_id, status')
      .filter('session_id', 'in', sessionIds)
      .eq('status', 'present');
  
  final attendanceList = attendanceRows as List;

  // 3. Group by day of week (0=Mon, 6=Sun)
  final dailyCounts = List.filled(7, 0.0);
  
  for (final record in attendanceList) {
    final sessionId = record['session_id'];
    final session = sessions.firstWhere((s) => s['id'] == sessionId);
    final startTime = DateTime.parse(session['start_time']);
    // weekday is 1..7, we want 0..6
    final dayIndex = startTime.weekday - 1;
    if (dayIndex >= 0 && dayIndex < 7) {
      dailyCounts[dayIndex]++;
    }
  }

  return dailyCounts;
}
