import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';

/// ASP 区块标题组件
class ASSectionTitle extends StatelessWidget {
  const ASSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: ASSpacing.pagePadding,
        right: ASSpacing.pagePadding,
        top: ASSpacing.lg,
        bottom: ASSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ASColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: ASSpacing.xs),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ASColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (trailing == null && onTap != null)
            GestureDetector(
              onTap: onTap,
              child: const Row(
                children: [
                  Text(
                    '查看全部',
                    style: TextStyle(
                      fontSize: 14,
                      color: ASColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: ASSpacing.xs),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: ASColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
