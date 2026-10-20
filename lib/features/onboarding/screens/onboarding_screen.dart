import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/state/app_settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_slide_accessibility.dart';
import '../widgets/onboarding_slide_language.dart';
import '../widgets/onboarding_slide_safety.dart';

/// Main Onboarding flow for HajiCare.
/// Implements a refined, WanderWise-inspired layout
/// Symmetrical top header with centered brand logo and minimal "Lewati" action
/// Story-style 3-segment progress indicator dynamically tracking drag gestures
/// Immersive, centered visual showcase per slide
/// Centered, comfortable primary pill action button at the bottom
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const int _totalPages = 3;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    final settings = Get.find<AppSettingsController>();
    final colors = context.hc;
    final isDark = colors.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.canvasCream,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.darkScaffold,
                    const Color(0xFF1E1712),
                    AppColors.darkScaffold,
                  ]
                : [
                    const Color(0xFFFDFBF7),
                    const Color(0xFFF7F1E7),
                    const Color(0xFFEFE6D7),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                children: [
                  // 1. Top Brand Bar & Minimalist "Lewati" (WanderWise style
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenEdgeGutter,
                      AppSpacing.xs,
                      AppSpacing.screenEdgeGutter,
                      AppSpacing.xs,
                    ),
                    child: SizedBox(
                      height: 40,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Centered HajiCare Logo & Wordmark
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.accent.withValues(alpha: 0.6),
                                    width: 1.0,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icon.jpeg',
                                    cacheWidth: 48,
                                    cacheHeight: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.mosque_rounded,
                                          color: colors.accent,
                                          size: 14,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'HajiCare',
                                style: context.text.titleMedium.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.5,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),

                          // Minimalist, elegant "Lewati" action button in top-right
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => ctrl.completeOnboarding(),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.textSecondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(48, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Obx(() {
                                final _ = settings.rxLocale.value;
                                return Text(
                                  context.tr('onboarding.skip'),
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Dynamic 3-Segment Progress Indicator (Scroll Tracking
                  AnimatedBuilder(
                    animation: ctrl.pageController,
                    builder: (context, _) {
                      double page = 0.0;
                      if (ctrl.pageController.hasClients &&
                          ctrl.pageController.position.haveDimensions) {
                        page =
                            ctrl.pageController.page ??
                            ctrl.currentPage.value.toDouble();
                      } else {
                        page = ctrl.currentPage.value.toDouble();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenEdgeGutter,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: List.generate(_totalPages, (index) {
                            // Calculate dynamic fill fraction for segment (0.0 to 1.0
                            final double fill;
                            if (index == 0) {
                              fill = 1.0;
                            } else {
                              fill = (page - (index - 1)).clamp(0.0, 1.0);
                            }

                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                  right: index < _totalPages - 1 ? 6 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colors.border.withValues(alpha: 0.35)
                                      : const Color(0xFFE5DDD0),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: fill,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? colors.accent
                                          : colors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),

                  // 3. Page Slider (PageView with Visual Showcase
                  Expanded(
                    child: PageView(
                      controller: ctrl.pageController,
                      onPageChanged: ctrl.changePage,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        OnboardingSlideLanguage(
                          activeIndex: ctrl.currentPage.value,
                        ),
                        OnboardingSlideSafety(
                          activeIndex: ctrl.currentPage.value,
                        ),
                        OnboardingSlideAccessibility(
                          activeIndex: ctrl.currentPage.value,
                        ),
                      ],
                    ),
                  ),

                  // 4. Bottom Controls: Single Centered Primary CTA Button
                  Obx(() {
                    final _ = settings.rxLocale.value;
                    final page = ctrl.currentPage.value;
                    final isLastPage = page == _totalPages - 1;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenEdgeGutter,
                        AppSpacing.sm,
                        AppSpacing.screenEdgeGutter,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Centered Primary Action Button (Compact & Elegant like WanderWise
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 240,
                                maxWidth: 290,
                              ),
                              child: SizedBox(
                                height: 52,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    ctrl.nextPage(_totalPages);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.espressoDark,
                                    foregroundColor: isDark
                                        ? AppColors.darkOnPrimary
                                        : Colors.white,
                                    elevation: isDark ? 0 : 3,
                                    shadowColor: AppColors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isLastPage
                                            ? context.tr('btnStartNow')
                                            : context.tr('common.next'),
                                        style: context.text.labelLarge.copyWith(
                                          color: isDark
                                              ? AppColors.darkOnPrimary
                                              : Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16.0,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isLastPage
                                            ? Icons.check_circle_rounded
                                            : Icons.arrow_forward_rounded,
                                        size: 19,
                                        color: isDark
                                            ? AppColors.darkOnPrimary
                                            : Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // Subtle Trust & Stage Footnote
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 14,
                                color: colors.accent,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  context.tr('onboarding.stepProgress', {
                                    'current': page + 1,
                                    'total': _totalPages,
                                  }),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: context.text.bodySmall.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
