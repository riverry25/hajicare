import '../../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideAccessibility extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideAccessibility({super.key, this.activeIndex = 2});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingHeroBanner(
              badgeText: context.tr('onboarding.accessSlideBadge'),
              stageText: context.tr('onboardingStage3'),
              title: context.tr('onboarding.accessSlideTitle'),
              icon: Icons.accessibility_new,
              height: 180,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Stepper
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.canvasCream.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _buildStepper(
                activeIndex: activeIndex,
                label: context.tr('onboarding.stage3Of3'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section intro header
            _buildAccessibilityHeader(context),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('onboarding.accessIntro'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Feature Card 1: Scan Uang Riyal
            _buildSlide3FeatureCard(
              icon: Icons.payments_outlined,
              title: context.tr('onboarding.scanRiyal'),
              description: context.tr('onboarding.scanRiyalDesc'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Feature Card 2: Komunikasi & Isyarat
            _buildSlide3FeatureCard(
              icon: Icons.mic_outlined,
              title: context.tr('onboarding.commGestures'),
              description: context.tr('onboarding.commGesturesDesc'),
              badgeText: context.tr('onboarding.voiceAndText'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Checklist indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusPositive.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.statusPositive.withValues(alpha: .15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.record_voice_over_rounded,
                    color: AppColors.statusPositive,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      context.tr('onboarding.ttsReady'),
                      style: AppTypography.bodySmall.copyWith(
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
    );
  }

  Widget _buildStepper({required int activeIndex, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = activeIndex == index;
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 32 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.espressoDark
                        : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              );
            }),
          ),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.tanMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.canvasCream.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.accessibility_new,
              size: 28,
              color: AppColors.primaryContainer,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('onboarding.accessFeaturesHeader'),
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.espressoDark.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  context.tr('onboarding.accessFeaturesSub'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.espressoDark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide3FeatureCard({
    required IconData icon,
    required String title,
    required String description,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: .25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.canvasCream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: AppColors.primaryContainer),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(badgeText, style: AppTypography.captionSmall),
                  ),

                if (badgeText != null) const SizedBox(height: 10),

                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.espressoDark.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.espressoDark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
