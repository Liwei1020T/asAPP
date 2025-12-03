import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

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

/// 管理员仪表板
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
            child: GestureDetector(
              onTap: () => _showProfileMenu(context, ref),
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  currentUser?.fullName.substring(0, 1) ?? 'A',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 问候 - 带入场动画
            Text(
              '欢迎回来，${currentUser?.fullName ?? 'Admin'}',
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .fadeIn(duration: ASAnimations.normal)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: ASSpacing.xs),
            Text(
              '这里是您的学院概览',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: ASAnimations.normal),
            const SizedBox(height: ASSpacing.xl),

            // 统计概览 - 带交错动画
            _buildStatsOverview(context, ref),

            const SizedBox(height: ASSpacing.xl),

            // 最近活动（实时读取 Supabase）
            Text(
              '最近活动',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: ASAnimations.normal),
            const SizedBox(height: ASSpacing.md),
            _buildRecentActivity(context, ref),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/students'),
        icon: const Icon(Icons.add),
        label: const Text('添加学员'),
        backgroundColor: theme.colorScheme.primary,
      )
          .animate(delay: 600.ms)
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: ASAnimations.medium,
            curve: ASAnimations.emphasizeCurve,
          ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('个人资料'),
              onTap: () => Navigator.pop(context),
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
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final future = Future.wait<_CountTrend>([
      _loadClassStat(),
      _loadProfileStat(UserRole.student),
      _loadProfileStat(UserRole.coach),
    ]);

    return FutureBuilder<List<_CountTrend>>(
      future: future,
      builder: (context, snapshot) {
        // 加载中显示骨架屏
        if (!snapshot.hasData) {
          return ASResponsiveBuilder(
            mobile: Column(
              children: List.generate(3, (i) => Padding(
                padding: EdgeInsets.only(bottom: i < 2 ? ASSpacing.md : 0),
                child: const ASSkeletonStatCard(),
              )),
            ),
            tablet: Row(
              children: List.generate(3, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i > 0 ? ASSpacing.md : 0),
                  child: const ASSkeletonStatCard(),
                ),
              )),
            ),
          );
        }

        final stats = snapshot.data!;
        final classStat = stats[0];
        final studentStat = stats[1];
        final coachStat = stats[2];

        final cards = [
          _StatCard(
            label: '活跃班级',
            value: '${classStat.count}',
            icon: Icons.class_,
            color: theme.colorScheme.primary,
            trend: classStat.trend,
            animationIndex: 0,
          ),
          _StatCard(
            label: '学员总数',
            value: '${studentStat.count}',
            icon: Icons.people,
            color: theme.colorScheme.tertiary,
            trend: studentStat.trend,
            animationIndex: 1,
          ),
          _StatCard(
            label: '教练团队',
            value: '${coachStat.count}',
            icon: Icons.sports,
            color: Colors.green,
            trend: coachStat.trend,
            animationIndex: 2,
          ),
        ];

        return ASResponsiveBuilder(
          mobile: Column(
            children: [
              cards[0],
              const SizedBox(height: ASSpacing.md),
              cards[1],
              const SizedBox(height: ASSpacing.md),
              cards[2],
            ],
          ),
          tablet: Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: ASSpacing.md),
              Expanded(child: cards[1]),
              const SizedBox(width: ASSpacing.md),
              Expanded(child: cards[2]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
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
          return const ASSkeletonCard(height: 200)
              .animate(delay: 500.ms)
              .fadeIn(duration: ASAnimations.normal);
        }

        final notices = snapshot.data ?? [];
        if (notices.isEmpty) {
          return ASCard(
            animate: true,
            animationDelay: 500.ms,
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
          animate: true,
          animationDelay: 500.ms,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notices.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notice = notices[index];
              final color = notice.isUrgent 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.primary;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(Icons.campaign, color: color, size: 20),
                ),
                title: Text(notice.title),
                subtitle: Text(DateFormatters.relativeTime(notice.createdAt)),
                contentPadding: EdgeInsets.zero,
              )
                  .animate(delay: ASAnimations.getStaggerDelay(index))
                  .fadeIn(duration: ASAnimations.normal)
                  .slideX(begin: 0.05, end: 0);
            },
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.animationIndex = 0,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ASCard(
      animate: true,
      animationIndex: animationIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: ASSpacing.lg),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: ASSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
          ),
        ],
      ),
    );
  }
}

class _CountTrend {
  final int count;
  final String trend;
  const _CountTrend(this.count, this.trend);
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
