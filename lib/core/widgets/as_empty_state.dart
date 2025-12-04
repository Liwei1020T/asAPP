import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';
import '../constants/spacing.dart';

/// 空状态类型
enum ASEmptyStateType {
  /// 无数据
  noData,
  /// 空盒子
  emptyBox,
  /// 搜索无结果
  noResults,
  /// 错误
  error,
  /// 自定义
  custom,
}

/// ASP 空状态组件
/// 
/// 支持 Lottie 动画、自定义图标、操作按钮
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

  /// 空状态类型
  final ASEmptyStateType type;
  
  /// 标题（可选，默认根据类型自动设置）
  final String? title;
  
  /// 描述文本
  final String? description;
  
  /// 自定义图标（优先于 Lottie）
  final IconData? icon;
  
  /// 图标尺寸
  final double iconSize;
  
  /// 自定义 Lottie 资源路径
  final String? lottieAsset;
  
  /// Lottie 动画尺寸
  final double lottieSize;
  
  /// 主操作按钮文本
  final String? actionLabel;
  
  /// 主操作回调
  final VoidCallback? onAction;
  
  /// 次要操作按钮文本
  final String? secondaryActionLabel;
  
  /// 次要操作回调
  final VoidCallback? onSecondaryAction;
  
  /// 是否启用入场动画
  final bool animate;

  String get _defaultTitle {
    switch (type) {
      case ASEmptyStateType.noData:
        return '暂无数据';
      case ASEmptyStateType.emptyBox:
        return '这里空空如也';
      case ASEmptyStateType.noResults:
        return '未找到相关内容';
      case ASEmptyStateType.error:
        return '出错了';
      case ASEmptyStateType.custom:
        return '';
    }
  }

  String get _defaultDescription {
    switch (type) {
      case ASEmptyStateType.noData:
        return '数据还在路上，请稍后再来';
      case ASEmptyStateType.emptyBox:
        return '还没有添加任何内容';
      case ASEmptyStateType.noResults:
        return '换个关键词试试吧';
      case ASEmptyStateType.error:
        return '请检查网络连接后重试';
      case ASEmptyStateType.custom:
        return '';
    }
  }

  String get _defaultLottieAsset {
    switch (type) {
      case ASEmptyStateType.noData:
        return 'assets/animations/no_data.json';
      case ASEmptyStateType.emptyBox:
        return 'assets/animations/empty_box.json';
      case ASEmptyStateType.noResults:
        return 'assets/animations/no_data.json';
      case ASEmptyStateType.error:
        return 'assets/animations/error_alert.json';
      case ASEmptyStateType.custom:
        return '';
    }
  }

  IconData get _defaultIcon {
    switch (type) {
      case ASEmptyStateType.noData:
        return Icons.inbox_outlined;
      case ASEmptyStateType.emptyBox:
        return Icons.inventory_2_outlined;
      case ASEmptyStateType.noResults:
        return Icons.search_off_outlined;
      case ASEmptyStateType.error:
        return Icons.error_outline;
      case ASEmptyStateType.custom:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 图标或 Lottie 动画
        if (icon != null)
          Icon(
            icon,
            size: iconSize,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          )
        else
          _buildLottie(colorScheme),
        
        const SizedBox(height: ASSpacing.lg),
        
        // 标题
        Text(
          title ?? _defaultTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        
        if (description != null || _defaultDescription.isNotEmpty) ...[
          const SizedBox(height: ASSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ASSpacing.xxl),
            child: Text(
              description ?? _defaultDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        
        // 操作按钮
        if (actionLabel != null || secondaryActionLabel != null) ...[
          const SizedBox(height: ASSpacing.xl),
          Wrap(
            spacing: ASSpacing.md,
            runSpacing: ASSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              if (actionLabel != null)
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(actionLabel!),
                ),
              if (secondaryActionLabel != null)
                OutlinedButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryActionLabel!),
                ),
            ],
          ),
        ],
      ],
    );

    if (animate) {
      content = content
          .animate()
          .fadeIn(
            duration: ASAnimations.medium,
            curve: ASAnimations.defaultCurve,
          )
          .slideY(
            begin: 0.1,
            end: 0,
            duration: ASAnimations.medium,
            curve: ASAnimations.defaultCurve,
          );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ASSpacing.xl),
        child: content,
      ),
    );
  }

  Widget _buildLottie(ColorScheme colorScheme) {
    final asset = lottieAsset ?? _defaultLottieAsset;
    
    if (asset.isEmpty) {
      return Icon(
        _defaultIcon,
        size: iconSize,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      );
    }

    return SizedBox(
      width: lottieSize,
      height: lottieSize,
      child: Lottie.asset(
        asset,
        fit: BoxFit.contain,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            _defaultIcon,
            size: iconSize,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          );
        },
      ),
    );
  }
}

/// 简化版空状态（仅文字）
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ASSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: ASSpacing.md),
            ],
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
