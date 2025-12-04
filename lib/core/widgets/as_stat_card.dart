import 'package:flutter/material.dart';
import '../constants/animations.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import 'as_card.dart';

enum ASTrendDirection { up, down, flat }

/// 统计卡片：渐变背景、图标容器、趋势标记
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
    this.animateValue = true,
    this.animate = true,
    this.animationIndex,
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
  final bool animateValue;
  final bool animate;
  final int? animationIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return ASCard.gradient(
      gradient: gradient ?? ASColors.cardGradient,
      animate: animate,
      animationIndex: animationIndex,
      padding: const EdgeInsets.all(ASSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 24,
                  ),
                ),
              if (trend != null)
                _TrendBadge(
                  label: trend!,
                  direction: trendDirection,
                ),
            ],
          ),
          const SizedBox(height: ASSpacing.lg),
          _buildValue(theme, accent),
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
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValue(ThemeData theme, Color accent) {
    final displayText = valueText ?? value?.toString() ?? '--';
    if (value == null || !animateValue) {
      return Text(
        displayText,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      duration: ASAnimations.medium,
      curve: ASAnimations.smoothCurve,
      tween: Tween<double>(begin: 0, end: value!.toDouble()),
      builder: (context, val, _) {
        return Text(
          _formatValue(val, value!),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        );
      },
    );
  }

  String _formatValue(double animatedValue, num target) {
    final isInt = target % 1 == 0;
    return isInt ? animatedValue.toStringAsFixed(0) : animatedValue.toStringAsFixed(1);
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({
    required this.label,
    required this.direction,
  });

  final String label;
  final ASTrendDirection direction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late Color color;
    late IconData icon;

    switch (direction) {
      case ASTrendDirection.up:
        color = Colors.green;
        icon = Icons.trending_up;
        break;
      case ASTrendDirection.down:
        color = theme.colorScheme.error;
        icon = Icons.trending_down;
        break;
      case ASTrendDirection.flat:
        color = theme.colorScheme.outline;
        icon = Icons.trending_flat;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: ASSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
