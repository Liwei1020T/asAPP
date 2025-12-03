import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';

/// 骨架屏加载效果组件
class ASSkeleton extends StatelessWidget {
  const ASSkeleton({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? ASColorsDark.shimmerBase : ASColors.shimmerBase;
    final highlightColor = isDark ? ASColorsDark.shimmerHighlight : ASColors.shimmerHighlight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

/// 骨架屏占位盒子
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? ASColorsDark.shimmerBase : ASColors.shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius ?? ASSpacing.buttonRadius),
      ),
    );
  }
}

/// 骨架屏卡片
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
    return ASSkeleton(
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.all(ASSpacing.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ASSkeletonBox(width: 120, height: 20),
            const SizedBox(height: ASSpacing.md),
            const ASSkeletonBox(width: double.infinity, height: 16),
            const SizedBox(height: ASSpacing.sm),
            const ASSkeletonBox(width: 200, height: 16),
          ],
        ),
      ),
    );
  }
}

/// 骨架屏列表项
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

/// 骨架屏列表
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
      separatorBuilder: (context, index) => SizedBox(height: separatorHeight),
      itemBuilder: (context, index) => ASSkeletonListItem(hasAvatar: hasAvatar),
    );
  }
}

/// 骨架屏网格
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          ),
        ),
      ),
    );
  }
}

/// 统计数字骨架屏
class ASSkeletonStatCard extends StatelessWidget {
  const ASSkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ASSkeleton(
      child: Container(
        padding: const EdgeInsets.all(ASSpacing.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ASSkeletonBox(
                  width: 40,
                  height: 40,
                  borderRadius: 8,
                ),
                const Spacer(),
                const ASSkeletonBox(width: 60, height: 20),
              ],
            ),
            const SizedBox(height: ASSpacing.lg),
            const ASSkeletonBox(width: 80, height: 32),
            const SizedBox(height: ASSpacing.sm),
            const ASSkeletonBox(width: 100, height: 14),
          ],
        ),
      ),
    );
  }
}
