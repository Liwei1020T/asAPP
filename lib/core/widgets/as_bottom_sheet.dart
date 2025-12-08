import 'package:flutter/material.dart';
import '../constants/spacing.dart';

/// ASP 底部弹窗组件
/// 
/// 现代化设计，带拖拽指示器
class ASBottomSheet extends StatelessWidget {
  const ASBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showDragHandle = true,
    this.showCloseButton = false,
    this.padding,
    this.maxHeight,
    this.isScrollable = true,
  });

  /// 内容
  final Widget child;
  
  /// 标题
  final String? title;
  
  /// 副标题
  final String? subtitle;
  
  /// 标题左侧组件
  final Widget? leading;
  
  /// 右侧操作按钮
  final List<Widget>? actions;
  
  /// 是否显示拖拽指示器
  final bool showDragHandle;
  
  /// 是否显示关闭按钮
  final bool showCloseButton;
  
  /// 内容内边距
  final EdgeInsetsGeometry? padding;
  
  /// 最大高度（相对于屏幕高度的比例）
  final double? maxHeight;
  
  /// 是否可滚动
  final bool isScrollable;

  /// 显示底部弹窗的静态方法
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    Widget? leading,
    List<Widget>? actions,
    bool showDragHandle = true,
    bool showCloseButton = false,
    EdgeInsetsGeometry? padding,
    double? maxHeight,
    bool isScrollable = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useSafeArea = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ASSpacing.cardRadius + 4),
        ),
      ),
      builder: (context) => ASBottomSheet(
        title: title,
        subtitle: subtitle,
        leading: leading,
        actions: actions,
        showDragHandle: showDragHandle,
        showCloseButton: showCloseButton,
        padding: padding,
        maxHeight: maxHeight,
        isScrollable: isScrollable,
        child: child,
      ),
    );
  }

  /// 显示确认底部弹窗
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    String? message,
    String confirmLabel = '确认',
    String cancelLabel = '取消',
    Color? confirmColor,
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return show<bool>(
      context: context,
      title: title,
      showCloseButton: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: ASSpacing.lg),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: ASSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDangerous
                        ? colorScheme.error
                        : confirmColor ?? colorScheme.primary,
                  ),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 显示操作列表底部弹窗
  static Future<T?> showActions<T>({
    required BuildContext context,
    required List<ASBottomSheetAction<T>> actions,
    String? title,
  }) {
    return show<T>(
      context: context,
      title: title,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: actions.map((action) {
          return ListTile(
            leading: action.icon != null
                ? Icon(
                    action.icon,
                    color: action.isDestructive
                        ? Theme.of(context).colorScheme.error
                        : null,
                  )
                : null,
            title: Text(
              action.label,
              style: action.isDestructive
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null,
            ),
            subtitle: action.subtitle != null ? Text(action.subtitle!) : null,
            onTap: () => Navigator.pop(context, action.value),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    
    final effectiveMaxHeight = maxHeight ?? 0.9;
    final maxHeightPx = mediaQuery.size.height * effectiveMaxHeight;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeightPx,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示器
          if (showDragHandle)
            Container(
              margin: const EdgeInsets.only(top: ASSpacing.md),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          
          // 标题栏
          if (title != null || showCloseButton || actions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ASSpacing.lg,
                ASSpacing.md,
                ASSpacing.sm,
                ASSpacing.sm,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: ASSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                  if (showCloseButton)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
          
          // 分隔线
          if (title != null || showCloseButton)
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          
          // 内容
          Flexible(
            child: isScrollable
                ? SingleChildScrollView(
                    padding: padding ?? const EdgeInsets.all(ASSpacing.lg),
                    child: child,
                  )
                : Padding(
                    padding: padding ?? const EdgeInsets.all(ASSpacing.lg),
                    child: child,
                  ),
          ),
          
          // 底部安全区域
          SizedBox(height: mediaQuery.padding.bottom),
        ],
      ),
    );
  }
}

/// 底部弹窗操作项
class ASBottomSheetAction<T> {
  const ASBottomSheetAction({
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final String? subtitle;
  final bool isDestructive;
}
