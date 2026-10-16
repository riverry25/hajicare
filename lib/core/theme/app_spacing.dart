/// Centralized 4/8-point spacing system for HajiCare.
class AppSpacing {
  AppSpacing._();

  // ── 4/8-Point On-Grid Scale ────────────────────────────────────────────────
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // ── Core Semantic Spacing Scale ────────────────────────────────────────────
  static const double xs = s4;
  static const double sm = s8;
  static const double md = s12;
  static const double lg = s16;
  static const double xl = s20;
  static const double xxl = s24;
  static const double xxxl = s32;
  static const double huge = s40;

  // ── Semantic Hierarchy Gaps (On-Grid Standards) ────────────────────────────
  static const double gapTitleSubtitleGrid = s4;
  static const double gapSubtitleContent = s12;
  static const double gapSection = s24;
  static const double gapCardsGrid = s16;
  static const double listGap = s12;

  // ── Layout Gutters & Padding (On-Grid Standards) ───────────────────────────
  static const double screenEdgeGutter = s16;
  static const double cardPaddingGrid = s16;
  static const double cardInnerGutterGrid = s16;

  // ── Legacy Aliases Preserved for Non-Breaking Backwards Compatibility ───────
  static const double gapTitleSubtitle = 6.0;
  static const double gapCards = 14.0;
  static const double cardPadding = 18.0;
  static const double cardInnerGutter = 14.0;
  static const double sm2 = xs;
  static const double xl2 = xxl;
  static const double xl3 = xxxl;
  static const double xl4 = huge;
}
