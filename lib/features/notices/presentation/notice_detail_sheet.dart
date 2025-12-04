import 'package:flutter/material.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/notice.dart';

/// 公告详情底部弹窗
class NoticeDetailSheet extends StatelessWidget {
  const NoticeDetailSheet({super.key, required this.notice});

  final Notice notice;

  static Future<void> show(BuildContext context, Notice notice) {
    return ASBottomSheet.show(
      context: context,
      maxHeight: 0.9,
      padding: const EdgeInsets.all(ASSpacing.lg),
      title: '公告详情',
      child: NoticeDetailSheet(notice: notice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notice.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: ASSpacing.sm),
        Wrap(
          spacing: ASSpacing.sm,
          runSpacing: ASSpacing.xs,
          children: [
            ASTag(
              label: _audienceLabel(notice.targetAudience),
              type: ASTagType.info,
            ),
            if (notice.isPinned) const ASTag(label: '置顶', type: ASTagType.warning),
            if (notice.isUrgent) const ASTag(label: '紧急', type: ASTagType.urgent),
            ASTag(
              label: DateFormatters.relativeDate(notice.createdAt),
              type: ASTagType.primary,
            ),
          ],
        ),
        const SizedBox(height: ASSpacing.md),
        Text(
          notice.content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: ASSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '发布人：${notice.createdBy}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
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
