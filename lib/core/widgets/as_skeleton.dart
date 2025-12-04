import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/spacing.dart';

/// 基础骨架 shimmer 包装
class ASSkeleton extends StatelessWidget {
  const ASSkeleton({
    super.key,
    required this.child,
    this.enabled = true,
    this.period = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final bool enabled;
  final Duration period;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surfaceContainerHighest;
    final highlightColor =
        Colors.white.withValues(alpha: isDark ? 0.10 : 0.30);

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: period,
        child: child,
      ),
    );
  }
}

/// 基础占位块
class ASSkeletonBox extends StatelessWidget {
  const ASSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surfaceContainerHighest;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(borderRadius ?? ASSpacing.buttonRadius),
      ),
    );
  }
}

/// 骨架屏过渡包装器：骨架淡出 + 内容淡入缩放
class ASSkeletonTransition extends StatelessWidget {
  const ASSkeletonTransition({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
    this.placeholderHeight,
    this.fadeOutDuration = const Duration(milliseconds: 200),
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  final bool isLoading;
  final Widget skeleton;
  final Widget child;
  final double? placeholderHeight;
  final Duration fadeOutDuration;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    final skeletonBox = placeholderHeight != null
        ? SizedBox(height: placeholderHeight, child: skeleton)
        : skeleton;

    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: isLoading ? fadeOutDuration : fadeInDuration,
        reverseDuration: fadeOutDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (widget, animation) {
          final fade = FadeTransition(opacity: animation, child: widget);
          return ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(animation),
            child: fade,
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: isLoading
            ? KeyedSubtree(
                key: const ValueKey('skeleton'),
                child: skeletonBox,
              )
            : KeyedSubtree(
                key: const ValueKey('content'),
                child: child,
              ),
      ),
    );
  }
}

/// 头像骨架
class ASSkeletonAvatar extends StatelessWidget {
  const ASSkeletonAvatar({
    super.key,
    this.size = 40,
    this.isSquare = false,
  });

  final double size;
  final bool isSquare;

  @override
  Widget build(BuildContext context) {
    return ASSkeletonBox(
      width: size,
      height: size,
      borderRadius: isSquare ? ASSpacing.buttonRadius : size / 2,
    );
  }
}

/// 文本行骨架
class ASSkeletonText extends StatelessWidget {
  const ASSkeletonText({
    super.key,
    this.widthFactor = 1.0,
    this.height = 14,
  });

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: ASSkeletonBox(
        height: height,
        borderRadius: ASSpacing.buttonRadius,
      ),
    );
  }
}

/// 图片/封面骨架
class ASSkeletonImage extends StatelessWidget {
  const ASSkeletonImage({
    super.key,
    this.width,
    this.height = 140,
    this.icon = Icons.image_outlined,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final IconData icon;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overlayColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black12;

    return ASSkeleton(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius:
              BorderRadius.circular(borderRadius ?? ASSpacing.cardRadius),
        ),
        child: Center(
          child: Icon(
            icon,
            color: overlayColor,
            size: 32,
          ),
        ),
      ),
    );
  }
}

/// 按钮骨架
class ASSkeletonButton extends StatelessWidget {
  const ASSkeletonButton({
    super.key,
    this.width = double.infinity,
    this.height = 44,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ASSkeleton(
      child: ASSkeletonBox(
        width: width,
        height: height,
        borderRadius: ASSpacing.buttonRadius,
      ),
    );
  }
}

/// 统计卡骨架
class ASSkeletonStatCard extends StatelessWidget {
  const ASSkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ASSkeleton(
      child: Container(
        padding: const EdgeInsets.all(ASSpacing.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ASSkeletonBox(
                  width: 44,
                  height: 44,
                  borderRadius: 12,
                ),
                const Spacer(),
                const ASSkeletonBox(width: 64, height: 20),
              ],
            ),
            const SizedBox(height: ASSpacing.lg),
            const ASSkeletonBox(width: 100, height: 32),
            const SizedBox(height: ASSpacing.sm),
            const ASSkeletonBox(width: 120, height: 14),
          ],
        ),
      ),
    );
  }
}

/// 列表项骨架
class ASSkeletonListItem extends StatelessWidget {
  const ASSkeletonListItem({
    super.key,
    this.hasAvatar = true,
    this.avatarSize = 48,
    this.lines = 2,
  });

