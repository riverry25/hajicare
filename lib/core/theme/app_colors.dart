import 'package:flutter/material.dart';
import 'theme_context.dart';

/// Centralized Color Palette for HajiCare.
/// Designed for modern, premium Islamic aesthetics (warm white, desert sand, and rich espresso),
/// with high accessibility, anti-neon calmness, and contrast calibrated for elderly pilgrims (lansia).
class AppColors {
  AppColors._();

  // ── Primary Palette (Espresso & Kaaba Cloth tones) ─────────────────────────
  static const Color primary = Color(0xFF3B2A1F); // Deep rich espresso
  static const Color primaryContainer = Color(
    0xFFF3EADF,
  ); // Warm sand container
  static const Color espressoDark = Color(0xFF2A1D15); // Signature espresso
  static const Color espressoMedium = Color(0xFF4A3829);

  // ── Secondary Palette (Tan & Desert Sand) ──────────────────────────────────
  static const Color secondary = Color(0xFF755938); // Refined tan
  static const Color secondaryContainer = Color(0xFFEFE6D8); // Soft desert sand
  static const Color tanMedium = Color(0xFFA67C52); // Camel tan
  static const Color tanLight = Color(0xFFCBB296);

  // ── Tertiary & Islamic Accents (Desert Gold & Sacred Emerald) ──────────────
  static const Color tertiary = Color(0xFF322000);
  static const Color tertiaryContainer = Color(0xFF4B350D);
  static const Color goldLight = Color(0xFFD4B896); // Soft warm gold
  static const Color accentGoldStar = Color(0xFFB08A57); // Desert sand gold
  static const Color primaryGold = accentGoldStar;
  static const Color goldPrimary = Color(0xFFB08A57); // Desert sand gold
  static const Color goldDark = Color(0xFF6F4F24); // Deep rich gold
  static const Color goldMuted = Color(0xFFCBB698);
  static const Color goldAccent = Color(0xFFD2AF7E);

  // Islamic Emerald accents (for prayer, Quran, and sacred status)
  static const Color emeraldIslamic = Color(0xFF285F45);
  static const Color emeraldLight = Color(0xFFE3EFE8);
  static const Color emeraldDark = Color(0xFF183C2C);

  // ── Backgrounds & Canvas (Warm white 60% surfaces & pure white cards) ────────
  static const Color background = Color(0xFFFBF9F6); // Warm white canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure white cards
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color canvasCream = Color(0xFFFBF9F6); // Warm white canvas
  static const Color canvasCreamSubtle = Color(0xFFF6F1EA);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFBF9F6);
  static const Color surfaceContainer = Color(0xFFF6F1EA);
  static const Color surfaceContainerHigh = Color(0xFFEFE6D8);
  static const Color surfaceContainerHighest = Color(0xFFE7DDD0);
  static const Color surfaceVariant = Color(0xFFEFE6D8);
  static const Color surfaceDim = Color(0xFFEFE6D8);

  // ── Texts & Outlines (High Contrast WCAG AAA friendly for Elderly) ──────────
  static const Color textHeading = Color(0xFF2A1D15); // Deep espresso
  static const Color textBody = Color(0xFF554538); // High contrast body
  static const Color textSecondary = textBody;
  static const Color textMuted = Color(0xFF706050);
  static const Color textCaption = Color(0xFF706050);
  static const Color textHighContrast = Color(0xFF1B110B);

  static const Color outline = Color(0xFF8C7A6B);
  static const Color outlineVariant = Color(0xFFECE4D8);
  static const Color borderGold = outlineVariant;
  static const Color lightCardBorder = Color(0xFFECE4D8);
  static const Color darkCardBorder = Color(0xFF3A2F26);

  // ── Status, SOS, & Alerts (Earthy, non-neon, WCAG AA/AAA compliant) ─────────
  static const Color sosEmergency = Color(0xFFB3412F); // Calibrated brick red
  static const Color distanceWarning = Color(
    0xFF8B541C,
  ); // Calibrated warm ochre
  static const Color statusPositive = Color(
    0xFF2E6B44,
  ); // Calibrated sage green
  static const Color statusWarning = distanceWarning;
  static const Color statusCaution = distanceWarning;
  static const Color statusDanger = sosEmergency;
  static const Color statusSafe = statusPositive;

  static const Color error = Color(0xFFB3412F);
  static const Color errorContainer = Color(0xFFF8E8E4);

  // ── Text on Colors (Contrast calibrated) ───────────────────────────────────
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF3B2A1F);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF43301B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFB58E4C);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF4A231D);
  static const Color onBackground = Color(0xFF2A1D15);
  static const Color onSurface = Color(0xFF2A1D15);
  static const Color onSurfaceVariant = Color(0xFF554538);

  // ── Dark Mode Tokens (Warm Charcoal-Espresso, never pure OLED harsh black) ───
  static const Color darkScaffold = Color(0xFF15100C);
  static const Color darkSurface = Color(0xFF1F1813);
  static const Color darkSurfaceContainer = Color(0xFF28201A);
  static const Color darkSurfaceContainerHigh = Color(0xFF352A21);
  static const Color darkSurfaceContainerHighest = Color(0xFF42352B);
  static const Color darkPrimary = Color(0xFFE6D0B1);
  static const Color darkPrimaryContainer = Color(0xFF4A3829);
  static const Color darkOnPrimary = Color(0xFF2A1D15);
  static const Color darkSecondary = Color(0xFFD2AF7E);
  static const Color darkSecondaryContainer = Color(0xFF443322);
  static const Color darkTextHeading = Color(0xFFF6EFE7);
  static const Color darkTextBody = Color(0xFFD2C4B6);
  static const Color darkOutline = Color(0xFF54453A);
  static const Color darkBorder = darkOutline;
  static const Color darkOutlineVariant = Color(0xFF3A2F26);
  static const Color darkBorderSubtle = darkOutlineVariant;

  // ── Semantic Brightness & Adaptive Helpers ─────────────────────────────────
  static bool isDark(BuildContext context) => context.isDarkTheme;

  static Color scaffoldColor(BuildContext context) => context.hc.canvas;

  static Color surfaceColor(BuildContext context) => context.hc.surface;

  static Color cardBgColor(BuildContext context) => context.hc.surface;

  static Color cardBorderColor(BuildContext context) => context.hc.border;

  static Color textHeadingColor(BuildContext context) => context.hc.textPrimary;

  static Color textBodyColor(BuildContext context) => context.hc.textSecondary;

  static Color textSecondaryColor(BuildContext context) =>
      context.hc.textTertiary;

  static Color outlineColor(BuildContext context) => context.hc.border;
}
