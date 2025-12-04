import 'package:flutter/material.dart';

/// 简化版 ASP 玻璃态容器组件 (标准 Container)
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

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final bool showBorder;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool animate;
  final Duration? animationDelay;

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
    Widget container = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: showBorder && borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}

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
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

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
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
    );
  }
}
