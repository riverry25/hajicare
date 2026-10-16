import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import 'legal_document_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;

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
          context.tr('aboutTitle'),
          style: context.text.titleLarge.copyWith(color: colors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // ── App Identity Header ─────────────────────────────────────────
                _AppIdentitySection(colors: colors),
                const SizedBox(height: AppSpacing.gapSection),

                // ── About Description ───────────────────────────────────────────
                _ContentSection(
                  title: context.tr('aboutTitle'),
                  content: context.tr('aboutDescription'),
                  icon: Icons.info_outline_rounded,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.gapCards),

                // ── Features ───────────────────────────────────────────────────
                _FeaturesSection(colors: colors),
                const SizedBox(height: AppSpacing.gapCards),

                // ── Accessibility ───────────────────────────────────────────────
                _ContentSection(
                  title: context.tr('accessibilitySectionTitle'),
                  content: context.tr('accessibilitySectionDesc'),
                  icon: Icons.accessibility_new_rounded,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.gapCards),

                // ── Privacy & Security ──────────────────────────────────────────
                _ContentSection(
                  title: context.tr('privacySectionTitle'),
                  content: context.tr('privacySectionDesc'),
                  icon: Icons.shield_outlined,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.gapCards),

                // ── Legal ───────────────────────────────────────────────────────
                _LegalSection(colors: colors),
                const SizedBox(height: AppSpacing.gapSection),

                OutlinedButton.icon(
                  key: const Key('about_help_button'),
                  onPressed: () => Get.toNamed(AppRoutes.helpCenter),
                  icon: const Icon(Icons.help_outline_rounded),
                  label: Text(context.tr('legalHelpCta')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.border),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.gapSection),

                // ── Footer ──────────────────────────────────────────────────────
                _FooterSection(colors: colors),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// App Identity Section
// ────────────────────────────────────────────────────────────────────────────

class _AppIdentitySection extends StatelessWidget {
  final HajiColors colors;

  const _AppIdentitySection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxxl,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: colors.border),
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
                color: colors.accent.withValues(alpha: 0.6),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl - 2),
              child: Image.asset(
                'assets/icon.jpeg',
                cacheWidth: 192,
                cacheHeight: 192,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colors.primary,
                  child: Icon(
                    Icons.mosque_rounded,
                    color: colors.accent,
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
            style: context.text.titleLarge.copyWith(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Tagline
          Text(
            context.tr('aboutSubtitle'),
            style: context.text.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
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
              color: colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '${context.tr('appVersionLabel')} ${AppConstants.appVersion}',
              style: context.text.labelLarge.copyWith(color: colors.primary),
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
  final HajiColors colors;

  const _ContentSection({
    required this.title,
    required this.content,
    required this.icon,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.touchTargetMin,
                height: AppSizes.touchTargetMin,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: context.text.titleLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            content,
            style: context.text.bodyMedium.copyWith(
              color: colors.textSecondary,
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
  final HajiColors colors;

  const _FeaturesSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.people_outline_rounded,
        'featureCompanion',
        'featureCompanionDesc',
        colors.primary,
      ),
      (Icons.schedule_rounded, 'featureInfo', 'featureInfoDesc', colors.accent),
      (
        Icons.accessibility_new_rounded,
        'featureAccessibility',
        'featureAccessibilityDesc',
        colors.success,
      ),
      (
        Icons.translate_rounded,
        'featureLanguage',
        'featureLanguageDesc',
        colors.info,
      ),
      (
        Icons.dark_mode_outlined,
        'featureDarkMode',
        'featureDarkModeDesc',
        colors.primary,
      ),
      (
        Icons.person_outline_rounded,
        'featureProfile',
        'featureProfileDesc',
        colors.warning,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: colors.border),
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
                  color: colors.primaryContainer.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_outline_rounded,
                  color: colors.primary,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                context.tr('featuresTitle'),
                style: context.text.titleLarge.copyWith(
                  color: colors.textPrimary,
                ),
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
                      color: f.$4.withValues(alpha: 0.12),
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
                          style: context.text.bodyLarge.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(f.$3),
                          style: context.text.bodySmall.copyWith(
                            color: colors.textSecondary,
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
  final HajiColors colors;

  const _LegalSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, VoidCallback)>[
      (
        context.tr('privacyPolicy'),
        Icons.privacy_tip_outlined,
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const LegalDocumentScreen(type: LegalDocumentType.privacy),
          ),
        ),
      ),
      (
        context.tr('termsOfService'),
        Icons.gavel_rounded,
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const LegalDocumentScreen(type: LegalDocumentType.terms),
          ),
        ),
      ),
      (
        context.tr('openSourceLicenses'),
        Icons.code_rounded,
        () => showLicensePage(
          context: context,
          applicationName: context.tr('appName'),
          applicationVersion: AppConstants.appVersion,
          applicationIcon: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Image.asset(
              'assets/icon.jpeg',
              width: 52,
              height: 52,
              cacheWidth: 104,
              cacheHeight: 104,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.mosque_rounded, size: 48, color: colors.accent),
            ),
          ),
          applicationLegalese: '© ${DateTime.now().year} HajiCare',
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: colors.border),
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
                    color: colors.primaryContainer.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: colors.primary,
                    size: AppSizes.iconMd,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  context.tr('legalSectionTitle'),
                  style: context.text.titleLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Divider(height: 1, indent: AppSpacing.xl, color: colors.border),
                Semantics(
                  button: true,
                  label: item.$1,
                  child: InkWell(
                    onTap: item.$3,
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
                          Icon(
                            item.$2,
                            size: AppSizes.iconMd,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: context.text.bodyMedium.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.borderStrong,
                          ),
                        ],
                      ),
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
  final HajiColors colors;

  const _FooterSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr('appFooter'),
          style: context.text.labelLarge.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('appFooterSubtitle'),
          style: context.text.bodySmall.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '© ${DateTime.now().year} HajiCare',
          style: context.text.bodySmall.copyWith(color: colors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
