import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';

/// 卡片变体
enum ASCardVariant {
  basic,
  gradient,
  glass,
  outline,
}

/// ASP 现代化卡片组件
/// 
/// 支持悬停、点击、玻璃拟态和入场动画。
class ASCard extends StatefulWidget {
  const ASCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
    this.elevation = 0,
    this.variant = ASCardVariant.basic,
    this.gradient,
    this.backgroundColor,
    this.glassBlurSigma = 10,
    this.glassOpacity = 0.1,
    this.borderRadius,
    this.animate = false,
    this.animationDelay,
    this.animationIndex,
  });

  const ASCard.gradient({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.elevation = 0,
    required Gradient this.gradient,
    this.backgroundColor,
    this.glassBlurSigma = 0,
    this.glassOpacity = 1,
    this.borderRadius,
    this.animate = false,
    this.animationDelay,
    this.animationIndex,
  }) : variant = ASCardVariant.gradient;

  const ASCard.glass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.elevation = 0,
    this.gradient,
    this.backgroundColor,
    this.glassBlurSigma = 10,
    this.glassOpacity = 0.1,
    this.borderRadius,
    this.animate = false,
    this.animationDelay,
    this.animationIndex,
  }) : variant = ASCardVariant.glass;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;
  final ASCardVariant variant;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double glassBlurSigma;
  final double glassOpacity;
  final BorderRadius? borderRadius;
  
  /// 是否启用入场动画
  final bool animate;
  /// 动画延迟
  final Duration? animationDelay;
  /// 列表索引（自动计算交错延迟）
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
    
    final radius = widget.borderRadius ?? BorderRadius.circular(ASSpacing.cardRadius);
    
    // 计算背景色
    Color? bgColor = widget.backgroundColor;
    if (bgColor == null) {
      switch (widget.variant) {
        case ASCardVariant.basic:
          bgColor = theme.cardTheme.color;
          break;
        case ASCardVariant.glass:
          bgColor = (isDark ? Colors.black : Colors.white).withValues(alpha: widget.glassOpacity);
          break;
        case ASCardVariant.outline:
          bgColor = Colors.transparent;
          break;
        case ASCardVariant.gradient:
          bgColor = null; // 使用 gradient
          break;
      }
    }

    // 构建基础容器
    Widget content = Container(
      padding: widget.padding ?? const EdgeInsets.all(ASSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        gradient: widget.gradient,
        borderRadius: radius,
        border: widget.variant == ASCardVariant.outline || widget.borderColor != null
            ? Border.all(
                color: widget.borderColor ?? theme.dividerColor,
                width: widget.borderWidth,
              )
            : null,
        boxShadow: _isHovered && widget.onTap != null
            ? [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : (widget.elevation > 0
                ? [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.05),
                      blurRadius: widget.elevation * 4,
                      offset: Offset(0, widget.elevation * 2),
                    )
                  ]
                : null),
      ),
      child: widget.child,
    );

    // 应用玻璃拟态
    if (widget.variant == ASCardVariant.glass) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.glassBlurSigma,
            sigmaY: widget.glassBlurSigma,
          ),
          child: content,
        ),
      );
    }

    // 应用交互效果 (Scale + Hover)
    if (widget.onTap != null) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : (_isHovered ? 1.01 : 1.0),
            duration: ASAnimations.short,
            curve: Curves.easeInOut,
            child: content,
          ),
        ),
      );
    } else {
      // 即使不可点击，也可以有 margin
      content = Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: content,
      );
    }

    // 应用入场动画
    if (widget.animate) {
      final delay = widget.animationDelay ?? 
          (widget.animationIndex != null 
              ? ASAnimations.staggerInterval * widget.animationIndex! 
              : Duration.zero);
              
      content = content.animate(delay: delay)
          .fadeIn(duration: ASAnimations.medium, curve: ASAnimations.standard)
          .slideY(begin: 0.1, end: 0, duration: ASAnimations.medium, curve: ASAnimations.standard);
    }

    // 如果有 margin 且可点击，margin 需要在 InkWell/GestureDetector 外部
    if (widget.onTap != null && widget.margin != null) {
      content = Padding(
        padding: widget.margin!,
        child: content,
      );
    }

    return content;
  }
}
