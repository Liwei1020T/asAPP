import 'package:flutter/material.dart';

/// ASP-MS 动画常量
class ASAnimations {
  ASAnimations._();

  // ============ 动画时长 ============
  
  /// 极快动画 - 用于即时反馈（涟漪、高亮）
  static const Duration instant = Duration(milliseconds: 50);
  
  /// 快速动画 - 用于微交互（按钮点击、hover等）
  static const Duration fast = Duration(milliseconds: 150);
  
  /// 正常动画 - 用于一般过渡
  static const Duration normal = Duration(milliseconds: 300);
  
  /// 中等动画 - 用于页面元素入场
  static const Duration medium = Duration(milliseconds: 400);
  
  /// 慢速动画 - 用于复杂过渡或强调效果
  static const Duration slow = Duration(milliseconds: 500);
  
  /// 超慢动画 - 用于大型动画效果
  static const Duration slower = Duration(milliseconds: 700);
  
  /// 页面过渡动画
  static const Duration pageTransition = Duration(milliseconds: 350);
  
  /// 模态弹窗动画
  static const Duration modal = Duration(milliseconds: 250);

  // ============ 动画曲线 ============
  
  /// 默认缓动曲线 - 平滑自然
  static const Curve defaultCurve = Curves.easeOutCubic;
  
  /// 弹性曲线 - 带轻微回弹
  static const Curve bounceCurve = Curves.elasticOut;
  
  /// 弹簧曲线 - 更自然的弹性效果
  static const Curve springCurve = Curves.easeOutBack;
  
  /// 平滑曲线 - 用于渐变和淡入淡出
  static const Curve smoothCurve = Curves.easeInOutCubic;
  
  /// 减速曲线 - 快进慢出
  static const Curve decelerateCurve = Curves.decelerate;
  
  /// 加速曲线 - 慢进快出
  static const Curve accelerateCurve = Curves.easeIn;
  
  /// 强调曲线 - 用于强调动画
  static const Curve emphasizeCurve = Curves.easeOutBack;
  
  /// 进入曲线
  static const Curve enterCurve = Curves.easeOutCubic;
  
  /// 退出曲线
  static const Curve exitCurve = Curves.easeInCubic;
  
  /// 页面进入曲线
  static const Curve pageEnterCurve = Curves.easeOutCubic;
  
  /// 页面退出曲线
  static const Curve pageExitCurve = Curves.easeInCubic;
  
  /// 弹窗曲线
  static const Curve dialogCurve = Curves.easeOutBack;

  // ============ 微交互参数 ============
  
  /// 悬停缩放
  static const double hoverScale = 1.02;
  
  /// 按下缩放
  static const double tapScale = 0.96;
  
  /// 按钮按下缩放
  static const double buttonPressScale = 0.97;
  
  /// 卡片按下缩放
  static const double cardPressScale = 0.98;
  
  /// 拖拽时缩放
  static const double dragScale = 1.05;
  
  /// 悬停高程增量
  static const double hoverElevation = 4.0;
  
  /// 按下高程减量
  static const double pressedElevation = 1.0;

  // ============ 列表动画延迟 ============
  
  /// 列表项交错延迟
  static const Duration staggerDelay = Duration(milliseconds: 50);
  
  /// 快速交错延迟
  static const Duration staggerDelayFast = Duration(milliseconds: 30);
  
  /// 慢速交错延迟
  static const Duration staggerDelaySlow = Duration(milliseconds: 80);
  
  /// 最大交错延迟（防止列表过长时延迟过大）
  static const Duration maxStaggerDelay = Duration(milliseconds: 500);

  // ============ 动画偏移量 ============
  
  /// 垂直滑入偏移
  static const double slideOffsetY = 20.0;
  
  /// 水平滑入偏移
  static const double slideOffsetX = 20.0;
  
  /// 页面滑入偏移
  static const double pageSlideOffset = 30.0;
  
  /// 缩放起始值
  static const double scaleStart = 0.95;
  
  /// 淡入起始透明度
  static const double fadeStart = 0.0;

  // ============ 辅助方法 ============
  
  /// 计算列表项的交错延迟
  static Duration getStaggerDelay(int index, {int maxItems = 10}) {
    final clampedIndex = index.clamp(0, maxItems);
    return Duration(
      milliseconds: staggerDelay.inMilliseconds * clampedIndex,
    );
  }
  
  /// 计算快速交错延迟
  static Duration getStaggerDelayFast(int index, {int maxItems = 15}) {
    final clampedIndex = index.clamp(0, maxItems);
    return Duration(
      milliseconds: staggerDelayFast.inMilliseconds * clampedIndex,
    );
  }
}

/// 页面转场动画构建器
class ASPageTransition {
  ASPageTransition._();
  
  /// 淡入 + 向上滑入
  static Widget fadeSlideUp({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: ASAnimations.enterCurve,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: ASAnimations.enterCurve,
        )),
        child: child,
      ),
    );
  }
  
  /// 淡入 + 缩放
  static Widget fadeScale({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: ASAnimations.enterCurve,
      ),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: ASAnimations.scaleStart,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: ASAnimations.springCurve,
        )),
        child: child,
      ),
    );
  }
  
  /// 共享轴转场 (水平)
  static Widget sharedAxisHorizontal({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: ASAnimations.enterCurve,
        )),
        child: child,
      ),
    );
  }
  
  /// 模态弹窗动画
  static Widget modalTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: ASAnimations.smoothCurve,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: ASAnimations.dialogCurve,
        )),
        child: child,
      ),
    );
  }
}
