import 'package:flutter/material.dart';
import 'haji_colors.dart';

/// Centralized Typography Service for HajiCare.
/// Uses locally bundled offline-ready font families:
/// - [headingFontFamily] ('Poppins'): Headings, titles, app bars, buttons, and high-emphasis display.
/// - [bodyFontFamily] ('Montserrat'): Body text, captions, subtitles, badges, and readouts.
/// - [arabicFontFamily] ('NotoNaskhArabic'): Quranic verses, prayers, and Arabic calligraphy.
///
/// Provides predefined accessible text scales, Material 3 [buildTextTheme],
/// and dynamic generator methods to allow any screen across the entire app
/// to customize typography dynamically, safely, and consistently.
class AppTypography {
  AppTypography._();

  // ── Core Font Families ─────────────────────────────────────────────────────
  static const String headingFontFamily = 'Poppins';
  static const String bodyFontFamily = 'Montserrat';
  static const String arabicFontFamily = 'NotoNaskhArabic';

  // ── Material 3 Dynamic TextTheme Builder ───────────────────────────────────
  /// Fills all 15 M3 typography slots with calibrated offline font families
  /// and dynamic contrast colors provided by [HajiColors].
  static TextTheme buildTextTheme(HajiColors c) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: c.textPrimary,
        height: 1.25,
        letterSpacing: -0.02,
      ),
      displayMedium: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: c.textPrimary,
        height: 1.3,
        letterSpacing: -0.02,
      ),
      displaySmall: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
        height: 1.35,
        letterSpacing: -0.01,
      ),
      headlineLarge: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
        height: 1.35,
        letterSpacing: -0.01,
      ),
      headlineMedium: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
        height: 1.35,
      ),
      headlineSmall: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
        height: 1.4,
        letterSpacing: -0.01,
      ),
      titleMedium: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.45,
      ),
      titleSmall: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: c.textSecondary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: c.textSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: c.textSecondary,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
        height: 1.35,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: c.textTertiary,
        height: 1.35,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: c.textTertiary,
        height: 1.3,
        letterSpacing: 0.3,
      ),
    );
  }

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

/// ThemeExtension for domain-specific typography (Quranic Arabic, hero metrics, labels).
class HajiTextStyles extends ThemeExtension<HajiTextStyles> {
  const HajiTextStyles({
    required this.heroNumber,
    required this.arabicLarge,
    required this.arabic,
    required this.arabicMedium,
    required this.arabicSmall,
    required this.transliteration,
    required this.translation,
    required this.metadataLabel,
    required this.button,
  });

  final TextStyle heroNumber;
  final TextStyle arabicLarge;
  final TextStyle arabic;
  final TextStyle arabicMedium;
  final TextStyle arabicSmall;
  final TextStyle transliteration;
  final TextStyle translation;
  final TextStyle metadataLabel;
  final TextStyle button;

  /// Creates a calibrated [HajiTextStyles] instance using [HajiColors].
  static HajiTextStyles forBrightness(HajiColors c, Brightness brightness) {
    return HajiTextStyles(
      heroNumber: TextStyle(
        fontFamily: AppTypography.headingFontFamily,
        fontSize: 52,
        fontWeight: FontWeight.w800,
        color: c.textPrimary,
        height: 1.15,
        letterSpacing: -0.02,
      ),
      arabicLarge: TextStyle(
        fontFamily: AppTypography.arabicFontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        height: 1.9,
      ),
      arabic: TextStyle(
        fontFamily: AppTypography.arabicFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
        height: 1.85,
      ),
      arabicMedium: TextStyle(
        fontFamily: AppTypography.arabicFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
        height: 1.7,
      ),
      arabicSmall: TextStyle(
        fontFamily: AppTypography.arabicFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
        height: 1.6,
      ),
      transliteration: TextStyle(
        fontFamily: AppTypography.bodyFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: c.textSecondary,
        height: 1.7,
      ),
      translation: TextStyle(
        fontFamily: AppTypography.bodyFontFamily,
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: c.textSecondary,
        height: 1.7,
      ),
      metadataLabel: TextStyle(
        fontFamily: AppTypography.bodyFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: c.textTertiary,
        height: 1.4,
        letterSpacing: 0.7,
      ),
      button: TextStyle(
        fontFamily: AppTypography.headingFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: c.onPrimary,
        height: 1.35,
      ),
    );
  }

  static HajiTextStyles light(HajiColors c) =>
      forBrightness(c, Brightness.light);
  static HajiTextStyles dark(HajiColors c) => forBrightness(c, Brightness.dark);

  @override
  HajiTextStyles copyWith({
    TextStyle? heroNumber,
    TextStyle? arabicLarge,
    TextStyle? arabic,
    TextStyle? arabicMedium,
    TextStyle? arabicSmall,
    TextStyle? transliteration,
    TextStyle? translation,
    TextStyle? metadataLabel,
    TextStyle? button,
  }) {
    return HajiTextStyles(
      heroNumber: heroNumber ?? this.heroNumber,
      arabicLarge: arabicLarge ?? this.arabicLarge,
      arabic: arabic ?? this.arabic,
      arabicMedium: arabicMedium ?? this.arabicMedium,
      arabicSmall: arabicSmall ?? this.arabicSmall,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      metadataLabel: metadataLabel ?? this.metadataLabel,
      button: button ?? this.button,
    );
  }

  @override
  HajiTextStyles lerp(ThemeExtension<HajiTextStyles>? other, double t) {
    if (other is! HajiTextStyles) return this;
    return HajiTextStyles(
      heroNumber: TextStyle.lerp(heroNumber, other.heroNumber, t) ?? heroNumber,
      arabicLarge:
          TextStyle.lerp(arabicLarge, other.arabicLarge, t) ?? arabicLarge,
      arabic: TextStyle.lerp(arabic, other.arabic, t) ?? arabic,
      arabicMedium:
          TextStyle.lerp(arabicMedium, other.arabicMedium, t) ?? arabicMedium,
      arabicSmall:
          TextStyle.lerp(arabicSmall, other.arabicSmall, t) ?? arabicSmall,
      transliteration:
          TextStyle.lerp(transliteration, other.transliteration, t) ??
          transliteration,
      translation:
          TextStyle.lerp(translation, other.translation, t) ?? translation,
      metadataLabel:
          TextStyle.lerp(metadataLabel, other.metadataLabel, t) ??
          metadataLabel,
      button: TextStyle.lerp(button, other.button, t) ?? button,
    );
  }
}
