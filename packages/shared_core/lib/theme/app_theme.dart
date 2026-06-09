import 'package:flutter/material.dart';

class AppColors {
  // Elegant modern palette
  static const Color primary = Color(0xFF6B58F8); // Sleek Lavender-Purple
  static const Color primaryLight = Color(0xFFEBE8FF); // Soft Lavender background/accent
  static const Color accent = Color(0xFFFF855F); // Warm Soft Coral
  static const Color success = Color(0xFF57CC99); // Emerald Mint Green
  static const Color warning = Color(0xFFFFD043); // Sunny Warm Yellow
  
  static const Color background = Color(0xFFF6F5FD); // Soft Lavender/grey background
  static const Color surface = Colors.white;
  
  static const Color textPrimary = Color(0xFF1A1738); // Deep Navy-Purple (Very dark)
  static const Color textSecondary = Color(0xFF706D8C); // Slate Purple
  static const Color textMuted = Color(0xFFA5A2BF); // Light Slate
  
  // Progression Matrix colors
  static const Color level1 = Color(0xFFECEAFE); // Soft pastel gray/purple
  static const Color level2 = Color(0xFFD3CDFF); // Pastel lavender blue
  static const Color level3 = primary; // Brand purple
  static const Color level4 = Color(0xFF38B000); // Vibrant Green
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        background: AppColors.background,
        surface: AppColors.surface,
        error: AppColors.accent,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter', // Premium look, falls back to System Sans-Serif
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Soft friendly corners
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Smooth premium cards
          side: BorderSide(color: AppColors.primary.withOpacity(0.06), width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
