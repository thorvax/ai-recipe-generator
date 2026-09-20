import 'package:flutter/material.dart';

/// Color palette from the design system (Color_Scheme).
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4F7D3A); // green
  static const Color secondary = Color(0xFFF4A261); // orange

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFFFDF5); // app background (cream)
  static const Color surface = Color(0xFFF5F5F5); // cards, input fills
  static const Color textSecondary = Color(0xFF757575);
  static const Color textPrimary = Color(0xFF2D2D2D);

  // Extras (not in the Figma palette; needed for states)
  static const Color primaryDisabled = Color(0xFFB7CBAD);
  static const Color primaryLight = Color(0xFFE6EFE0); // light green tint
  static const Color border = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD64545);
}
