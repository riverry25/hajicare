import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF321F14); // Very dark brown
  static const Color primaryContainer = Color(0xFF4A3428); // Espresso
  static const Color espressoDark = Color(0xFF3D2B1F);
  
  // Secondary (Tan)
  static const Color secondary = Color(0xFF745A34);
  static const Color secondaryContainer = Color(0xFFFEDAAA);
  static const Color tanMedium = Color(0xFFA67C52);
  
  // Tertiary (Gold)
  static const Color tertiary = Color(0xFF322000);
  static const Color tertiaryContainer = Color(0xFF4B350D);
  static const Color goldLight = Color(0xFFD4B896);
  static const Color accentGoldStar = Color(0xFFD4A857);
  static const Color primaryGold = accentGoldStar; // alias

  // Backgrounds
  static const Color background = Color(0xFFFFF8F4);
  static const Color surface = Color(0xFFFFF8F4);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color canvasCream = Color(0xFFF0E8DC);
  static const Color canvasCreamSubtle = Color(0xFFEDE4D3);
  static const Color surfaceBright = Color(0xFFFFFBFF);
  static const Color surfaceContainerLow = Color(0xFFFFF1E6);
  static const Color surfaceContainer = Color(0xFFFEEBD8);
  static const Color surfaceContainerHigh = Color(0xFFF9E5D3);
  static const Color surfaceContainerHighest = Color(0xFFF3DFCD);
  static const Color surfaceVariant = Color(0xFFF3DFCD);
  static const Color surfaceDim = Color(0xFFEAD7C5);

  // Texts / Outlines
  static const Color textHeading = Color(0xFF2B1F16);
  static const Color textBody = Color(0xFF6B5D4F);
  static const Color textSecondary = textBody; // alias
  static const Color borderGold = outlineVariant; // alias
  static const Color outline = Color(0xFF81746F);
  static const Color outlineVariant = Color(0xFFD3C3BC);
  
  // Status / Alerts
  static const Color sosEmergency = Color(0xFFE63946);
  static const Color distanceWarning = Color(0xFFF4A259);
  static const Color statusPositive = Color(0xFF4CAF50);
  
  // Standard Status Tokens
  static const Color statusWarning = Color(0xFFF4A259);
  static const Color statusDanger = Color(0xFFE63946);
  static const Color statusSafe = Color(0xFF4CAF50);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  
  // Text on colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFBB9C8C);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF795E38);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFBE9E6C);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color onBackground = Color(0xFF231A0F);
  static const Color onSurface = Color(0xFF231A0F);
  static const Color onSurfaceVariant = Color(0xFF4F453F);

  // Dark Mode Tokens (Warm Espresso & Charcoal, avoiding harsh pure black)
  static const Color darkScaffold = Color(0xFF19130E);
  static const Color darkSurface = Color(0xFF231B15);
  static const Color darkSurfaceContainer = Color(0xFF2D231C);
  static const Color darkSurfaceContainerHigh = Color(0xFF382C24);
  static const Color darkSurfaceContainerHighest = Color(0xFF44362D);
  static const Color darkPrimary = Color(0xFFF2D1B2);
  static const Color darkPrimaryContainer = Color(0xFF533C2E);
  static const Color darkOnPrimary = Color(0xFF2B180C);
  static const Color darkSecondary = Color(0xFFE0C19B);
  static const Color darkSecondaryContainer = Color(0xFF463524);
  static const Color darkTextHeading = Color(0xFFF6EFEA);
  static const Color darkTextBody = Color(0xFFCBBBB0);
  static const Color darkOutline = Color(0xFF6B5B50);
  static const Color darkBorder = darkOutline; // alias
  static const Color darkOutlineVariant = Color(0xFF4A3C33);

  // Semantic brightness helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffoldColor(BuildContext context) =>
      isDark(context) ? darkScaffold : canvasCream;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : surfaceWhite;

  static Color textHeadingColor(BuildContext context) =>
      isDark(context) ? darkTextHeading : textHeading;

  static Color textBodyColor(BuildContext context) =>
      isDark(context) ? darkTextBody : textBody;

  static Color outlineColor(BuildContext context) =>
      isDark(context) ? darkOutlineVariant : outlineVariant;
}
