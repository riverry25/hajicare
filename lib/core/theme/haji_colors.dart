import 'package:flutter/material.dart';

/// Semantic status tones for HajiCare notifications, alerts, badges, and readouts.
/// Decouples presentation models and controllers from concrete Flutter Color instances.
enum StatusTone { neutral, success, warning, danger, info, islamic }

/// Semantic, M3-aligned ThemeExtension for HajiCare.
/// Implements the "White Sand" aesthetic:
/// - 60% warm-white canvas (#FBF9F6) and pure white cards (#FFFFFF)
/// - 30% refined desert sand, camel tan, and espresso surfaces
/// - 10% rich espresso (#3B2A1F) and desert gold (#B08A57) primary actions
/// - Non-neon, earthy status tones calibrated for elderly readability & WCAG AA/AAA.
class HajiColors extends ThemeExtension<HajiColors> {
  const HajiColors({
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceSand,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accent,
    required this.accentText,
    required this.danger,
    required this.dangerContainer,
    required this.onDanger,
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    required this.info,
    required this.infoContainer,
    required this.onInfo,
    required this.islamic,
    required this.islamicContainer,
    required this.onIslamic,
    required this.neutral,
    required this.neutralContainer,
    required this.onNeutral,
    required this.shadow,
    required this.scrim,
    required this.poi,
    required this.currency,
  });

  // ── Structural Surfaces ───────────────────────────────────────────────────
  final Color canvas;
  final Color surface;
  final Color surfaceSubtle;
  final Color surfaceSand;
  final Color border;
  final Color borderStrong;

  // ── High-Contrast Typography ──────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // ── Brand Accents & CTAs ──────────────────────────────────────────────────
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color accent;
  final Color accentText;

  // ── Calibrated Earthy / Non-Neon Semantic Tones ────────────────────────────
  final Color danger;
  final Color dangerContainer;
  final Color onDanger;

  final Color success;
  final Color successContainer;
  final Color onSuccess;

  final Color warning;
  final Color warningContainer;
  final Color onWarning;

  final Color info;
  final Color infoContainer;
  final Color onInfo;

  final Color islamic;
  final Color islamicContainer;
  final Color onIslamic;

  final Color neutral;
  final Color neutralContainer;
  final Color onNeutral;

  // ── Overlays & Elevations ─────────────────────────────────────────────────
  final Color shadow;
  final Color scrim;

  // ── Domain-Specific Maps (POI & Currency) ──────────────────────────────────
  final Map<String, Color> poi;
  final Map<int, Color> currency;

  // ── Semantic Tone Resolvers ───────────────────────────────────────────────
  Color tone(StatusTone t) {
    switch (t) {
      case StatusTone.danger:
        return danger;
      case StatusTone.success:
        return success;
      case StatusTone.warning:
        return warning;
      case StatusTone.info:
        return info;
      case StatusTone.islamic:
        return islamic;
      case StatusTone.neutral:
        return neutral;
    }
  }

  Color toneContainer(StatusTone t) {
    switch (t) {
      case StatusTone.danger:
        return dangerContainer;
      case StatusTone.success:
        return successContainer;
      case StatusTone.warning:
        return warningContainer;
      case StatusTone.info:
        return infoContainer;
      case StatusTone.islamic:
        return islamicContainer;
      case StatusTone.neutral:
        return neutralContainer;
    }
  }

  Color onTone(StatusTone t) {
    switch (t) {
      case StatusTone.danger:
        return onDanger;
      case StatusTone.success:
        return onSuccess;
      case StatusTone.warning:
        return onWarning;
      case StatusTone.info:
        return onInfo;
      case StatusTone.islamic:
        return onIslamic;
      case StatusTone.neutral:
        return onNeutral;
    }
  }

