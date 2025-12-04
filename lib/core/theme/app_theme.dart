import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';

/// ASP-MS Premium App Theme
/// 
/// 现代化、高端设计系统，基于 Material 3
class AppTheme {
  AppTheme._();

  // ============ Typography ============
  
  static TextTheme _getTextTheme() {
    final baseTextTheme = ThemeData.light().textTheme;
    
    // 使用 Inter 字体，提供现代、干净的视觉体验
    return GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700, // 加粗强调
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600, // 稍微加粗
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15, // 优化阅读体验
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600, // 按钮文字加粗
        letterSpacing: 0.1,
      ),
    );
  }

  /// Light Theme
  static ThemeData get lightTheme {
    final textTheme = _getTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: ASColors.primary,
        onPrimary: ASColors.textOnPrimary,
        primaryContainer: ASColors.primaryContainer,
        onPrimaryContainer: ASColors.onPrimaryContainer,
        secondary: ASColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: ASColors.secondaryContainer,
        onSecondaryContainer: ASColors.onSecondaryContainer,
        tertiary: ASColors.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: ASColors.tertiaryContainer,
        onTertiaryContainer: ASColors.onTertiaryContainer,
        error: ASColors.error,
        onError: Colors.white,
        surface: ASColors.surface,
        onSurface: ASColors.textPrimary,
        surfaceContainerHighest: ASColors.surfaceContainerHighest,
        onSurfaceVariant: ASColors.textSecondary,
        outline: ASColors.outline,
        outlineVariant: ASColors.outlineVariant,
      ),
      scaffoldBackgroundColor: ASColors.background,
      textTheme: textTheme.apply(
        bodyColor: ASColors.textPrimary,
        displayColor: ASColors.textPrimary,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: ASColors.surface.withValues(alpha: 0.8), // 玻璃拟态基础
        foregroundColor: ASColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ASColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: ASColors.textPrimary),
      ),

      // Card Theme - 更现代的卡片
      cardTheme: CardThemeData(
        color: ASColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          side: const BorderSide(color: ASColors.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias, // 确保子元素不溢出圆角
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ASColors.primary,
          foregroundColor: ASColors.textOnPrimary,
          elevation: 0, // 扁平化设计
          padding: const EdgeInsets.symmetric(
            horizontal: ASSpacing.xl,
            vertical: ASSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ASColors.primary,
          foregroundColor: ASColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ASSpacing.xl,
            vertical: ASSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ASColors.primary,
          side: const BorderSide(color: ASColors.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: ASSpacing.xl,
            vertical: ASSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ASColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: ASSpacing.md,
            vertical: ASSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme - 更精致的输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ASColors.surface, // 纯白背景
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ASSpacing.lg,
          vertical: ASSpacing.md,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: ASColors.textHint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: ASColors.textSecondary),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: ASColors.primary),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: ASColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: ASColors.surfaceContainerHighest,
        labelStyle: textTheme.labelMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
