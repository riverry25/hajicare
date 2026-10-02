import '../../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideLanguage extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideLanguage({super.key, this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final isDark = AppColors.isDark(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : AppColors.goldLight.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingHeroBanner(
              badgeText: context.tr('onboarding.elderlyAccess'),
              stageText: context.tr('onboardingStage1'),
              title: context.tr('onboarding.chooseLanguageTitle'),
              icon: Icons.mosque,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Stepper indicator
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.canvasCream.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _buildStepper(
                context: context,
                activeIndex: activeIndex,
                label: context.tr('onboarding.stage1Of3'),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Section intro header
            _buildLanguageHeader(context),

            const SizedBox(height: AppSpacing.lg),

            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text(
                context.tr('onboarding.chooseLanguageDesc'),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textBodyColor(context),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 2x2 Language Grid
            Obx(() {
              final currentCode = settings.currentLocale.languageCode;

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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.35,
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
                    onTap: () {
                      settings.setLocale(Locale(lang.$1));
                    },
                  );
                },
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // Accessibility hint footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.statusPositive.withValues(alpha: .15)
                    : AppColors.statusPositive.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? AppColors.statusPositive.withValues(alpha: .3)
                      : AppColors.statusPositive.withValues(alpha: .15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    color: isDark
                        ? AppColors.statusSafe
                        : AppColors.statusPositive,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      context.tr('onboarding.audioGuideHint'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textBodyColor(context),
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
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
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
                        ? (isDark
                              ? AppColors.accentGoldStar
                              : AppColors.espressoDark)
                        : (isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.outlineVariant),
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
              style: AppTypography.captionSmall.copyWith(
                color: isDark ? AppColors.darkTextBody : AppColors.tanMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageHeader(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.canvasCream.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerHighest
                  : AppColors.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.translate,
              size: 26,
              color: isDark ? AppColors.darkPrimary : AppColors.espressoDark,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('onboarding.introTitle'),
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadingColor(context),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  context.tr('onboarding.introDesc'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryColor(context),
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
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.primaryContainer)
                : AppColors.cardBorderColor(context),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? (isDark
                        ? AppColors.darkPrimary.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.08))
                  : (isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.03)),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? AppColors.goldPrimary.withValues(alpha: 0.25)
                              : AppColors.goldPrimary.withValues(alpha: 0.15))
                        : (isDark
                              ? AppColors.darkSurfaceContainerHighest
                              : AppColors.canvasCream),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    type,
                    style: AppTypography.captionSmall.copyWith(
                      color: isSelected
                          ? (isDark
                                ? AppColors.accentGoldStar
                                : AppColors.espressoDark)
                          : AppColors.textBodyColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey(true),
                          color: AppColors.statusSafe,
                          size: 22,
                        )
                      : Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: const ValueKey(false),
                          color: isDark
                              ? AppColors.darkOutline
                              : AppColors.tanMedium,
                          size: 22,
                        ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textHeadingColor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