  final bool hasAvatar;
  final double avatarSize;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return ASSkeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ASSpacing.lg,
          vertical: ASSpacing.md,
        ),
        child: Row(
          children: [
            if (hasAvatar) ...[
              ASSkeletonBox(
                width: avatarSize,
                height: avatarSize,
                borderRadius: avatarSize / 2,
              ),
              const SizedBox(width: ASSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ASSkeletonBox(width: 150, height: 16),
                  if (lines > 1) ...[
                    const SizedBox(height: ASSpacing.sm),
                    const ASSkeletonBox(width: double.infinity, height: 14),
                  ],
                  if (lines > 2) ...[
                    const SizedBox(height: ASSpacing.sm),
                    const ASSkeletonBox(width: 100, height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 列表骨架
class ASSkeletonList extends StatelessWidget {
  const ASSkeletonList({
    super.key,
    this.itemCount = 5,
    this.hasAvatar = true,
    this.separatorHeight = 1,
  });

  final int itemCount;
  final bool hasAvatar;
  final double separatorHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          SizedBox(height: separatorHeight),
      itemBuilder: (context, index) =>
          ASSkeletonListItem(hasAvatar: hasAvatar),
    );
  }
}

/// 网格骨架
class ASSkeletonGrid extends StatelessWidget {
  const ASSkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = ASSpacing.md,
    this.crossAxisSpacing = ASSpacing.md,
  });

  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => ASSkeleton(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          ),
        ),
      ),
    );
  }
}

/// 仪表板骨架
class ASSkeletonDashboard extends StatelessWidget {
  const ASSkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ASSkeletonBox(width: 220, height: 28),
        const SizedBox(height: ASSpacing.xs),
        const ASSkeletonBox(width: 160, height: 16),
        const SizedBox(height: ASSpacing.xl),
        Wrap(
          spacing: ASSpacing.md,
          runSpacing: ASSpacing.md,
          children: List.generate(
            3,
            (_) => SizedBox(
              width: 260,
              child: const ASSkeletonStatCard(),
            ),
          ),
        ),
        const SizedBox(height: ASSpacing.xl),
        const ASSkeletonBox(width: 140, height: 22),
        const SizedBox(height: ASSpacing.md),
        const ASSkeletonCard(height: 180),
      ],
    );
  }
}

/// 用户信息卡骨架
class ASSkeletonProfileCard extends StatelessWidget {
  const ASSkeletonProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ASSkeleton(
      child: Container(
        padding: const EdgeInsets.all(ASSpacing.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
        child: Row(
          children: [
            const ASSkeletonAvatar(size: 56),
            const SizedBox(width: ASSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ASSkeletonText(widthFactor: 0.6, height: 16),
                  SizedBox(height: ASSpacing.xs),
                  ASSkeletonText(widthFactor: 0.4, height: 14),
                  SizedBox(height: ASSpacing.xs),
                  ASSkeletonText(widthFactor: 0.8, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 课程卡骨架
class ASSkeletonSessionCard extends StatelessWidget {
  const ASSkeletonSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ASSkeleton(
      child: Container(
        padding: const EdgeInsets.all(ASSpacing.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ASSkeletonText(widthFactor: 0.5, height: 16),
            SizedBox(height: ASSpacing.sm),
            ASSkeletonText(widthFactor: 0.9, height: 14),
            SizedBox(height: ASSpacing.xs),
            ASSkeletonText(widthFactor: 0.6, height: 12),
          ],
        ),
      ),
    );
  }
}

/// 公告卡骨架
class ASSkeletonNoticeCard extends StatelessWidget {
  const ASSkeletonNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ASSkeleton(
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(ASSpacing.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ASSkeletonText(widthFactor: 0.9, height: 16),
            SizedBox(height: ASSpacing.sm),
            ASSkeletonText(widthFactor: 0.7, height: 14),
            SizedBox(height: ASSpacing.xs),
            ASSkeletonText(widthFactor: 0.5, height: 12),
          ],
        ),
      ),
    );
  }
}

/// 简易卡骨架
class ASSkeletonCard extends StatelessWidget {
  const ASSkeletonCard({
    super.key,
    this.height = 120,
    this.padding,
  });

  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ASSkeleton(
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.all(ASSpacing.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ASSkeletonBox(width: 120, height: 20),
            SizedBox(height: ASSpacing.md),
            ASSkeletonBox(width: double.infinity, height: 16),
            SizedBox(height: ASSpacing.sm),
            ASSkeletonBox(width: 200, height: 16),
          ],
        ),
      ),
    );
  }
}
