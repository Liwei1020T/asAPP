import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/notice.dart';
import '../../../data/repositories/supabase/notice_repository.dart';
import '../../auth/application/auth_providers.dart';
import 'notice_detail_sheet.dart';

/// 公告列表 + 创建页面（管理员）
class NoticeListPage extends ConsumerStatefulWidget {
  const NoticeListPage({super.key});

  @override
  ConsumerState<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends ConsumerState<NoticeListPage> {
  NoticeAudience? _filterAudience;
  bool? _filterPinned;

  @override
  Widget build(BuildContext context) {
    final stream = ref.read(supabaseNoticeRepositoryProvider).watchNotices();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('公告管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: ASColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('新增公告'),
      ).animate().scale(
            delay: ASAnimations.normal,
            duration: ASAnimations.medium,
            curve: ASAnimations.bounceCurve,
          ),
      body: StreamBuilder<List<Notice>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSourceToggle(),
                  const SizedBox(height: ASSpacing.sm),
                  _buildFilters(),
                  const SizedBox(height: ASSpacing.md),
                  Expanded(child: ASSkeletonList(itemCount: 5, hasAvatar: false)),
                ],
              ),
            );
          }

          var notices = snapshot.data ?? [];

          // 过滤
          notices = notices.where((n) {
            final matchAudience = _filterAudience == null || n.targetAudience == _filterAudience;
            final matchPinned = _filterPinned == null || n.isPinned == _filterPinned;
            return matchAudience && matchPinned;
          }).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSourceToggle(),
                  const SizedBox(height: ASSpacing.sm),
                  _buildFilters(),
                  const SizedBox(height: ASSpacing.md),
                  if (notices.isEmpty)
                    _buildEmpty(isDark)
                  else
                    ...notices.asMap().entries.map((entry) => _NoticeCard(
                          notice: entry.value,
                          animationIndex: entry.key,
                          onPinToggle: () => _togglePin(entry.value),
                          onTap: () => NoticeDetailSheet.show(context, entry.value),
                          onEdit: () => _showEditDialog(entry.value),
                          onDelete: () => _deleteNotice(entry.value),
                        )),
                  const SizedBox(height: ASSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: ASSpacing.sm,
      runSpacing: ASSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('全部'),
          selected: _filterAudience == null,
          onSelected: (_) => setState(() => _filterAudience = null),
        ),
        ChoiceChip(
          label: const Text('教练'),
          selected: _filterAudience == NoticeAudience.coach,
          onSelected: (_) => setState(() => _filterAudience = NoticeAudience.coach),
        ),
        ChoiceChip(
          label: const Text('家长'),
          selected: _filterAudience == NoticeAudience.parent,
          onSelected: (_) => setState(() => _filterAudience = NoticeAudience.parent),
        ),
        ChoiceChip(
          label: const Text('全部用户'),
          selected: _filterAudience == NoticeAudience.all,
          onSelected: (_) => setState(() => _filterAudience = NoticeAudience.all),
        ),
        const SizedBox(width: ASSpacing.md),
        FilterChip(
          label: const Text('仅置顶'),
          selected: _filterPinned == true,
          onSelected: (v) => setState(() => _filterPinned = v ? true : null),
        ),
        FilterChip(
          label: const Text('隐藏置顶'),
          selected: _filterPinned == false,
          onSelected: (v) => setState(() => _filterPinned = v ? false : null),
        ),
      ],
    );
  }

  Widget _buildEmpty(bool isDark) {
    final hintColor = isDark ? ASColorsDark.textHint : ASColors.textHint;
    final secondaryColor = isDark ? ASColorsDark.textSecondary : ASColors.textSecondary;
    
    return ASCard(
      animate: true,
      child: Padding(
        padding: const EdgeInsets.all(ASSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.campaign, size: 48, color: hintColor),
            const SizedBox(height: ASSpacing.md),
            Text('暂无公告', style: TextStyle(color: secondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceToggle() {
    return Row(
      children: [
        const Text('数据源：Supabase'),
      ],
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => _CreateNoticeDialog(onCreated: () async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发布成功')),
          );
        }
      }),
    );
  }

  void _showEditDialog(Notice notice) {
    showDialog(
      context: context,
      builder: (_) => _CreateNoticeDialog(
        onCreated: () async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('更新成功')),
            );
          }
        },
        initial: notice,
      ),
    );
  }

  Future<void> _togglePin(Notice notice) async {
    try {
      await ref
          .read(supabaseNoticeRepositoryProvider)
          .updateNotice(notice.copyWith(isPinned: !notice.isPinned));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败：$e')),
        );
      }
    }
  }

  Future<void> _deleteNotice(Notice notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除公告'),
        content: Text('确定删除公告《${notice.title}》吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: ASColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(supabaseNoticeRepositoryProvider).deleteNotice(notice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.onPinToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.animationIndex = 0,
  });

  final Notice notice;
  final VoidCallback onPinToggle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? ASColorsDark.textSecondary : ASColors.textSecondary;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: ASSpacing.md),
      child: ASCard(
        animate: true,
        animationIndex: animationIndex,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ASSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notice.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (notice.isPinned)
                    const ASTag(label: '置顶', type: ASTagType.warning),
                  if (notice.isUrgent)
                    const Padding(
                      padding: EdgeInsets.only(left: ASSpacing.xs),
                      child: ASTag(label: '紧急', type: ASTagType.error),
                    ),
                ],
              ),
              const SizedBox(height: ASSpacing.xs),
              Text(
                notice.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: ASSpacing.sm),
              Row(
                children: [
                  ASTag(
                    label: _audienceLabel(notice.targetAudience),
                    type: ASTagType.info,
                  ),
                  const SizedBox(width: ASSpacing.sm),
                  Text(
                    DateFormatters.relativeDate(notice.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                  IconButton(
                    icon: Icon(
                      notice.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: notice.isPinned ? ASColors.primary : secondaryColor,
                    ),
                    onPressed: onPinToggle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _audienceLabel(NoticeAudience audience) {
    switch (audience) {
      case NoticeAudience.all:
        return '全部';
      case NoticeAudience.coach:
        return '教练';
      case NoticeAudience.parent:
        return '家长';
    }
  }
}

class _CreateNoticeDialog extends ConsumerStatefulWidget {
  const _CreateNoticeDialog({required this.onCreated, this.initial});

  final VoidCallback onCreated;
  final Notice? initial;

  @override
  ConsumerState<_CreateNoticeDialog> createState() => _CreateNoticeDialogState();
}

class _CreateNoticeDialogState extends ConsumerState<_CreateNoticeDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late NoticeAudience _audience;
  late bool _isPinned;
  late bool _isUrgent;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _audience = initial?.targetAudience ?? NoticeAudience.all;
    _isPinned = initial?.isPinned ?? false;
    _isUrgent = initial?.isUrgent ?? false;
    if (initial != null) {
      _titleController.text = initial.title;
      _contentController.text = initial.content;
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写标题和内容')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final now = DateTime.now();
    final isEdit = widget.initial != null;
    final notice = isEdit
        ? widget.initial!.copyWith(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            isPinned: _isPinned,
            isUrgent: _isUrgent,
            targetAudience: _audience,
          )
        : Notice(
            id: 'notice-${now.millisecondsSinceEpoch}',
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            isPinned: _isPinned,
            isUrgent: _isUrgent,
            targetAudience: _audience,
            createdBy: ref.read(currentUserProvider)?.id ?? 'admin',
            createdAt: now,
          );

    try {
      if (isEdit) {
        await ref.read(supabaseNoticeRepositoryProvider).updateNotice(notice);
      } else {
        await ref.read(supabaseNoticeRepositoryProvider).createNotice(notice);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存公告失败：$e')),
        );
      }
    }

    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.of(context).pop();
      widget.onCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(ASSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '发布公告',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: ASSpacing.lg),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '请输入公告标题',
                ),
              ),
              const SizedBox(height: ASSpacing.md),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '内容',
                  hintText: '请输入公告内容',
                ),
              ),
              const SizedBox(height: ASSpacing.md),
              Wrap(
                spacing: ASSpacing.sm,
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: _audience == NoticeAudience.all,
                    onSelected: (_) => setState(() => _audience = NoticeAudience.all),
                  ),
                  ChoiceChip(
                    label: const Text('教练'),
                    selected: _audience == NoticeAudience.coach,
                    onSelected: (_) => setState(() => _audience = NoticeAudience.coach),
                  ),
                  ChoiceChip(
                    label: const Text('家长'),
                    selected: _audience == NoticeAudience.parent,
                    onSelected: (_) => setState(() => _audience = NoticeAudience.parent),
                  ),
                ],
              ),
              const SizedBox(height: ASSpacing.md),
              Row(
                children: [
                  Checkbox(
                    value: _isPinned,
                    onChanged: (v) => setState(() => _isPinned = v ?? false),
                  ),
                  const Text('置顶'),
                  const SizedBox(width: ASSpacing.lg),
                  Checkbox(
                    value: _isUrgent,
                    onChanged: (v) => setState(() => _isUrgent = v ?? false),
                  ),
                  const Text('紧急'),
                ],
              ),
              const SizedBox(height: ASSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: ASSpacing.sm),
                  ASPrimaryButton(
                    label: '发布',
                    onPressed: _isLoading ? null : _submit,
                    isLoading: _isLoading,
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
