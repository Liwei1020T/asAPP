import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../constants/animations.dart';
import '../constants/spacing.dart';

/// ASP 玻璃态容器组件
/// 
/// 实现现代毛玻璃效果，支持自适应降级
class ASGlassContainer extends StatelessWidget {
  const ASGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.opacity = 0.7,
    this.borderColor,
    this.borderWidth = 1,
    this.showBorder = true,
    this.backgroundColor,
    this.onTap,
    this.animate = false,
    this.animationDelay,
  });

  /// 子组件
  final Widget child;
  
  /// 内边距
  final EdgeInsetsGeometry? padding;
  
  /// 外边距
  final EdgeInsetsGeometry? margin;
  
  /// 圆角
  final BorderRadius? borderRadius;
  
  /// 模糊强度
  final double blur;
  
  /// 背景透明度 (0-1)
  final double opacity;
  
  /// 边框颜色
  final Color? borderColor;
  
  /// 边框宽度
  final double borderWidth;
  
  /// 是否显示边框
  final bool showBorder;
  
  /// 背景颜色（默认自动根据主题选择）
  final Color? backgroundColor;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 是否启用入场动画
  final bool animate;
  
  /// 动画延迟
  final Duration? animationDelay;

  /// 自适应构造函数 - 自动降级处理
  factory ASGlassContainer.adaptive({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double blur = 10.0,
    double opacity = 0.7,
    Color? borderColor,
    double borderWidth = 1,
    bool showBorder = true,
    Color? backgroundColor,
    VoidCallback? onTap,
    bool animate = false,
    Duration? animationDelay,
  }) {
    // 可以在这里添加设备性能检测逻辑
    // 对于低端设备自动降低模糊强度
    return ASGlassContainer(
      key: key,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: blur,
      opacity: opacity,
      borderColor: borderColor,
      borderWidth: borderWidth,
      showBorder: showBorder,
      backgroundColor: backgroundColor,
      onTap: onTap,
      animate: animate,
      animationDelay: animationDelay,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = backgroundColor ?? 
        (isDark ? ASColorsDark.glassBackground : ASColors.glassBackground);
    final border = borderColor ?? 
        (isDark ? ASColorsDark.glassBorder : ASColors.glassBorder);
    final radius = borderRadius ?? BorderRadius.circular(ASSpacing.cardRadius);

    Widget container = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: opacity),
            borderRadius: radius,
            border: showBorder
                ? Border.all(
                    color: border,
                    width: borderWidth,
                  )
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
                Colors.white.withValues(alpha: isDark ? 0.02 : 0.05),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      container = GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: container,
        ),
      );
    }

    if (animate) {
      return container
          .animate(delay: animationDelay ?? Duration.zero)
          .fadeIn(
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          )
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: ASAnimations.normal,
            curve: ASAnimations.springCurve,
          );
    }

    return container;
  }
}

/// 玻璃态卡片 - 预设样式的 ASGlassContainer
class ASGlassCard extends StatelessWidget {
  const ASGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.animate = false,
    this.animationIndex,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool animate;
  final int? animationIndex;

  @override
  Widget build(BuildContext context) {
    return ASGlassContainer(
      padding: const EdgeInsets.all(ASSpacing.cardPadding),
      blur: ASColors.glassBlurSigma,
      opacity: 0.8,
      onTap: onTap,
      animate: animate,
      animationDelay: animationIndex != null
          ? ASAnimations.getStaggerDelay(animationIndex!)
          : null,
      child: child,
    );
  }
}

/// 玻璃态 AppBar
class ASGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ASGlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle,
    this.blur = 15.0,
    this.elevation = 0,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final double blur;
  final double elevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? ASColorsDark.glassBackground : ASColors.glassBackground)
                .withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark ? ASColorsDark.glassBorder : ASColors.glassBorder,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ASSpacing.sm),
              child: Row(
                children: [
                  if (leading != null) leading!,
                  if (leading == null && Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  if (title != null) ...[
                    const SizedBox(width: ASSpacing.sm),
                    Expanded(
                      child: centerTitle == true
                          ? Center(child: title!)
                          : title!,
                    ),
                  ] else
                    const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
