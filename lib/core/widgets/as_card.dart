import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';
import '../constants/spacing.dart';

/// ASP 风格卡片组件
/// 
/// 支持入场动画和悬停效果
class ASCard extends StatefulWidget {
  const ASCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.elevation = 2,
    this.animate = false,
    this.animationDelay,
    this.animationIndex,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;
  
  /// 是否启用入场动画
  final bool animate;
  
  /// 自定义动画延迟
  final Duration? animationDelay;
  
  /// 列表中的索引，用于计算交错动画延迟
  final int? animationIndex;

  @override
  State<ASCard> createState() => _ASCardState();
}

class _ASCardState extends State<ASCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final shadowColor = isDark 
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.1);

    // 计算当前高度
    final currentElevation = _isPressed
        ? widget.elevation * 0.5
        : _isHovered
            ? widget.elevation * 1.5
            : widget.elevation;

    final scaleValue = _isPressed ? ASAnimations.buttonPressScale : 1.0;

    Widget card = AnimatedContainer(
      duration: ASAnimations.fast,
      curve: ASAnimations.defaultCurve,
      transform: Matrix4.identity()
        ..setEntry(0, 0, scaleValue)
        ..setEntry(1, 1, scaleValue),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        border: widget.borderColor != null && widget.borderWidth > 0
            ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
            : null,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: currentElevation * 2,
            offset: Offset(0, currentElevation),
          ),
        ],
      ),
      padding: widget.padding ?? const EdgeInsets.all(ASSpacing.cardPadding),
      margin: widget.margin,
      child: widget.child,
    );

    if (widget.onTap != null) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: card,
        ),
      );
    }

    // 应用入场动画
    if (widget.animate) {
      final delay = widget.animationDelay ?? 
          (widget.animationIndex != null 
              ? ASAnimations.getStaggerDelay(widget.animationIndex!)
              : Duration.zero);
      
      return card
          .animate(delay: delay)
          .fadeIn(
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          )
          .slideY(
            begin: 0.1,
            end: 0,
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          );
    }

    return card;
  }
}
