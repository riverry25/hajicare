import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

/// Third slide of the onboarding flow: Accessibility, Sign Language & AI Currency Scanner.
/// Designed according to UI/UX Pro Max and Architecture Best Practices
/// 60-30-10 palette using authentic HajiCare design tokens (desert gold & espresso sand
/// Overlapping WanderWise-style showcase cards (AI Currency Scanner & BISINDO Sign Language
/// Vector Islamic and accessibility icons (zero raw emoji inconsistencies
/// AAA high-contrast readability calibrated for elderly pilgrims (lansia
class OnboardingSlideAccessibility extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideAccessibility({super.key, this.activeIndex = 2});

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
          final heroHeight = isShortScreen ? 285.0 : 325.0;
          final minContentHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 0.0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdgeGutter,
              vertical: AppSpacing.xs,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minContentHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xs),

                  // 1. Visual Showcase: Overlapping Accessibility Cards
                  OnboardingHeroBanner(
                    badgeText: _trOr(
                      context,
                      'onboarding.accessSlideBadge',
                      'Aksesibilitas Ramah Lansia & Disabilitas',
                    ),
                    stageText: _trOr(context, 'onboardingStage3', 'TAHAP 3'),
                    title: _trOr(
                      context,
                      'onboarding.accessSlideTitle',
                      'Mudah Diakses Siapa Saja',
                    ),
                    icon: Icons.accessibility_new_rounded,
                    height: heroHeight,
                    child: LayoutBuilder(
                      builder: (context, bannerBox) {
                        final w = bannerBox.maxWidth;

                        // Responsive card dimensions calibrated to never overflow 320px screens
                        final cardWidth = (w * 0.58).clamp(185.0, 238.0);

                        // Center the overlapping card cluster
                        final totalClusterWidth = cardWidth * 2 - 50.0;
                        final baseLeft = ((w - totalClusterWidth) / 2).clamp(
                          6.0,
                          32.0,
                        );
                        final card1Left = baseLeft;
                        final card2Right = baseLeft;

                        final card1Top = isShortScreen ? 6.0 : 10.0;
                        final card2Top = isShortScreen ? 82.0 : 94.0;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1.1 Looping Curved Dashed Journey Path
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DashedWanderCurvePainter(
                                  isDark: isDark,
                                  pathColor: isDark
                                      ? AppColors.darkCardBorder.withValues(
                                          alpha: 0.45,
                                        )
                                      : AppColors.goldLight.withValues(
                                          alpha: 0.40,
                                        ),
                                ),
                              ),
                            ),

                            // 1.2 Floating Decorative Vector Accent Nodes
                            // Top-right: Voice / Audio assistance badge (for lansia
                            Positioned(
                              top: 8,
                              right: (card2Right + 12).clamp(12.0, w - 46),
                              child: _buildAudioAssistanceNode(isDark: isDark),
                            ),

                            // Left-middle: Ka'bah / Qibla navigation node
                            Positioned(
                              top: isShortScreen ? 95 : 110,
                              left: (card1Left - 8).clamp(4.0, 24.0),
                              child: _buildQiblaNode(isDark: isDark),
                            ),

                            // Bottom-left: Decorative gold accent ring
                            Positioned(
                              bottom: isShortScreen ? 10 : 16,
                              left: (card1Left + 22).clamp(10.0, 60.0),
                              child: _buildAccentRing(isDark: isDark),
                            ),

                            // 1.3 Back/Upper-Left Card: BISINDO Sign Language Recognition
                            Positioned(
                              top: card1Top,
                              left: card1Left,
                              width: cardWidth,
                              child: _buildSignLanguageCard(
                                context: context,
                                isDark: isDark,
                              ),
                            ),

                            // 1.4 Front/Lower-Right Card: AI Saudi Riyal Currency Scanner
                            Positioned(
                              top: card2Top,
                              right: card2Right,
                              width: cardWidth,
                              child: _buildCurrencyScannerCard(
                                context: context,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 2. Editorial Headline & Narrative Description
                  Text(
                    _trOr(
                      context,
                      'onboarding.accessSlideTitle',
                      'Mudah Diakses Siapa Saja',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: isShortScreen ? 25.0 : 28.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.18,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      _trOr(
                        context,
                        'onboarding.accessIntro',
                        'Bantuan pintar deteksi uang riyal serta komunikasi suara dan isyarat untuk kemudahan jamaah lansia dan berkebutuhan khusus.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13.5,
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

  // Frosted Glassmorphism Card Container Helper
  Widget _buildGlassCard({
    required bool isDark,
    required Widget child,
    Color? borderColor,
    Color? glowColor,
    double blur = 14.0,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 11,
      vertical: 10,
    ),
  }) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    final border =
        borderColor ??
        (isDark
            ? AppColors.darkCardBorder.withValues(alpha: 0.85)
            : AppColors.outlineVariant.withValues(alpha: 0.90));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.darkSurface.withValues(alpha: 0.92),
                      AppColors.darkSurfaceContainer.withValues(alpha: 0.82),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      AppColors.surface.withValues(alpha: 0.88),
                    ],
            ),
            border: Border.all(color: border, width: 1.0),
            boxShadow: [
              if (glowColor != null)
                BoxShadow(
                  color: glowColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              BoxShadow(
                color: AppColors.espressoDark.withValues(
                  alpha: isDark ? 0.35 : 0.08,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  static String _trOr(BuildContext context, String key, String fallback) {
    final val = context.tr(key);
    return (val == key || val.isEmpty) ? fallback : val;
  }

  // Card 1: BISINDO Sign Language Recognition
  Widget _buildSignLanguageCard({
    required BuildContext context,
    required bool isDark,
  }) {
    return _buildGlassCard(
      isDark: isDark,
      borderColor: AppColors.emeraldIslamic.withValues(
        alpha: isDark ? 0.40 : 0.55,
      ),
      glowColor: AppColors.emeraldIslamic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Sign Language + BISINDO live pill
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.emeraldDark.withValues(alpha: 0.7)
                      : AppColors.emeraldLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sign_language_rounded,
                  size: 13,
                  color: AppColors.emeraldIslamic,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _trOr(
                    context,
                    'onboarding.signLanguageTitle',
                    'Bahasa Isyarat',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Live BISINDO Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.emeraldDark
                      : AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.emeraldIslamic.withValues(alpha: 0.40),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.emeraldIslamic,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      _trOr(context, 'onboarding.signLanguageBadge', 'BISINDO'),
                      style: const TextStyle(
                        color: AppColors.emeraldIslamic,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Divider(
            height: 1,
            thickness: 0.8,
            color:
                (isDark ? AppColors.darkCardBorder : AppColors.outlineVariant)
                    .withValues(alpha: 0.65),
          ),
          const SizedBox(height: 6),

          // 3 Dynamic Localized Phrases (Terima Kasih, Bantuan Medis, Arah Kiblat
          _buildPhraseItem(
            icon: Icons.volunteer_activism_rounded,
            iconColor: AppColors.emeraldIslamic,
            bgColor: isDark
                ? AppColors.emeraldDark.withValues(alpha: 0.65)
                : AppColors.emeraldLight,
            title: _trOr(
              context,
              'onboarding.signPhraseThanks',
              'Terima Kasih',
            ),
            sub: _trOr(
              context,
              'onboarding.signSubThanks',
              'Syukran • Respon AI Cepat',
            ),
            subColor: AppColors.emeraldIslamic,
            isDark: isDark,
          ),
          const SizedBox(height: 4.5),
          _buildPhraseItem(
            icon: Icons.medical_services_rounded,
            iconColor: AppColors.sosEmergency,
            bgColor: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.errorContainer,
            title: _trOr(
              context,
              'onboarding.signPhraseMedical',
              'Bantuan Medis',
            ),
            sub: _trOr(
              context,
              'onboarding.signSubMedical',
              'Darurat Posko Sehat',
            ),
            subColor: AppColors.sosEmergency,
            isDark: isDark,
          ),
          const SizedBox(height: 4.5),
          _buildPhraseItem(
            icon: Icons.explore_rounded,
            iconColor: AppColors.goldPrimary,
            bgColor: isDark
                ? AppColors.darkPrimaryContainer
                : AppColors.primaryContainer,
            title: _trOr(context, 'onboarding.signPhraseQibla', 'Arah Kiblat'),
            sub: _trOr(
              context,
              'onboarding.signSubQibla',
              "Navigasi Ka'bah & Masjid",
            ),
            subColor: isDark ? AppColors.goldLight : AppColors.goldPrimary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Card 2: AI Saudi Riyal Banknote Scanner
  Widget _buildCurrencyScannerCard({
    required BuildContext context,
    required bool isDark,
  }) {
    return _buildGlassCard(
      isDark: isDark,
      borderColor: AppColors.goldPrimary.withValues(
        alpha: isDark ? 0.50 : 0.70,
      ),
      glowColor: AppColors.goldPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Vector Banknote & AI SCANNER Badge (Required by test expectations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Vector Banknote with AI Viewfinder Reticle
              SizedBox(
                width: 48,
                height: 28,
                child: CustomPaint(
                  painter: _SaudiRiyalBanknotePainter(
                    isDark: isDark,
                    primaryGreen: AppColors.emeraldIslamic,
                    goldAccent: AppColors.goldPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // AI SCANNER Badge (Unit test expectation preserved
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.80),
                      width: 0.8,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _trOr(context, 'onboarding.aiScannerBadge', 'AI SCANNER'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.goldPrimary,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // Title & Precision subtitle (Dynamic localized with ellipsis & fallback
          Text(
            _trOr(context, 'onboarding.currencyName', '100 Riyal (SAR)'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
              fontSize: 13.0,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 11,
                color: AppColors.emeraldIslamic,
              ),
              const SizedBox(width: 3.5),
              Expanded(
                child: Text(
                  _trOr(
                    context,
                    'onboarding.currencySubtitle',
                    'Presisi AI Vision 99.4%',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.emeraldIslamic,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Divider(
            height: 1,
            thickness: 0.8,
            color:
                (isDark ? AppColors.darkCardBorder : AppColors.outlineVariant)
                    .withValues(alpha: 0.65),
          ),
          const SizedBox(height: 5),

          // Bottom Conversion Row (Padded container with high contrast
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _trOr(
                      context,
                      'onboarding.currencyEstimate',
                      'Estimasi Kurs IDR',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextBody
                          : AppColors.textSecondary,
                      fontSize: 9.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _trOr(
                        context,
                        'onboarding.currencyValue',
                        '≈ Rp 430.000',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.goldPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhraseItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String sub,
    required Color subColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subColor,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Floating Decorative Accents (Clean Vector Motifs
  Widget _buildAudioAssistanceNode({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.record_voice_over_rounded,
            size: 13,
            color: AppColors.goldPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            'Audio',
            style: TextStyle(
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaNode({required bool isDark}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.explore_rounded,
          size: 15,
          color: AppColors.goldPrimary,
        ),
      ),
    );
  }

  Widget _buildAccentRing({required bool isDark}) {
    return Container(
      width: 14,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.7),
          width: 1.3,
        ),
      ),
    );
  }
}

// Native Vector Painter: Saudi Riyal 100 SAR Banknote
class _SaudiRiyalBanknotePainter extends CustomPainter {
  final bool isDark;
  final Color primaryGreen;
  final Color goldAccent;

  _SaudiRiyalBanknotePainter({
    required this.isDark,
    required this.primaryGreen,
    required this.goldAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Banknote Fill
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.5, 3.5, size.width - 7, size.height - 7),
      const Radius.circular(4),
    );
    final bgPaint = Paint()
      ..color = isDark ? AppColors.emeraldDark : AppColors.emeraldLight
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, bgPaint);

    // 2. Banknote Inner Border
    final innerBorderPaint = Paint()
      ..color = primaryGreen.withValues(alpha: isDark ? 0.40 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5.5, 5.5, size.width - 11, size.height - 11),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(innerRect, innerBorderPaint);

    // 3. Central Islamic Star / Rosette Motif
    final center = Offset(size.width * 0.48, size.height * 0.5);
    final starPaint = Paint()
      ..color = goldAccent.withValues(alpha: isDark ? 0.35 : 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final radius = size.height * 0.22;
    canvas.drawCircle(center, radius, starPaint);

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      starPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      starPaint,
    );

    // 4. "100" and "SAR" text stamp
    final textPainter = TextPainter(
      text: TextSpan(
        text: '100',
        style: TextStyle(
          color: primaryGreen,
          fontSize: 8.0,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(7.0, size.height * 0.5 - 5.0));

    final sarPainter = TextPainter(
      text: TextSpan(
        text: 'SAR',
        style: TextStyle(
          color: goldAccent,
          fontSize: 6.0,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    sarPainter.paint(
      canvas,
      Offset(size.width - 20.0, size.height * 0.5 - 3.8),
    );

    // 5. Four AI Camera Viewfinder Reticle Corners (Gold L-brackets
    final reticlePaint = Paint()
      ..color = goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const cornerLen = 4.5;
    // Top-left
    canvas.drawLine(
      const Offset(0.8, 0.8 + cornerLen),
      const Offset(0.8, 0.8),
      reticlePaint,
    );
    canvas.drawLine(
      const Offset(0.8, 0.8),
      Offset(0.8 + cornerLen, 0.8),
      reticlePaint,
    );
    // Top-right
    canvas.drawLine(
      Offset(size.width - 0.8 - cornerLen, 0.8),
      Offset(size.width - 0.8, 0.8),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(size.width - 0.8, 0.8),
      Offset(size.width - 0.8, 0.8 + cornerLen),
      reticlePaint,
    );
    // Bottom-left
    canvas.drawLine(
      Offset(0.8, size.height - 0.8 - cornerLen),
      Offset(0.8, size.height - 0.8),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(0.8, size.height - 0.8),
      Offset(0.8 + cornerLen, size.height - 0.8),
      reticlePaint,
    );
    // Bottom-right
    canvas.drawLine(
      Offset(size.width - 0.8 - cornerLen, size.height - 0.8),
      Offset(size.width - 0.8, size.height - 0.8),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(size.width - 0.8, size.height - 0.8 - cornerLen),
      Offset(size.width - 0.8, size.height - 0.8),
      reticlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SaudiRiyalBanknotePainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.primaryGreen != primaryGreen ||
      oldDelegate.goldAccent != goldAccent;
}

// Native Vector Painter: Looping Dashed Journey Path
class _DashedWanderCurvePainter extends CustomPainter {
  final bool isDark;
  final Color pathColor;

  _DashedWanderCurvePainter({required this.isDark, required this.pathColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.08, h * 0.22)
      ..cubicTo(w * 0.35, h * 0.06, w * 0.70, h * 0.12, w * 0.85, h * 0.28)
      ..cubicTo(w * 0.98, h * 0.45, w * 0.75, h * 0.70, w * 0.55, h * 0.72)
      ..cubicTo(w * 0.30, h * 0.74, w * 0.10, h * 0.60, w * 0.18, h * 0.88);

    final paint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 5.0;
      const dashGap = 4.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(distance, next);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedWanderCurvePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.pathColor != pathColor;
}
