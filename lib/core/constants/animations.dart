import 'package:flutter/material.dart';

/// ASP-MS 动画常量
class ASAnimations {
  ASAnimations._();

  // ============ 动画时长 ============
  
  /// 快速动画 - 用于微交互（按钮点击、hover等）
  static const Duration fast = Duration(milliseconds: 150);
  
  /// 正常动画 - 用于一般过渡
  static const Duration normal = Duration(milliseconds: 300);
  
  /// 中等动画 - 用于页面元素入场
  static const Duration medium = Duration(milliseconds: 400);
  
  /// 慢速动画 - 用于复杂过渡或强调效果
  static const Duration slow = Duration(milliseconds: 500);
  
  /// 页面过渡动画
  static const Duration pageTransition = Duration(milliseconds: 350);

  // ============ 动画曲线 ============
  
  /// 默认缓动曲线 - 平滑自然
  static const Curve defaultCurve = Curves.easeOutCubic;
  
  /// 弹性曲线 - 带轻微回弹
  static const Curve bounceCurve = Curves.elasticOut;
  
  /// 减速曲线 - 快进慢出
  static const Curve decelerateCurve = Curves.decelerate;
  
  /// 强调曲线 - 用于强调动画
  static const Curve emphasizeCurve = Curves.easeOutBack;
  
  /// 进入曲线
  static const Curve enterCurve = Curves.easeOut;
  
  /// 退出曲线
  static const Curve exitCurve = Curves.easeIn;

  // ============ 列表动画延迟 ============
  
  /// 列表项交错延迟
  static const Duration staggerDelay = Duration(milliseconds: 50);
  
  /// 最大交错延迟（防止列表过长时延迟过大）
  static const Duration maxStaggerDelay = Duration(milliseconds: 500);

  // ============ 动画偏移量 ============
  
  /// 垂直滑入偏移
  static const double slideOffsetY = 20.0;
  
  /// 水平滑入偏移
  static const double slideOffsetX = 20.0;
  
  /// 缩放起始值
  static const double scaleStart = 0.95;
  
  /// 按钮按下缩放
  static const double buttonPressScale = 0.97;

  // ============ 辅助方法 ============
  
  /// 计算列表项的交错延迟
  static Duration getStaggerDelay(int index, {int maxItems = 10}) {
    final clampedIndex = index.clamp(0, maxItems);
    return Duration(
      milliseconds: staggerDelay.inMilliseconds * clampedIndex,
    );
  }
}
