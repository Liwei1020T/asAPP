import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/animations.dart';

/// 标签类型
enum ASTagType {
  /// 默认灰色
  normal,

  /// 主色红
  primary,

  /// 成功绿
  success,

  /// 警告黄
  warning,

  /// 错误红
  error,

  /// 信息蓝
  info,

  /// 紧急（红底白字）
  urgent,
}

/// ASP 标签组件
/// 
/// 支持暗色模式、点击动画
class ASTag extends StatefulWidget {
  const ASTag({
    super.key,
    required this.label,
    this.type = ASTagType.normal,
    this.icon,
    this.onTap,
    this.animate = false,
    this.animationDelay,
  });

  final String label;
  final ASTagType type;
  final IconData? icon;
  final VoidCallback? onTap;
  
  /// 是否启用入场动画
  final bool animate;
  
  /// 动画延迟
  final Duration? animationDelay;

  @override
  State<ASTag> createState() => _ASTagState();
}

class _ASTagState extends State<ASTag> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: ASAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: ASAnimations.tapScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: ASAnimations.defaultCurve,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    
    switch (widget.type) {
      case ASTagType.normal:
        return isDark 
            ? colorScheme.surfaceContainerHighest 
            : ASColors.divider;
      case ASTagType.primary:
        return colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1);
      case ASTagType.success:
        return ASColors.success.withValues(alpha: isDark ? 0.2 : 0.1);
      case ASTagType.warning:
        return ASColors.warning.withValues(alpha: isDark ? 0.2 : 0.1);
      case ASTagType.error:
        return colorScheme.error.withValues(alpha: isDark ? 0.2 : 0.1);
      case ASTagType.info:
        return ASColors.info.withValues(alpha: isDark ? 0.2 : 0.1);
      case ASTagType.urgent:
        return colorScheme.error;
    }
  }

  Color _getForegroundColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    
    switch (widget.type) {
      case ASTagType.normal:
        return isDark 
            ? colorScheme.onSurfaceVariant 
            : ASColors.textSecondary;
      case ASTagType.primary:
        return colorScheme.primary;
      case ASTagType.success:
        return isDark ? const Color(0xFF81C784) : ASColors.success;
      case ASTagType.warning:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      case ASTagType.error:
        return colorScheme.error;
      case ASTagType.info:
        return isDark ? const Color(0xFF64B5F6) : ASColors.info;
      case ASTagType.urgent:
        return colorScheme.onError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor(context);
    final fgColor = _getForegroundColor(context);
    
    Widget tag = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: ASAnimations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: ASSpacing.sm,
          vertical: ASSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(ASSpacing.tagRadius),
          boxShadow: _isPressed
              ? null
              : [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 12, color: fgColor),
              const SizedBox(width: ASSpacing.xs),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.onTap != null) {
      tag = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: tag,
        ),
      );
    }

    return tag;
  }
}

/// 出勤状态标签
class ASAttendanceTag extends StatelessWidget {
  const ASAttendanceTag({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    late ASTagType type;
    late String label;

    switch (status.toLowerCase()) {
      case 'present':
        type = ASTagType.success;
        label = '出席';
        break;
      case 'absent':
        type = ASTagType.error;
        label = '缺席';
        break;
      case 'late':
        type = ASTagType.warning;
        label = '迟到';
        break;
      case 'leave':
        type = ASTagType.normal;
        label = '请假';
        break;
      default:
        type = ASTagType.normal;
        label = status;
    }

    return ASTag(label: label, type: type);
  }
}

/// 级别标签
class ASLevelTag extends StatelessWidget {
  const ASLevelTag({
    super.key,
    required this.level,
  });

  final String level;

  @override
  Widget build(BuildContext context) {
    return ASTag(
      label: level,
      type: ASTagType.primary,
    );
  }
}
