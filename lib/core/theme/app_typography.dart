import 'package:flutter/material.dart';

/// Centralized Typography Service for HajiCare.
/// Uses locally bundled offline-ready font families:
/// - [headingFontFamily] ('Poppins'): Headings, titles, app bars, buttons, and high-emphasis display.
/// - [bodyFontFamily] ('Montserrat'): Body text, captions, subtitles, badges, and readouts.
/// - [arabicFontFamily] ('NotoNaskhArabic'): Quranic verses, prayers, and Arabic calligraphy.
///
/// Provides both predefined accessible text scales and dynamic generator methods
/// (`heading`, `bodyText`, `arabicText`) to allow any screen across the entire app
/// to customize typography dynamically, safely, and consistently.
class AppTypography {
  AppTypography._();

  // ── Core Font Families ─────────────────────────────────────────────────────
  static const String headingFontFamily = 'Poppins';
  static const String bodyFontFamily = 'Montserrat';
  static const String arabicFontFamily = 'NotoNaskhArabic';

  // ── Dynamic Typography Service Generators ──────────────────────────────────
  /// Creates a dynamic heading text style using [headingFontFamily] (Poppins).
  static TextStyle heading({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: headingFontFamily,
      fontSize: fontSize ?? 18,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color,
      height: height ?? 1.35,
      letterSpacing: letterSpacing ?? -0.2,
      decoration: decoration,
    );
  }

  /// Creates a dynamic body text style using [bodyFontFamily] (Montserrat).
  static TextStyle bodyText({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: fontSize ?? 14.5,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height ?? 1.5,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
    );
  }

  /// Creates a dynamic arabic text style using [arabicFontFamily] (NotoNaskhArabic).
  static TextStyle arabicText({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: arabicFontFamily,
      fontSize: fontSize ?? 28,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      height: height ?? 1.8,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  // ── Primary Display & Hero Scales (Poppins) ────────────────────────────────
  static TextStyle get heroNumberLarge => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 52,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.02,
  );

  static TextStyle get displayLarge => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.3,
    letterSpacing: -0.02,
  );

  static TextStyle get displayMedium => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 21,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.01,
  );

  // ── Titles & Section Headers (Poppins) ─────────────────────────────────────
  static TextStyle get titleLarge => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: -0.01,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  // ── Body Texts (Montserrat) ────────────────────────────────────────────────
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  // ── Labels, Badges, & Captions ─────────────────────────────────────────────
  static TextStyle get labelLarge => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: 0.1,
  );

  static TextStyle get caption => const TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get captionSmall => const TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.3,
  );

  // ── Arabic Scales (NotoNaskhArabic) ────────────────────────────────────────
  static TextStyle get arabicLarge => const TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.9,
  );

  static TextStyle get arabic => const TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.85,
  );

  static TextStyle get arabicMedium => const TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.7,
  );

  static TextStyle get arabicSmall => const TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  // ── Legacy & Compatibility Aliases ─────────────────────────────────────────
  static TextStyle get displayHero => displayLarge;
  static TextStyle get headlineLg => displayMedium;
  static TextStyle get headlineMd => titleLarge;
  static TextStyle get titleSm => titleMedium;
  static TextStyle get bodyLg => bodyLarge;
  static TextStyle get bodyMd => bodyMedium;
  static TextStyle get bodySm => bodySmall;
  static TextStyle get labelPill => labelLarge;
  static TextStyle get captionBold => captionSmall;

  // Feature specific aliases
  static TextStyle get headlineMedium => titleLarge;
  static TextStyle get headlineLarge => displayMedium;
  static TextStyle get titleSmall => titleMedium;
  static TextStyle get labelMedium => bodySmall;
  static TextStyle get displaySmall => displayMedium;
  static TextStyle get button => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
}
