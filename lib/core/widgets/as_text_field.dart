import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';
import '../constants/spacing.dart';

/// ASP 统一输入框组件
/// 
/// 支持聚焦动画、错误抖动、密码可见切换
class ASTextField extends StatefulWidget {
  const ASTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.none,
    this.animate = false,
    this.animationDelay,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;
  
  /// 是否启用入场动画
  final bool animate;
  
  /// 动画延迟
  final Duration? animationDelay;

  @override
  State<ASTextField> createState() => _ASTextFieldState();
}

class _ASTextFieldState extends State<ASTextField> 
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isFocused = false;
  bool _obscureText = false;
  String? _previousError;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.obscureText;
    
    // 错误抖动动画
    _shakeController = AnimationController(
      duration: ASAnimations.normal,
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
  }

  @override
  void didUpdateWidget(ASTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 检测新错误时触发抖动
    if (widget.errorText != null && 
        widget.errorText != _previousError &&
        _previousError == null) {
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
    _previousError = widget.errorText;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Widget field = AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = _shakeAnimation.value * 
            ((_shakeController.status == AnimationStatus.forward) ? 8 : -8);
        return Transform.translate(
          offset: Offset(shakeOffset * (1 - _shakeAnimation.value), 0),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: ASAnimations.fast,
        curve: ASAnimations.defaultCurve,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          boxShadow: _isFocused && widget.errorText == null
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          autovalidateMode: widget.autovalidateMode,
          textCapitalization: widget.textCapitalization,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? AnimatedContainer(
                    duration: ASAnimations.fast,
                    child: Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: AnimatedSwitcher(
                      duration: ASAnimations.fast,
                      child: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        key: ValueKey(_obscureText),
                      ),
                    ),
                    onPressed: _toggleObscure,
                  )
                : widget.suffixIcon,
          ),
        ),
      ),
    );

    if (widget.animate) {
      return field
          .animate(delay: widget.animationDelay ?? Duration.zero)
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

    return field;
  }
}

/// ASP 搜索输入框
class ASSearchField extends StatefulWidget {
  const ASSearchField({
    super.key,
    this.controller,
    this.hint = '搜索...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  State<ASSearchField> createState() => _ASSearchFieldState();
}

class _ASSearchFieldState extends State<ASSearchField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChange);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(
          Icons.search,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: AnimatedSwitcher(
          duration: ASAnimations.fast,
          child: _hasText
              ? IconButton(
                  key: const ValueKey('clear'),
                  icon: const Icon(Icons.close),
                  onPressed: _onClear,
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ASSpacing.lg,
          vertical: ASSpacing.md,
        ),
      ),
    );
  }
}
