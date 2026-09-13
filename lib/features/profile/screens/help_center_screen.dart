import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../controllers/help_center_controller.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HelpCenterController());
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: headingColor),
          onPressed: () => Get.back(),
          tooltip: context.tr('back'),
        ),
        title: Text(
          context.tr('helpCenterTitle'),
          style: AppTypography.headlineMd.copyWith(color: headingColor),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header section with search
          Container(
            color: scaffoldBg,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('helpCenterSubtitle'),
                  style: AppTypography.bodyMedium.copyWith(color: bodyColor),
                ),
                const SizedBox(height: AppSpacing.md),
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                    ),
                  ),
                  child: TextField(
                    onChanged: controller.updateSearch,
                    style: AppTypography.bodyMedium.copyWith(color: headingColor),
                    decoration: InputDecoration(
                      hintText: context.tr('searchHelp'),
                      hintStyle: AppTypography.bodyMedium.copyWith(color: bodyColor),
                      prefixIcon: Icon(Icons.search_rounded, color: bodyColor),
                      suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: bodyColor, size: 18),
                              onPressed: controller.clearSearch,
                            )
                          : const SizedBox.shrink()),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge,
              ),
              children: [
                // Categories section
                Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _CategoriesSection(
                    cardBg: cardBg,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    isDark: isDark,
                  );
                }),

                // FAQ section
                _FaqSection(
                  controller: controller,
                  cardBg: cardBg,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  isDark: isDark,
                ),

                const SizedBox(height: AppSpacing.gapSection),

                // Contact support
                Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) return const SizedBox.shrink();
                  return _ContactSupportSection(
                    cardBg: cardBg,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    isDark: isDark,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Categories Section
// ────────────────────────────────────────────────────────────────────────────

class _CategoriesSection extends StatelessWidget {
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _CategoriesSection({
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      (Icons.person_outline_rounded, 'catAccountProfile', 'catAccountProfileDesc', AppColors.primary),
      (Icons.people_outline_rounded, 'catCompanion', 'catCompanionDesc', AppColors.secondary),
      (Icons.apps_rounded, 'catFeatures', 'catFeaturesDesc', AppColors.tanMedium),
      (Icons.accessibility_new_rounded, 'catAccessibility', 'catAccessibilityDesc', AppColors.accentGoldStar),
      (Icons.translate_rounded, 'catLanguage', 'catLanguageDesc', AppColors.statusSafe),
      (Icons.build_rounded, 'catTechnical', 'catTechnicalDesc', AppColors.statusDanger),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Text(
            context.tr('helpCategoriesTitle'),
            style: AppTypography.labelPill.copyWith(color: bodyColor),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(
              color: isDark ? AppColors.darkOutlineVariant : AppColors.canvasCreamSubtle,
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < categories.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.xl + AppSizes.touchTargetMin,
                    color: isDark ? AppColors.darkOutlineVariant : AppColors.canvasCreamSubtle,
                  ),
                _CategoryTile(
                  icon: categories[i].$1,
                  titleKey: categories[i].$2,
                  descKey: categories[i].$3,
                  iconColor: categories[i].$4,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gapSection),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final Color iconColor;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _CategoryTile({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.iconColor,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(titleKey),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: AppSizes.touchTargetMin,
                height: AppSizes.touchTargetMin,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(titleKey),
                      style: AppTypography.bodyLarge.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(descKey),
                      style: AppTypography.bodySmall.copyWith(color: bodyColor),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkOutline : AppColors.tanMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// FAQ Section
// ────────────────────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  final HelpCenterController controller;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _FaqSection({
    required this.controller,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final allFaqs = [
      ('faqQ1', 'faqA1'),
      ('faqQ2', 'faqA2'),
      ('faqQ3', 'faqA3'),
      ('faqQ4', 'faqA4'),
      ('faqQ5', 'faqA5'),
      ('faqQ6', 'faqA6'),
      ('faqQ7', 'faqA7'),
      ('faqQ8', 'faqA8'),
      ('faqQ9', 'faqA9'),
      ('faqQ10', 'faqA10'),
      ('faqQ11', 'faqA11'),
      ('faqQ12', 'faqA12'),
    ];

    return Obx(() {
      final query = controller.searchQuery.value;

      final filtered = allFaqs.where((faq) {
        if (query.isEmpty) return true;
        final q = context.tr(faq.$1).toLowerCase();
        final a = context.tr(faq.$2).toLowerCase();
        return q.contains(query) || a.contains(query);
      }).toList();

      if (filtered.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: bodyColor),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tidak ada hasil yang ditemukan',
                  style: AppTypography.bodyMedium.copyWith(color: bodyColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
            child: Text(
              context.tr('faqTitle'),
              style: AppTypography.labelPill.copyWith(color: bodyColor),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              border: Border.all(
                color: isDark ? AppColors.darkOutlineVariant : AppColors.canvasCreamSubtle,
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                      color: isDark ? AppColors.darkOutlineVariant : AppColors.canvasCreamSubtle,
                    ),
                  _FaqItem(
                    index: allFaqs.indexOf(filtered[i]),
                    questionKey: filtered[i].$1,
                    answerKey: filtered[i].$2,
                    controller: controller,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _FaqItem extends StatelessWidget {
  final int index;
  final String questionKey;
  final String answerKey;
  final HelpCenterController controller;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _FaqItem({
    required this.index,
    required this.questionKey,
    required this.answerKey,
    required this.controller,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expanded = controller.isExpanded(index);
      final activeColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;

      return Semantics(
        button: true,
        expanded: expanded,
        label: context.tr(questionKey),
        child: InkWell(
          onTap: () => controller.toggleFaq(index),
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(questionKey),
                        style: AppTypography.bodyLarge.copyWith(
                          color: expanded ? activeColor : headingColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: expanded ? activeColor : bodyColor,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      context.tr(answerKey),
                      style: AppTypography.bodyMedium.copyWith(color: bodyColor),
                    ),
                  ),
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Contact Support Section
// ────────────────────────────────────────────────────────────────────────────

class _ContactSupportSection extends StatelessWidget {
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _ContactSupportSection({
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : AppColors.canvasCreamSubtle,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent_rounded,
            size: AppSizes.iconXl,
            color: activeColor,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('contactSupportTitle'),
            style: AppTypography.titleLarge.copyWith(color: headingColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('contactSupportSubtitle'),
            style: AppTypography.bodyMedium.copyWith(color: bodyColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.email_outlined,
                  label: context.tr('contactEmail'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ContactButton(
                  icon: Icons.chat_outlined,
                  label: context.tr('contactWhatsApp'),
                  isDark: isDark,
                  isPrimary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: _ContactButton(
              icon: Icons.bug_report_outlined,
              label: context.tr('reportProblem'),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isPrimary;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;
    final bgColor = isPrimary
        ? activeColor
        : (isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream);
    final fgColor = isPrimary
        ? (isDark ? AppColors.darkOnPrimary : AppColors.surfaceWhite)
        : activeColor;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          Get.snackbar(
            'Info',
            ' — ',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fgColor, size: AppSizes.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(color: fgColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
