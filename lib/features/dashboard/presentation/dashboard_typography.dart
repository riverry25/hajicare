import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

/// Typography used by every role dashboard.
/// Fully unified with [AppTypography] as the Single Source of Truth.
class DashboardTypography {
  DashboardTypography._();

  static const String headingFontFamily = AppTypography.headingFontFamily;
  static const String bodyFontFamily = AppTypography.bodyFontFamily;

  static TextStyle get heroNumberLarge => AppTypography.heroNumberLarge;
  static TextStyle get displayLarge => AppTypography.displayLarge;
  static TextStyle get displayMedium => AppTypography.displayMedium;
  static TextStyle get titleLarge => AppTypography.titleLarge;
  static TextStyle get titleMedium => AppTypography.titleMedium;
  static TextStyle get titleSmall => AppTypography.titleSmall;

  static TextStyle get bodyLarge => AppTypography.bodyLarge;
  static TextStyle get bodyMedium => AppTypography.bodyMedium;
  static TextStyle get bodySmall => AppTypography.bodySmall;

  static TextStyle get labelLarge => AppTypography.labelLarge;
  static TextStyle get button => AppTypography.button;
  static TextStyle get caption => AppTypography.caption;
  static TextStyle get captionSmall => AppTypography.captionSmall;

  static TextStyle get headlineLarge => displayMedium;

  static ThemeData applyTo(ThemeData base) {
    return base;
  }
}
