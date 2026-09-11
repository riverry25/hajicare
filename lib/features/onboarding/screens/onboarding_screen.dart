import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_slide_accessibility.dart';
import '../widgets/onboarding_slide_language.dart';
import '../widgets/onboarding_slide_safety.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            'appTagline'.tr,
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
                    onPressed: () => Get.offAllNamed(AppRoutes.login),
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
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  OnboardingSlideLanguage(activeIndex: _currentPage),
                  OnboardingSlideSafety(activeIndex: _currentPage),
                  OnboardingSlideAccessibility(activeIndex: _currentPage),
                ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeightPrimary,
                    child: ElevatedButton(
                      onPressed: _nextPage,
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
                            _currentPage == 0
                                ? 'btnNextFeature'.tr
                                : _currentPage == 1
                                ? 'btnNextAccess'.tr
                                : 'btnStartNow'.tr,
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
                        'Langkah ${_currentPage + 1} dari 3 Menuju Perjalanan Aman Anda',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
