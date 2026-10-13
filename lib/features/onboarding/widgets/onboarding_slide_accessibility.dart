import 'package:flutter/material.dart';
import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideAccessibility extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideAccessibility({super.key, this.activeIndex = 2});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
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
                color: colors.surfaceSand,
                borderRadius: BorderRadius.circular(18),
              ),
              child: _buildStepper(
                context: context,
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
              style: context.text.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Feature Card 1: Scan Uang Riyal
            _buildSlide3FeatureCard(
              context: context,
              icon: Icons.payments_outlined,
              title: context.tr('onboarding.scanRiyal'),
              description: context.tr('onboarding.scanRiyalDesc'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Feature Card 2: Komunikasi & Isyarat
            _buildSlide3FeatureCard(
              context: context,
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
                color: colors.successContainer.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.success.withValues(alpha: .25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    color: colors.success,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      context.tr('onboarding.ttsReady'),
                      style: context.text.bodySmall.copyWith(
                        color: colors.textSecondary,
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

  Widget _buildStepper({
    required BuildContext context,
    required int activeIndex,
    required String label,
  }) {
    final colors = context.hc;

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
                        ? colors.primary
                        : colors.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: context.text.labelSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityHeader(BuildContext context) {
    final colors = context.hc;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceSand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.accessibility_new,
              size: 28,
              color: colors.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('onboarding.accessFeaturesHeader'),
                  style: context.text.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  context.tr('onboarding.accessFeaturesSub'),
                  style: context.text.bodySmall.copyWith(
                    color: colors.textSecondary,
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    String? badgeText,
  }) {
    final colors = context.hc;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
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
              color: colors.surfaceSand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 28,
              color: colors.primary,
            ),
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
                      color: colors.surfaceSand,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      badgeText,
                      style: context.text.labelSmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),

                if (badgeText != null) const SizedBox(height: 10),

                Text(
                  title,
                  style: context.text.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: context.text.bodySmall.copyWith(
                    color: colors.textSecondary,
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
