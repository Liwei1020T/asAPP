import 'package:flutter/material.dart';

/// 简化版骨架屏 (简单的灰色占位块)
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
    return Opacity(opacity: 0.3, child: child);
  }
}

class ASSkeletonBox extends StatelessWidget {
  const ASSkeletonBox({super.key, this.width, this.height, this.borderRadius});
  final double? width;
  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius ?? 4),
      ),
    );
  }
}

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
    return isLoading ? skeleton : child;
  }
}

class ASSkeletonAvatar extends StatelessWidget {
  const ASSkeletonAvatar({super.key, this.size = 40, this.isSquare = false});
  final double size;
  final bool isSquare;

  @override
  Widget build(BuildContext context) {
    return ASSkeletonBox(width: size, height: size, borderRadius: isSquare ? 4 : size / 2);
  }
}

class ASSkeletonText extends StatelessWidget {
  const ASSkeletonText({super.key, this.widthFactor = 1.0, this.height = 14});
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: ASSkeletonBox(height: height),
    );
  }
}

class ASSkeletonImage extends StatelessWidget {
  const ASSkeletonImage({super.key, this.width, this.height = 140, this.icon = Icons.image, this.borderRadius});
  final double? width;
  final double height;
  final IconData icon;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(icon, color: Colors.grey),
    );
  }
}

class ASSkeletonButton extends StatelessWidget {
  const ASSkeletonButton({super.key, this.width = double.infinity, this.height = 44});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ASSkeletonBox(width: width, height: height);
  }
}

class ASSkeletonStatCard extends StatelessWidget {
  const ASSkeletonStatCard({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(child: SizedBox(height: 100, child: Center(child: Text('Loading...'))));
  }
}

class ASSkeletonListItem extends StatelessWidget {
  const ASSkeletonListItem({super.key, this.hasAvatar = true, this.avatarSize = 48, this.lines = 2});
  final bool hasAvatar;
  final double avatarSize;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: CircleAvatar(),
      title: Text('Loading...'),
      subtitle: Text('Loading...'),
    );
  }
}

class ASSkeletonList extends StatelessWidget {
  const ASSkeletonList({super.key, this.itemCount = 5, this.hasAvatar = true, this.separatorHeight = 1});
  final int itemCount;
  final bool hasAvatar;
  final double separatorHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      itemBuilder: (context, index) => const ASSkeletonListItem(),
    );
  }
}

class ASSkeletonGrid extends StatelessWidget {
  const ASSkeletonGrid({super.key, this.itemCount = 6, this.crossAxisCount = 2, this.childAspectRatio = 1.0, this.mainAxisSpacing = 8, this.crossAxisSpacing = 8});
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      children: List.generate(itemCount, (index) => const Card(child: Center(child: Text('Loading...')))),
    );
  }
}

class ASSkeletonDashboard extends StatelessWidget {
  const ASSkeletonDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Loading Dashboard...'));
  }
}

class ASSkeletonProfileCard extends StatelessWidget {
  const ASSkeletonProfileCard({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(child: ListTile(title: Text('Loading Profile...')));
  }
}

class ASSkeletonSessionCard extends StatelessWidget {
  const ASSkeletonSessionCard({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(child: ListTile(title: Text('Loading Session...')));
  }
}

class ASSkeletonNoticeCard extends StatelessWidget {
  const ASSkeletonNoticeCard({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(child: ListTile(title: Text('Loading Notice...')));
  }
}

class ASSkeletonCard extends StatelessWidget {
  const ASSkeletonCard({super.key, this.height = 120, this.padding});
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, child: const Card(child: Center(child: Text('Loading...'))));
  }
}
