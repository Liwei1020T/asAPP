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
}

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
    this.variant = ASCardVariant.basic,
    this.gradient,
    this.backgroundColor,
    this.glassBlurSigma = ASColors.glassBlurSigma,
    this.glassOpacity = 0.85,
    this.showShadow = true,
    this.animate = false,
    this.animationDelay,
    this.animationIndex,
  });

  /// 渐变卡片便捷构造
  const ASCard.gradient({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.elevation = 2,
    Gradient? gradient,
    this.backgroundColor,
    this.glassBlurSigma = ASColors.glassBlurSigma,
    this.glassOpacity = 0.9,
    this.showShadow = true,
    this.animate = false,
    this.animationDelay,
    this.animationIndex,
  })  : variant = ASCardVariant.gradient,
        gradient = gradient ?? ASColors.cardGradient;

  /// 玻璃态卡片便捷构造
  const ASCard.glass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
    this.elevation = 0,
    this.gradient,
    this.backgroundColor,
    this.glassBlurSigma = ASColors.glassBlurSigmaLight,
    this.glassOpacity = 0.7,
    this.showShadow = false,
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
  final bool showShadow;
  
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
    
    final cardColor = widget.backgroundColor ?? 
        theme.cardTheme.color ?? 
        theme.colorScheme.surface;
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

    final borderRadius = BorderRadius.circular(ASSpacing.cardRadius);
    final effectiveGradient = widget.gradient ??
        (widget.variant == ASCardVariant.gradient
            ? ASColors.cardGradient
            : null);
    final effectiveBorderColor = widget.borderColor ??
        (widget.variant == ASCardVariant.glass
            ? (isDark ? ASColorsDark.glassBorder : ASColors.glassBorderLight)
            : null);

    Widget card = AnimatedContainer(
      duration: ASAnimations.fast,
      curve: ASAnimations.defaultCurve,
      transform: Matrix4.identity()
        ..setEntry(0, 0, scaleValue)
        ..setEntry(1, 1, scaleValue),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.variant == ASCardVariant.glass
            ? (cardColor.withValues(alpha: widget.glassOpacity))
            : cardColor,
        gradient: effectiveGradient,
        borderRadius: borderRadius,
        border: effectiveBorderColor != null && widget.borderWidth > 0
            ? Border.all(color: effectiveBorderColor, width: widget.borderWidth)
            : null,
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: currentElevation * 2,
                  offset: Offset(0, currentElevation),
                ),
              ]
            : null,
      ),
      padding: widget.padding ?? const EdgeInsets.all(ASSpacing.cardPadding),
      margin: widget.margin,
      child: widget.child,
    );

    if (widget.variant == ASCardVariant.glass) {
      card = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.glassBlurSigma,
            sigmaY: widget.glassBlurSigma,
          ),
          child: card,
        ),
      );
    }

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
