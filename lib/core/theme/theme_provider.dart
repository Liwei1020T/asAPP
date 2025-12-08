import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式枚举
enum ASThemeMode {
  light,
}

/// 主题状态
class ThemeState {
  const ThemeState({
    required this.mode,
    required this.themeMode,
  });

  final ASThemeMode mode;
  final ThemeMode themeMode;

  ThemeState copyWith({
    ASThemeMode? mode,
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// 主题控制器
class ThemeNotifier extends Notifier<ThemeState> {
  static const String _themeKey = 'asp_theme_mode';

  @override
  ThemeState build() {
    return const ThemeState(
      mode: ASThemeMode.light,
      themeMode: ThemeMode.light,
    );
  }

  /// 切换到指定主题模式 (已禁用，仅支持浅色模式)
  Future<void> setThemeMode(ASThemeMode mode) async {
    // No-op
  }

  /// 切换主题 (已禁用)
  Future<void> toggleTheme() async {
    // No-op
  }

  /// 快速切换明暗模式 (已禁用)
  Future<void> toggleLightDark() async {
    // No-op
  }
}

/// 主题状态 Provider
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

/// 当前主题模式 Provider（便捷访问）
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.light;
});

/// 是否为深色模式 Provider (始终为 false)
final isDarkModeProvider = Provider<bool>((ref) {
  return false;
});

/// 主题模式图标
IconData getThemeModeIcon(ASThemeMode mode) {
  return Icons.light_mode;
}

/// 主题模式名称
String getThemeModeName(ASThemeMode mode) {
  return '浅色模式';
}
