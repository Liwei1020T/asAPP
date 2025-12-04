import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';
import '../constants/spacing.dart';

/// ASP 加载遮罩组件
/// 
/// 支持 Lottie 动画和自定义加载指示器
class ASLoadingOverlay extends StatelessWidget {
  const ASLoadingOverlay({
    super.key,
    this.isLoading = true,
    this.message,
    this.lottieAsset,
    this.lottieSize = 100,
    this.useDefaultLoader = false,
    this.backgroundColor,
    this.opacity = 0.7,
    this.child,
  });

  /// 是否显示加载中
  final bool isLoading;
  
  /// 加载提示文本
  final String? message;
  
  /// 自定义 Lottie 资源
  final String? lottieAsset;
  
  /// Lottie 动画尺寸
  final double lottieSize;
  
  /// 是否使用默认 CircularProgressIndicator
  final bool useDefaultLoader;
  
  /// 背景颜色
  final Color? backgroundColor;
  
  /// 背景透明度
  final double opacity;
  
  /// 子组件（可选，用于 Stack 布局）
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Stack(
        children: [
          child!,
          if (isLoading)
            Positioned.fill(
              child: _buildOverlay(context),
            ),
        ],
      );
    }

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return _buildOverlay(context);
  }

  Widget _buildOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bgColor = backgroundColor ?? colorScheme.surface;

    return AnimatedOpacity(
      opacity: isLoading ? 1.0 : 0.0,
      duration: ASAnimations.fast,
      child: Container(
        color: bgColor.withValues(alpha: opacity),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLoader(colorScheme),
              if (message != null) ...[
                const SizedBox(height: ASSpacing.lg),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          )
              .animate()
              .fadeIn(duration: ASAnimations.normal)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: ASAnimations.normal,
                curve: ASAnimations.springCurve,
              ),
        ),
      ),
    );
  }

  Widget _buildLoader(ColorScheme colorScheme) {
    if (useDefaultLoader) {
      return SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: colorScheme.primary,
        ),
      );
    }

    final asset = lottieAsset ?? 'assets/animations/loading_dots.json';

    return SizedBox(
      width: lottieSize,
      height: lottieSize,
      child: Lottie.asset(
        asset,
        fit: BoxFit.contain,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}

/// 全屏加载页面
class ASLoadingPage extends StatelessWidget {
  const ASLoadingPage({
    super.key,
    this.message,
    this.lottieAsset,
  });

  final String? message;
  final String? lottieAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ASLoadingOverlay(
        isLoading: true,
        message: message,
        lottieAsset: lottieAsset,
        opacity: 1.0,
      ),
    );
  }
}

/// 加载按钮包装器
class ASLoadingButton extends StatelessWidget {
  const ASLoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.loadingChild,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? loadingChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: ASAnimations.fast,
        child: isLoading
            ? loadingChild ??
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
            : child,
      ),
    );
  }
}

/// 加载状态包装器（用于 FutureBuilder/StreamBuilder 场景）
class ASAsyncBuilder<T> extends StatelessWidget {
  const ASAsyncBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.loadingMessage,
  });

  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              ASLoadingOverlay(
                isLoading: true,
                message: loadingMessage,
              );
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: ASSpacing.md),
                    Text(
                      '加载失败',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
