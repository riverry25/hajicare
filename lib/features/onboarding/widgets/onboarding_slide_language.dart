import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

/// First slide of the onboarding flow: Language Selection & Welcoming.
/// Formatted with high-contrast accessibility tokens, elderly-friendly touch
/// targets (>= 56dp), and responsive layout adaptation.
class OnboardingSlideLanguage extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideLanguage({super.key, this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final colors = context.hc;
    final isDark = colors.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
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
                badgeText: context.tr('onboarding.elderlyAccess'),
                stageText: context.tr('onboardingStage1'),
                title: context.tr('onboarding.chooseLanguageTitle'),
                icon: Icons.mosque_rounded,
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
                  context.tr('onboarding.chooseLanguageDesc'),
                  style: context.text.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // 2x2 Language Grid (Adaptive Aspect Ratio & Columns)
              Obx(() {
                final currentCode = settings.currentLocale.languageCode;
                final isNarrow = constraints.maxWidth < 320;
                final crossAxisCount = isNarrow ? 1 : 2;
                final dynamicAspectRatio = isNarrow
                    ? 2.8
                    : (textScale > 1.35
                          ? 1.05
                          : (textScale > 1.15 ? 1.18 : 1.35));

                final languages = [
                  (
                    'id',
                    'Indonesia',
                    context.tr('onboarding.indonesiaSubtitle'),
                    context.tr('onboarding.mainLanguage'),
                  ),
                  (
                    'jv',
                    'Basa Jawi',
                    context.tr('onboarding.jawiSubtitle'),
                    context.tr('onboarding.regionalLanguage'),
                  ),
                  (
                    'su',
                    'Basa Sunda',
                    context.tr('onboarding.sundaSubtitle'),
                    context.tr('onboarding.regionalLanguage'),
                  ),
                  (
                    'en',
                    'English',
                    context.tr('onboarding.englishSubtitle'),
                    context.tr('onboarding.globalLanguage'),
                  ),
                ];

                return GridView.builder(
                  itemCount: languages.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: dynamicAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isSelected = currentCode == lang.$1;

                    return _buildLanguageCard(
                      context: context,
                      title: lang.$2,
                      subtitle: lang.$3,
                      type: lang.$4,
                      isSelected: isSelected,
                      onTap: () => settings.setLocale(Locale(lang.$1)),
                    );
                  },
                );
              }),

              const SizedBox(height: AppSpacing.md),

              // Audio Guide & Accessibility Hint Footer
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
                        Icons.volume_up_rounded,
                        color: colors.islamic,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('onboarding.audioGuideHint'),
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
              Icons.translate_rounded,
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
                  context.tr('onboarding.introTitle'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('onboarding.introDesc'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall.copyWith(
                    color: colors.textSecondary,
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

  Widget _buildLanguageCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.hc;
    final isDark = colors.isDark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardPadding = textScale > 1.15 ? 10.0 : 12.0;

    // Card background: Warm Sand in Selected, Neutral Surface in Unselected
    final cardBg = isSelected
        ? (isDark ? const Color(0xFF2C2016) : const Color(0xFFFBF5ED))
        : colors.surface;

    // Card border: Vivid Gold accent in Selected, BorderStrong in Unselected
    final cardBorder = isSelected
        ? (isDark ? const Color(0xFFE2C499) : const Color(0xFFB08A57))
        : colors.borderStrong;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: cardBorder,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? colors.accent.withValues(alpha: isDark ? 0.28 : 0.16)
                    : colors.shadow.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge & Radio Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.accent.withValues(alpha: 0.22)
                            : colors.surfaceSand,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelSmall.copyWith(
                          color: isSelected
                              ? colors.accentText
                              : colors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey(true),
                            color: colors.accent,
                            size: 22,
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            key: const ValueKey(false),
                            color: colors.borderStrong,
                            size: 22,
                          ),
                  ),
                ],
              ),
              const Spacer(),
              // Title
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isSelected
                      ? (isDark
                            ? const Color(0xFFFAF7F2)
                            : const Color(0xFF2A1C12))
                      : colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
