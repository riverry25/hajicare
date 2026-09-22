import '../../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideSafety extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideSafety({super.key, this.activeIndex = 1});

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
              badgeText: context.tr('onboarding.safetySystemBadge'),
              stageText: context.tr('onboardingStage2'),
              title: context.tr('onboarding.safetySlideTitle'),
              icon: Icons.shield,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Stepper Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.canvasCream.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: _buildStepper(
                activeIndex: activeIndex,
                label: context.tr('onboarding.stage2Of3'),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            _buildSectionHeader(context),

            const SizedBox(height: AppSpacing.lg),

            _buildFeatureCard(
              icon: Icons.near_me,
              title: context.tr('onboarding.safeCompanion'),
              description: context.tr('onboarding.safeCompanionDesc'),
              badgeText: context.tr('onboarding.radarActive'),
              badgeColor: AppColors.espressoDark,
              badgeBgColor: AppColors.canvasCream,
            ),

            const SizedBox(height: AppSpacing.md),

            _buildFeatureCard(
              icon: Icons.map,
              title: context.tr('onboarding.integratedMapSos'),
              description: context.tr('onboarding.integratedMapSosDesc'),
              badgeText: context.tr('onboarding.sos24h'),
              badgeColor: AppColors.sosEmergency,
              badgeBgColor: AppColors.sosEmergency.withValues(alpha: .08),
              isSosBadge: true,
            ),

            const SizedBox(height: AppSpacing.md),

            _buildFeatureCard(
              icon: Icons.accessibility_new,
              title: context.tr('onboarding.elderlyFriendly'),
              description: context.tr('onboarding.elderlyFriendlyDesc'),
              badgeText: context.tr('onboarding.elderlyFriendly'),
              badgeColor: AppColors.espressoDark,
              badgeBgColor: AppColors.canvasCream,
            ),

            const SizedBox(height: AppSpacing.xl),

            _buildSafetyFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasCream.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_moon_outlined,
              color: AppColors.espressoDark,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('onboarding.safetyFeaturesHeader'),
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.espressoDark.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  context.tr('onboarding.safetyFeaturesSub'),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
    bool isSosBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: .25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 20,
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
            child: Icon(icon, size: 28, color: AppColors.espressoDark),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTypography.captionSmall.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.espressoDark.withValues(alpha: 0.7),
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

  Widget _buildSafetyFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusPositive.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.statusPositive.withValues(alpha: .15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user,
            color: AppColors.statusPositive,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              context.tr('onboarding.safetyFooterNote'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.espressoDark.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
