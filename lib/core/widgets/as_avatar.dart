import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 头像尺寸
enum ASAvatarSize {
  xs,
  sm,
  md,
  lg,
  xl,
  xxl,
}

/// 简化版 ASP 头像组件 (标准 CircleAvatar)
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

  final String? imageUrl;
  final String? name;
  final ASAvatarSize size;
  final double? customSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool showStatus;
  final bool isOnline;
  final VoidCallback? onTap;
  final bool animate;
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
    Widget avatar = SizedBox(
      width: _size,
      height: _size,
      child: CircleAvatar(
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImageProvider(imageUrl!)
            : null,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Text(
                _initials,
                style: TextStyle(
                  color: foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );

    if (showStatus) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}

/// 头像组
class ASAvatarGroup extends StatelessWidget {
  const ASAvatarGroup({
    super.key,
    required this.avatars,
    this.maxDisplay = 4,
    this.size = ASAvatarSize.sm,
    this.overlapFactor = 0.3,
  });

  final List<({String? imageUrl, String? name})> avatars;
  final int maxDisplay;
  final ASAvatarSize size;
  final double overlapFactor;

  @override
  Widget build(BuildContext context) {
    // 简化版暂不实现重叠逻辑，直接显示一排
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: avatars.take(maxDisplay).map((a) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: ASAvatar(imageUrl: a.imageUrl, name: a.name, size: size),
      )).toList(),
    );
  }
}
