import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
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

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: SafeArea(
        child: Column(
          children: [
            // ============================================================
            // HEADER
            // ============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.espressoDark,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espressoDark.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: AppColors.canvasCream,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // App identity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HajiCare',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.espressoDark,
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
                            color: AppColors.tanMedium,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Skip button
                  TextButton(
                    onPressed: () => ctrl.completeOnboarding(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textBody,
                      backgroundColor: AppColors.surfaceWhite,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusPill,
                        ),
                        side: BorderSide(
                          color: AppColors.goldLight.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: Text(
                      'Lewati',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // PAGE CONTENT
            // ============================================================
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

            // ============================================================
            // BOTTOM ACTION AREA
            // ============================================================
            // ============================================================
            // BOTTOM ACTION AREA
            // ============================================================
            Obx(
              () => Container(
                width: double.infinity,
                color: AppColors.canvasCream, // sama persis dengan Scaffold
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PAGE INDICATOR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (index) {
                        final isActive = ctrl.currentPage.value == index;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 24 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.espressoDark
                                : AppColors.goldLight.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeightPrimary,
                      child: ElevatedButton(
                        onPressed: () => ctrl.nextPage(_totalPages),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.espressoDark,
                          foregroundColor: AppColors.surfaceWhite,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusPill,
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
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.surfaceWhite,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWhite.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 17,
                                color: AppColors.surfaceWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // PROGRESS INFORMATION
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 15,
                            color: AppColors.accentGoldStar,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Langkah ${ctrl.currentPage.value + 1} dari $_totalPages '
                              '• Menuju Perjalanan Aman Anda',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textBody,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
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
