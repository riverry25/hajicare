import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

class AppConstants {
  AppConstants._();

  // Spacing (from tokens)
  static const double space2xs = AppSpacing.sm2;
  static const double spaceXs = AppSpacing.sm;
  static const double spaceSm = AppSpacing.md;
  static const double spaceMd = AppSpacing.lg;
  static const double spaceLg = AppSpacing.xl;
  static const double spaceXl = AppSpacing.xl2;
  static const double space2xl = AppSpacing.xl3;
  static const double space3xl = AppSpacing.xl4;
  
  static const double screenEdgeGutter = AppSpacing.screenEdgeGutter;
  static const double cardPadding = AppSpacing.cardPadding;

  // Touch Targets
  static const double touchTargetMin = AppSizes.touchTargetMin;
  static const double buttonHeightPrimary = AppSizes.buttonHeightPrimary;
  static const double buttonHeightSecondary = AppSizes.buttonHeightSecondary;

  // Border Radius
  static const double radiusSm = AppRadius.sm;
  static const double radiusMd = AppRadius.md;
  static const double radiusCard = AppRadius.lg; // Standard card radius
  static const double radiusSheet = AppRadius.xl;
  static const double radiusPill = AppRadius.pill;
}

