import 'package:flutter/material.dart';

class AppColors {
  // Neomorphic Base Colors
  static const Color background = Color(0xFFF0F2F5); // Soft Gray Base
  static const Color lightShadow = Colors.white;     // Top-left light
  static const Color darkShadow = Color(0xFFD1D9E6);  // Bottom-right shadow
  
  // Brand Colors (Subtle Accents)
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color accent = Color(0xFF8B5CF6);  // Purple
  
  // Basic Colors
  static const Color white = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color border = Color(0xFFE5E7EB);

  // Aliases for component compatibility
  static const Color primaryBlue = primary;
  static const Color successGreen = success;
  static const Color errorRed = error;
  static const Color warningYellow = warning;
  static const Color backgroundLight = background;

  // Glassmorphic Colors
  static const Color glassWhite = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x1A000000);

  // Gradients for premium accents (used sparingly in Neomorphism)
  static const List<Color> mainGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];
}
