import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

/// Second slide of the onboarding flow: Safety, Radar Rombongan & Connected Pilgrims.
/// Implements an arched globe world map showcase aligned with AppColors
/// Arched/curved hemispherical dotted world map spanning edge-to-edge
/// High accuracy landmass dot projection (Americas, Europe, Africa, Middle East, Asia, Nusantara, Australia
/// 3 floating Islamic vector art cards matching AppColors
/// Center: Ka'bah (Deep Espresso & Kiswah Gold) with Gold-Emerald gradient border & pilgrim avatar
/// Left: Masjid Nabawi (Sacred Emerald & Desert Sand Dawn
/// Right: Tenda Mina & Jabal Rahmah (Warm Desert Sand, Camel Tan & Clean White
/// Floating live status pill and Ka'bah location pin badge
/// High contrast  AA/AAA compliant typography for Light & Dark mode
class OnboardingSlideSafety extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideSafety({super.key, this.activeIndex = 1});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final colors = context.hc;
    final isDark = colors.isDark;

    return Obx(() {
      final _ = settings.rxLocale.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isShortScreen = constraints.maxHeight < 680;
          final heroHeight = isShortScreen ? 295.0 : 335.0;
          final minContentHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 0.0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 0, // Edge-to-edge for arched world globe map
              vertical: AppSpacing.xs,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minContentHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xs),

                  // 1. Visual Showcase: Full-Width Arched Dotted Globe Map
                  OnboardingHeroBanner(
                    badgeText: context.tr('onboarding.safetySystemBadge'),
                    stageText: context.tr('onboardingStage2'),
                    title: context.tr('onboarding.safetySlideTitle'),
                    icon: Icons.shield_rounded,
                    height: heroHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // 1.1 Pure Native Vector Map: Architectural World Dot Matrix
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _WorldDotMatrixMapPainter(isDark: isDark),
                          ),
                        ),

                        // 1.2 Three Floating Modern Islamic Art Cards (Arched Fan
                        Positioned(
                          top: isShortScreen ? 6 : 10,
                          child: _buildArchedCardsShowcase(context, isDark),
                        ),

                        // 1.3 Floating Location Pill Badge (Right
                        Positioned(
                          bottom: isShortScreen ? 18 : 24,
                          right: 14,
                          child: _buildLocationPill(context, isDark),
                        ),

                        // 1.4 Floating Ka'bah Pin Badge (Left
                        Positioned(
                          bottom: isShortScreen ? 24 : 30,
                          left: 18,
                          child: _buildPinBadge(context, isDark),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 2. Editorial Headline & Narrative Description
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenEdgeGutter,
                    ),
                    child: Text(
                      context.tr('onboarding.safetySlideTitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading,
                        fontSize: isShortScreen ? 25.0 : 28.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenEdgeGutter + 4,
                    ),
                    child: Text(
                      context.tr('onboarding.safeCompanionDesc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextBody
                            : AppColors.textBody,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  /// Builds the 3 arched floating cards arranged gracefully over the globe.
  Widget _buildArchedCardsShowcase(BuildContext context, bool isDark) {
    return SizedBox(
      width: 280,
      height: 175,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Left Card: Masjid Nabawi / Madinah (tilted counter-clockwise
          Positioned(
            left: 18,
            top: 14,
            child: Transform.rotate(
              angle: -0.13, // 7.5 degrees
              child: _buildSideArtCard(
                width: 78,
                height: 112,
                isDark: isDark,
                cardType: _CardArtType.nabawi,
                avatarFallbackIcon: Icons.location_city_rounded,
                avatarFallbackColor: AppColors.goldLight,
                badgeBgColor: AppColors.emeraldIslamic,
              ),
            ),
          ),

          // Right Card: Tenda Mina & Arafat (tilted clockwise
          Positioned(
            right: 18,
            top: 14,
            child: Transform.rotate(
              angle: 0.13, // +7.5 degrees
              child: _buildSideArtCard(
                width: 78,
                height: 112,
                isDark: isDark,
                cardType: _CardArtType.mina,
                avatarFallbackIcon: Icons.landscape_rounded,
                avatarFallbackColor: AppColors.surfaceWhite,
                badgeBgColor: AppColors.secondary,
              ),
            ),
          ),

          // Center Card: Ka'bah & Masjidil Haram (straight, elevated
          Positioned(top: 0, child: _buildCenterKaabaCard(isDark)),
        ],
      ),
    );
  }

  /// Builds the prominent center card featuring the Holy Ka'bah with an
  /// AppColors gold & sacred emerald gradient border and overlapping avatar.
  Widget _buildCenterKaabaCard(bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // AppColors multi-tone gradient border wrapper (Desert Gold to Sacred Emerald
        Container(
          width: 96,
          height: 136,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.goldPrimary, // Desert Gold
                AppColors.emeraldIslamic, // Sacred Emerald
                AppColors.goldLight, // Warm Light Gold
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withValues(
                  alpha: isDark ? 0.40 : 0.28,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.5), // Gradient border thickness
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17.5),
            child: CustomPaint(painter: _KaabaVectorArtPainter(isDark: isDark)),
          ),
        ),

        // Overlapping Avatar Badge at bottom of center card
        Positioned(
          bottom: -15,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.surfaceWhite,
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.statusPositive, AppColors.emeraldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: AppColors.surfaceWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the left/right tilted side art cards using AppColors palettes.
  Widget _buildSideArtCard({
    required double width,
    required double height,
    required bool isDark,
    required _CardArtType cardType,
    required IconData avatarFallbackIcon,
    required Color avatarFallbackColor,
    required Color badgeBgColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.lightCardBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.5),
            child: CustomPaint(
              painter: _LandscapeVectorArtPainter(
                isDark: isDark,
                type: cardType,
              ),
            ),
          ),
        ),

        // Small overlapping avatar badge at bottom
        Positioned(
          bottom: -11,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.surfaceWhite,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeBgColor,
                ),
                child: Center(
                  child: Icon(
                    avatarFallbackIcon,
                    size: 11,
                    color: avatarFallbackColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the floating location pill badge ("Sedang di Masjidil Haram") on the right.
  Widget _buildLocationPill(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.outlineVariant,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular mini thumbnail with live status indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.goldPrimary, AppColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.mosque_rounded,
                    size: 13,
                    color: AppColors.surfaceWhite,
                  ),
                ),
              ),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.statusPositive,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Location status text formatted with AppColors tokens
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('onboarding.currentlyAt'),
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextBody
                      : AppColors.textSecondary,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                context.tr('onboarding.locationHaram'),
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the floating Ka'bah/Saudi pin badge on the left side of the map.
  Widget _buildPinBadge(BuildContext context, bool isDark) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.outlineVariant,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.emeraldLight.withValues(
              alpha: isDark ? 0.12 : 0.70,
            ),
          ),
          child: const Center(
            child: Text('🕋', style: TextStyle(fontSize: 14)),
          ),
        ),
      ),
    );
  }
}

