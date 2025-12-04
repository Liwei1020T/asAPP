import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';
import '../constants/spacing.dart';
import 'as_card.dart';

enum ASTrendDirection { up, down, flat }

/// 现代化 ASP 统计卡片
class ASStatCard extends StatelessWidget {
  const ASStatCard({
    super.key,
    required this.title,
    this.value,
    this.valueText,
    this.subtitle,
    this.icon,
    this.color,
    this.gradient,
    this.trend,
    this.trendDirection = ASTrendDirection.up,
    this.onTap,
  });

  final String title;
  final num? value;
  final String? valueText;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final Gradient? gradient;
  final String? trend;
  final ASTrendDirection trendDirection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return ASCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ASSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(ASSpacing.xs),
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: effectiveColor),
                ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ASSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTrendColor(trendDirection).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTrendIcon(trendDirection),
                        size: 12,
                        color: _getTrendColor(trendDirection),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getTrendColor(trendDirection),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: ASSpacing.md),
          Text(
            valueText ?? value?.toString() ?? '--',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ).animate().fadeIn().scale(duration: ASAnimations.medium, curve: ASAnimations.emphasized),
          if (title.isNotEmpty) ...[
            const SizedBox(height: ASSpacing.xs),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: ASSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTrendColor(ASTrendDirection direction) {
    switch (direction) {
      case ASTrendDirection.up:
        return Colors.green;
      case ASTrendDirection.down:
        return Colors.red;
      case ASTrendDirection.flat:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(ASTrendDirection direction) {
    switch (direction) {
      case ASTrendDirection.up:
        return Icons.arrow_upward;
      case ASTrendDirection.down:
        return Icons.arrow_downward;
      case ASTrendDirection.flat:
        return Icons.remove;
    }
  }
}
