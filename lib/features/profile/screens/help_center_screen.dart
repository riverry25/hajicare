import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/help_center_controller.dart';
import '../services/profile_support_service.dart';

class HelpCenterScreen extends StatelessWidget {
  final ProfileSupportService? supportService;

  const HelpCenterScreen({super.key, this.supportService});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HelpCenterController>();
    final colors = context.hc;
    final support = supportService ?? ProfileSupportService();

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Get.back(),
          tooltip: context.tr('back'),
        ),
        title: Text(
          context.tr('helpCenterTitle'),
          style: context.text.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header section with search
          Container(
            color: colors.canvas,
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 728),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('helpCenterSubtitle'),
                    style: context.text.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: colors.border),
                    ),
                    child: TextField(
                      controller: controller.searchTextController,
                      onChanged: controller.updateSearch,
                      textInputAction: TextInputAction.search,
                      style: context.text.bodyMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr('searchHelp'),
                        hintStyle: context.text.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colors.textSecondary,
                        ),
                        suffixIcon: Obx(
                          () => controller.searchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: colors.textSecondary,
                                    size: 18,
                                  ),
                                  onPressed: controller.clearSearch,
                                )
                              : const SizedBox.shrink(),
                        ),
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
          ),

          // Scrollable content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.huge,
                  ),
                  children: [
                    // Categories section
                    Obx(() {
                      if (controller.searchQuery.value.isNotEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _CategoriesSection(
                        controller: controller,
                        colors: colors,
                      );
                    }),

                    // FAQ section
                    _FaqSection(controller: controller, colors: colors),

                    const SizedBox(height: AppSpacing.gapSection),

                    // Contact support
                    Obx(() {
                      if (controller.searchQuery.value.isNotEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _ContactSupportSection(
                        supportService: support,
                        colors: colors,
                      );
                    }),
                  ],
                ),
              ),
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
  final HelpCenterController controller;
  final HajiColors colors;

  const _CategoriesSection({required this.controller, required this.colors});

  @override
  Widget build(BuildContext context) {
    final categories = [
      (
        'account',
        Icons.person_outline_rounded,
        'catAccountProfile',
        'catAccountProfileDesc',
        colors.primary,
      ),
      (
        'companion',
        Icons.people_outline_rounded,
        'catCompanion',
        'catCompanionDesc',
        colors.accent,
      ),
      (
        'features',
        Icons.apps_rounded,
        'catFeatures',
        'catFeaturesDesc',
        colors.primary,
      ),
      (
        'accessibility',
        Icons.accessibility_new_rounded,
        'catAccessibility',
        'catAccessibilityDesc',
        colors.success,
      ),
      (
        'language',
        Icons.translate_rounded,
        'catLanguage',
        'catLanguageDesc',
        colors.info,
      ),
      (
        'technical',
        Icons.build_rounded,
        'catTechnical',
        'catTechnicalDesc',
        colors.danger,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            context.tr('helpCategoriesTitle'),
            style: context.text.labelSmall.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: colors.border),
          ),
          child: Obx(() {
            final activeCategory = controller.selectedCategory.value;
            return Column(
              children: [
                for (int i = 0; i < categories.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpacing.xl + AppSizes.touchTargetMin,
                      color: colors.border,
                    ),
                  _CategoryTile(
                    key: ValueKey(categories[i].$1),
                    icon: categories[i].$2,
                    titleKey: categories[i].$3,
                    descKey: categories[i].$4,
                    iconColor: categories[i].$5,
                    colors: colors,
                    isSelected: activeCategory == categories[i].$1,
                    onTap: () => controller.selectCategory(categories[i].$1),
                  ),
                ],
              ],
            );
          }),
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
  final HajiColors colors;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.iconColor,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: context.tr(titleKey),
      child: InkWell(
        onTap: onTap,
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
                  color: iconColor.withValues(alpha: 0.12),
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
                      style: context.text.bodyLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(descKey),
                      style: context.text.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: isSelected ? 0.25 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isSelected ? iconColor : colors.borderStrong,
                ),
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
  final HajiColors colors;

  const _FaqSection({required this.controller, required this.colors});

  @override
  Widget build(BuildContext context) {
    final allFaqs = [
      ('faqQ1', 'faqA1', 'account'),
      ('faqQ2', 'faqA2', 'account'),
      ('faqQ3', 'faqA3', 'account'),
      ('faqQ4', 'faqA4', 'account'),
      ('faqQ5', 'faqA5', 'accessibility'),
      ('faqQ6', 'faqA6', 'accessibility'),
      ('faqQ7', 'faqA7', 'language'),
      ('faqQ8', 'faqA8', 'companion'),
      ('faqQ9', 'faqA9', 'companion'),
      ('faqQ10', 'faqA10', 'features'),
      ('faqQ11', 'faqA11', 'technical'),
      ('faqQ12', 'faqA12', 'technical'),
    ];

    return Obx(() {
      final query = controller.searchQuery.value;
      final selectedCategory = controller.selectedCategory.value;

      final filtered = allFaqs.where((faq) {
        if (query.isEmpty) {
          return selectedCategory == null || faq.$3 == selectedCategory;
        }
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
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Belum ada jawaban yang sesuai',
                  style: context.text.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: query.isNotEmpty
                      ? controller.clearSearch
                      : controller.clearCategory,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tampilkan semua bantuan'),
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
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    query.isNotEmpty
                        ? 'Hasil Pencarian (${filtered.length})'
                        : context.tr('faqTitle'),
                    style: context.text.labelSmall.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selectedCategory != null)
                  TextButton.icon(
                    key: const Key('clear_help_category'),
                    onPressed: controller.clearCategory,
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Semua'),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                      color: colors.border,
                    ),
                  _FaqItem(
                    key: ValueKey(filtered[i].$1),
                    index: allFaqs.indexOf(filtered[i]),
                    questionKey: filtered[i].$1,
                    answerKey: filtered[i].$2,
                    controller: controller,
                    colors: colors,
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
  final HajiColors colors;

  const _FaqItem({
    super.key,
    required this.index,
    required this.questionKey,
    required this.answerKey,
    required this.controller,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expanded = controller.isExpanded(index);
      final activeColor = colors.primary;

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
                        style: context.text.bodyLarge.copyWith(
                          color: expanded ? activeColor : colors.textPrimary,
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
                        color: expanded ? activeColor : colors.textSecondary,
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
                      style: context.text.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
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
  final ProfileSupportService supportService;
  final HajiColors colors;

  const _ContactSupportSection({
    required this.supportService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent_rounded,
            size: AppSizes.iconXl,
            color: colors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('contactSupportTitle'),
            style: context.text.titleLarge.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('contactSupportSubtitle'),
            style: context.text.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions =
                  constraints.maxWidth < 360 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.25;
              final buttons = <Widget>[
                if (supportService.hasSupportEmail)
                  _ContactButton(
                    key: const Key('support_email_button'),
                    icon: Icons.email_outlined,
                    label: context.tr('contactEmail'),
                    colors: colors,
                    isPrimary: true,
                    onTap: () => _openEmail(context),
                  ),
                if (supportService.hasSupportWhatsApp)
                  _ContactButton(
                    key: const Key('support_whatsapp_button'),
                    icon: Icons.chat_outlined,
                    label: context.tr('contactWhatsApp'),
                    colors: colors,
                    onTap: () => _openWhatsApp(context),
                  ),
              ];
              if (buttons.isEmpty) {
                return Text(
                  'Untuk bantuan langsung, hubungi pendamping rombongan Anda.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                );
              }
              if (stackActions || buttons.length == 1) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int index = 0; index < buttons.length; index++) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.sm),
                      buttons[index],
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (int index = 0; index < buttons.length; index++) ...[
                    if (index > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: buttons[index]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: _ContactButton(
              key: const Key('report_problem_button'),
              icon: Icons.bug_report_outlined,
              label: context.tr('reportProblem'),
              colors: colors,
              onTap: () => _openEmail(context, reportProblem: true),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEmail(
    BuildContext context, {
    bool reportProblem = false,
  }) async {
    final opened = await supportService.openEmail(
      reportProblem: reportProblem,
      platformLabel: kIsWeb ? 'Web' : defaultTargetPlatform.name,
    );
    if (!context.mounted || opened) return;

    if (supportService.hasSupportEmail) {
      await Clipboard.setData(ClipboardData(text: supportService.supportEmail));
      if (!context.mounted) return;
      AppAlert.info(
        context,
        title: context.tr('help.emailCopied'),
        message:
            'Aplikasi email belum dapat dibuka. Alamat ${supportService.supportEmail} sudah disalin dan siap ditempel.',
        okText: 'Mengerti',
      );
      return;
    }

    AppAlert.warning(
      context,
      title: context.tr('help.contactUnavailable'),
      message: 'Silakan minta bantuan pendamping rombongan Anda.',
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final opened = await supportService.openWhatsApp();
    if (!context.mounted || opened) return;

    await Clipboard.setData(
      ClipboardData(text: supportService.supportWhatsAppDigits),
    );
    if (!context.mounted) return;
    AppAlert.info(
      context,
      title: context.tr('help.waCopied'),
      message:
          'WhatsApp belum dapat dibuka. Nomor dukungan sudah disalin dan siap ditempel.',
      okText: 'Mengerti',
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final HajiColors colors;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ContactButton({
    super.key,
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? colors.primary : colors.surfaceSand;
    final fgColor = isPrimary ? colors.onPrimary : colors.primary;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
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
                  style: context.text.labelLarge.copyWith(color: fgColor),
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
