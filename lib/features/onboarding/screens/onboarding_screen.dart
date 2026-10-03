import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/locales/app_localizations.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_slide_accessibility.dart';
import '../widgets/onboarding_slide_language.dart';
import '../widgets/onboarding_slide_safety.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const int _totalPages = 3;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenEdgeGutter,
                AppSpacing.md,
                AppSpacing.screenEdgeGutter,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.espressoDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.goldPrimary.withValues(
                          alpha: isDark ? 0.7 : 0.5,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : AppColors.espressoDark.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icon.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.mosque_rounded,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.canvasCream,
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
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textHeadingColor(context),
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('appTagline'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextBody
                                : AppColors.tanMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Skip Action Button
                  TextButton(
                    onPressed: () => ctrl.completeOnboarding(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textBodyColor(context),
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceContainerHigh
                          : AppColors.surfaceWhite,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        side: BorderSide(
                          color: AppColors.cardBorderColor(context),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Text(
                      context.tr('onboarding.skip'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textBodyColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page Slider
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
                    OnboardingSlideSafety(activeIndex: ctrl.currentPage.value),
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
                color: AppColors.scaffoldColor(context),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenEdgeGutter,
                  AppSpacing.sm,
                  AppSpacing.screenEdgeGutter,
                  AppSpacing.lg,
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
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark
                                      ? AppColors.accentGoldStar
                                      : AppColors.espressoDark)
                                : (isDark
                                      ? AppColors.darkOutlineVariant
                                      : AppColors.goldMuted.withValues(
                                          alpha: 0.5,
                                        )),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Primary CTA
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeightPrimary,
                      child: ElevatedButton(
                        onPressed: () => ctrl.nextPage(_totalPages),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primaryContainer,
                          foregroundColor: isDark
                              ? AppColors.darkOnPrimary
                              : AppColors.surfaceWhite,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
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
                                style: AppTypography.labelLarge.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnPrimary
                                      : AppColors.surfaceWhite,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkOnPrimary.withValues(
                                        alpha: 0.15,
                                      )
                                    : Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkOnPrimary
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Step indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 15,
                          color: isDark
                              ? AppColors.accentGoldStar
                              : AppColors.goldPrimary,
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
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textBodyColor(context),
                              fontWeight: FontWeight.w600,
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
    );
  }
}
