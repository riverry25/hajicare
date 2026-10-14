import 'package:flutter/material.dart';
import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideSafety extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideSafety({super.key, this.activeIndex = 1});

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
                color: colors.surfaceSand,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: _buildStepper(
                context: context,
                activeIndex: activeIndex,
                label: context.tr('onboarding.stage2Of3'),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            _buildSectionHeader(context),

            const SizedBox(height: AppSpacing.lg),

            _buildFeatureCard(
              context: context,
              icon: Icons.near_me,
              title: context.tr('onboarding.safeCompanion'),
              description: context.tr('onboarding.safeCompanionDesc'),
              badgeText: context.tr('onboarding.radarActive'),
              badgeColor: colors.primary,
              badgeBgColor: colors.primaryContainer.withValues(alpha: 0.35),
            ),

            const SizedBox(height: AppSpacing.md),

            _buildFeatureCard(
              context: context,
              icon: Icons.map,
              title: context.tr('onboarding.integratedMapSos'),
              description: context.tr('onboarding.integratedMapSosDesc'),
              badgeText: context.tr('onboarding.sos24h'),
              badgeColor: colors.danger,
              badgeBgColor: colors.dangerContainer.withValues(alpha: 0.35),
              isSosBadge: true,
            ),

            const SizedBox(height: AppSpacing.md),

            _buildFeatureCard(
              context: context,
              icon: Icons.accessibility_new,
              title: context.tr('onboarding.elderlyFriendly'),
              description: context.tr('onboarding.elderlyFriendlyDesc'),
              badgeText: context.tr('onboarding.elderlyFriendly'),
              badgeColor: colors.primary,
              badgeBgColor: colors.primaryContainer.withValues(alpha: 0.35),
            ),

            const SizedBox(height: AppSpacing.xl),

            _buildSafetyFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final colors = context.hc;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSand,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_moon_outlined, color: colors.primary),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('onboarding.safetyFeaturesHeader'),
                  style: context.text.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  context.tr('onboarding.safetyFeaturesSub'),
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
                    color: isActive ? colors.primary : colors.borderStrong,
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

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
    bool isSosBadge = false,
  }) {
    final colors = context.hc;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
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
              color: isSosBadge ? colors.danger : colors.primary,
            ),
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
                    style: context.text.labelSmall.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

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

  Widget _buildSafetyFooter(BuildContext context) {
    final colors = context.hc;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.successContainer.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.success.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: colors.success, size: 22),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              context.tr('onboarding.safetyFooterNote'),
              style: context.text.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
