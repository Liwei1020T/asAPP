import 'package:flutter/material.dart';

/// 空状态类型
enum ASEmptyStateType {
  noData,
  emptyBox,
  noResults,
  error,
  custom,
}

/// 简化版 ASP 空状态组件
class ASEmptyState extends StatelessWidget {
  const ASEmptyState({
    super.key,
    this.type = ASEmptyStateType.noData,
    this.title,
    this.description,
    this.icon,
    this.iconSize = 64,
    this.lottieAsset,
    this.lottieSize = 200,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.animate = true,
  });

  final ASEmptyStateType type;
  final String? title;
  final String? description;
  final IconData? icon;
  final double iconSize;
  final String? lottieAsset;
  final double lottieSize;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.inbox, size: iconSize, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title ?? '暂无数据',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class ASEmptyStateSimple extends StatelessWidget {
  const ASEmptyStateSimple({
    super.key,
    required this.message,
    this.icon,
  });

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 48, color: Colors.grey),
          Text(message),
        ],
      ),
    );
  }
}