enum _CardArtType { nabawi, mina }

/// Custom painter rendering a beautiful minimalist vector illustration of the
/// Holy Ka'bah with crescent moon, starry twilight, and golden Kiswah details
/// calibrated to AppColors.espressoDark and AppColors.goldPrimary.
class _KaabaVectorArtPainter extends CustomPainter {
  final bool isDark;

  const _KaabaVectorArtPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Celestial background gradient (Deep Espresso Night
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.espressoDark, // Signature deep espresso
          AppColors.primary,
          Color(0xFF1E1712),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Subtle celestial stars in AppColors.goldLight
    final starPaint = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.75);
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.18),
      1.0,
      starPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      1.2,
      starPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.32),
      0.8,
      starPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.14),
      1.0,
      starPaint,
    );

    // 3. Golden glowing crescent moon in AppColors.goldPrimary
    final moonCenter = Offset(size.width * 0.50, size.height * 0.26);
    final moonGlowPaint = Paint()
      ..color = AppColors.goldPrimary.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(moonCenter, 11, moonGlowPaint);

    final moonPaint = Paint()..color = AppColors.goldLight;
    final moonPath = Path()
      ..addArc(
        Rect.fromCircle(center: moonCenter, radius: 9),
        -math.pi / 2,
        math.pi * 1.5,
      )
      ..arcToPoint(
        Offset(moonCenter.dx, moonCenter.dy - 9),
        radius: const Radius.circular(7.5),
        clockwise: false,
      );
    canvas.drawPath(moonPath, moonPaint);

    // 4. Holy Ka'bah cubic silhouette
    final kaabaLeft = size.width * 0.28;
    final kaabaTop = size.height * 0.52;
    final kaabaWidth = size.width * 0.44;
    final kaabaHeight = size.height * 0.36;

    // Soft warm floor reflection / aura
    final floorAura = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.goldPrimary.withValues(alpha: 0.28),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, kaabaTop + kaabaHeight * 0.7),
              radius: 36,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.5, kaabaTop + kaabaHeight * 0.7),
      36,
      floorAura,
    );

    // Ka'bah body (Deepest rich charcoal black
    final kaabaPaint = Paint()..color = const Color(0xFF140E0A);
    final kaabaRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(kaabaLeft, kaabaTop, kaabaWidth, kaabaHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(kaabaRect, kaabaPaint);

    // Golden Kiswah Upper Band (AppColors.goldPrimary
    final kiswahBandPaint = Paint()..color = AppColors.goldPrimary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(kaabaLeft, kaabaTop + 7, kaabaWidth, 4),
        const Radius.circular(1),
      ),
      kiswahBandPaint,
    );

    // Ka'bah golden door in AppColors.goldLight
    final doorPaint = Paint()..color = AppColors.goldLight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          kaabaLeft + kaabaWidth * 0.58,
          kaabaTop + 13,
          kaabaWidth * 0.24,
          kaabaHeight * 0.48,
        ),
        const Radius.circular(2),
      ),
      doorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _KaabaVectorArtPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Custom painter rendering minimalist vector illustrations of Nabawi or Mina landscapes
