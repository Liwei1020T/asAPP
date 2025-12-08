import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/models/timeline_comment.dart';
import '../../../data/repositories/supabase/timeline_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../../data/repositories/storage_repository.dart';

/// 训练动态 Timeline 列表页
class TimelineListPage extends ConsumerStatefulWidget {
  const TimelineListPage({super.key});

  @override
  ConsumerState<TimelineListPage> createState() => _TimelineListPageState();
}

class _TimelineListPageState extends ConsumerState<TimelineListPage> {
  Set<String> _likedPostIds = {};
  bool _likedLoaded = false;
  double? _uploadProgress;

  Future<void> _loadLiked(String userId) async {
    try {
      final ids = await ref.read(supabaseTimelineRepositoryProvider).getLikedPostIds(userId);
      if (mounted) {
        setState(() {
          _likedPostIds = ids.toSet();
          _likedLoaded = true;
        });
      }
    } catch (_) {
      // 忽略加载失败
    }
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    // 乐观更新
    setState(() {
      if (isLiked) {
        _likedPostIds.remove(postId);
      } else {
        _likedPostIds.add(postId);
      }
    });
    try {
      await ref.read(supabaseTimelineRepositoryProvider).toggleLike(postId, currentUser.id);
    } catch (_) {
      // 回滚
      setState(() {
        if (isLiked) {
          _likedPostIds.add(postId);
        } else {
          _likedPostIds.remove(postId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.read(supabaseTimelineRepositoryProvider).watchAllPosts();
    final currentUser = ref.watch(currentUserProvider);
    if (!_likedLoaded && currentUser != null) {
      _loadLiked(currentUser.id);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('训练动态 Moments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // 发布按钮 - 仅教练和管理员可见
          Consumer(
            builder: (context, ref, _) {
              final role = ref.watch(currentUserRoleProvider);
              if (role == UserRole.coach || role == UserRole.admin) {
                return IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  onPressed: () => _showCreatePostDialog(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TimelinePost>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              child: Column(
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: i == 3 ? 0 : ASSpacing.md),
                    child: const ASSkeletonCard(height: 200),
                  ),
                ),
              ),
            );
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(ASSpacing.pagePadding),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: ASSpacing.lg),
            itemBuilder: (context, index) {
              final post = posts[index];
              final isLiked = _likedPostIds.contains(post.id);
              return _TimelinePostCard(
                post: post,
                animationIndex: index,
                isLiked: isLiked,
                onLike: () => _toggleLike(post.id, isLiked),
                onComment: () => _showComments(context, post),
                onTap: () => _showPostDetail(post, isLiked),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const ASEmptyState(
      type: ASEmptyStateType.noData,
      title: '暂无训练动态',
      description: '教练将在这里分享训练精彩瞬间',
      icon: Icons.photo_library_outlined,
    );
  }

  void _showPostDetail(TimelinePost post, bool isLiked) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostDetailSheet(
        post: post,
        isLiked: isLiked,
        onLike: () => _toggleLike(post.id, isLiked),
        onComment: () => _showComments(context, post),
        onShare: () => _sharePost(post),
        canDelete: _canDeletePost(post),
        onDelete: () => _deletePost(post),
      ),
    );
  }

  bool _canDeletePost(TimelinePost post) {
    final currentUser = ref.read(currentUserProvider);
    final role = ref.read(currentUserRoleProvider);
    if (currentUser == null) return false;
    return currentUser.id == post.authorId || role == UserRole.admin;
  }

  Future<bool> _deletePost(TimelinePost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除动态'),
        content: const Text('确定要删除这条训练动态吗？评论和点赞也会一并删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: ASColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    try {
      await ref.read(supabaseTimelineRepositoryProvider).deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('动态已删除')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
      return false;
    }
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreatePostDialog(
        onCreated: () {}, // 实时流会自动更新
      ),
    );
  }

  void _sharePost(TimelinePost post) async {
    final link = '${Uri.base.origin}/#/timeline/${post.id}';
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('链接已复制')),
      );
    }
  }

  void _showComments(BuildContext context, TimelinePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(post: post),
    );
  }
}

/// 动态卡片
class _TimelinePostCard extends ConsumerWidget {
  const _TimelinePostCard({
    required this.post,
    required this.onTap,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    this.animationIndex = 0,
  });

