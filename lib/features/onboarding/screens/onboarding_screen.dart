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
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.espressoDark,
                        ),
                        child: const Icon(
                          Icons.mosque,
                          color: AppColors.canvasCream,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HajiCare',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.tr('appTagline'),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.tanMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Skip button
                  TextButton(
                    onPressed: () => Get.offNamed('/login'),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceWhite,
                      minimumSize: const Size(48, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm2,
                      ),
                      side: BorderSide(
                        color: AppColors.goldLight.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: Text(
                      'Lewati',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel Slides
            Expanded(
              child: Obx(
                () => PageView(
                  controller: ctrl.pageController,
                  onPageChanged: ctrl.changePage,
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

            // Bottom CTA Tray
            Container(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.goldLight.withValues(alpha: 0.2),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeightPrimary,
                      child: ElevatedButton(
                        onPressed: () => ctrl.nextPage(_totalPages),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.espressoDark,
                          foregroundColor: AppColors.surfaceWhite,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusPill,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ctrl.currentPage.value == 0
                                  ? context.tr('btnNextFeature')
                                  : ctrl.currentPage.value == 1
                                  ? context.tr('btnNextAccess')
                                  : context.tr('btnStartNow'),
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.surfaceWhite,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          size: 14,
                          color: AppColors.accentGoldStar,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Langkah ${ctrl.currentPage.value + 1} dari 3 Menuju Perjalanan Aman Anda',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textBody,
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