/// calibrated to AppColors (Sacred Emerald, Camel Tan, Desert Sand, and Espresso).
class _LandscapeVectorArtPainter extends CustomPainter {
  final bool isDark;
  final _CardArtType type;

  const _LandscapeVectorArtPainter({required this.isDark, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Offset.zero & size;

    if (type == _CardArtType.nabawi) {
      // Nabawi: Sacred Emerald Twilight Gradient
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.emeraldDark, // Sacred Deep Emerald
            AppColors.emeraldIslamic,
            AppColors.secondary, // Refined Tan
            AppColors.goldLight, // Warm Gold Horizon
          ],
        ).createShader(bgRect);
      canvas.drawRect(bgRect, bgPaint);

      // Distant desert mountain silhouette
      final mountainPaint = Paint()..color = AppColors.primary;
      final mountainPath = Path()
        ..moveTo(0, size.height * 0.72)
        ..lineTo(size.width * 0.35, size.height * 0.58)
        ..lineTo(size.width * 0.70, size.height * 0.68)
        ..lineTo(size.width, size.height * 0.60)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(mountainPath, mountainPaint);

      // Green Dome silhouette (Qubbah al-Khadra) in AppColors.statusPositive
      final domePaint = Paint()..color = AppColors.statusPositive;
      canvas.drawArc(
        Rect.fromLTWH(
          size.width * 0.20,
          size.height * 0.64,
          size.width * 0.46,
          size.height * 0.36,
        ),
        math.pi,
        math.pi,
        true,
        domePaint,
      );

      // Minaret silhouette in AppColors.espressoDark
      final minaretPaint = Paint()..color = AppColors.espressoDark;
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.70,
          size.height * 0.42,
          size.width * 0.12,
          size.height * 0.58,
        ),
        minaretPaint,
      );
      // Minaret cone tip in AppColors.goldLight
      final tipPaint = Paint()..color = AppColors.goldLight;
      final tipPath = Path()
        ..moveTo(size.width * 0.70, size.height * 0.42)
        ..lineTo(size.width * 0.76, size.height * 0.34)
        ..lineTo(size.width * 0.82, size.height * 0.42)
        ..close();
      canvas.drawPath(tipPath, tipPaint);
    } else {
      // Mina & Arafat: Warm Desert Dawn Gradient in AppColors tan & gold
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.secondary, // Refined Tan
            AppColors.tanMedium, // Camel Tan
            AppColors.goldLight, // Soft Warm Gold
            AppColors.secondaryContainer, // Soft Desert Sand
          ],
        ).createShader(bgRect);
      canvas.drawRect(bgRect, bgPaint);

      // Desert sandstone dunes in AppColors.secondary
      final dunePaint = Paint()..color = AppColors.secondary;
      final dunePath = Path()
        ..moveTo(0, size.height * 0.68)
        ..quadraticBezierTo(
          size.width * 0.45,
          size.height * 0.56,
          size.width,
          size.height * 0.65,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(dunePath, dunePaint);

      // White Mina tents (geometric triangular peaks) in AppColors.surfaceWhite
      final tentPaint = Paint()
        ..color = AppColors.surfaceWhite.withValues(alpha: 0.95);
      void drawTent(double x, double y, double w, double h) {
        final path = Path()
          ..moveTo(x + w * 0.5, y)
          ..lineTo(x + w, y + h)
          ..lineTo(x, y + h)
          ..close();
        canvas.drawPath(path, tentPaint);
      }

      drawTent(size.width * 0.15, size.height * 0.70, 20, 16);
      drawTent(size.width * 0.42, size.height * 0.66, 24, 20);
      drawTent(size.width * 0.72, size.height * 0.72, 18, 14);
    }
  }

  @override
  bool shouldRepaint(covariant _LandscapeVectorArtPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.type != type;
}

