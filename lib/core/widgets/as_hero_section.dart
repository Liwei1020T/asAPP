import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import 'as_card.dart';

/// 页头英雄区：渐变背景 + 头像 + 问候语
class ASHeroSection extends StatelessWidget {
  const ASHeroSection({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.avatar,
    this.trailing,
    this.actions,
    this.padding,
    this.gradient,
    this.compact = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? description;
  final Widget? avatar;
  final Widget? trailing;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onPrimary;

    Widget content = Row(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (avatar != null) ...[
          avatar!,
          const SizedBox(width: ASSpacing.lg),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: ASSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
              if (description != null) ...[
                const SizedBox(height: ASSpacing.sm),
                Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: ASSpacing.md),
                Wrap(
                  spacing: ASSpacing.sm,
                  runSpacing: ASSpacing.sm,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: ASSpacing.lg),
          trailing!,
        ],
      ],
    );

    return ASCard.gradient(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: ASSpacing.xl),
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: ASSpacing.xl,
            vertical: ASSpacing.xl,
          ),
      gradient: gradient ?? ASColors.heroGradient,
      child: content,
    );
  }
}
