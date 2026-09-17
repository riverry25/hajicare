import 'package:flutter/material.dart';

/// Centralized Color Palette for HajiCare.
/// Designed for modern, premium Islamic aesthetics (warm espresso, desert sand, and Mecca gold),
/// with high accessibility and contrast calibrated for elderly pilgrims (lansia).
class AppColors {
  AppColors._();

  // ── Primary Palette (Espresso & Kaaba Cloth tones) ─────────────────────────
  static const Color primary = Color(0xFF2E1C12); // Deep rich espresso
  static const Color primaryContainer = Color(0xFF4A3428); // Warm dark roast
  static const Color espressoDark = Color(0xFF38251A); // Signature espresso
  static const Color espressoMedium = Color(0xFF503829);

  // ── Secondary Palette (Tan & Desert Sand) ──────────────────────────────────
  static const Color secondary = Color(0xFF755938); // Refined tan
  static const Color secondaryContainer = Color(0xFFFEDBA8); // Soft sand
  static const Color tanMedium = Color(0xFFA67C52); // Camel tan
  static const Color tanLight = Color(0xFFCBB296);

  // ── Tertiary & Islamic Accents (Mecca Gold & Sacred Emerald) ───────────────
  static const Color tertiary = Color(0xFF322000);
  static const Color tertiaryContainer = Color(0xFF4B350D);
  static const Color goldLight = Color(0xFFD4B896); // Soft warm gold
  static const Color accentGoldStar = Color(0xFFD4A857); // Glowing star gold
  static const Color primaryGold = accentGoldStar; // Alias for backward compatibility
  static const Color goldPrimary = Color(0xFFCFA043); // Rich metallic gold
  static const Color goldDark = Color(0xFF9E7422); // Deep rich gold
  static const Color goldMuted = Color(0xFFCBB698);
  static const Color goldAccent = Color(0xFFE5BE6C);

  // Islamic Emerald accents (for prayer, Quran, and sacred status)
  static const Color emeraldIslamic = Color(0xFF1B633E);
  static const Color emeraldLight = Color(0xFFE8F5EE);
  static const Color emeraldDark = Color(0xFF124329);

  // ── Backgrounds & Canvas (Warm cream surfaces, avoiding blinding pure white) ─
  static const Color background = Color(0xFFFFF9F5);
  static const Color surface = Color(0xFFFFF9F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color canvasCream = Color(0xFFF2ECE1); // Signature warm parchment
  static const Color canvasCreamSubtle = Color(0xFFEAE2D4);
  static const Color surfaceBright = Color(0xFFFFFBFF);
  static const Color surfaceContainerLow = Color(0xFFFFF2E6);
  static const Color surfaceContainer = Color(0xFFFDECDA);
  static const Color surfaceContainerHigh = Color(0xFFF8E4CF);
  static const Color surfaceContainerHighest = Color(0xFFF2DCBF);
  static const Color surfaceVariant = Color(0xFFF2DCBF);
  static const Color surfaceDim = Color(0xFFE8D4BE);

  // ── Texts & Outlines (High Contrast WCAG AAA friendly for Elderly) ──────────
  static const Color textHeading = Color(0xFF22160E); // Deep espresso for maximum readability
  static const Color textBody = Color(0xFF57483B); // Solid contrast against cream/white
  static const Color textSecondary = textBody; // Alias
  static const Color textMuted = Color(0xFF7D6E62);
  static const Color textCaption = Color(0xFF8E7E73);
  static const Color textHighContrast = Color(0xFF150D08);

  static const Color outline = Color(0xFF7E706A);
  static const Color outlineVariant = Color(0xFFCEBDB5);
  static const Color borderGold = outlineVariant; // Alias
  static const Color lightCardBorder = Color(0xFFE5DACD);
  static const Color darkCardBorder = Color(0xFF3E3027);

  // ── Status, SOS, & Alerts ──────────────────────────────────────────────────
  static const Color sosEmergency = Color(0xFFE02B39); // Vibrant emergency red
  static const Color distanceWarning = Color(0xFFE68A2E); // High-visibility amber orange
  static const Color statusPositive = Color(0xFF2E8540); // High-contrast green
  static const Color statusWarning = distanceWarning;
  static const Color statusDanger = sosEmergency;
  static const Color statusSafe = statusPositive;

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // ── Text on Colors (Contrast calibrated) ───────────────────────────────────
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFF0E8);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF63471E);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFB58E4C);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color onBackground = Color(0xFF22160E);
  static const Color onSurface = Color(0xFF22160E);
  static const Color onSurfaceVariant = Color(0xFF4C3E35);

  // ── Dark Mode Tokens (Warm Charcoal-Espresso, never pure OLED harsh black) ───
  static const Color darkScaffold = Color(0xFF17110C);
  static const Color darkSurface = Color(0xFF211913);
  static const Color darkSurfaceContainer = Color(0xFF2B211A);
  static const Color darkSurfaceContainerHigh = Color(0xFF362B22);
  static const Color darkSurfaceContainerHighest = Color(0xFF42352B);
  static const Color darkPrimary = Color(0xFFF5D6B8);
  static const Color darkPrimaryContainer = Color(0xFF503828);
  static const Color darkOnPrimary = Color(0xFF261408);
  static const Color darkSecondary = Color(0xFFE5C7A2);
  static const Color darkSecondaryContainer = Color(0xFF443322);
  static const Color darkTextHeading = Color(0xFFFBF4ED);
  static const Color darkTextBody = Color(0xFFD2C1B4);
  static const Color darkOutline = Color(0xFF6E5C50);
  static const Color darkBorder = darkOutline; // Alias
  static const Color darkOutlineVariant = Color(0xFF46382E);
  static const Color darkBorderSubtle = darkOutlineVariant;

  // ── Semantic Brightness & Adaptive Helpers ─────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffoldColor(BuildContext context) =>
      isDark(context) ? darkScaffold : canvasCream;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : surfaceWhite;

  static Color cardBgColor(BuildContext context) =>
      isDark(context) ? darkSurface : surfaceWhite;

  static Color cardBorderColor(BuildContext context) =>
      isDark(context) ? darkCardBorder : lightCardBorder;

  static Color textHeadingColor(BuildContext context) =>
      isDark(context) ? darkTextHeading : textHeading;

  static Color textBodyColor(BuildContext context) =>
      isDark(context) ? darkTextBody : textBody;

  static Color textSecondaryColor(BuildContext context) =>
      isDark(context) ? darkTextBody.withValues(alpha: 0.8) : textMuted;

  static Color outlineColor(BuildContext context) =>
      isDark(context) ? darkOutlineVariant : outlineVariant;
}
