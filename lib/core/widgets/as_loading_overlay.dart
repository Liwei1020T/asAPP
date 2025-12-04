import 'package:flutter/material.dart';

/// 简化版 ASP 加载遮罩组件
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

  final bool isLoading;
  final String? message;
  final String? lottieAsset;
  final double lottieSize;
  final bool useDefaultLoader;
  final Color? backgroundColor;
  final double opacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Stack(
        children: [
          child!,
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      );
    }

    if (!isLoading) return const SizedBox.shrink();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}

class ASLoadingPage extends StatelessWidget {
  const ASLoadingPage({super.key, this.message, this.lottieAsset});
  final String? message;
  final String? lottieAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) Text(message!),
          ],
        ),
      ),
    );
  }
}

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
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child,
    );
  }
}

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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
