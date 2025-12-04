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
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../../data/repositories/supabase/notice_repository.dart';
import '../../../data/repositories/supabase/attendance_repository.dart';
import '../../../data/repositories/supabase/timeline_repository.dart';
import '../../notices/presentation/notice_detail_sheet.dart';

/// 家长仪表板
class ParentDashboardPage extends ConsumerStatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  ConsumerState<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends ConsumerState<ParentDashboardPage> {
  List<Student> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      final children = await authRepo.getLinkedStudents(currentUser.id);
      if (mounted) {
        setState(() {
          _children = children;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载孩子列表失败：$e')),
        );
      }
    }
  }

  Future<void> _showAddChildDialog() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final controller = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加孩子'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '学生 ID',
            hintText: '请输入孩子的学生 ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (added != true) return;

    final studentId = controller.text.trim();
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('学生 ID 不能为空')),
      );
      return;
    }

    try {
      await ref.read(supabaseAuthRepositoryProvider).bindStudentsToParent(
            parentId: currentUser.id,
            studentIds: [studentId],
          );
      await _loadChildren();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已关联孩子')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('关联失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_tennis, size: 24),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: ASSpacing.md),
            child: ASAvatar(
              imageUrl: currentUser?.avatarUrl,
              name: currentUser?.fullName ?? 'P',
              size: ASAvatarSize.sm,
              showBorder: true,
              onTap: _showProfileMenu,
              animate: true,
            ),
          ).animate().scale(
                delay: ASAnimations.fast,
                duration: ASAnimations.medium,
                curve: ASAnimations.bounceCurve,
              ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChildren,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 问候语
              _buildGreetingSection(isDark),

              // 孩子出勤概览
              ASSectionTitle(
                title: '📊 出勤概览 Attendance Overview',
                animate: true,
                animationDelay: 100.ms,
              ),
              _buildChildrenAttendanceSection(isDark),

              // 训练精彩时刻
              ASSectionTitle(
                title: '🎬 训练精彩 Training Moments',
                animate: true,
                animationDelay: 200.ms,
              ),
              _buildMomentsSection(isDark),

              // 公告
              ASSectionTitle(
                title: '📢 通知 Notices',
                animate: true,
                animationDelay: 300.ms,
              ),
              _buildNoticesSection(isDark),

              const SizedBox(height: ASSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileMenu() {
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
            leading: const Icon(Icons.logout, color: ASColors.error),
            title: const Text('退出登录', style: TextStyle(color: ASColors.error)),
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

  /// 问候区块
  Widget _buildGreetingSection(bool isDark) {
    final currentUser = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.all(ASSpacing.pagePadding),
      child: ASGlassContainer.adaptive(
        padding: const EdgeInsets.all(ASSpacing.cardPadding),
        blur: isDark ? ASColors.glassBlurSigma : ASColors.glassBlurSigmaLight,
        opacity: 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ASAvatar(
                  name: currentUser?.fullName ?? 'Parent',
                  size: ASAvatarSize.lg,
                  showBorder: true,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  animate: true,
                ),
                const SizedBox(width: ASSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${currentUser?.fullName ?? 'Parent'}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: ASSpacing.xs),
                      Text(
                        _children.isEmpty
                            ? '欢迎回来'
                            : '您有 ${_children.length} 位小孩在训练',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _showAddChildDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('添加孩子'),
                ),
              ],
            ),
            if (_children.isNotEmpty) ...[
              const SizedBox(height: ASSpacing.md),
              Wrap(
                spacing: ASSpacing.sm,
                runSpacing: ASSpacing.sm,
                children: _children
                    .map((child) => ASTag(
                          label: child.fullName,
                          type: ASTagType.primary,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 孩子出勤区块
  Widget _buildChildrenAttendanceSection(bool isDark) {
    final hintColor = isDark ? ASColorsDark.textHint : ASColors.textHint;
    final secondaryColor = isDark ? ASColorsDark.textSecondary : ASColors.textSecondary;

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
        child: Column(
          children: List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: ASSpacing.md),
              child: const ASSkeletonProfileCard(),
            ),
          ),
        ),
      );
    }

    if (_children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
        child: ASEmptyState(
          type: ASEmptyStateType.noData,
          title: '暂无关联的学员',
          description: '请添加孩子后查看出勤与课时信息',
          icon: Icons.child_care,
          actionLabel: '添加孩子',
          onAction: _showAddChildDialog,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
      child: Column(
        children: _children.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: ASSpacing.md),
          child: _ChildAttendanceCard(
            child: entry.value,
            animationIndex: entry.key,
          ),
        )).toList(),
      ),
    );
  }

  /// 训练精彩区块
  Widget _buildMomentsSection(bool isDark) {
    final hintColor = isDark ? ASColorsDark.textHint : ASColors.textHint;
    final secondaryColor = isDark ? ASColorsDark.textSecondary : ASColors.textSecondary;

    return FutureBuilder<List<TimelinePost>>(
      future: _fetchMoments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 160,
                margin: const EdgeInsets.only(right: ASSpacing.md),
                child: const ASSkeletonImage(height: 180),
              ),
            ),
          );
        }

        final posts = snapshot.data!;
        if (posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
            child: ASEmptyState(
              type: ASEmptyStateType.noData,
              title: '暂无训练精彩时刻',
              description: '关注孩子的每一次突破，这里会展示最新动态',
              icon: Icons.video_library_outlined,
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
            itemCount: posts.length > 5 ? 5 : posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _MomentCard(post: post, animationIndex: index);
            },
          ),
        );
      },
    );
  }

  /// 公告区块
  Widget _buildNoticesSection(bool isDark) {
    return FutureBuilder<List<Notice>>(
      future: _fetchParentNotices(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: ASSpacing.md),
                  child: const ASSkeletonNoticeCard(),
                ),
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
              description: '新的通知会出现在这里',
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
          child: Column(
            children: notices.take(3).toList().asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: ASSpacing.md),
              child: _NoticeListItem(
                notice: entry.value,
                animationIndex: entry.key,
                onTap: () => _showNoticeDetail(entry.value),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  Future<List<Notice>> _fetchParentNotices() async {
    try {
      return await ref.read(supabaseNoticeRepositoryProvider).fetchNotices(
            audiences: [NoticeAudience.parent, NoticeAudience.all],
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

  void _showNoticeDetail(Notice notice) {
    NoticeDetailSheet.show(context, notice);
  }

  Future<List<TimelinePost>> _fetchMoments() async {
    final childIds = _children.map((c) => c.id).toList();
    if (childIds.isEmpty) return [];
    try {
      return await ref
          .read(supabaseTimelineRepositoryProvider)
          .getPostsForStudents(childIds, limit: 20);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载训练精彩失败：$e')),
        );
      }
      return [];
    }
  }
}

/// 孩子出勤卡片
class _ChildAttendanceCard extends ConsumerWidget {
  const _ChildAttendanceCard({
    required this.child,
    this.animationIndex = 0,
  });

  final Student child;
  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<StudentAttendanceSummary>(
      future: _fetchStudentSummary(ref, child.id, child.fullName),
      builder: (context, snapshot) {
        final summary = snapshot.data;

        return ASCard.glass(
          animate: true,
          animationIndex: animationIndex,
          padding: const EdgeInsets.all(ASSpacing.cardPadding),
          child: Row(
            children: [
              ASAvatar(
                name: child.fullName,
                size: ASAvatarSize.md,
                showBorder: true,
                backgroundColor: ASColors.info.withValues(alpha: 0.15),
                foregroundColor: ASColors.info,
              ),
              const SizedBox(width: ASSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: ASSpacing.xs),
                    Text(
                      '剩余课时 ${child.remainingSessions}/${child.totalSessions}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${summary?.presentCount ?? 0}/${summary?.totalSessions ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ASColors.primary,
                    ),
                  ),
                  const SizedBox(height: ASSpacing.xs),
                  Text(
                    '${DateFormatters.month(DateTime.now())}出勤',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<StudentAttendanceSummary> _fetchStudentSummary(
    WidgetRef ref,
    String studentId,
    String studentName,
  ) async {
    try {
      return await ref
          .read(supabaseAttendanceRepositoryProvider)
          .getMonthlyAttendanceSummary(studentId, studentName);
    } catch (_) {
      return StudentAttendanceSummary(
        studentId: studentId,
        studentName: studentName,
        totalSessions: 0,
        presentCount: 0,
        absentCount: 0,
        lateCount: 0,
        leaveCount: 0,
      );
    }
  }
}

/// 精彩时刻卡片
class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.post,
    this.animationIndex = 0,
  });

  final TimelinePost post;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? ASColorsDark.divider : ASColors.divider;
    final hintColor = isDark ? ASColorsDark.textHint : ASColors.textHint;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: ASSpacing.md),
      child: ASCard(
        animate: true,
        animationIndex: animationIndex,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 缩略图
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(ASSpacing.cardRadius),
              ),
              child: Container(
                height: 100,
                color: dividerColor,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (post.thumbnailUrl != null)
                      Image.network(
                        post.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image,
                          size: 40,
                          color: hintColor,
                        ),
                      )
                    else
                      Icon(
                        Icons.image,
                        size: 40,
                        color: hintColor,
                      ),
                    if (post.mediaType == MediaType.video)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(ASSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.mentionedStudentNames != null &&
                        post.mentionedStudentNames!.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: post.mentionedStudentNames!.take(2).map((name) =>
                          Text(
                            '@$name',
                            style: const TextStyle(
                              fontSize: 11,
                              color: ASColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ).toList(),
                      ),
                    const Spacer(),
                    Text(
                      DateFormatters.relativeTime(post.createdAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 公告列表项
class _NoticeListItem extends StatelessWidget {
  const _NoticeListItem({
    required this.notice, 
    required this.onTap,
    this.animationIndex = 0,
  });

  final Notice notice;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return ASCard(
      animate: true,
      animationIndex: animationIndex,
      onTap: onTap,
      child: Row(
        children: [
          // 图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notice.isUrgent
                  ? ASColors.error.withValues(alpha: 0.1)
                  : ASColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              notice.isUrgent ? Icons.warning : Icons.campaign,
              color: notice.isUrgent ? ASColors.error : ASColors.info,
            ),
          ),
          const SizedBox(width: ASSpacing.md),
          // 内容
          Expanded(
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
                const SizedBox(height: ASSpacing.xs),
                Text(
                  notice.content,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
