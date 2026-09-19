import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum LegalDocumentType { privacy, terms }

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final background = AppColors.scaffoldColor(context);
    final cardColor = AppColors.cardBgColor(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final accentColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;
    final isPrivacy = type == LegalDocumentType.privacy;
    final title = context.tr(isPrivacy ? 'privacyPolicy' : 'termsOfService');
    final sections = isPrivacy
        ? const [
            ('privacyDataTitle', 'privacyDataBody'),
            ('privacyUseTitle', 'privacyUseBody'),
            ('privacySharingTitle', 'privacySharingBody'),
            ('privacyPermissionsTitle', 'privacyPermissionsBody'),
            ('privacyControlTitle', 'privacyControlBody'),
          ]
        : const [
            ('termsPurposeTitle', 'termsPurposeBody'),
            ('termsAccountTitle', 'termsAccountBody'),
            ('termsSafetyTitle', 'termsSafetyBody'),
            ('termsLimitationsTitle', 'termsLimitationsBody'),
            ('termsConductTitle', 'termsConductBody'),
          ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          tooltip: context.tr('back'),
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: headingColor),
        ),
        title: Text(
          title,
          style: AppTypography.titleLarge.copyWith(color: headingColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.outlineColor(context)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          isPrivacy
                              ? Icons.shield_outlined
                              : Icons.gavel_rounded,
                          size: 32,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMd.copyWith(
                          color: headingColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${context.tr('legalVersionNote')} ${AppConstants.appVersion}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (int index = 0; index < sections.length; index++) ...[
                  _LegalSectionCard(
                    number: index + 1,
                    title: context.tr(sections[index].$1),
                    body: context.tr(sections[index].$2),
                    cardColor: cardColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    accentColor: accentColor,
                  ),
                  if (index < sections.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.helpCenter),
                  icon: const Icon(Icons.help_outline_rounded),
                  label: Text(context.tr('legalHelpCta')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  final int number;
  final String title;
  final String body;
  final Color cardColor;
  final Color headingColor;
  final Color bodyColor;
  final Color accentColor;

  const _LegalSectionCard({
    required this.number,
    required this.title,
    required this.body,
    required this.cardColor,
    required this.headingColor,
    required this.bodyColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.1),
            ),
            child: Text(
              '$number',
              style: AppTypography.labelLarge.copyWith(color: accentColor),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: AppTypography.bodyMedium.copyWith(
                    color: bodyColor,
                    height: 1.55,
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
