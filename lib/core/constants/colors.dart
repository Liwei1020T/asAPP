import 'package:flutter/material.dart';

/// ASP-MS Premium Color Palette
class ASColors {
  ASColors._();

  // ============ Primary Brand Colors (Vibrant Red) ============
  static const Color primary = Color(0xFFE63946); // More vibrant red
  static const Color primaryLight = Color(0xFFFF6B6B);
  static const Color primaryDark = Color(0xFFD00000);
  
  static const Color primaryContainer = Color(0xFFFFEBEE);
  static const Color onPrimaryContainer = Color(0xFF9B0000);

  // ============ Secondary & Accent Colors ============
  static const Color secondary = Color(0xFF457B9D); // Steel Blue
  static const Color secondaryLight = Color(0xFFA8DADC);
  static const Color secondaryDark = Color(0xFF1D3557);
  
  static const Color secondaryContainer = Color(0xFFD1E4F3);
  static const Color onSecondaryContainer = Color(0xFF0D2339);

  static const Color tertiary = Color(0xFF2A9D8F); // Teal
  static const Color tertiaryContainer = Color(0xFFE0F2F1);
  static const Color onTertiaryContainer = Color(0xFF004D40);

  // ============ Neutral / Surface Colors ============
  static const Color background = Color(0xFFF8F9FA); // Off-white, not stark white
  static const Color surface = Colors.white;
  static const Color surfaceDim = Color(0xFFF1F3F5);
  static const Color surfaceBright = Colors.white;
  
  static const Color surfaceContainerLowest = Colors.white;
  static const Color surfaceContainerLow = Color(0xFFF8F9FA);
  static const Color surfaceContainer = Color(0xFFF1F3F5);
  static const Color surfaceContainerHigh = Color(0xFFE9ECEF);
  static const Color surfaceContainerHighest = Color(0xFFDEE2E6);

  static const Color outline = Color(0xFFADB5BD);
  static const Color outlineVariant = Color(0xFFDEE2E6);

  // ============ Text Colors ============
  static const Color textPrimary = Color(0xFF212529); // Dark Grey, softer than black
  static const Color textSecondary = Color(0xFF495057);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color textOnPrimary = Colors.white;

  // ============ Status Colors ============
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF0288D1);

  // ============ Glassmorphism ============
  static const Color glassBackground = Color(0xCCFFFFFF); // 80% opacity
  static const Color glassBorder = Color(0x4DFFFFFF); // 30% opacity
  static const Color glassBorderLight = Color(0x4DFFFFFF);
  static const double glassBlurSigma = 10.0;
  static const double glassBlurSigmaLight = 10.0;
  
  // ============ Additional UI Colors ============
  static const Color divider = outlineVariant;
  static const Color shadow = Color(0x1A000000);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  
  // ============ Attendance Colors ============
  static const Color present = success;
  static const Color absent = error;
  static const Color leave = warning;

  // ============ Gradients ============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x99FFFFFF), Color(0x66FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8F9FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// ASP-MS Dark Theme Colors
class ASColorsDark {
  ASColorsDark._();

  // ============ Primary Brand Colors (Dark Mode) ============
  static const Color primary = Color(0xFFFF6B6B); // Lighter red for dark mode
  static const Color primaryLight = Color(0xFFFF8A80);
  static const Color primaryDark = Color(0xFFD32F2F);
  
  static const Color primaryContainer = Color(0xFF5A0000);
  static const Color onPrimaryContainer = Color(0xFFFFDAD6);

  // ============ Secondary & Accent Colors (Dark) ============
  static const Color secondary = Color(0xFF457B9D);
  static const Color secondaryContainer = Color(0xFF1D3557);
  static const Color onSecondaryContainer = Color(0xFFD1E4F3);

  static const Color tertiary = Color(0xFF2A9D8F);
  static const Color tertiaryContainer = Color(0xFF004D40);
  static const Color onTertiaryContainer = Color(0xFFE0F2F1);

  // ============ Neutral / Surface Colors (Dark) ============
  static const Color background = Color(0xFF121212); // Deep dark
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceDim = Color(0xFF121212);
  static const Color surfaceBright = Color(0xFF2C2C2C);
  
  static const Color surfaceContainerLowest = Color(0xFF0F0F0F);
  static const Color surfaceContainerLow = Color(0xFF1E1E1E);
  static const Color surfaceContainer = Color(0xFF252525);
  static const Color surfaceContainerHigh = Color(0xFF2C2C2C);
  static const Color surfaceContainerHighest = Color(0xFF363636);

  static const Color outline = Color(0xFF8E9196);
  static const Color outlineVariant = Color(0xFF444746);
  static const Color divider = Color(0xFF444746);

  // ============ Text Colors (Dark) ============
  static const Color textPrimary = Color(0xFFE1E1E1);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFF410002);

  // ============ Glassmorphism (Dark) ============
  static const Color glassBackground = Color(0xCC1E1E1E);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const double glassBlurSigma = 10.0;
}