/// Pure native architectural vector painter rendering a full-width, full-height
/// precision mathematical World Dot Matrix Map inspired by luxury travel interfaces (WanderWise).
/// Features
/// 50x22 uniform cartographic dot matrix spanning the entire banner canvas
/// Rich western continents (Americas, West Africa, Europe) so the left is NEVER empty
/// Gold Holy Land cluster (`G`) around Makkah & Madinah with glowing ripple halos
/// Emerald Kloter cluster (`E`) across Indonesia (Jakarta, Surabaya, Makassar
/// Warm accent cluster (`A`) directly beneath the lower-left Ka'bah pin badge
/// Smooth flowing dashed connecting journey curve with miniature aircraft
class _WorldDotMatrixMapPainter extends CustomPainter {
  final bool isDark;

  const _WorldDotMatrixMapPainter({required this.isDark});

  // 50 columns x 22 rows cartographic world matrix
  // '.' = standard continent dot, 'G' = Gold Makkah/Madinah cluster
  // 'E' = Emerald Indonesia cluster, 'A' = Left Pin Area cluster, ' ' = ocean
  static const List<String> worldGrid = [
    // 0: Northern Canada / Scandinavia / Russia
    "   ...   ...             .....      ........      ",
    // 1: Alaska, Canada, Northern Europe, Siberia
    " .....  ........       .........   .......... ... ",
    // 2: Canada, UK, Western Europe, Russia
    ".......  .......     ........................ ... ",
    // 3: USA North, Central Europe, Russia
    " .....    .....     .......................... .  ",
    // 4: USA, Mediterranean, Central Asia, China
    "  ...     ....       ............................ ",
    // 5: USA South, North Africa, Middle East, China
    "   ..      ...      ... .......................   ",
    // 6: Mexico, Sahara, Egypt, Arabia North, Japan
    "   ..     .....      ...  GG............. .....   ",
    // 7: Central America, Sahara, Makkah/Madinah, India
    "    .    .......      .  GGGG   .......  ....     ",
    // 8: Caribbean, West Africa, Saudi Arabia, India South
    "    .   .........        GGGG    ......   ..      ",
    // 9: Colombia, West Africa coast, Yemen, Bay of Bengal
    "   ..   .........         GG       ...      ...   ",
    // 10: Venezuela, Nigeria, Horn of Africa, Indochina
    "  ....    .....            .        .     .....   ",
    // 11: Amazon, Congo, East Africa, Thailand, Philippines
    " ......   ......          ...            .......  ",
    // 12: Brazil North, Angola, Tanzania, Malaysia
    "........   .....         .....            .....   ",
    // 13: Brazil Central, Mozambique, Sumatra, Borneo
    " ......     ...           ...             EEEE.   ",
    // 14: Bolivia/Brazil, Madagascar, Java, Sulawesi
    "  ....       .             .              EEEEEE  ",
    // 15: Argentina North (Left Pin Area!), Bali, Papua
    "  AA..                                    .EEEE.. ",
    // 16: Argentina Central / Chile, Australia North
    "  AAAA                                     .....  ",
    // 17: Patagonia (Dense cluster near Pin), Australia Central
    "   AA.                                    ....... ",
    // 18: South America South, Australia South
    "   ..                                    .........",
    // 19: Tierra del Fuego, Victoria/Sydney
    "    .                                     ....... ",
    // 20: Southern Ocean, Melbourne/Tasmania
    "                                           .....  ",
    // 21: Bottom border
    "                                            ...   ",
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const marginX = 12.0;
    const marginY = 14.0;
    final availableW = w - (marginX * 2);
    final availableH = h - (marginY * 2);

    const numCols = 50;
    final numRows = worldGrid.length;

    final stepX = availableW / (numCols - 1);
    final stepY = availableH / (numRows - 1);

    // Paints
    final baseDotPaint = Paint()
      ..color = (isDark ? AppColors.darkOutline : AppColors.tanLight)
          .withValues(alpha: isDark ? 0.40 : 0.55)
      ..style = PaintingStyle.fill;

    final goldDotPaint = Paint()
      ..color = isDark ? AppColors.darkPrimary : AppColors.goldPrimary
      ..style = PaintingStyle.fill;

    final emeraldDotPaint = Paint()
      ..color = AppColors.statusPositive
      ..style = PaintingStyle.fill;

    final accentDotPaint = Paint()
      ..color = (isDark ? AppColors.darkSecondary : AppColors.goldPrimary)
          .withValues(alpha: isDark ? 0.85 : 0.90)
      ..style = PaintingStyle.fill;

    // 1. Draw Full Architectural Dot Matrix
    for (int r = 0; r < numRows; r++) {
      final row = worldGrid[r].padRight(numCols);
      final y = marginY + r * stepY;

      for (int c = 0; c < numCols; c++) {
        final ch = row[c];
        if (ch == ' ') continue;

        final x = marginX + c * stepX;
        final pos = Offset(x, y);

        switch (ch) {
          case 'G':
            canvas.drawCircle(pos, 2.4, goldDotPaint);
            break;
          case 'E':
            canvas.drawCircle(pos, 2.4, emeraldDotPaint);
            break;
          case 'A':
            canvas.drawCircle(pos, 2.2, accentDotPaint);
            break;
          default:
            canvas.drawCircle(pos, 1.65, baseDotPaint);
        }
      }
    }

    // 2. Strategic Landmark Hub Nodes
    // Left Pin Anchor Node (South America / Patagonia cluster
    final leftPinNode = Offset(marginX + 5.0 * stepX, marginY + 16.5 * stepY);
    // Makkah Holy Beacon Node (Saudi Arabia
    final makkahNode = Offset(marginX + 26.5 * stepX, marginY + 7.5 * stepY);
    // Right Pill Anchor Node (Indonesia / Australia
    final rightPillNode = Offset(
      marginX + 41.5 * stepX,
      marginY + 15.5 * stepY,
    );

    // 3. Smooth Connecting Journey Curve
    final journeyPath = Path()
      ..moveTo(leftPinNode.dx, leftPinNode.dy)
      ..cubicTo(
        w * 0.14,
        h * 0.42,
        w * 0.20,
        makkahNode.dy - 8,
        makkahNode.dx,
        makkahNode.dy,
      )
      ..cubicTo(
        w * 0.34,
        makkahNode.dy + 12,
        w * 0.44,
        h * 0.60,
        rightPillNode.dx,
        rightPillNode.dy,
      );

    final dashedPaint = Paint()
      ..color = (isDark ? AppColors.darkPrimary : AppColors.goldPrimary)
          .withValues(alpha: isDark ? 0.65 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (final metric in journeyPath.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 5.0;
      const dashGap = 4.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(distance, next);
        canvas.drawPath(extractPath, dashedPaint);
        distance += dashLength + dashGap;
      }

      // Miniature Airplane vector cruising midway towards Makkah
      final tangent = metric.getTangentForOffset(metric.length * 0.62);
      if (tangent != null) {
        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        // Plane heading in reverse direction (towards Makkah / northwest
        canvas.rotate(tangent.angle + 3.14159);

        final planePaint = Paint()
          ..color = isDark ? AppColors.darkPrimary : AppColors.goldPrimary
          ..style = PaintingStyle.fill;

        final planePath = Path()
          ..moveTo(6.0, 0)
          ..lineTo(-3.5, -4.0)
          ..lineTo(-1.8, -1.0)
          ..lineTo(-5.5, -1.0)
          ..lineTo(-5.5, 1.0)
          ..lineTo(-1.8, 1.0)
          ..lineTo(-3.5, 4.0)
          ..close();

        canvas.drawPath(planePath, planePaint);
        canvas.restore();
      }
    }

    // 4. Pulsing Beacons & Holy Halos
    // Left Pin Anchor Beacon (Golden Halo
    final leftHalo = Paint()
      ..color = AppColors.goldPrimary.withValues(alpha: isDark ? 0.35 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(leftPinNode, 8.0, leftHalo);
    canvas.drawCircle(leftPinNode, 3.0, goldDotPaint);

    // Makkah Sacred Beacon (Expanding Golden & Emerald Halos
    final makkahHalo1 = Paint()
      ..color = (isDark ? AppColors.darkPrimary : AppColors.goldPrimary)
          .withValues(alpha: isDark ? 0.25 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(makkahNode, 13.0, makkahHalo1);

    final makkahHalo2 = Paint()
      ..color = AppColors.statusPositive.withValues(alpha: isDark ? 0.30 : 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(makkahNode, 7.5, makkahHalo2);

    canvas.drawCircle(makkahNode, 3.8, goldDotPaint);

    // Right Pill Beacon (Emerald Halo
    final rightHalo = Paint()
      ..color = AppColors.statusPositive.withValues(alpha: isDark ? 0.30 : 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(rightPillNode, 9.0, rightHalo);
    canvas.drawCircle(rightPillNode, 3.4, emeraldDotPaint);
  }

  @override
  bool shouldRepaint(covariant _WorldDotMatrixMapPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
