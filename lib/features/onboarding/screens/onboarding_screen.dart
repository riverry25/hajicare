import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_slide_accessibility.dart';
import '../widgets/onboarding_slide_language.dart';
import '../widgets/onboarding_slide_safety.dart';

/// Main Onboarding flow for HajiCare.
/// Implements responsive constraints, high-contrast typography, and
/// an elderly-friendly navigation bar adhering to Islamic White Sand & Kiswah design tokens.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const int _totalPages = 3;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    final colors = context.hc;
    final isDark = colors.isDark;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdgeGutter,
                    AppSpacing.sm,
                    AppSpacing.screenEdgeGutter,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      // Brand Logo with Golden Accent Halo
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(
                                alpha: isDark ? 0.35 : 0.08,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon.jpeg',
                            cacheWidth: 88,
                            cacheHeight: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.mosque_rounded,
                              color: colors.accent,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HajiCare',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleLarge.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              context.tr('appTagline'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Skip Action Button with High Contrast
                      TextButton(
                        onPressed: () => ctrl.completeOnboarding(),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.accentText,
                          backgroundColor: colors.surfaceSubtle,
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            side: BorderSide(
                              color: colors.borderStrong,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Text(
                          context.tr('onboarding.skip'),
                          style: context.text.bodySmall.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 0.8),

                // Page Slider (PageView)
                Expanded(
                  child: Obx(
                    () => PageView(
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
                ),

                // Bottom Action Area
                Obx(
                  () => Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.canvas,
                      border: Border(
                        top: BorderSide(color: colors.border, width: 0.8),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenEdgeGutter,
                      AppSpacing.sm,
                      AppSpacing.screenEdgeGutter,
                      AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dot Page Indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_totalPages, (index) {
                            final isActive = ctrl.currentPage.value == index;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 30 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? colors.accent
                                    : colors.borderStrong,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Primary Action Button (Next / Get Started)
                        SizedBox(
                          width: double.infinity,
                          height: AppSizes.buttonHeightPrimary,
                          child: ElevatedButton(
                            onPressed: () => ctrl.nextPage(_totalPages),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
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
                                Flexible(
                                  child: Text(
                                    ctrl.currentPage.value == 0
                                        ? context.tr('btnNextFeature')
                                        : ctrl.currentPage.value == 1
                                        ? context.tr('btnNextAccess')
                                        : context.tr('btnStartNow'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: context.text.labelLarge.copyWith(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.18,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: colors.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // Step Indicator Subtitle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 15,
                              color: colors.accent,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                context.tr('onboarding.stepProgress', {
                                  'current': ctrl.currentPage.value + 1,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
