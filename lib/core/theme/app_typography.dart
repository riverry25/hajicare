import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 34 / 26,
    letterSpacing: -0.02,
  );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 30 / 22,
    letterSpacing: -0.01,
  );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 26 / 18,
  );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 26 / 16,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 22 / 14,
  );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 20 / 13,
  );

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.01,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
  );

  static TextStyle get captionSmall => GoogleFonts.plusJakartaSans(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    height: 14 / 10,
    letterSpacing: 0.04,
  );

  static TextStyle get heroNumberLarge => GoogleFonts.plusJakartaSans(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 56 / 48,
  );

  // Legacy aliases to prevent breakages during transition
  static TextStyle get displayHero => displayLarge;
  static TextStyle get headlineLg => displayMedium;
  static TextStyle get headlineMd => titleLarge;
  static TextStyle get titleSm => titleMedium;
  static TextStyle get bodyLg => bodyLarge;
  static TextStyle get bodyMd => bodyMedium;
  static TextStyle get bodySm => bodySmall;
  static TextStyle get labelPill => labelLarge;
  static TextStyle get captionBold => captionSmall;
}
