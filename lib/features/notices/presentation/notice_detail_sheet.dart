import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/notice.dart';

/// 公告详情底部弹窗
class NoticeDetailSheet extends StatelessWidget {
  const NoticeDetailSheet({super.key, required this.notice});

  final Notice notice;

  static Future<void> show(BuildContext context, Notice notice) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoticeDetailSheet(notice: notice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: ASColors.shadow,
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ASSpacing.pagePadding,
                vertical: ASSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: ASSpacing.md),
                      decoration: BoxDecoration(
                        color: ASColors.textHint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notice.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
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
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Text(
                        notice.content,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
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
              ),
            ),
          ),
        );
      },
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
