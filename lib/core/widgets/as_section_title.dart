import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/spacing.dart';
import '../constants/animations.dart';

/// ASP 区块标题组件
/// 
/// 支持暗色模式、入场动画
class ASSectionTitle extends StatelessWidget {
  const ASSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.viewAllLabel = '查看全部',
    this.animate = false,
    this.animationDelay,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  
  /// 查看全部按钮文本
  final String viewAllLabel;
  
  /// 是否启用入场动画
  final bool animate;
  
  /// 动画延迟
  final Duration? animationDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Widget content = Padding(
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: ASSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (trailing == null && onTap != null)
            _ViewAllButton(
              label: viewAllLabel,
              onTap: onTap!,
            ),
        ],
      ),
    );
    
    if (animate) {
      return content
          .animate(delay: animationDelay ?? Duration.zero)
          .fadeIn(
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          )
          .slideX(
            begin: -0.05,
            end: 0,
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          );
    }
    
    return content;
  }
}

/// 查看全部按钮
class _ViewAllButton extends StatefulWidget {
  const _ViewAllButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: ASAnimations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: ASSpacing.sm,
            vertical: ASSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _isHovered 
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: ASSpacing.xs),
              AnimatedSlide(
                duration: ASAnimations.fast,
                offset: Offset(_isHovered ? 0.1 : 0, 0),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
