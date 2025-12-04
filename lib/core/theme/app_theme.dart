import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';

/// ASP-MS Premium App Theme
class AppTheme {
  AppTheme._();

  // ============ Typography ============
  
  static TextTheme _getTextTheme(Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    
    // Using Inter for a modern, clean look
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
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
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
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    );
  }

  /// Light Theme
  static ThemeData get lightTheme {
    final textTheme = _getTextTheme(Brightness.light);
    
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
        backgroundColor: ASColors.surface,
        foregroundColor: ASColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ASColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: ASColors.textPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: ASColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          side: const BorderSide(color: ASColors.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
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

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ASColors.surface,
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
        hintStyle: textTheme.bodyLarge?.copyWith(color: ASColors.textHint),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: ASColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    final textTheme = _getTextTheme(Brightness.dark);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: ASColorsDark.primary,
        onPrimary: ASColorsDark.textOnPrimary,
        primaryContainer: ASColorsDark.primaryContainer,
        onPrimaryContainer: ASColorsDark.onPrimaryContainer,
        secondary: ASColorsDark.secondary,
        onSecondary: Colors.white,
        secondaryContainer: ASColorsDark.secondaryContainer,
        onSecondaryContainer: ASColorsDark.onSecondaryContainer,
        tertiary: ASColorsDark.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: ASColorsDark.tertiaryContainer,
        onTertiaryContainer: ASColorsDark.onTertiaryContainer,
        error: ASColors.error,
        onError: Colors.white,
        surface: ASColorsDark.surface,
        onSurface: ASColorsDark.textPrimary,
        surfaceContainerHighest: ASColorsDark.surfaceContainerHighest,
        onSurfaceVariant: ASColorsDark.textSecondary,
        outline: ASColorsDark.outline,
        outlineVariant: ASColorsDark.outlineVariant,
      ),
      scaffoldBackgroundColor: ASColorsDark.background,
      textTheme: textTheme.apply(
        bodyColor: ASColorsDark.textPrimary,
        displayColor: ASColorsDark.textPrimary,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: ASColorsDark.surface,
        foregroundColor: ASColorsDark.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ASColorsDark.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: ASColorsDark.textPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: ASColorsDark.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          side: const BorderSide(color: ASColorsDark.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ASColorsDark.primary,
          foregroundColor: ASColorsDark.textOnPrimary,
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
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ASColorsDark.primary,
          foregroundColor: ASColorsDark.textOnPrimary,
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
          foregroundColor: ASColorsDark.primary,
          side: const BorderSide(color: ASColorsDark.outline),
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

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ASColorsDark.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColorsDark.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColorsDark.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          borderSide: const BorderSide(color: ASColorsDark.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ASSpacing.lg,
          vertical: ASSpacing.md,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: ASColorsDark.textHint),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: ASColorsDark.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
