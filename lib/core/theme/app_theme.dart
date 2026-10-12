import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static TargetPlatform get _currentPlatform =>
      PlatformUtils.isDesktopOrWeb ? TargetPlatform.macOS : TargetPlatform.android;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      platform: _currentPlatform,
      splashFactory: InkSparkle.splashFactory,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkShadow.withValues(alpha: 0.3),
        thickness: 1,
        space: 24,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.pageTitle,
        headlineMedium: AppTextStyles.sectionTitle,
        titleLarge: AppTextStyles.cardTitle,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      platform: _currentPlatform,
      splashFactory: InkSparkle.splashFactory,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: const Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.12),
        thickness: 1,
        space: 24,
      ),
    );
  }
}
