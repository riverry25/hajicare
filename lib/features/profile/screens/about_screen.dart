import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
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
          context.tr('aboutTitle'),
          style: AppTypography.headlineMd.copyWith(color: headingColor),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── App Identity Header ─────────────────────────────────────────
          _AppIdentitySection(
            headingColor: headingColor,
            bodyColor: bodyColor,
            cardBg: cardBg,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.gapSection),

          // ── About Description ───────────────────────────────────────────
          _ContentSection(
            title: context.tr('aboutTitle'),
            content: context.tr('aboutDescription'),
            icon: Icons.info_outline_rounded,
            cardBg: cardBg,
            headingColor: headingColor,
            bodyColor: bodyColor,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.gapCards),

          // ── Features ───────────────────────────────────────────────────
          _FeaturesSection(
            cardBg: cardBg,
            headingColor: headingColor,
            bodyColor: bodyColor,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.gapCards),

          // ── Accessibility ───────────────────────────────────────────────
          _ContentSection(
            title: context.tr('accessibilitySectionTitle'),
            content: context.tr('accessibilitySectionDesc'),
            icon: Icons.accessibility_new_rounded,
            cardBg: cardBg,
            headingColor: headingColor,
            bodyColor: bodyColor,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.gapCards),

          // ── Privacy & Security ──────────────────────────────────────────
          _ContentSection(
            title: context.tr('privacySectionTitle'),
            content: context.tr('privacySectionDesc'),
            icon: Icons.shield_outlined,
            cardBg: cardBg,
            headingColor: headingColor,
            bodyColor: bodyColor,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.gapCards),

          // ── Legal ───────────────────────────────────────────────────────
          _LegalSection(
            cardBg: cardBg,
            headingColor: headingColor,
            bodyColor: bodyColor,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.gapSection),

          // ── Footer ──────────────────────────────────────────────────────
          _FooterSection(bodyColor: bodyColor),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// App Identity Section
// ────────────────────────────────────────────────────────────────────────────

class _AppIdentitySection extends StatelessWidget {
  final Color headingColor;
  final Color bodyColor;
  final Color cardBg;
  final bool isDark;

  const _AppIdentitySection({
    required this.headingColor,
    required this.bodyColor,
    required this.cardBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxxl,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.canvasCreamSubtle,
        ),
      ),
      child: Column(
        children: [
          // App Icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.goldPrimary.withValues(alpha: 0.6),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDark.withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl - 2),
              child: Image.asset(
                'assets/icon.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.espressoDark,
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: AppColors.goldLight,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // App Name
          Text(
            context.tr('appName'),
            style: AppTypography.displayLarge.copyWith(
              color: headingColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Tagline
          Text(
            context.tr('aboutSubtitle'),
            style: AppTypography.bodyMedium.copyWith(color: bodyColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Version pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              ' ',
              style: AppTypography.labelLarge.copyWith(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Generic content section (icon + title + body text)
// ────────────────────────────────────────────────────────────────────────────

class _ContentSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _ContentSection({
    required this.title,
    required this.content,
    required this.icon,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.canvasCreamSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.touchTargetMin,
                height: AppSizes.touchTargetMin,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(color: headingColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: bodyColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Features Section
// ────────────────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _FeaturesSection({
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.people_outline_rounded,
        'featureCompanion',
        'featureCompanionDesc',
        AppColors.secondary,
      ),
      (
        Icons.schedule_rounded,
        'featureInfo',
        'featureInfoDesc',
        AppColors.accentGoldStar,
      ),
      (
        Icons.accessibility_new_rounded,
        'featureAccessibility',
        'featureAccessibilityDesc',
        AppColors.statusSafe,
      ),
      (
        Icons.translate_rounded,
        'featureLanguage',
        'featureLanguageDesc',
        AppColors.tanMedium,
      ),
      (
        Icons.dark_mode_outlined,
        'featureDarkMode',
        'featureDarkModeDesc',
        AppColors.primary,
      ),
      (
        Icons.person_outline_rounded,
        'featureProfile',
        'featureProfileDesc',
        AppColors.statusWarning,
      ),
    ];

    final accentColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.canvasCreamSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.touchTargetMin,
                height: AppSizes.touchTargetMin,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_outline_rounded,
                  color: accentColor,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                context.tr('featuresTitle'),
                style: AppTypography.titleLarge.copyWith(color: headingColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: f.$4.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(f.$1, color: f.$4, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(f.$2),
                          style: AppTypography.bodyLarge.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(f.$3),
                          style: AppTypography.bodySmall.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Legal Section
// ────────────────────────────────────────────────────────────────────────────

class _LegalSection extends StatelessWidget {
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _LegalSection({
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;

    final items = [
      (context.tr('privacyPolicy'), Icons.privacy_tip_outlined),
      (context.tr('termsOfService'), Icons.gavel_rounded),
      (context.tr('openSourceLicenses'), Icons.code_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.canvasCreamSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.touchTargetMin,
                  height: AppSizes.touchTargetMin,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: accentColor,
                    size: AppSizes.iconMd,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  context.tr('legalSectionTitle'),
                  style: AppTypography.titleLarge.copyWith(color: headingColor),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Divider(
                  height: 1,
                  indent: AppSpacing.xl,
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.canvasCreamSubtle,
                ),
                InkWell(
                  onTap: () {},
                  borderRadius: i == items.length - 1
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(AppRadius.lg),
                        )
                      : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(item.$2, size: AppSizes.iconMd, color: bodyColor),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: AppTypography.bodyMedium.copyWith(
                              color: headingColor,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark
                              ? AppColors.darkOutline
                              : AppColors.tanMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Footer
// ────────────────────────────────────────────────────────────────────────────

class _FooterSection extends StatelessWidget {
  final Color bodyColor;

  const _FooterSection({required this.bodyColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr('appFooter'),
          style: AppTypography.labelLarge.copyWith(color: bodyColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('appFooterSubtitle'),
          style: AppTypography.caption.copyWith(color: bodyColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '\u00a9 2025 HajiCare',
          style: AppTypography.caption.copyWith(
            color: bodyColor.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
