import 'package:flutter/material.dart';

/// ASP-MS 应用配色方案 - 浅色模式
class ASColors {
  ASColors._();

  /// 主色 - 运动红
  static const Color primary = Color(0xFFD32F2F);
  static const Color primaryLight = Color(0xFFEF5350);
  static const Color primaryDark = Color(0xFFB71C1C);

  /// 强调色 - 白色系
  static const Color accent = Colors.white;
  static const Color accentLight = Color(0xFFFAFAFA);

  /// 背景色
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  /// 文字颜色
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  /// 状态颜色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2196F3);

  /// 出勤状态颜色
  static const Color present = Color(0xFF4CAF50);
  static const Color absent = Color(0xFFD32F2F);
  static const Color late = Color(0xFFFFC107);
  static const Color leave = Color(0xFF9E9E9E);

  /// 分隔线
  static const Color divider = Color(0xFFE0E0E0);

  /// 阴影
  static const Color shadow = Color(0x1A000000);

  /// 渐变色 - 红白渐变
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Shimmer 颜色
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}

/// ASP-MS 应用配色方案 - 深色模式
class ASColorsDark {
  ASColorsDark._();

  /// 主色 - 运动红（深色模式下略微调亮）
  static const Color primary = Color(0xFFEF5350);
  static const Color primaryLight = Color(0xFFFF867C);
  static const Color primaryDark = Color(0xFFD32F2F);

  /// 强调色 - 白色系
  static const Color accent = Colors.white;
  static const Color accentLight = Color(0xFFE0E0E0);

  /// 背景色 - 深色
  static const Color background = Color(0xFF121212);
  static const Color backgroundLight = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFF252525);

  /// 文字颜色
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;

  /// 状态颜色（深色模式下调亮以提高可读性）
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFD54F);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF64B5F6);

  /// 出勤状态颜色
  static const Color present = Color(0xFF81C784);
  static const Color absent = Color(0xFFEF5350);
  static const Color late = Color(0xFFFFD54F);
  static const Color leave = Color(0xFF9E9E9E);

  /// 分隔线
  static const Color divider = Color(0xFF424242);

  /// 阴影
  static const Color shadow = Color(0x40000000);

  /// 渐变色 - 红白渐变（深色模式）
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF252525), Color(0xFF1E1E1E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Shimmer 颜色
  static const Color shimmerBase = Color(0xFF2A2A2A);
  static const Color shimmerHighlight = Color(0xFF3A3A3A);
}
