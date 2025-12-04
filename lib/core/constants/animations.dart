import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ASP-MS 动画系统常量
/// 
/// 统一管理应用内的动画时长、曲线和常用效果，确保视觉体验的一致性。
class ASAnimations {
  ASAnimations._();

  // ============ 时长 (Durations) ============
  
  /// 极短动画 (50ms) - 用于微交互，如按钮按压
  static const Duration short = Duration(milliseconds: 50);
  
  /// 短动画 (150ms) - 用于简单的状态变化，如复选框切换
  static const Duration fast = Duration(milliseconds: 150);
  
  /// 标准动画 (300ms) - 用于大多数 UI 元素的入场、页面切换
  static const Duration medium = Duration(milliseconds: 300);
  
  /// 长动画 (500ms) - 用于复杂的强调动画或大面积内容变化
  static const Duration long = Duration(milliseconds: 500);
  
  /// 极长动画 (800ms) - 用于加载状态或背景流动
  static const Duration extraLong = Duration(milliseconds: 800);

  // ============ 曲线 (Curves) ============
  
  /// 标准曲线 - 用于大多数自然运动
  static const Curve standard = Curves.easeOutCubic;
  
  /// 强调曲线 - 用于弹窗、重要元素的入场，带有轻微的弹性
  static const Curve emphasized = Curves.easeOutBack;
  
  /// 减速曲线 - 用于退出动画
  static const Curve decelerate = Curves.decelerate;
  
  /// 线性 - 用于旋转加载等
  static const Curve linear = Curves.linear;

  // ============ 常用效果配置 (Effect Configs) ============
  
  /// 列表项交错延迟
  static const Duration staggerInterval = Duration(milliseconds: 50);
  
  /// 页面转场配置
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);
  static const Curve pageTransitionCurve = Curves.easeOutQuart;
}

/// 动画扩展方法
extension ASAnimateExtensions on Widget {
  /// 标准入场动画：淡入 + 向上轻微位移
  /// 
  /// 适用于列表项、卡片等内容块的入场
  Widget asFadeSlide({
    Duration? delay,
    Duration duration = ASAnimations.medium,
    Offset begin = const Offset(0, 10), // 10px 向上位移
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: ASAnimations.standard)
        .slide(
          begin: Offset(0, 0.1), // 相对高度的 10%
          end: Offset.zero,
          duration: duration,
          curve: ASAnimations.standard,
        );
  }

  /// 强调入场动画：淡入 + 缩放
  /// 
  /// 适用于弹窗、重要图标、头像等
  Widget asScaleIn({
    Duration? delay,
    Duration duration = ASAnimations.medium,
    double begin = 0.9,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: ASAnimations.standard)
        .scale(
          begin: Offset(begin, begin),
          end: const Offset(1, 1),
          duration: duration,
          curve: ASAnimations.emphasized,
        );
  }

  /// 悬停缩放效果 (需要配合 MouseRegion 或 InkWell 使用，这里仅提供动画定义)
  /// 注意：flutter_animate 的 toggle 需要状态控制，这里仅作为静态定义参考
}
