import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';

/// 头像尺寸
enum ASAvatarSize {
  /// 超小 24px
  xs,
  /// 小 32px
  sm,
  /// 中 40px
  md,
  /// 大 56px
  lg,
  /// 超大 80px
  xl,
  /// 巨大 120px
  xxl,
}

/// ASP 头像组件
/// 
/// 支持网络图片加载、占位符、状态指示器
class ASAvatar extends StatelessWidget {
  const ASAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = ASAvatarSize.md,
    this.customSize,
    this.backgroundColor,
    this.foregroundColor,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
    this.showStatus = false,
    this.isOnline = false,
    this.onTap,
    this.animate = false,
    this.animationDelay,
  });

  /// 头像图片 URL
  final String? imageUrl;
  
  /// 用户名（用于生成首字母占位符）
  final String? name;
  
  /// 预设尺寸
  final ASAvatarSize size;
  
  /// 自定义尺寸（优先于 size）
  final double? customSize;
  
  /// 背景色（占位符时使用）
  final Color? backgroundColor;
  
  /// 前景色（首字母颜色）
  final Color? foregroundColor;
  
  /// 是否显示边框
  final bool showBorder;
  
  /// 边框颜色
  final Color? borderColor;
  
  /// 边框宽度
  final double borderWidth;
  
  /// 是否显示在线状态
  final bool showStatus;
  
  /// 是否在线
  final bool isOnline;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 是否启用动画
  final bool animate;
  
  /// 动画延迟
  final Duration? animationDelay;

  double get _size {
    if (customSize != null) return customSize!;
    switch (size) {
      case ASAvatarSize.xs:
        return 24;
      case ASAvatarSize.sm:
        return 32;
      case ASAvatarSize.md:
        return 40;
      case ASAvatarSize.lg:
        return 56;
      case ASAvatarSize.xl:
        return 80;
      case ASAvatarSize.xxl:
        return 120;
    }
  }

  double get _fontSize {
    switch (size) {
      case ASAvatarSize.xs:
        return 10;
      case ASAvatarSize.sm:
        return 12;
      case ASAvatarSize.md:
        return 14;
      case ASAvatarSize.lg:
        return 20;
      case ASAvatarSize.xl:
        return 28;
      case ASAvatarSize.xxl:
        return 40;
    }
  }

  double get _statusSize {
    switch (size) {
      case ASAvatarSize.xs:
        return 6;
      case ASAvatarSize.sm:
        return 8;
      case ASAvatarSize.md:
        return 10;
      case ASAvatarSize.lg:
        return 12;
      case ASAvatarSize.xl:
        return 16;
      case ASAvatarSize.xxl:
        return 20;
    }
  }

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bgColor = backgroundColor ?? colorScheme.primaryContainer;
    final fgColor = foregroundColor ?? colorScheme.onPrimaryContainer;
    final border = borderColor ?? colorScheme.surface;

    Widget avatar = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: border, width: borderWidth)
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(bgColor, fgColor),
                errorWidget: (context, url, error) => _buildPlaceholder(bgColor, fgColor),
              )
            : _buildPlaceholder(bgColor, fgColor),
      ),
    );

    // 添加在线状态指示器
    if (showStatus) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: _statusSize,
              height: _statusSize,
              decoration: BoxDecoration(
                color: isOnline 
                    ? colorScheme.tertiary 
                    : colorScheme.outline,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 添加点击效果
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: avatar,
        ),
      );
    }

    // 添加入场动画
    if (animate) {
      return avatar
          .animate(delay: animationDelay ?? Duration.zero)
          .fadeIn(
            duration: ASAnimations.normal,
            curve: ASAnimations.defaultCurve,
          )
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: ASAnimations.normal,
            curve: ASAnimations.springCurve,
          );
    }

    return avatar;
  }

  Widget _buildPlaceholder(Color bgColor, Color fgColor) {
    return Container(
      color: bgColor,
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: fgColor,
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 头像组（用于显示多个头像重叠）
class ASAvatarGroup extends StatelessWidget {
  const ASAvatarGroup({
    super.key,
    required this.avatars,
    this.maxDisplay = 4,
    this.size = ASAvatarSize.sm,
    this.overlapFactor = 0.3,
  });

  /// 头像列表（包含 imageUrl 和 name）
  final List<({String? imageUrl, String? name})> avatars;
  
  /// 最多显示数量
  final int maxDisplay;
  
  /// 头像尺寸
  final ASAvatarSize size;
  
  /// 重叠比例 (0-1)
  final double overlapFactor;

  double get _avatarSize {
    switch (size) {
      case ASAvatarSize.xs:
        return 24;
      case ASAvatarSize.sm:
        return 32;
      case ASAvatarSize.md:
        return 40;
      case ASAvatarSize.lg:
        return 56;
      case ASAvatarSize.xl:
        return 80;
      case ASAvatarSize.xxl:
        return 120;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final displayCount = avatars.length > maxDisplay ? maxDisplay : avatars.length;
    final remaining = avatars.length - maxDisplay;
    final overlap = _avatarSize * overlapFactor;

    return SizedBox(
      width: _avatarSize + (displayCount - 1) * (_avatarSize - overlap) + 
             (remaining > 0 ? _avatarSize - overlap : 0),
      height: _avatarSize,
      child: Stack(
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * (_avatarSize - overlap),
              child: ASAvatar(
                imageUrl: avatars[i].imageUrl,
                name: avatars[i].name,
                size: size,
                showBorder: true,
                borderColor: colorScheme.surface,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: displayCount * (_avatarSize - overlap),
              child: Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: _avatarSize * 0.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
