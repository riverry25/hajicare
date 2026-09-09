import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayHero => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 34 / 26,
        letterSpacing: -0.02,
      );

  static TextStyle get headlineLg => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 30 / 22,
        letterSpacing: -0.01,
      );

  static TextStyle get headlineMd => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 26 / 18,
      );

  static TextStyle get titleSm => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
      );

  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 26 / 16,
      );

  static TextStyle get bodyMd => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 24 / 15,
      );

  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 20 / 13,
      );

  static TextStyle get labelPill => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 20 / 14,
        letterSpacing: 0.01,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      );

  static TextStyle get captionBold => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 14 / 11,
        letterSpacing: 0.04,
      );
}
