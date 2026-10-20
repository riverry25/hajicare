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
/// Implements a stacked destination-card layout inspired by WanderWise
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

    return Obx(() {
      final currentCode = settings.currentLocale.languageCode;

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

                  // 1. Visual Showcase: WanderWise Stacked Language Cards
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
                                  : colors.borderStrong.withValues(alpha: 0.45),
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
                              // Top Frosted Welcome Pill (Ahlan wa Sahlan
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
                                    Icon(
                                      Icons.explore_rounded,
                                      size: 13,
                                      color: colors.accent,
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
                                child: Builder(
                                  builder: (context) {
                                    final languages = [
                                      _LanguageItemData(
                                        code: 'id',
                                        title: 'Indonesia',
                                        subtitle: context.tr(
                                          'onboarding.indonesiaSubtitle',
                                        ),
                                        flag: '🇮🇩',
                                      ),
                                      _LanguageItemData(
                                        code: 'jv',
                                        title: 'Basa Jawi',
                                        subtitle: context.tr(
                                          'onboarding.jawiSubtitle',
                                        ),
                                        flag: '🕌',
                                      ),
                                      _LanguageItemData(
                                        code: 'su',
                                        title: 'Basa Sunda',
                                        subtitle: context.tr(
                                          'onboarding.sundaSubtitle',
                                        ),
                                        flag: '🌿',
                                      ),
                                      _LanguageItemData(
                                        code: 'en',
                                        title: 'English',
                                        subtitle: context.tr(
                                          'onboarding.englishSubtitle',
                                        ),
                                        flag: '🇬🇧',
                                      ),
                                    ];

                                    return Column(
                                      children: languages.map((item) {
                                        final isSelected =
                                            currentCode == item.code;

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
                                                vertical: isSelected
                                                    ? 3.0
                                                    : 2.0,
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
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 2. Editorial Headline & Narrative Description
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
    });
  }

  Widget _buildWanderWiseCard({
    required BuildContext context,
    required _LanguageItemData item,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onSelect,
  }) {
    final colors = context.hc;

    // Strict alignment with HajiColors (ThemeExtension
    // In Light Mode: Signature rich espresso (colors.primary) provides high-contrast, premium, non-orange selection.
    // In Dark Mode: Warm desert amber/gold (colors.accent) glows softly against charcoal surfaces.
    final selectedColor = isDark ? colors.accent : colors.primary;
    final onSelectedColor = isDark ? colors.canvas : colors.onPrimary;

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
                      : colors.surface)
                : (isDark
                      ? colors.surface.withValues(alpha: 0.55)
                      : colors.surface.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? selectedColor
                  : (isDark
                        ? colors.border.withValues(alpha: 0.5)
                        : colors.border.withValues(alpha: 0.7)),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    // Cohesive theme glow matching HajiColors primary / accent (zero neon orange
                    BoxShadow(
                      color: selectedColor.withValues(
                        alpha: isDark ? 0.28 : 0.14,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
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
              // Left: Unified Flag Thumbnail (Cohesive HajiCare Palette
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isSelected ? 42 : 36,
                height: isSelected ? 42 : 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? (isSelected
                              ? [colors.primaryContainer, colors.surfaceSubtle]
                              : [colors.surfaceSubtle, colors.surface])
                        : (isSelected
                              ? [colors.primaryContainer, colors.surfaceSand]
                              : [colors.surfaceSubtle, colors.surface]),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                              ? colors.accent.withValues(alpha: 0.6)
                              : colors.borderStrong)
                        : colors.border.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.flag,
                  style: TextStyle(fontSize: isSelected ? 18 : 15),
                ),
              ),

              const SizedBox(width: 10),

              // Middle: Language Name & Subtitle
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(height: 2.0),

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
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Right: Clean Selection Indicator (Cohesive Theme Radio/Check
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 26 : 22,
                height: isSelected ? 26 : 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? selectedColor : Colors.transparent,
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark
                              ? colors.border.withValues(alpha: 0.5)
                              : colors.border.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.30),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: onSelectedColor,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data container for language options in Slide 1.
class _LanguageItemData {
  final String code;
  final String title;
  final String subtitle;
  final String flag;

  const _LanguageItemData({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.flag,
  });
}

/// Draws an elegant, smooth S-curved dashed travel route behind the cards
/// matching the WanderWisedesign.
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
