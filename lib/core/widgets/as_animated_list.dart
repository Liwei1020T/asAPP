import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';

/// 带交错动画的列表组件
/// 
/// 自动为列表项添加入场动画
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
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final Widget? emptyWidget;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && emptyWidget != null) {
      return emptyWidget!;
    }

    if (separatorBuilder != null) {
      return ListView.separated(
        controller: controller,
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: items.length,
        separatorBuilder: separatorBuilder!,
        itemBuilder: (context, index) {
          return itemBuilder(context, items[index], index)
              .animate(delay: ASAnimations.getStaggerDelay(index))
              .fadeIn(
                duration: ASAnimations.normal,
                curve: ASAnimations.defaultCurve,
              )
              .slideX(
                begin: 0.05,
                end: 0,
                duration: ASAnimations.normal,
                curve: ASAnimations.defaultCurve,
              );
        },
      );
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index)
            .animate(delay: ASAnimations.getStaggerDelay(index))
            .fadeIn(
              duration: ASAnimations.normal,
              curve: ASAnimations.defaultCurve,
            )
            .slideX(
              begin: 0.05,
              end: 0,
              duration: ASAnimations.normal,
              curve: ASAnimations.defaultCurve,
            );
      },
    );
  }
}

/// 带交错动画的网格组件
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
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Widget? emptyWidget;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && emptyWidget != null) {
      return emptyWidget!;
    }

    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index)
            .animate(delay: ASAnimations.getStaggerDelay(index))
            .fadeIn(
              duration: ASAnimations.normal,
              curve: ASAnimations.defaultCurve,
            )
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: ASAnimations.normal,
              curve: ASAnimations.defaultCurve,
            );
      },
    );
  }
}

/// 带交错动画的 Sliver 列表
class ASAnimatedSliverList<T> extends StatelessWidget {
  const ASAnimatedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return itemBuilder(context, items[index], index)
              .animate(delay: ASAnimations.getStaggerDelay(index))
              .fadeIn(
                duration: ASAnimations.normal,
                curve: ASAnimations.defaultCurve,
              )
              .slideX(
                begin: 0.05,
                end: 0,
                duration: ASAnimations.normal,
                curve: ASAnimations.defaultCurve,
              );
        },
        childCount: items.length,
      ),
    );
  }
}

/// 页面内容包装器 - 添加入场动画
class ASAnimatedPage extends StatelessWidget {
  const ASAnimatedPage({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
          duration: ASAnimations.normal,
          curve: ASAnimations.defaultCurve,
        );
  }
}

/// 交错动画容器 - 为子组件添加交错动画
class ASStaggeredColumn extends StatelessWidget {
  const ASStaggeredColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.asMap().entries.map((entry) {
        return entry.value
            .animate(delay: ASAnimations.getStaggerDelay(entry.key))
            .fadeIn(
              duration: ASAnimations.normal,
              curve: ASAnimations.defaultCurve,
            )
            .slideY(
              begin: 0.1,
              end: 0,
              duration: ASAnimations.normal,
              curve: ASAnimations.defaultCurve,
            );
      }).toList(),
    );
  }
}

/// 交错动画行容器
class ASStaggeredRow extends StatelessWidget {
  const ASStaggeredRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.asMap().entries.map((entry) {
        return entry.value
            .animate(delay: ASAnimations.getStaggerDelay(entry.key))
            .fadeIn(
              duration: ASAnimations.normal,
              curve: ASAnimations.defaultCurve,
            )
            .slideX(
              begin: 0.1,
              end: 0,
              duration: ASAnimations.normal,
              curve: ASAnimations.defaultCurve,
            );
      }).toList(),
    );
  }
}