  final TimelinePost post;
  final VoidCallback onTap;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ASCard(
      animate: true,
      animationIndex: animationIndex,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：作者信息
          FutureBuilder<Profile?>(
            future: _loadAuthor(ref, post.authorId),
            builder: (context, snapshot) {
              final author = snapshot.data;
              return Row(
                children: [
                  ASAvatar(
                    name: author?.fullName ?? 'User',
                    size: ASAvatarSize.md,
                    showBorder: true,
                    backgroundColor: ASColors.primary.withValues(alpha: 0.1),
                    foregroundColor: ASColors.primary,
                  ),
                  const SizedBox(width: ASSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author?.fullName ?? '用户',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          DateFormatters.relativeDate(post.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (post.visibility == PostVisibility.internal)
                    ASTag(
                      label: '内部',
                      type: ASTagType.warning,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: ASSpacing.md),

          // 内容
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: ASSpacing.md),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 15),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // 图片预览
          if (post.mediaUrls.isNotEmpty) _buildMediaPreview(context),

          const SizedBox(height: ASSpacing.sm),

          // 底部：点赞评论
          Row(
            children: [
              _InteractionButton(
                icon: Icons.favorite_border,
                count: post.likesCount,
                isSelected: isLiked,
                onTap: onLike,
              ),
              const SizedBox(width: ASSpacing.lg),
              _InteractionButton(
                icon: Icons.chat_bubble_outline,
                count: post.commentsCount,
                onTap: onComment,
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: ASColors.textHint, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    if (post.mediaUrls.length == 1) {
      return _MediaItem(
        url: post.mediaUrls.first,
        isVideo: post.mediaType == MediaType.video,
        onTap: post.mediaType == MediaType.image
            ? () => _showImagePreview(context, post.mediaUrls, 0)
            : null,
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: post.mediaUrls.length > 4 ? 4 : post.mediaUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: ASSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 3 && post.mediaUrls.length > 4) {
            return Stack(
              children: [
                _MediaItem(
                  url: post.mediaUrls[index],
                  height: 120,
                  width: 120,
                  onTap: post.mediaType == MediaType.image
                      ? () => _showImagePreview(context, post.mediaUrls, index)
                      : null,
                ),
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
                  ),
                  child: Center(
                    child: Text(
                      '+${post.mediaUrls.length - 3}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return _MediaItem(
            url: post.mediaUrls[index],
            height: 120,
            width: 120,
            onTap: post.mediaType == MediaType.image
                ? () => _showImagePreview(context, post.mediaUrls, index)
                : null,
          );
        },
      ),
    );
  }

}

Future<Profile?> _loadAuthor(WidgetRef ref, String userId) async {
  try {
    return await ref.read(supabaseAuthRepositoryProvider).getProfile(userId);
  } catch (_) {
    return null;
  }
}

/// 媒体项组件
class _MediaItem extends StatelessWidget {
  const _MediaItem({
    required this.url,
    this.height,
    this.width,
    this.isVideo = false,
    this.onTap,
  });

  final String url;
  final double? height;
  final double? width;
  final bool isVideo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ASSpacing.cardRadius);

    Widget child;
    if (!isVideo) {
      child = ClipRRect(
        borderRadius: radius,
        child: Image.network(
          url,
          height: height ?? 180,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _buildPlaceholder();
          },
        ),
      );
    } else {
      child = _buildPlaceholder(isVideo: true);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }

  Widget _buildPlaceholder({bool isVideo = false}) {
    return Container(
      height: height ?? 180,
      width: width,
      decoration: BoxDecoration(
        color: ASColors.backgroundLight,
        borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ASColors.primary.withValues(alpha: 0.1),
            ASColors.primary.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              isVideo ? Icons.play_circle_outline : Icons.image,
              size: 48,
              color: ASColors.primary.withValues(alpha: 0.5),
            ),
          ),
          if (isVideo)
            Positioned(
              bottom: ASSpacing.sm,
              right: ASSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ASSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '视频',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showImagePreview(
  BuildContext context,
  List<String> urls,
  int initialIndex,
) {
  if (urls.isEmpty) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black87,
    builder: (_) {
      final pageController = PageController(initialPage: initialIndex);
      return GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: urls.length,
                  itemBuilder: (context, index) {
                    final url = urls[index];
                    return Center(
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4,
                        child: Image.network(url),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 互动按钮
class _InteractionButton extends StatelessWidget {
  const _InteractionButton({
    required this.icon,
    required this.count,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Icon(
              isSelected && icon == Icons.favorite_border ? Icons.favorite : icon,
              size: 20,
              color: isSelected ? ASColors.primary : ASColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? ASColors.primary : ASColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 动态详情底部弹窗
class _PostDetailSheet extends ConsumerWidget {
  const _PostDetailSheet({
    required this.post,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.canDelete,
    required this.onDelete,
  });

  final TimelinePost post;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final bool canDelete;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 用局部状态保存点赞状态和计数，避免弹窗打开后不随父级刷新
    return _PostDetailSheetBody(
      post: post,
      initialLiked: isLiked,
      onLike: onLike,
      onComment: onComment,
      onShare: onShare,
      canDelete: canDelete,
      onDelete: onDelete,
    );
  }
}

class _PostDetailSheetBody extends ConsumerStatefulWidget {
  const _PostDetailSheetBody({
    required this.post,
    required this.initialLiked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.canDelete,
    required this.onDelete,
  });

  final TimelinePost post;
  final bool initialLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final bool canDelete;
  final Future<bool> Function() onDelete;

  @override
  ConsumerState<_PostDetailSheetBody> createState() => _PostDetailSheetBodyState();
}

class _PostDetailSheetBodyState extends ConsumerState<_PostDetailSheetBody> {
  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLiked;
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount = (_likesCount + (_isLiked ? 1 : -1)).clamp(0, 1 << 31);
    });
    widget.onLike();
  }

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    final success = await widget.onDelete();
    if (!mounted) return;
    setState(() => _isDeleting = false);
    if (success) {
      Navigator.of(context).pop(); // 关闭详情弹窗
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖动指示条
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ASColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 内容
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(ASSpacing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 作者信息
                      FutureBuilder<Profile?>(
                        future: ref
                            .read(supabaseAuthRepositoryProvider)
                            .getProfile(widget.post.authorId),
                        builder: (context, snapshot) {
                          final author = snapshot.data;
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: ASColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  author?.fullName.substring(0, 1) ?? 'U',
                                  style: const TextStyle(
                                    color: ASColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: ASSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      author?.fullName ?? '用户',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      DateFormatters.formatDateTime(widget.post.createdAt),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.canDelete)
                                IconButton(
                                  tooltip: '删除',
                                  onPressed: _isDeleting ? null : _handleDelete,
                                  icon: _isDeleting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.delete_outline, color: ASColors.error),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: ASSpacing.lg),

                      // 内容文本
                      if (widget.post.content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: ASSpacing.lg),
                          child: Text(
                            widget.post.content,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),

                      // 媒体
                      if (widget.post.mediaUrls.isNotEmpty)
                        Column(
                          children: widget.post.mediaUrls.asMap().entries.map((entry) {
                            final index = entry.key;
                            final url = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: ASSpacing.md),
                              child: _MediaItem(
                                url: url,
                                isVideo: widget.post.mediaType == MediaType.video,
                                onTap: widget.post.mediaType == MediaType.image
                                    ? () => _showImagePreview(
                                          context,
                                          widget.post.mediaUrls,
                                          index,
                                        )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: ASSpacing.lg),
                      const Divider(),
                      const SizedBox(height: ASSpacing.md),

                      // 互动区域
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _LargeInteractionButton(
                            icon: Icons.favorite_border,
                            label: '点赞',
                            count: _likesCount,
                            isSelected: _isLiked,
                            onTap: _handleLike,
                          ),
                          _LargeInteractionButton(
                            icon: Icons.chat_bubble_outline,
                            label: '评论',
                            count: _commentsCount,
                            onTap: () {
                              widget.onComment();
                              // 交给评论弹窗更新计数；这里先不乐观加
                            },
                          ),
                          _LargeInteractionButton(
                            icon: Icons.share_outlined,
                            label: '分享',
                            onTap: widget.onShare,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Profile?> _loadAuthor(WidgetRef ref) async {
    try {
      return await ref.read(supabaseAuthRepositoryProvider).getProfile(widget.post.authorId);
    } catch (_) {
      return null;
    }
  }
}

/// 大号互动按钮
class _LargeInteractionButton extends StatelessWidget {
  const _LargeInteractionButton({
    required this.icon,
    required this.label,
    this.count,
    this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Icon(
          isSelected && icon == Icons.favorite_border ? Icons.favorite : icon,
          size: 28,
          color: isSelected ? ASColors.primary : ASColors.textSecondary,
        ),
        const SizedBox(height: 4),
        Text(
          count != null ? '$label ($count)' : label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? ASColors.primary : ASColors.textSecondary,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// 评论列表/发表
class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.post});

  final TimelinePost post;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(supabaseTimelineRepositoryProvider).addComment(
            postId: widget.post.id,
            userId: currentUser.id,
            content: text,
          );
      _controller.clear();
      // 触发刷新
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发表评论失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: ASSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ASColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: ASSpacing.md),
              const Text(
                '评论',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: ASSpacing.md),
              Expanded(
                child: FutureBuilder<List<TimelineComment>>(
                  future: ref
                      .read(supabaseTimelineRepositoryProvider)
                      .fetchComments(widget.post.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data!;
                    if (comments.isEmpty) {
                      return const Center(child: Text('还没有评论，来抢沙发吧~'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ASSpacing.pagePadding,
                        vertical: ASSpacing.sm,
                      ),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                ASColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              (c.userName ?? c.userId).substring(0, 1),
                              style: const TextStyle(
                                  color: ASColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c.userName ?? '用户'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.content),
                              const SizedBox(height: 4),
                              Text(
                                DateFormatters.relativeDate(c.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(ASSpacing.pagePadding),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: '写评论...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: ASSpacing.sm),
                    ASPrimaryButton(
                      label: '发送',
                      onPressed: _submitting ? null : _submit,
                      isLoading: _submitting,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 创建动态对话框
class _CreatePostDialog extends ConsumerStatefulWidget {
  const _CreatePostDialog({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends ConsumerState<_CreatePostDialog> {
  final _contentController = TextEditingController();
  PostVisibility _visibility = PostVisibility.public;
  bool _isLoading = false;
  MediaType? _selectedMediaType;
  final List<Uint8List> _pickedImageBytes = [];
  final List<String> _pickedImageNames = [];
  Uint8List? _pickedVideoBytes;
  String? _pickedVideoName;
  bool _isUploading = false;
  bool _uploadFailed = false;
  double? _uploadProgress;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(MediaType type) async {
    if (type == MediaType.video) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = await _loadBytes(file);
        if (bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法读取视频文件，请重试或更换文件')),
            );
          }
          return;
        }
        setState(() {
          _selectedMediaType = MediaType.video;
          _pickedImageBytes.clear();
          _pickedImageNames.clear();
          _pickedVideoBytes = bytes;
          _pickedVideoName = file.name;
        });
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final files = result.files.where((f) => f.bytes != null || f.readStream != null).toList();
        if (files.isEmpty) return;
        final loadedBytes = <Uint8List>[];
        final names = <String>[];
        for (final f in files) {
          final bytes = await _loadBytes(f);
          if (bytes != null) {
            loadedBytes.add(bytes);
            names.add(f.name);
          }
        }
        if (loadedBytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法读取图片文件，请重试或更换文件')),
            );
          }
          return;
        }
        setState(() {
          _selectedMediaType = MediaType.image;
          _pickedVideoBytes = null;
          _pickedVideoName = null;
          _pickedImageBytes
            ..clear()
            ..addAll(loadedBytes);
          _pickedImageNames
            ..clear()
            ..addAll(names);
        });
      }
    }
  }

  Future<void> _submit({bool retryUploadOnly = false}) async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }

    if (_pickedImageBytes.isEmpty && _pickedVideoBytes == null && !retryUploadOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择图片或视频')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadFailed = false;
      _uploadProgress = 0;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final storageRepo = ref.read(storageRepositoryProvider);
      final timelineRepoSupabase = ref.read(supabaseTimelineRepositoryProvider);

      final now = DateTime.now();
      final basePath =
          'timeline/${currentUser?.id ?? 'unknown'}/${now.millisecondsSinceEpoch}';
      final mediaUrls = <String>[];
      var mediaType = MediaType.image;

      try {
        if (_selectedMediaType == MediaType.video && _pickedVideoBytes != null) {
          mediaType = MediaType.video;
          final ext = _pickedVideoName?.split('.').last ?? 'mp4';
          final filename = 'video.$ext';
          
          final url = await storageRepo.uploadFile(
            bytes: _pickedVideoBytes!,
            filename: filename,
            folder: basePath,
            onProgress: (p) {
              if (mounted) setState(() => _uploadProgress = p);
            },
          );
          mediaUrls.add(url);
        } else if (_selectedMediaType == MediaType.image &&
            _pickedImageBytes.isNotEmpty) {
          mediaType = MediaType.image;
          for (var i = 0; i < _pickedImageBytes.length; i++) {
            final bytes = _pickedImageBytes[i];
            final name = _pickedImageNames[i];
            final ext = name.split('.').last;
            final filename = 'image_$i.$ext';

            final url = await storageRepo.uploadFile(
              bytes: bytes,
              filename: filename,
              folder: basePath,
              onProgress: (p) {
                if (mounted) setState(() => _uploadProgress = p);
              },
            );
            mediaUrls.add(url);
          }
        }
      } catch (e) {
        debugPrint('Upload failed: $e');
        setState(() {
          _isUploading = false;
          _uploadFailed = true;
          _isLoading = false;
          _uploadProgress = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传媒体失败：$e')),
        );
        return;
      }


      final post = TimelinePost(
        id: 'post-${DateTime.now().millisecondsSinceEpoch}',
        authorId: currentUser?.id ?? 'unknown',
        content: _contentController.text.trim(),
        mediaUrls: mediaUrls,
        mediaType: mediaType,
        visibility: _visibility,
        createdAt: DateTime.now(),
      );

      await timelineRepoSupabase.createPost(post);
      widget.onCreated();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('发布成功！'),
            backgroundColor: ASColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败：$e'), backgroundColor: ASColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
          _uploadProgress = null;
          _pickedImageBytes.clear();
          _pickedImageNames.clear();
          _pickedVideoBytes = null;
          _pickedVideoName = null;
        });
      }
    }
  }

  Future<Uint8List?> _loadBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    if (file.readStream != null) {
      final buffer = <int>[];
      await for (final chunk in file.readStream!) {
        buffer.addAll(chunk);
      }
      return Uint8List.fromList(buffer);
    }
    return null;
  }

  Widget _buildMediaPreview() {
    final isVideo = _selectedMediaType == MediaType.video && _pickedVideoBytes != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ASColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ASColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isVideo)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _pickedImageBytes.isNotEmpty
                  ? Image.memory(
                      _pickedImageBytes.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(width: 80, height: 80),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ASColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.videocam, color: ASColors.info),
            ),
          const SizedBox(width: ASSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVideo
                      ? (_pickedVideoName ?? '已选择视频')
                      : (_pickedImageNames.isNotEmpty
                          ? (_pickedImageNames.first +
                              (_pickedImageNames.length > 1
                                  ? ' 等 ${_pickedImageNames.length} 张'
                                  : ''))
                          : '已选择图片'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isVideo)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '上传后可能需要转码，稍后可播放',
                      style: TextStyle(color: ASColors.textSecondary, fontSize: 12),
                    ),
                  ),
                if (_isUploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _uploadProgress,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isLoading
                ? null
                : () => setState(() {
                      _pickedImageBytes.clear();
                      _pickedImageNames.clear();
                      _pickedVideoBytes = null;
                      _pickedVideoName = null;
                    }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(ASSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '发布动态',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: ASSpacing.lg),

              // 内容输入
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '分享今天的训练精彩瞬间...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: ASSpacing.md),

              // 添加媒体按钮
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _pickMedia(MediaType.image),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('添加图片'),
                  ),
                  const SizedBox(width: ASSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _pickMedia(MediaType.video),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('添加视频'),
                  ),
                ],
              ),
              if (_pickedImageBytes.isNotEmpty || _pickedVideoBytes != null) ...[
                const SizedBox(height: ASSpacing.sm),
                _buildMediaPreview(),
              ],
              const SizedBox(height: ASSpacing.md),

              // 可见性选择
              Row(
                children: [
                  const Text('可见范围：'),
                  const SizedBox(width: ASSpacing.md),
                  ChoiceChip(
                    label: const Text('公开'),
                    selected: _visibility == PostVisibility.public,
                    onSelected: (_) => setState(() => _visibility = PostVisibility.public),
                  ),
                  const SizedBox(width: ASSpacing.sm),
                  ChoiceChip(
                    label: const Text('内部'),
                    selected: _visibility == PostVisibility.internal,
                    onSelected: (_) => setState(() => _visibility = PostVisibility.internal),
                  ),
                ],
              ),
              const SizedBox(height: ASSpacing.lg),

              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: ASSpacing.md),
                  ASPrimaryButton(
                    label: _isUploading ? '上传中...' : '发布',
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),
                  if (_uploadFailed)
                    Padding(
                      padding: const EdgeInsets.only(left: ASSpacing.sm),
                      child: TextButton(
                        onPressed: _isLoading ? null : () => _submit(retryUploadOnly: true),
                        child: const Text('重试上传'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
