import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

/// Third slide of the onboarding flow: Accessibility, Sign Language & AI Currency Scanner.
/// Showcases WanderWise-inspired overlapping preview cards with premium frosted glassmorphism:
/// 1. Top/Upper-Left Card: BISINDO Sign Language Recognition with live gesture phrases (Dynamic localized).
/// 2. Front/Lower-Right Card: AI Saudi Riyal Banknote Scanner with viewfinder reticle & IDR conversion.
/// 3. Looping curved dashed journey background path with floating decorative nodes.
class OnboardingSlideAccessibility extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideAccessibility({super.key, this.activeIndex = 2});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final isDark = colors.isDark;

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

                // ── 1. Visual Showcase: WanderWise-style Overlapping Glass Cards ──
                OnboardingHeroBanner(
                  badgeText: _trOr(
                    context,
                    'onboarding.accessSlideBadge',
                    'Akses Ramah Jamaah',
                  ),
                  stageText: _trOr(context, 'onboardingStage3', 'TAHAP 3'),
                  title: _trOr(
                    context,
                    'onboarding.accessSlideTitle',
                    'Ramah Disabilitas & Lansia',
                  ),
                  icon: Icons.accessibility_new_rounded,
                  height: heroHeight,
                  child: LayoutBuilder(
                    builder: (context, bannerBox) {
                      final w = bannerBox.maxWidth;

                      // Responsive card dimensions calibrated to never overflow 320px screens
                      final card1Width = (w * 0.58).clamp(185.0, 235.0);
                      final card2Width = (w * 0.58).clamp(185.0, 235.0);

                      // Center the overlapping card cluster
                      final totalClusterWidth = card1Width + card2Width - 50.0;
                      final baseLeft = ((w - totalClusterWidth) / 2).clamp(
                        6.0,
                        32.0,
                      );
                      final card1Left = baseLeft;
                      final card2Right = baseLeft;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1.1 Looping Curved Dashed Journey Path (WanderWise reference)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DashedWanderCurvePainter(
                                isDark: isDark,
                                pathColor: isDark
                                    ? AppColors.darkOutline.withValues(
                                        alpha: 0.35,
                                      )
                                    : AppColors.tanLight.withValues(
                                        alpha: 0.45,
                                      ),
                              ),
                            ),
                          ),

                          // 1.2 Floating Decorative Accent Nodes
                          // Top-right pilgrim avatar badge with micro dot cluster
                          Positioned(
                            top: 8,
                            right: (card2Right + 12).clamp(14.0, w - 50),
                            child: _buildAvatarNode(isDark: isDark),
                          ),

                          // Left-middle circular Ka'bah / camera lens node
                          Positioned(
                            top: isShortScreen ? 95 : 110,
                            left: (card1Left - 10).clamp(4.0, 24.0),
                            child: _buildCircularThumbnailNode(
                              isDark: isDark,
                              colors: colors,
                            ),
                          ),

                          // Floating accent ring at bottom-left
                          Positioned(
                            bottom: isShortScreen ? 10 : 16,
                            left: (card1Left + 24).clamp(10.0, 60.0),
                            child: _buildAccentRing(isDark: isDark),
                          ),

                          // 1.3 Back/Upper-Left Card: BISINDO Sign Language Recognition (ON TOP)
                          Positioned(
                            top: isShortScreen ? 6 : 10,
                            left: card1Left,
                            width: card1Width,
                            child: _buildSignLanguageCard(
                              context: context,
                              isDark: isDark,
                              colors: colors,
                              isShortScreen: isShortScreen,
                            ),
                          ),

                          // 1.4 Front/Lower-Right Card: AI Saudi Riyal Currency Scanner (ON BOTTOM, OVERLAPPING)
                          Positioned(
                            top: isShortScreen ? 82 : 94,
                            right: card2Right,
                            width: card2Width,
                            child: _buildCurrencyScannerCard(
                              context: context,
                              isDark: isDark,
                              colors: colors,
                              isShortScreen: isShortScreen,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── 2. Editorial Headline & Narrative Description ──────
                Text(
                  _trOr(
                    context,
                    'onboarding.accessSlideTitle',
                    'Ramah Disabilitas & Lansia',
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
  }

  // ── Frosted Glassmorphism Card Container Helper ────────────────────────────
  Widget _buildGlassCard({
    required bool isDark,
    required Widget child,
    double blur = 14.0,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 11,
      vertical: 10,
    ),
  }) {
    final radius = borderRadius ?? BorderRadius.circular(18);
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
                      AppColors.darkSurface.withValues(alpha: 0.86),
                      AppColors.darkSurfaceContainer.withValues(alpha: 0.72),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.90),
                      AppColors.surface.withValues(alpha: 0.76),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorderSubtle.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.95),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.espressoDark.withValues(
                  alpha: isDark ? 0.40 : 0.08,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: (isDark ? AppColors.darkPrimary : AppColors.goldPrimary)
                    .withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
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

  // ── Card 1: BISINDO Sign Language Recognition (Positioned at Top-Left) ─────
  Widget _buildSignLanguageCard({
    required BuildContext context,
    required bool isDark,
    required dynamic colors,
    required bool isShortScreen,
  }) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Sign Language + BISINDO live pill
          Row(
            children: [
              const Icon(
                Icons.sign_language_rounded,
                size: 14,
                color: AppColors.emeraldIslamic,
              ),
              const SizedBox(width: 5),
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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.emeraldDark
                        : AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.emeraldIslamic.withValues(alpha: 0.35),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: const BoxDecoration(
                          color: AppColors.emeraldIslamic,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _trOr(
                              context,
                              'onboarding.signLanguageBadge',
                              'BISINDO',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.emeraldIslamic,
                              fontSize: 8.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Divider(
            height: 1,
            thickness: 0.8,
            color: (isDark ? AppColors.darkOutline : AppColors.outlineVariant)
                .withValues(alpha: 0.45),
          ),
          const SizedBox(height: 6),

          // 3 Dynamic Localized Phrases (Terima Kasih, Bantuan Medis, Arah Kiblat)
          _buildPhraseItem(
            icon: Icons.volunteer_activism_rounded,
            iconColor: AppColors.emeraldIslamic,
            bgColor: isDark
                ? AppColors.emeraldDark.withValues(alpha: 0.6)
                : AppColors.emeraldLight,
            title: _trOr(
              context,
              'onboarding.signPhraseThanks',
              'Terima Kasih',
            ),
            sub: _trOr(
              context,
              'onboarding.signSubThanks',
              'Syukran • Syukron',
            ),
            subColor: AppColors.emeraldIslamic,
            isDark: isDark,
          ),
          const SizedBox(height: 5),
          _buildPhraseItem(
            icon: Icons.medical_services_rounded,
            iconColor: AppColors.sosEmergency,
            bgColor: isDark
                ? const Color(0xFF381B17)
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
          const SizedBox(height: 5),
          _buildPhraseItem(
            icon: Icons.explore_rounded,
            iconColor: AppColors.goldPrimary,
            bgColor: isDark ? const Color(0xFF3D2E1A) : const Color(0xFFFEF3DE),
            title: _trOr(context, 'onboarding.signPhraseQibla', 'Arah Kiblat'),
            sub: _trOr(context, 'onboarding.signSubQibla', "Navigasi Ka'bah"),
            subColor: isDark ? AppColors.darkPrimary : AppColors.goldPrimary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Card 2: AI Currency Scanner (Positioned at Lower-Right, Overlapping) ───
  Widget _buildCurrencyScannerCard({
    required BuildContext context,
    required bool isDark,
    required dynamic colors,
    required bool isShortScreen,
  }) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Vector Banknote & AI SCANNER Badge (Constrained with Flexible & FittedBox)
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
              // AI SCANNER Badge (Required by unit tests, protected against overflow)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4A3414)
                        : const Color(0xFFFEF3DE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.goldPrimary,
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

          const SizedBox(height: 8),

          // Title & Precision subtitle (Dynamic localized with ellipsis & fallback)
          Text(
            _trOr(context, 'onboarding.currencyName', '100 Riyal (SAR)'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
              fontSize: 13.0,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _trOr(
              context,
              'onboarding.currencySubtitle',
              'Presisi AI Vision 99.4%',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.emeraldIslamic,
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),
          Divider(
            height: 1,
            thickness: 0.8,
            color: (isDark ? AppColors.darkOutline : AppColors.outlineVariant)
                .withValues(alpha: 0.45),
          ),
          const SizedBox(height: 5),

          // Bottom Conversion Row (Dynamic localized & scaled safely)
          Row(
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
                    _trOr(context, 'onboarding.currencyValue', '≈ Rp 430.000'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.goldPrimary,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
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
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: iconColor),
        ),
        const SizedBox(width: 7),
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

  // ── Floating Decorative Accents (WanderWise reference) ──────────────────────
  Widget _buildAvatarNode({required bool isDark}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkSurfaceContainerHigh : Colors.white,
            border: Border.all(
              color: AppColors.goldPrimary.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text('🧕', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 4),
        // Mini cluster dots
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.goldPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 3.5,
              height: 3.5,
              decoration: const BoxDecoration(
                color: AppColors.emeraldIslamic,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularThumbnailNode({
    required bool isDark,
    required dynamic colors,
  }) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Center(child: Text('🕋', style: TextStyle(fontSize: 13))),
    );
  }

  Widget _buildAccentRing({required bool isDark}) {
    return Container(
      width: 13,
      height: 7,
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

// ── Native Vector Painter: Saudi Riyal 100 SAR Banknote ──────────────────────
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
      ..color = isDark ? const Color(0xFF1B3024) : const Color(0xFFE4EFE7)
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

    // 5. Four AI Camera Viewfinder Reticle Corners (Gold L-brackets)
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

// ── Native Vector Painter: Looping Dashed Journey Path ───────────────────────
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