  // ── Light Theme Instance (Warm White & Espresso Sand) ──────────────────────
  static const HajiColors light = HajiColors(
    canvas: Color(0xFFFBF9F6),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF6F1EA),
    surfaceSand: Color(0xFFEFE6D8),
    border: Color(0xFFECE4D8),
    borderStrong: Color(0xFFD8CAB5),
    textPrimary: Color(0xFF2A1D15),
    textSecondary: Color(0xFF554538),
    textTertiary: Color(0xFF706050),
    primary: Color(0xFF3B2A1F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF3EADF),
    onPrimaryContainer: Color(0xFF3B2A1F),
    accent: Color(0xFFB08A57),
    accentText: Color(0xFF6F4F24),
    // Earthy semantic tones (calm, non-neon, saturation <= 0.80)
    danger: Color(0xFFB3412F),
    dangerContainer: Color(0xFFF8E8E4),
    onDanger: Color(0xFFFFFFFF),
    success: Color(0xFF2E6B44),
    successContainer: Color(0xFFE5F0E9),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF8B541C),
    warningContainer: Color(0xFFFAF1DF),
    onWarning: Color(0xFFFFFFFF),
    info: Color(0xFF355E77),
    infoContainer: Color(0xFFE2EDF3),
    onInfo: Color(0xFFFFFFFF),
    islamic: Color(0xFF285F45),
    islamicContainer: Color(0xFFE3EFE8),
    onIslamic: Color(0xFFFFFFFF),
    neutral: Color(0xFF5C4E43),
    neutralContainer: Color(0xFFEFE8DF),
    onNeutral: Color(0xFFFFFFFF),
    shadow: Color(0x142A1D15),
    scrim: Color(0x662A1D15),
    poi: {
      'hotel': Color(0xFF7D5D30),
      'mosque': Color(0xFF285F45),
      'health': Color(0xFFB3412F),
      'food': Color(0xFF8B541C),
      'transport': Color(0xFF355E77),
      'shop': Color(0xFF6E4E73),
      'default': Color(0xFF5C4E43),
    },
    currency: {
      1000: Color(0xFF7D5D30),
      2000: Color(0xFF5C626E),
      5000: Color(0xFF8B541C),
      10000: Color(0xFF6E4E73),
      20000: Color(0xFF285F45),
      50000: Color(0xFF355E77),
      100000: Color(0xFFB3412F),
    },
  );

  // ── Dark Theme Instance (Charcoal Espresso & Desert Amber) ─────────────────
  static const HajiColors dark = HajiColors(
    canvas: Color(0xFF15100C),
    surface: Color(0xFF1F1813),
    surfaceSubtle: Color(0xFF28201A),
    surfaceSand: Color(0xFF352A21),
    border: Color(0xFF3A2F26),
    borderStrong: Color(0xFF54453A),
    textPrimary: Color(0xFFF6EFE7),
    textSecondary: Color(0xFFD2C4B6),
    textTertiary: Color(0xFFA79584),
    primary: Color(0xFFE6D0B1),
    onPrimary: Color(0xFF2A1D15),
    primaryContainer: Color(0xFF4A3829),
    onPrimaryContainer: Color(0xFFF3E6D6),
    accent: Color(0xFFD2AF7E),
    accentText: Color(0xFFE0C08F),
    // Earthy semantic tones for dark surfaces
    danger: Color(0xFFE58A7C),
    dangerContainer: Color(0xFF4A231D),
    onDanger: Color(0xFF24100C),
    success: Color(0xFF8DBF9C),
    successContainer: Color(0xFF1D3726),
    onSuccess: Color(0xFF0F2215),
    warning: Color(0xFFE3B266),
    warningContainer: Color(0xFF45331A),
    onWarning: Color(0xFF241A09),
    info: Color(0xFF93B8CF),
    infoContainer: Color(0xFF1C313E),
    onInfo: Color(0xFF0B1922),
    islamic: Color(0xFF8CC2A6),
    islamicContainer: Color(0xFF1A3528),
    onIslamic: Color(0xFF0C2016),
    neutral: Color(0xFFD2C4B6),
    neutralContainer: Color(0xFF382E26),
    onNeutral: Color(0xFF1E1712),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
    poi: {
      'hotel': Color(0xFFD2AF7E),
      'mosque': Color(0xFF8CC2A6),
      'health': Color(0xFFE58A7C),
      'food': Color(0xFFE3B266),
      'transport': Color(0xFF93B8CF),
      'shop': Color(0xFFC7A2CE),
      'default': Color(0xFFD2C4B6),
    },
    currency: {
      1000: Color(0xFFD2AF7E),
      2000: Color(0xFFB5BAC6),
      5000: Color(0xFFE3B266),
      10000: Color(0xFFC7A2CE),
      20000: Color(0xFF8CC2A6),
      50000: Color(0xFF93B8CF),
      100000: Color(0xFFE58A7C),
    },
  );

  @override
  HajiColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSubtle,
    Color? surfaceSand,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? accent,
    Color? accentText,
    Color? danger,
    Color? dangerContainer,
    Color? onDanger,
    Color? success,
    Color? successContainer,
    Color? onSuccess,
    Color? warning,
    Color? warningContainer,
    Color? onWarning,
    Color? info,
    Color? infoContainer,
    Color? onInfo,
    Color? islamic,
    Color? islamicContainer,
    Color? onIslamic,
    Color? neutral,
    Color? neutralContainer,
    Color? onNeutral,
    Color? shadow,
    Color? scrim,
    Map<String, Color>? poi,
    Map<int, Color>? currency,
  }) {
    return HajiColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceSand: surfaceSand ?? this.surfaceSand,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDanger: onDanger ?? this.onDanger,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfo: onInfo ?? this.onInfo,
      islamic: islamic ?? this.islamic,
      islamicContainer: islamicContainer ?? this.islamicContainer,
      onIslamic: onIslamic ?? this.onIslamic,
      neutral: neutral ?? this.neutral,
      neutralContainer: neutralContainer ?? this.neutralContainer,
      onNeutral: onNeutral ?? this.onNeutral,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      poi: poi ?? this.poi,
      currency: currency ?? this.currency,
    );
  }

  @override
  HajiColors lerp(ThemeExtension<HajiColors>? other, double t) {
    if (other is! HajiColors) return this;
    return HajiColors(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSubtle:
          Color.lerp(surfaceSubtle, other.surfaceSubtle, t) ?? surfaceSubtle,
      surfaceSand:
          Color.lerp(surfaceSand, other.surfaceSand, t) ?? surfaceSand,
      border: Color.lerp(border, other.border, t) ?? border,
      borderStrong:
          Color.lerp(borderStrong, other.borderStrong, t) ?? borderStrong,
      textPrimary:
          Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t) ??
          primaryContainer,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t) ??
          onPrimaryContainer,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentText: Color.lerp(accentText, other.accentText, t) ?? accentText,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      dangerContainer:
          Color.lerp(dangerContainer, other.dangerContainer, t) ??
          dangerContainer,
      onDanger: Color.lerp(onDanger, other.onDanger, t) ?? onDanger,
      success: Color.lerp(success, other.success, t) ?? success,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
          successContainer,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t) ?? onSuccess,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
      onWarning: Color.lerp(onWarning, other.onWarning, t) ?? onWarning,
      info: Color.lerp(info, other.info, t) ?? info,
      infoContainer:
          Color.lerp(infoContainer, other.infoContainer, t) ?? infoContainer,
      onInfo: Color.lerp(onInfo, other.onInfo, t) ?? onInfo,
      islamic: Color.lerp(islamic, other.islamic, t) ?? islamic,
      islamicContainer:
          Color.lerp(islamicContainer, other.islamicContainer, t) ??
          islamicContainer,
      onIslamic: Color.lerp(onIslamic, other.onIslamic, t) ?? onIslamic,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
      neutralContainer:
          Color.lerp(neutralContainer, other.neutralContainer, t) ??
          neutralContainer,
      onNeutral: Color.lerp(onNeutral, other.onNeutral, t) ?? onNeutral,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
      scrim: Color.lerp(scrim, other.scrim, t) ?? scrim,
      poi: t < 0.5 ? poi : other.poi,
      currency: t < 0.5 ? currency : other.currency,
    );
  }
}
