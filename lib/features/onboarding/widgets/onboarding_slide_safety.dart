import 'package:flutter/material.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

/// Second slide of the onboarding flow: Safety, Radar Rombongan & SOS.
/// High-contrast visual tokens, lansia-friendly typography, and responsive scrolling.
class OnboardingSlideSafety extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideSafety({super.key, this.activeIndex = 1});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final isDark = colors.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isShortScreen = constraints.maxHeight < 680;
        final heroHeight = isShortScreen ? 148.0 : 175.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner with Kaaba Velvet & Gold Trim
              OnboardingHeroBanner(
                badgeText: context.tr('onboarding.safetySystemBadge'),
                stageText: context.tr('onboardingStage2'),
                title: context.tr('onboarding.safetySlideTitle'),
                icon: Icons.shield_rounded,
                height: heroHeight,
              ),

              const SizedBox(height: AppSpacing.md),

              // Section Header
              _buildSectionHeader(context),

              const SizedBox(height: AppSpacing.md),

              // Feature Card 1: Radar Rombongan (Companion)
              _buildFeatureCard(
                context: context,
                icon: Icons.radar_rounded,
                title: context.tr('onboarding.safeCompanion'),
                description: context.tr('onboarding.safeCompanionDesc'),
                badgeText: context.tr('onboarding.radarActive'),
                badgeBgColor: isDark
                    ? const Color(0xFF1B3526)
                    : const Color(0xFFE5F5EB),
                badgeTextColor: isDark
                    ? const Color(0xFF8DBF9C)
                    : const Color(0xFF225E39),
                iconBgColor: isDark
                    ? const Color(0xFF1F382A)
                    : const Color(0xFFEBF7F0),
                iconColor: isDark
                    ? const Color(0xFF8DBF9C)
                    : const Color(0xFF2E6B44),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Feature Card 2: Integrated Map & SOS 24 Jam
              _buildFeatureCard(
                context: context,
                icon: Icons.emergency_rounded,
                title: context.tr('onboarding.integratedMapSos'),
                description: context.tr('onboarding.integratedMapSosDesc'),
                badgeText: context.tr('onboarding.sos24h'),
                badgeBgColor: isDark
                    ? const Color(0xFF4A231D)
                    : const Color(0xFFFBECE9),
                badgeTextColor: isDark
                    ? const Color(0xFFE58A7C)
                    : const Color(0xFF9E2C1A),
                iconBgColor: isDark
                    ? const Color(0xFF4A231D)
                    : const Color(0xFFFBECE9),
                iconColor: isDark
                    ? const Color(0xFFE58A7C)
                    : const Color(0xFFB3412F),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Feature Card 3: Elderly-Friendly (Ramah Lansia)
              _buildFeatureCard(
                context: context,
                icon: Icons.health_and_safety_rounded,
                title: context.tr('onboarding.elderlyFriendly'),
                description: context.tr('onboarding.elderlyFriendlyDesc'),
                badgeText: context.tr('onboarding.elderlyFriendly'),
                badgeBgColor: isDark
                    ? const Color(0xFF3B2A18)
                    : const Color(0xFFFBF4E8),
                badgeTextColor: isDark
                    ? const Color(0xFFE3B266)
                    : const Color(0xFF7A4A19),
                iconBgColor: isDark
                    ? const Color(0xFF3B2A18)
                    : const Color(0xFFFBF4E8),
                iconColor: isDark
                    ? const Color(0xFFE2C499)
                    : const Color(0xFF966228),
              ),

              const SizedBox(height: AppSpacing.md),

              // Safety Assurance Note Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2B20)
                      : const Color(0xFFEFF7F1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E543B)
                        : const Color(0xFFBCE3CA),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.islamic.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user_rounded,
                        color: colors.islamic,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('onboarding.safetyFooterNote'),
                        style: context.text.bodySmall.copyWith(
                          color: isDark
                              ? const Color(0xFFE2F0E7)
                              : const Color(0xFF1E462F),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final colors = context.hc;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.40),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.security_rounded,
              size: 22,
              color: colors.accentText,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('onboarding.safetyFeaturesHeader'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('onboarding.safetyFeaturesSub'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
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
    required Color badgeBgColor,
    required Color badgeTextColor,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final colors = context.hc;
    final isDark = colors.isDark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        badgeText.toUpperCase(),
                        style: context.text.labelSmall.copyWith(
                          color: badgeTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: context.text.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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
