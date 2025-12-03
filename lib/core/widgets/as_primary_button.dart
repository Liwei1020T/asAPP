import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';
import '../constants/spacing.dart';

/// ASP 主按钮组件
/// 
/// 支持按压动画和加载状态过渡
class ASPrimaryButton extends StatefulWidget {
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
  
  /// 是否启用入场动画
  final bool animate;
  
  /// 自定义动画延迟
  final Duration? animationDelay;

  @override
  State<ASPrimaryButton> createState() => _ASPrimaryButtonState();
}

class _ASPrimaryButtonState extends State<ASPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final onPrimaryColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;

    Widget button = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? ASAnimations.buttonPressScale : 1.0,
        duration: ASAnimations.fast,
        curve: ASAnimations.defaultCurve,
        child: SizedBox(
          height: widget.height,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: onPrimaryColor,
              disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
              disabledForegroundColor: onPrimaryColor.withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
              ),
              elevation: _isPressed ? 1 : 2,
            ),
            child: AnimatedSwitcher(
              duration: ASAnimations.fast,
              switchInCurve: ASAnimations.defaultCurve,
              switchOutCurve: ASAnimations.defaultCurve,
              child: widget.isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: onPrimaryColor,
                      ),
                    )
                  : Row(
                      key: const ValueKey('content'),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20),
                          const SizedBox(width: ASSpacing.sm),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    if (widget.isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    if (widget.animate) {
      return button
          .animate(delay: widget.animationDelay ?? Duration.zero)
          .fadeIn(
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          )
          .slideY(
            begin: 0.2,
            end: 0,
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          );
    }

    return button;
  }
}

/// ASP 次要按钮（描边样式）
class ASOutlineButton extends StatefulWidget {
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
  State<ASOutlineButton> createState() => _ASOutlineButtonState();
}

class _ASOutlineButtonState extends State<ASOutlineButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? theme.colorScheme.primary;

    Widget button = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? ASAnimations.buttonPressScale : 1.0,
        duration: ASAnimations.fast,
        curve: ASAnimations.defaultCurve,
        child: SizedBox(
          height: widget.height,
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: buttonColor,
              side: BorderSide(color: buttonColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
              ),
            ),
            child: AnimatedSwitcher(
              duration: ASAnimations.fast,
              child: widget.isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: buttonColor,
                      ),
                    )
                  : Row(
                      key: const ValueKey('content'),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20),
                          const SizedBox(width: ASSpacing.sm),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    if (widget.isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    if (widget.animate) {
      return button
          .animate(delay: widget.animationDelay ?? Duration.zero)
          .fadeIn(
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          )
          .slideY(
            begin: 0.2,
            end: 0,
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          );
    }

    return button;
  }
}

/// ASP 小型按钮（用于卡片内操作）
class ASSmallButton extends StatefulWidget {
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
  State<ASSmallButton> createState() => _ASSmallButtonState();
}

class _ASSmallButtonState extends State<ASSmallButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final fgColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? ASAnimations.buttonPressScale : 1.0,
        duration: ASAnimations.fast,
        curve: ASAnimations.defaultCurve,
        child: SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              padding: const EdgeInsets.symmetric(
                horizontal: ASSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
              ),
              elevation: _isPressed ? 0 : 1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16),
                  const SizedBox(width: ASSpacing.xs),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
