import 'package:flutter/material.dart';

/// Design tokens and typography matching the exact macOS desktop designs in the specification screenshots.
class MacOsTheme {
  // Brand & Primary Blues
  static const Color brandBlue = Color(0xFF1D68EE);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueHover = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFFEFF6FF);
  static const Color primaryBlueBorder = Color(0xFFDBEAFE);

  // Neutral Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color pillBackground = Color(0xFFF2F4F7);
  static const Color inputBackground = Color(0xFFF0F5FF);
  static const Color border = Color(0xFFEAECF0);
  static const Color borderSubtle = Color(0xFFF2F4F7);

  // Typography Colors
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF475467);
  static const Color textTertiary = Color(0xFF667085);
  static const Color textPlaceholder = Color(0xFF98A2B3);

  // Status & Badges
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFEE2E2);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);

  // Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusPill = 24.0;

  // Box Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // Typography
  static const TextStyle pageHeading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle pageSubheading = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: textTertiary,
    letterSpacing: 0.8,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );
}
