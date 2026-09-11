import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/state/app_settings_controller.dart';
import '../../../core/locales/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  final bool showBottomNav;
  const ProfileScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();

    return Obx(() {
      final isDark = AppColors.isDark(context);
      final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
      final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
      final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
      final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;

      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          title: Text(context.tr('profileTitle'),
              style: AppTypography.headlineMd.copyWith(color: headingColor)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Profile Header ─────────────────────────────────────────────
            _ProfileHeader(
            cardBg: cardBg,
            headingColor: headingColor,
            bodyColor: bodyColor,
          ),
          const SizedBox(height: AppSpacing.gapSection),

          // ── Data & Sinkronisasi ────────────────────────────────────────
          _SettingsGroup(
            title: context.tr('accountData'),
            titleColor: bodyColor,
            cardBg: cardBg,
            children: [
              _SettingsTile(
                icon: Icons.medical_information,
                label: context.tr('medicalData'),
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                onTap: () {},
              ),
              _DividerThin(),
              _SettingsTile(
                icon: Icons.link,
                label: context.tr('manageCompanion'),
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gapCards),

          // ── Aksesibilitas ──────────────────────────────────────────────
          _SettingsGroup(
            title: context.tr('accessibilitySettings'),
            titleColor: bodyColor,
            cardBg: cardBg,
            children: [
              _SettingsTile(
                icon: Icons.text_increase,
                label: context.tr('textSize'),
                trailingLabel: settings.currentTextScale.label,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                onTap: () => _showTextSizePicker(context, settings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gapCards),

          // ── Lainnya & Preferensi ───────────────────────────────────────
          _SettingsGroup(
            title: context.tr('otherSettings'),
            titleColor: bodyColor,
            cardBg: cardBg,
            children: [
              _SettingsTile(
                icon: Icons.language,
                label: context.tr('language'),
                trailingLabel: settings.localeName,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                onTap: () => _showLanguagePicker(context, settings),
              ),
              _DividerThin(),
              _SettingsTile(
                icon: Icons.contrast,
                label: context.tr('theme'),
                trailingLabel: settings.themeModeName,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                onTap: () => _showThemePicker(context, settings),
              ),
              _DividerThin(),
              _SettingsTile(
                icon: Icons.help_outline,
                label: context.tr('helpCenter'),
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                onTap: () {},
              ),
              _DividerThin(),
              _SettingsTile(
                icon: Icons.info_outline,
                label: context.tr('aboutApp'),
                trailingLabel: '1.0.0',
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.gapSection),
          _LogoutButton(label: context.tr('logout')),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
        bottomNavigationBar: showBottomNav
            ? const HajiCareBottomNavBar(
                currentIndex: 3,
              )
            : null,
      );
    });
  }

  // ── Language Picker Bottom Sheet ──────────────────────────────────────────
  void _showLanguagePicker(BuildContext context, AppSettingsController settings) {
    final options = [
      (const Locale('id'), 'Bahasa Indonesia', '🇮🇩'),
      (const Locale('jv'), 'Basa Jawi', '🏝️'),
      (const Locale('su'), 'Basa Sunda', '🌿'),
      (const Locale('en'), 'English', '🌐'),
    ];
    _showPickerSheet(
      context: context,
      title: context.tr('selectLanguageTitle'),
      children: options.map((opt) {
        final isSelected = settings.currentLocale.languageCode == opt.$1.languageCode;
        return _PickerOption(
          label: '${opt.$3}  ${opt.$2}',
          isSelected: isSelected,
          onTap: () {
            settings.setLocale(opt.$1);
            Get.back();
          },
        );
      }).toList(),
    );
  }

  // ── Theme Picker Bottom Sheet ─────────────────────────────────────────────
  void _showThemePicker(BuildContext context, AppSettingsController settings) {
    final options = [
      (ThemeMode.system, context.tr('themeSystem'), Icons.brightness_auto),
      (ThemeMode.light,  context.tr('themeLight'),  Icons.light_mode),
      (ThemeMode.dark,   context.tr('themeDark'),   Icons.dark_mode),
    ];
    _showPickerSheet(
      context: context,
      title: context.tr('selectThemeTitle'),
      children: options.map((opt) {
        final isSelected = settings.currentThemeMode == opt.$1;
        return _PickerOption(
          icon: opt.$3,
          label: opt.$2,
          isSelected: isSelected,
          onTap: () {
            settings.setThemeMode(opt.$1);
            Get.back();
          },
        );
      }).toList(),
    );
  }

  // ── Text Size Picker Bottom Sheet ─────────────────────────────────────────
  void _showTextSizePicker(BuildContext context, AppSettingsController settings) {
    _showPickerSheet(
      context: context,
      title: context.tr('selectTextSizeTitle'),
      children: AppTextScale.values.map((scale) {
        final isSelected = settings.currentTextScale == scale;
        return _PickerOption(
          label: scale.label,
          trailingHint: '${(scale.factor * 100).toStringAsFixed(0)}%',
          isSelected: isSelected,
          onTap: () {
            settings.setTextScale(scale);
            Get.back();
          },
        );
      }).toList(),
    );
  }

  // ── Generic Picker Bottom Sheet ───────────────────────────────────────────
  void _showPickerSheet({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle grip
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppTypography.titleLarge.copyWith(color: AppColors.textHeading)),
              const SizedBox(height: AppSpacing.md),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;

  const _ProfileHeader({
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: AppColors.isDark(context)
              ? AppColors.darkOutlineVariant
              : AppColors.canvasCreamSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.isDark(context)
                      ? AppColors.darkSurfaceContainer
                      : AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldLight, width: 2),
                ),
                child: Icon(Icons.account_circle,
                    color: AppColors.isDark(context)
                        ? AppColors.darkPrimary
                        : AppColors.primaryContainer,
                    size: 64),
              ),
              Semantics(
                label: 'Ubah foto profil',
                button: true,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.isDark(context)
                          ? AppColors.darkPrimary
                          : AppColors.espressoDark,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit,
                        color: AppColors.isDark(context)
                            ? AppColors.darkOnPrimary
                            : AppColors.surfaceWhite,
                        size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('H. Ahmad Dahlan',
              style: AppTypography.headlineMd.copyWith(color: headingColor)),
          const SizedBox(height: AppSpacing.gapTitleSubtitle),
          Text('Jamaah • Kloter 14 JKS',
              style: AppTypography.bodyMd.copyWith(color: bodyColor)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
            ),
            child: Text(
              context.tr('connectedWristband'),
              style: AppTypography.captionBold
                  .copyWith(color: AppColors.isDark(context) ? AppColors.darkTextHeading : AppColors.espressoDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Color cardBg;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.titleColor,
    required this.cardBg,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.sm, bottom: AppSpacing.xs, top: AppSpacing.sm),
          child: Text(title,
              style: AppTypography.labelPill.copyWith(color: titleColor)),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(
              color: AppColors.isDark(context)
                  ? AppColors.darkOutlineVariant
                  : AppColors.canvasCreamSubtle,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailingLabel,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label${trailingLabel != null ? ': $trailingLabel' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: AppSizes.touchTargetMin,
                height: AppSizes.touchTargetMin,
                decoration: BoxDecoration(
                  color: AppColors.isDark(context)
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: headingColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label,
                    style: AppTypography.bodyMd.copyWith(color: headingColor)),
              ),
              if (trailingLabel != null) ...[
                Text(trailingLabel!,
                    style: AppTypography.caption.copyWith(color: bodyColor)),
                const SizedBox(width: AppSpacing.xs),
              ],
              Icon(Icons.chevron_right,
                  color: AppColors.isDark(context)
                      ? AppColors.darkOutline
                      : AppColors.tanMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _DividerThin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.xl + AppSizes.touchTargetMin,
      color: AppColors.isDark(context)
          ? AppColors.darkOutlineVariant
          : AppColors.canvasCreamSubtle,
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final String label;
  const _LogoutButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ElevatedButton(
        onPressed: () {
          Get.defaultDialog(
            title: label,
            middleText: 'apakahYakinKeluar'.tr.isEmpty ? 'Yakin ingin keluar dari akun?' : 'apakahYakinKeluar'.tr,
            textConfirm: 'yes'.tr,
            textCancel: 'cancel'.tr,
            confirmTextColor: Colors.white,
            buttonColor: AppColors.error,
            onConfirm: () {
              Get.offAllNamed(AppRoutes.login);
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.errorContainer,
          foregroundColor: AppColors.error,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightPrimary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusPill)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? trailingHint;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickerOption({
    this.icon,
    required this.label,
    this.trailingHint,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.touchTargetMin + 4),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.espressoDark.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: AppSizes.iconMd,
                    color: isSelected
                        ? AppColors.espressoDark
                        : AppColors.textBody),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isSelected
                        ? AppColors.espressoDark
                        : AppColors.textHeading,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailingHint != null) ...[
                Text(trailingHint!,
                    style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.espressoDark, size: 20)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.outlineVariant, width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
