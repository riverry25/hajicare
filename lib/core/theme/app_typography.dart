import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Typography System for HajiCare.
/// Uses Plus Jakarta Sans with refined font weights and proportional line heights.
/// Specifically calibrated with larger, legible scales and crisp contrast for elderly pilgrims (lansia).
class AppTypography {
  AppTypography._();

  // ── Primary Display & Hero Scales ──────────────────────────────────────────
  static TextStyle get heroNumberLarge => GoogleFonts.plusJakartaSans(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.02,
  );

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.3,
    letterSpacing: -0.02,
  );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.01,
  );

  // ── Titles & Section Headers ───────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: -0.01,
  );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  // ── Body Texts (Calibrated for high readability) ───────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  // ── Labels, Badges, & Captions ─────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: 0.1,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get captionSmall => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.3,
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
  static TextStyle get button => titleMedium;
}
