import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';

/// ASP-MS 应用主题
class AppTheme {
  AppTheme._();

  /// 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ASColors.primary,
        primary: ASColors.primary,
        onPrimary: ASColors.textOnPrimary,
        secondary: ASColors.primaryLight,
        surface: ASColors.surface,
        error: ASColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: ASColors.background,

      // AppBar 主题
      appBarTheme: const AppBarTheme(
        backgroundColor: ASColors.primary,
        foregroundColor: ASColors.textOnPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ASColors.textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: ASColors.textOnPrimary),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: ASColors.cardBackground,
        elevation: 2,
        shadowColor: ASColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ASColors.primary,
          foregroundColor: ASColors.textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: ASSpacing.xl,
            vertical: ASSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 文本按钮主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ASColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ASColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ASSpacing.lg,
          vertical: ASSpacing.md,
        ),
      ),

      // 文字主题
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ASColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ASColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ASColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ASColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ASColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ASColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: ASColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: ASColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: ASColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ASColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ASColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          color: ASColors.textHint,
        ),
      ),

      // 分隔线主题
      dividerTheme: const DividerThemeData(
        color: ASColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Snackbar 主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ASColors.textPrimary,
        contentTextStyle: const TextStyle(color: ASColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // NavigationBar 主题
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ASColors.surface,
        indicatorColor: ASColors.primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: ASColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: ASColors.textSecondary,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ASColors.primary);
          }
          return const IconThemeData(color: ASColors.textSecondary);
        }),
      ),

      // NavigationRail 主题
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: ASColors.surface,
        selectedIconTheme: IconThemeData(color: ASColors.primary),
        unselectedIconTheme: IconThemeData(color: ASColors.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: ASColors.primary,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: ASColors.textSecondary,
        ),
      ),
    );
  }

  /// 深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ASColorsDark.primary,
        primary: ASColorsDark.primary,
        onPrimary: ASColorsDark.textOnPrimary,
        secondary: ASColorsDark.primaryLight,
        surface: ASColorsDark.surface,
        error: ASColorsDark.error,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: ASColorsDark.background,

      // AppBar 主题
      appBarTheme: const AppBarTheme(
        backgroundColor: ASColorsDark.cardBackground,
        foregroundColor: ASColorsDark.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ASColorsDark.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: ASColorsDark.textPrimary),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: ASColorsDark.cardBackground,
        elevation: 4,
        shadowColor: ASColorsDark.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ASColorsDark.primary,
          foregroundColor: ASColorsDark.textOnPrimary,
          elevation: 4,
          padding: const EdgeInsets.symmetric(
            horizontal: ASSpacing.xl,
            vertical: ASSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 文本按钮主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ASColorsDark.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ASColorsDark.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColorsDark.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColorsDark.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColorsDark.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColorsDark.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ASSpacing.lg,
          vertical: ASSpacing.md,
        ),
        hintStyle: const TextStyle(color: ASColorsDark.textHint),
        labelStyle: const TextStyle(color: ASColorsDark.textSecondary),
      ),

      // 文字主题
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ASColorsDark.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ASColorsDark.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ASColorsDark.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ASColorsDark.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ASColorsDark.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ASColorsDark.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: ASColorsDark.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: ASColorsDark.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: ASColorsDark.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ASColorsDark.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ASColorsDark.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          color: ASColorsDark.textHint,
        ),
      ),

      // 分隔线主题
      dividerTheme: const DividerThemeData(
        color: ASColorsDark.divider,
        thickness: 1,
        space: 1,
      ),

      // Snackbar 主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ASColorsDark.cardBackground,
        contentTextStyle: const TextStyle(color: ASColorsDark.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // NavigationBar 主题
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ASColorsDark.surface,
        indicatorColor: ASColorsDark.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: ASColorsDark.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: ASColorsDark.textSecondary,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ASColorsDark.primary);
          }
          return const IconThemeData(color: ASColorsDark.textSecondary);
        }),
      ),

      // NavigationRail 主题
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: ASColorsDark.surface,
        selectedIconTheme: IconThemeData(color: ASColorsDark.primary),
        unselectedIconTheme: IconThemeData(color: ASColorsDark.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: ASColorsDark.primary,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: ASColorsDark.textSecondary,
        ),
      ),

      // Dialog 主题
      dialogTheme: DialogThemeData(
        backgroundColor: ASColorsDark.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        ),
      ),

      // BottomSheet 主题
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ASColorsDark.cardBackground,
        modalBackgroundColor: ASColorsDark.cardBackground,
      ),

      // PopupMenu 主题
      popupMenuTheme: PopupMenuThemeData(
        color: ASColorsDark.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
        ),
      ),
    );
  }
}
