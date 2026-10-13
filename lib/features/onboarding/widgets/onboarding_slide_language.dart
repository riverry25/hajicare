import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_localizations.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import 'onboarding_hero_banner.dart';

class OnboardingSlideLanguage extends StatelessWidget {
  final int activeIndex;

  const OnboardingSlideLanguage({super.key, this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final colors = context.hc;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
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
                color: colors.surfaceSand,
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
                style: context.text.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 2x2 Language Grid
            Obx(() {
              final currentCode = settings.currentLocale.languageCode;
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final dynamicAspectRatio = textScale > 1.35
                  ? 1.05
                  : (textScale > 1.15 ? 1.18 : 1.35);

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
                  crossAxisCount: 2,
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
                color: colors.successContainer.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.success.withValues(alpha: .25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    color: colors.success,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      context.tr('onboarding.audioGuideHint'),
                      style: context.text.bodySmall.copyWith(
                        color: colors.textSecondary,
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

  Widget _buildLanguageHeader(BuildContext context) {
    final colors = context.hc;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icons.translate,
              size: 26,
              color: colors.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('onboarding.introTitle'),
                  style: context.text.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  context.tr('onboarding.introDesc'),
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

  Widget _buildLanguageCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.hc;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardPadding = textScale > 1.15 ? 12.0 : AppSpacing.cardPadding;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.12)
                  : colors.shadow,
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
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: textScale > 1.15 ? 6 : 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primaryContainer.withValues(alpha: 0.35)
                          : colors.surfaceSand,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall.copyWith(
                        color: isSelected
                            ? colors.primary
                            : colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey(true),
                          color: colors.success,
                          size: 20,
                        )
                      : Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: const ValueKey(false),
                          color: colors.borderStrong,
                          size: 20,
                        ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: context.text.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
