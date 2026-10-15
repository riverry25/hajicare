import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

/// First slide of the onboarding flow: Language Selection & Warm Welcoming.
/// Implements a stacked destination-card layout inspired by WanderWise,
/// featuring a subtle curved dashed route in the background and dynamic card
/// expansion/elevation when selected, preserving real-time multi-language switching.
class OnboardingSlideLanguage extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideLanguage({super.key, this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final colors = context.hc;
    final isDark = colors.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isShortScreen = constraints.maxHeight < 680;
        final heroHeight = isShortScreen ? 315.0 : 345.0;
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

                // ── 1. Visual Showcase: WanderWise Stacked Language Cards ──
                OnboardingHeroBanner(
                  badgeText: context.tr('onboarding.elderlyAccess'),
                  stageText: context.tr('onboardingStage1'),
                  title: context.tr('onboarding.chooseLanguageTitle'),
                  icon: Icons.language_rounded,
                  height: heroHeight,
                  child: Stack(
                    children: [
                      // Subtle curved dashed path in the background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CurvedDashedPathPainter(
                            color: isDark
                                ? colors.accent.withValues(alpha: 0.22)
                                : const Color(
                                    0xFFD4B896,
                                  ).withValues(alpha: 0.45),
                          ),
                        ),
                      ),

                      // Foreground Interactive Showcase
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            // Top Frosted Welcome Pill (Ahlan wa Sahlan)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? colors.surface.withValues(alpha: 0.85)
                                    : Colors.white.withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: colors.accent.withValues(
                                    alpha: isDark ? 0.40 : 0.60,
                                  ),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.shadow.withValues(
                                      alpha: isDark ? 0.20 : 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🕋',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Ahlan wa Sahlan',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 4 Stacked Language Destination Cards
                            Expanded(
                              child: Obx(() {
                                final currentCode =
                                    settings.currentLocale.languageCode;

                                final languages = [
                                  _LanguageItemData(
                                    code: 'id',
                                    title: 'Indonesia',
                                    subtitle: context.tr(
                                      'onboarding.indonesiaSubtitle',
                                    ),
                                    flag: '🇮🇩',
                                    rating: '4.9 (98%)',
                                    lightGrad: const [
                                      Color(0xFFFFEBEE),
                                      Color(0xFFFFCDD2),
                                    ],
                                    darkGrad: const [
                                      Color(0xFF4A181A),
                                      Color(0xFF2C1012),
                                    ],
                                  ),
                                  _LanguageItemData(
                                    code: 'jv',
                                    title: 'Basa Jawi',
                                    subtitle: context.tr(
                                      'onboarding.jawiSubtitle',
                                    ),
                                    flag: '🕌',
                                    rating: '4.8 (Krama)',
                                    lightGrad: const [
                                      Color(0xFFFFF8E1),
                                      Color(0xFFFFECB3),
                                    ],
                                    darkGrad: const [
                                      Color(0xFF423214),
                                      Color(0xFF241A08),
                                    ],
                                  ),
                                  _LanguageItemData(
                                    code: 'su',
                                    title: 'Basa Sunda',
                                    subtitle: context.tr(
                                      'onboarding.sundaSubtitle',
                                    ),
                                    flag: '🌿',
                                    rating: '4.8 (Lemes)',
                                    lightGrad: const [
                                      Color(0xFFE8F5E9),
                                      Color(0xFFC8E6C9),
                                    ],
                                    darkGrad: const [
                                      Color(0xFF143B22),
                                      Color(0xFF0C2415),
                                    ],
                                  ),
                                  _LanguageItemData(
                                    code: 'en',
                                    title: 'English',
                                    subtitle: context.tr(
                                      'onboarding.englishSubtitle',
                                    ),
                                    flag: '🇬🇧',
                                    rating: '4.9 (Global)',
                                    lightGrad: const [
                                      Color(0xFFE3F2FD),
                                      Color(0xFFBBDEFB),
                                    ],
                                    darkGrad: const [
                                      Color(0xFF132B45),
                                      Color(0xFF0A1828),
                                    ],
                                  ),
                                ];

                                return Column(
                                  children: languages.map((item) {
                                    final isSelected = currentCode == item.code;

                                    return Expanded(
                                      flex: isSelected ? 6 : 4,
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.025 : 0.985,
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: isSelected ? 3.0 : 2.0,
                                          ),
                                          child: _buildWanderWiseCard(
                                            context: context,
                                            item: item,
                                            isSelected: isSelected,
                                            isDark: isDark,
                                            onSelect: () {
                                              HapticFeedback.selectionClick();
                                              settings.setLocale(
                                                Locale(item.code),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── 2. Editorial Headline & Narrative Description ──────
                Text(
                  context.tr('onboarding.chooseLanguageTitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: isShortScreen ? 26.0 : 29.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.18,
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    context.tr('onboarding.chooseLanguageDesc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
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
  }

  Widget _buildWanderWiseCard({
    required BuildContext context,
    required _LanguageItemData item,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onSelect,
  }) {
    final colors = context.hc;

    // Active accent styling inspired by WanderWise (warm orange/accent button & red heart)
    const activeAccentColor = Color(0xFFFF7A3D);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 12 : 10,
            vertical: isSelected ? 6.0 : 4.0,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? colors.surface.withValues(alpha: 0.95)
                      : Colors.white)
                : (isDark
                      ? colors.surface.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.82)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? (isDark ? colors.accent : const Color(0xFFFF9E58))
                  : (isDark
                        ? colors.border.withValues(alpha: 0.5)
                        : colors.border.withValues(alpha: 0.7)),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: isDark
                          ? colors.accent.withValues(alpha: 0.28)
                          : activeAccentColor.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: colors.shadow.withValues(
                        alpha: isDark ? 0.30 : 0.08,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colors.shadow.withValues(
                        alpha: isDark ? 0.15 : 0.04,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // ── Left: WanderWise Destination-style Photo/Flag Thumbnail ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isSelected ? 42 : 36,
                    height: isSelected ? 42 : 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark ? item.darkGrad : item.lightGrad,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? colors.accent.withValues(
                                alpha: isDark ? 0.6 : 0.4,
                              )
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.flag,
                      style: TextStyle(fontSize: isSelected ? 18 : 15),
                    ),
                  ),

                  // Red map pin on focused card (exact match to Central Market KL in WanderWise)
                  if (isSelected)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x40E53935),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 10),

              // ── Middle: Language Name, Subtitle & Rating Tag ───────────
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title (ensured non-null color & full opacity for WCAG & tests)
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: isSelected ? 13.5 : 12.0,
                          height: 1.15,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1.5),

                      // Subtitle
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: isSelected ? 10.0 : 9.0,
                          height: 1.15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2.0),

                      // Status / Rating badge (⭐ 4.8 (80) style)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 11.5,
                            color: Color(0xFFFFA000),
                          ),
                          const SizedBox(width: 2.5),
                          Text(
                            item.rating,
                            style: TextStyle(
                              color: colors.textPrimary.withValues(alpha: 0.82),
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ── Right: Action Buttons (Heart + Round Action Button) ───
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Favorite Heart Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 28 : 24,
                    height: isSelected ? 28 : 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(
                              0xFFFFECEB,
                            ).withValues(alpha: isDark ? 0.22 : 0.85)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE53935).withValues(alpha: 0.4)
                            : (isDark
                                  ? colors.border.withValues(alpha: 0.5)
                                  : colors.border.withValues(alpha: 0.7)),
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isSelected
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: isSelected ? 14 : 12.5,
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : colors.textSecondary.withValues(alpha: 0.55),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 2. Main Circular Action Button (Active Glowing vs Inactive Outline)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 28 : 24,
                    height: isSelected ? 28 : 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF8E53), Color(0xFFFF6A28)],
                            )
                          : null,
                      color: isSelected ? null : Colors.transparent,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? colors.border.withValues(alpha: 0.5)
                                  : colors.border.withValues(alpha: 0.7),
                              width: 1.0,
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: activeAccentColor.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isSelected
                          ? Icons.check_rounded
                          : Icons.arrow_outward_rounded,
                      size: isSelected ? 15 : 12.5,
                      color: isSelected
                          ? Colors.white
                          : colors.textSecondary.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data container for WanderWise-styled language options.
class _LanguageItemData {
  final String code;
  final String title;
  final String subtitle;
  final String flag;
  final String rating;
  final List<Color> lightGrad;
  final List<Color> darkGrad;

  const _LanguageItemData({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.rating,
    required this.lightGrad,
    required this.darkGrad,
  });
}

/// Draws an elegant, smooth S-curved dashed travel route behind the cards
/// matching the WanderWise reference design.
class _CurvedDashedPathPainter extends CustomPainter {
  final Color color;

  const _CurvedDashedPathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.12, size.height * 0.08);
    path.cubicTo(
      size.width * 0.88,
      size.height * 0.05,
      size.width * 0.94,
      size.height * 0.36,
      size.width * 0.50,
      size.height * 0.44,
    );
    path.cubicTo(
      size.width * 0.06,
      size.height * 0.52,
      size.width * 0.04,
      size.height * 0.78,
      size.width * 0.54,
      size.height * 0.88,
    );
    path.cubicTo(
      size.width * 0.84,
      size.height * 0.94,
      size.width * 0.92,
      size.height * 0.97,
      size.width * 0.95,
      size.height * 0.98,
    );

    _drawDashedPath(canvas, path, paint, dashWidth: 5.0, dashSpace: 4.5);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double dashWidth,
    required double dashSpace,
  }) {
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedDashedPathPainter oldDelegate) =>
      oldDelegate.color != color;
}
