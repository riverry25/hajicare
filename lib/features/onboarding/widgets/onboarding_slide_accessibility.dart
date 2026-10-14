import 'package:flutter/material.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

/// Third slide of the onboarding flow: Accessibility, Riyal Scanner & Communication.
/// Designed for elderly pilgrims and individuals with special accessibility needs.
class OnboardingSlideAccessibility extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideAccessibility({super.key, this.activeIndex = 2});

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
                badgeText: context.tr('onboarding.accessSlideBadge'),
                stageText: context.tr('onboardingStage3'),
                title: context.tr('onboarding.accessSlideTitle'),
                icon: Icons.accessibility_new_rounded,
                height: heroHeight,
              ),

              const SizedBox(height: AppSpacing.md),

              // Section Header
              _buildSectionHeader(context),

              const SizedBox(height: AppSpacing.sm),

              // Explanatory Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  context.tr('onboarding.accessIntro'),
                  style: context.text.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Feature Card 1: Scan Uang Riyal (Currency Scanner)
              _buildFeatureCard(
                context: context,
                icon: Icons.payments_rounded,
                title: context.tr('onboarding.scanRiyal'),
                description: context.tr('onboarding.scanRiyalDesc'),
                badgeText: 'AI SCANNER',
                badgeBgColor: isDark
                    ? const Color(0xFF3B2A18)
                    : const Color(0xFFFBF4E8),
                badgeTextColor: isDark
                    ? const Color(0xFFE3B266)
                    : const Color(0xFF8B541C),
                iconBgColor: isDark
                    ? const Color(0xFF3B2A18)
                    : const Color(0xFFFBF4E8),
                iconColor: isDark
                    ? const Color(0xFFE2C499)
                    : const Color(0xFF966228),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Feature Card 2: Communication & Gestures
              _buildFeatureCard(
                context: context,
                icon: Icons.record_voice_over_rounded,
                title: context.tr('onboarding.commGestures'),
                description: context.tr('onboarding.commGesturesDesc'),
                badgeText: context.tr('onboarding.voiceAndText'),
                badgeBgColor: isDark
                    ? const Color(0xFF1B303E)
                    : const Color(0xFFE8F3FA),
                badgeTextColor: isDark
                    ? const Color(0xFF93B8CF)
                    : const Color(0xFF275573),
                iconBgColor: isDark
                    ? const Color(0xFF1B303E)
                    : const Color(0xFFE8F3FA),
                iconColor: isDark
                    ? const Color(0xFF93B8CF)
                    : const Color(0xFF355E77),
              ),

              const SizedBox(height: AppSpacing.md),

              // Accessibility Readiness Footer
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
                        Icons.record_voice_over_rounded,
                        color: colors.islamic,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('onboarding.ttsReady'),
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
              color: colors.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.40),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
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
                  context.tr('onboarding.accessFeaturesHeader'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('onboarding.accessFeaturesSub'),
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
