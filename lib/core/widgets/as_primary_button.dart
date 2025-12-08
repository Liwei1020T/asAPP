import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';

/// 基础交互按钮包装器 (处理点击缩放)
class _InteractiveButtonWrapper extends StatefulWidget {
  const _InteractiveButtonWrapper({
    required this.child,
    this.onPressed,
  });

  final Widget child;
  final VoidCallback? onPressed;

  @override
  State<_InteractiveButtonWrapper> createState() => _InteractiveButtonWrapperState();
}

class _InteractiveButtonWrapperState extends State<_InteractiveButtonWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onPressed == null) return widget.child;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: ASAnimations.short,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

/// ASP 主按钮组件
/// 
/// 支持加载状态、点击缩放动画。
class ASPrimaryButton extends StatelessWidget {
  const ASPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 48,
    this.animate = false,
    this.animationDelay,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final bool animate;
  final Duration? animationDelay;

  @override
  Widget build(BuildContext context) {
    Widget button = SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    // 交互包装
    button = _InteractiveButtonWrapper(
      onPressed: isLoading ? null : onPressed,
      child: button,
    );

    // 入场动画
    if (animate) {
      button = button.animate(delay: animationDelay)
          .fadeIn(duration: ASAnimations.medium)
          .slideY(begin: 0.2, end: 0, curve: ASAnimations.emphasized);
    }

    return button;
  }
}

/// ASP 次要按钮 (Outlined)
class ASOutlineButton extends StatelessWidget {
  const ASOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.color,
    this.height = 48,
    this.animate = false,
    this.animationDelay,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? color;
  final double height;
  final bool animate;
  final Duration? animationDelay;

  @override
  Widget build(BuildContext context) {
    Widget button = SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: color != null ? BorderSide(color: color!) : null,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: color,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    button = _InteractiveButtonWrapper(
      onPressed: isLoading ? null : onPressed,
      child: button,
    );

    if (animate) {
      button = button.animate(delay: animationDelay)
          .fadeIn(duration: ASAnimations.medium)
          .slideY(begin: 0.2, end: 0, curve: ASAnimations.emphasized);
    }

    return button;
  }
}

/// ASP 小型按钮
class ASSmallButton extends StatelessWidget {
  const ASSmallButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return _InteractiveButtonWrapper(
      onPressed: onPressed,
      child: SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 4),
              ],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
