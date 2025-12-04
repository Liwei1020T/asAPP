import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';
import '../constants/spacing.dart';

/// 现代化 ASP 区块标题组件
class ASSectionTitle extends StatelessWidget {
  const ASSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.viewAllLabel = '查看全部',
    this.animate = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String viewAllLabel;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ASSpacing.md, 
        horizontal: ASSpacing.pagePadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (trailing == null && onTap != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(viewAllLabel),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
        ],
      ),
    );

    if (animate) {
      return content.animate().fadeIn().slideX(begin: -0.05, end: 0, duration: ASAnimations.short, curve: ASAnimations.decelerate);
    }

    return content;
  }
}
