import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式枚举
enum ASThemeMode {
  system,
  light,
  dark,
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
    _loadTheme();
    return const ThemeState(
      mode: ASThemeMode.system,
      themeMode: ThemeMode.system,
    );
  }

  /// 从本地存储加载主题设置
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      final mode = ASThemeMode.values[themeIndex];
      _setMode(mode);
    } catch (e) {
      // 如果加载失败，使用系统默认
      _setMode(ASThemeMode.system);
    }
  }

  /// 保存主题设置到本地存储
  Future<void> _saveTheme(ASThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // 保存失败时静默处理
    }
  }

  /// 设置主题模式
  void _setMode(ASThemeMode mode) {
    final themeMode = switch (mode) {
      ASThemeMode.system => ThemeMode.system,
      ASThemeMode.light => ThemeMode.light,
      ASThemeMode.dark => ThemeMode.dark,
    };
    state = ThemeState(mode: mode, themeMode: themeMode);
  }

  /// 切换到指定主题模式
  Future<void> setThemeMode(ASThemeMode mode) async {
    _setMode(mode);
    await _saveTheme(mode);
  }

  /// 切换主题（在三种模式间循环）
  Future<void> toggleTheme() async {
    final nextIndex = (state.mode.index + 1) % ASThemeMode.values.length;
    final nextMode = ASThemeMode.values[nextIndex];
    await setThemeMode(nextMode);
  }

  /// 快速切换明暗模式（跳过系统模式）
  Future<void> toggleLightDark() async {
    final nextMode = state.mode == ASThemeMode.dark
        ? ASThemeMode.light
        : ASThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

/// 主题状态 Provider
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

/// 当前主题模式 Provider（便捷访问）
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

/// 是否为深色模式 Provider
final isDarkModeProvider = Provider<bool>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.mode == ASThemeMode.dark;
});

/// 主题模式图标
IconData getThemeModeIcon(ASThemeMode mode) {
  return switch (mode) {
    ASThemeMode.system => Icons.brightness_auto,
    ASThemeMode.light => Icons.light_mode,
    ASThemeMode.dark => Icons.dark_mode,
  };
}

/// 主题模式名称
String getThemeModeName(ASThemeMode mode) {
  return switch (mode) {
    ASThemeMode.system => '跟随系统',
    ASThemeMode.light => '浅色模式',
    ASThemeMode.dark => '深色模式',
  };
}
