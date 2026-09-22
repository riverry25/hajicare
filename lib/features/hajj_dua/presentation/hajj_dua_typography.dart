import 'package:flutter/material.dart';

class HajjDuaTypography {
  HajjDuaTypography._();

  static const String headingFontFamily = 'Poppins';
  static const String bodyFontFamily = 'Montserrat';
  static const String arabicFontFamily = 'NotoNaskhArabic';

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  static const TextStyle button = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle body = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle metadataLabel = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.7,
  );

  static const TextStyle arabic = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 31,
    fontWeight: FontWeight.w500,
    height: 1.9,
  );

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
