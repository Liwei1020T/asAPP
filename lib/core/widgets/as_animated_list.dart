import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';

/// 动画列表组件
/// 
/// 自动为列表项添加交错入场动画。
class ASAnimatedList<T> extends StatelessWidget {
  const ASAnimatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.separatorBuilder,
    this.emptyWidget,
    this.controller,
    this.animate = true,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final Widget? emptyWidget;
  final ScrollController? controller;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && emptyWidget != null) {
      return emptyWidget!.animate().fadeIn(duration: ASAnimations.medium);
    }

    Widget buildItem(int index) {
      final child = itemBuilder(context, items[index], index);
      if (!animate) return child;
      
      return child.animate(delay: ASAnimations.staggerInterval * index)
          .fadeIn(duration: ASAnimations.medium)
          .slideY(begin: 0.1, end: 0, curve: ASAnimations.standard);
    }

    if (separatorBuilder != null) {
      return ListView.separated(
        controller: controller,
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: items.length,
        separatorBuilder: separatorBuilder!,
        itemBuilder: (context, index) => buildItem(index),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) => buildItem(index),
    );
  }
}

/// 动画网格组件
class ASAnimatedGrid<T> extends StatelessWidget {
  const ASAnimatedGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.emptyWidget,
    this.controller,
    this.animate = true,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Widget? emptyWidget;
  final ScrollController? controller;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && emptyWidget != null) {
      return emptyWidget!.animate().fadeIn(duration: ASAnimations.medium);
    }

    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final child = itemBuilder(context, items[index], index);
        if (!animate) return child;

        return child.animate(delay: ASAnimations.staggerInterval * index)
            .fadeIn(duration: ASAnimations.medium)
            .scale(begin: const Offset(0.9, 0.9), curve: ASAnimations.standard);
      },
    );
  }
}

/// 动画 Sliver 列表
class ASAnimatedSliverList<T> extends StatelessWidget {
  const ASAnimatedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.animate = true,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final child = itemBuilder(context, items[index], index);
          if (!animate) return child;
          
          return child.animate(delay: ASAnimations.staggerInterval * index)
              .fadeIn(duration: ASAnimations.medium)
              .slideY(begin: 0.1, end: 0, curve: ASAnimations.standard);
        },
        childCount: items.length,
      ),
    );
  }
}

/// 简单的交错动画 Column
class ASStaggeredColumn extends StatelessWidget {
  const ASStaggeredColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.animate = true,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    List<Widget> animatedChildren = children;
    
    if (animate) {
      animatedChildren = children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return child.animate(delay: ASAnimations.staggerInterval * index)
            .fadeIn(duration: ASAnimations.medium)
            .slideY(begin: 0.1, end: 0, curve: ASAnimations.standard);
      }).toList();
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: animatedChildren,
    );
  }
}
