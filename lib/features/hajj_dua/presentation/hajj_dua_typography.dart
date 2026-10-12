import 'package:flutter/material.dart';
import 'package:hajicare/core/theme/app_typography.dart';

/// Hajj & Umrah Dua Typography adapter.
/// Delegates to the centralized [AppTypography] service while preserving
/// specific semantic scales for supplications and translations.
class HajjDuaTypography {
  HajjDuaTypography._();

  static const String headingFontFamily = AppTypography.headingFontFamily;
  static const String bodyFontFamily = AppTypography.bodyFontFamily;
  static const String arabicFontFamily = AppTypography.arabicFontFamily;

  static TextStyle get appBarTitle => AppTypography.titleLarge;
  static TextStyle get screenTitle => AppTypography.displayMedium;
  static TextStyle get sectionTitle => AppTypography.titleLarge;
  static TextStyle get cardTitle => AppTypography.titleMedium;
  static TextStyle get button => AppTypography.button;

  static TextStyle get bodyLarge => AppTypography.bodyLarge;
  static TextStyle get body => AppTypography.bodyMedium;
  static TextStyle get caption => AppTypography.caption;

  static const TextStyle metadataLabel = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.7,
  );

  static TextStyle get arabic => AppTypography.arabicLarge;

  static const TextStyle transliteration = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    height: 1.7,
  );

  static const TextStyle translation = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.7,
  );
}
