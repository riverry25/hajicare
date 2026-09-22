import 'package:flutter/material.dart';

/// Typography used by every role dashboard.
///
/// The font files are bundled with the app, so dashboard readability does not
/// depend on a network connection. Poppins provides a clear visual hierarchy,
/// while Montserrat keeps longer supporting text comfortable to scan.
class DashboardTypography {
  DashboardTypography._();

  static const String headingFontFamily = 'Poppins';
  static const String bodyFontFamily = 'Montserrat';

  static const TextStyle heroNumberLarge = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 52,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.8,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 21,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle button = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle captionSmall = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
  );

  static const TextStyle headlineLarge = displayMedium;

  static ThemeData applyTo(ThemeData base) {
    final textTheme = base.textTheme.copyWith(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displayMedium,
      headlineLarge: displayMedium,
      headlineMedium: titleLarge,
      headlineSmall: titleLarge,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: caption,
      labelSmall: captionSmall,
    );

    return base.copyWith(textTheme: textTheme, primaryTextTheme: textTheme);
  }
}
