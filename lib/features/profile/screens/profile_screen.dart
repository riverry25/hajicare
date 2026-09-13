import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/state/app_settings_controller.dart';
import '../../../core/state/app_startup_controller.dart';
import '../../../core/locales/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  final bool showBottomNav;
  const ProfileScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final profileCtrl = Get.put(ProfileController());

    return Obx(() {
      // Observe settings to trigger rebuild on change
      settings.currentTextScale;
      settings.currentLocale;
      {
        final isDark = AppColors.isDark(context);
        final scaffoldBg = isDark
            ? AppColors.darkScaffold
            : AppColors.canvasCream;
        final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
        final headingColor = isDark
            ? AppColors.darkTextHeading
            : AppColors.espressoDark;
        final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;

        return Scaffold(
          backgroundColor: scaffoldBg,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            elevation: 0,
            title: Text(
              context.tr('profileTitle'),
              style: AppTypography.headlineMd.copyWith(color: headingColor),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              100,
            ),
            children: [
              _ProfileHeader(
                controller: profileCtrl,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.gapSection),
              _SettingsGroup(
                title: context.tr('accountData'),
                titleColor: bodyColor,
                cardBg: cardBg,
                children: [
                  _SettingsTile(
                    icon: Icons.medical_information_outlined,
                    label: context.tr('medicalData'),
                    cardBg: cardBg,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    onTap: () {},
                  ),
                  _DividerThin(),
                  _SettingsTile(
                    icon: Icons.link_rounded,
                    label: context.tr('manageCompanion'),
                    cardBg: cardBg,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gapCards),
              _SettingsGroup(
                title: context.tr('accessibilitySettings'),
                titleColor: bodyColor,
                cardBg: cardBg,
                children: [
                  _SettingsTile(
                    icon: Icons.text_increase_rounded,
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
              _SettingsGroup(
                title: context.tr('preferenceSettings'),
                titleColor: bodyColor,
                cardBg: cardBg,
                children: [
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    label: context.tr('language'),
                    trailingLabel: settings.localeName,
                    cardBg: cardBg,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    onTap: () => _showLanguagePicker(context, settings),
                  ),
                  _DividerThin(),
                  _SettingsTile(
                    icon: Icons.contrast_rounded,
                    label: context.tr('theme'),
                    trailingLabel: settings.themeModeName,
                    cardBg: cardBg,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    onTap: () => _showThemePicker(context, settings),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gapCards),
              _SettingsGroup(
                title: context.tr('otherSettings'),
                titleColor: bodyColor,
                cardBg: cardBg,
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: context.tr('helpCenter'),
                    cardBg: cardBg,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    onTap: () => Get.toNamed(AppRoutes.helpCenter),
                  ),
                  _DividerThin(),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    label: context.tr('aboutApp'),
                    trailingLabel: AppConstants.appVersion,
                    cardBg: cardBg,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    onTap: () => Get.toNamed(AppRoutes.about),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gapSection),
              _LogoutButton(label: context.tr('logout')),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
          bottomNavigationBar: showBottomNav
              ? const HajiCareBottomNavBar(currentIndex: 3)
              : null,
        );
      }
    });
  }

  void _showLanguagePicker(
    BuildContext context,
    AppSettingsController settings,
  ) {
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
        final isSelected =
            settings.currentLocale.languageCode == opt.$1.languageCode;
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

  void _showThemePicker(BuildContext context, AppSettingsController settings) {
    final options = [
      (
        ThemeMode.system,
        context.tr('themeSystem'),
        Icons.brightness_auto_rounded,
      ),
      (ThemeMode.light, context.tr('themeLight'), Icons.light_mode_rounded),
      (ThemeMode.dark, context.tr('themeDark'), Icons.dark_mode_rounded),
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

  void _showTextSizePicker(
    BuildContext context,
    AppSettingsController settings,
  ) {
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
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.isDark(Get.context!)
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final ProfileController controller;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _ProfileHeader({
    required this.controller,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isDark
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () =>
                _InitialsAvatar(initials: controller.initials, isDark: isDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Text(
              controller.displayName.value,
              style: AppTypography.headlineMd.copyWith(color: headingColor),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
          const SizedBox(height: AppSpacing.gapTitleSubtitle),
          if (controller.safeEmail.isNotEmpty)
            Text(
              controller.safeEmail,
              style: AppTypography.bodySmall.copyWith(color: bodyColor),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer.withValues(alpha: 0.5)
                  : AppColors.secondaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              context.tr('jamaah'),
              style: AppTypography.captionBold.copyWith(
                color: isDark ? AppColors.darkPrimary : AppColors.espressoDark,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _EditNameButton(controller: controller, isDark: isDark),
        ],
      ),
    );
  }
}

// ── Initials Avatar ───────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final bool isDark;

  const _InitialsAvatar({required this.initials, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkPrimaryContainer,
                  AppColors.darkSurfaceContainerHigh,
                ]
              : [AppColors.espressoDark, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? AppColors.darkPrimary : AppColors.goldLight,
          width: 2.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.displayMedium.copyWith(
          color: isDark ? AppColors.darkTextHeading : AppColors.surfaceWhite,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Edit Name Button ──────────────────────────────────────────────────────────

class _EditNameButton extends StatelessWidget {
  final ProfileController controller;
  final bool isDark;

  const _EditNameButton({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;
    return Semantics(
      button: true,
      label: context.tr('editName'),
      child: InkWell(
        onTap: () => _showEditNameSheet(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, size: 14, color: accentColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.tr('editName'),
                style: AppTypography.bodySmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameSheet(BuildContext context) {
    final isDarkSheet = AppColors.isDark(context);
    final sheetBg = isDarkSheet
        ? AppColors.darkSurface
        : AppColors.surfaceWhite;
    final headingClr = isDarkSheet
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyClr = isDarkSheet ? AppColors.darkTextBody : AppColors.textBody;
    final borderClr = isDarkSheet
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant;
    final nameCtrl = TextEditingController(text: controller.displayName.value);
    final inputError = RxnString();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderClr,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  sheetCtx.tr('editNameTitle'),
                  style: AppTypography.titleLarge.copyWith(color: headingClr),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  sheetCtx.tr('name'),
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyClr,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Obx(
                  () => TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 50,
                    style: AppTypography.bodyLarge.copyWith(color: headingClr),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: sheetCtx.tr('name'),
                      hintStyle: AppTypography.bodyLarge.copyWith(
                        color: bodyClr.withValues(alpha: 0.5),
                      ),
                      errorText: inputError.value,
                      filled: true,
                      fillColor: isDarkSheet
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: borderClr),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: borderClr),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(
                          color: isDarkSheet
                              ? AppColors.darkPrimary
                              : AppColors.espressoDark,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Obx(() {
                  final saving = controller.isSavingName.value;
                  return ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final input = nameCtrl.text.trim();
                            if (input.isEmpty) {
                              inputError.value = sheetCtx.tr('nameRequired');
                              return;
                            }
                            if (input.length > 50) {
                              inputError.value = sheetCtx.tr('nameTooLong');
                              return;
                            }
                            inputError.value = null;

                            final successTitle = sheetCtx.tr('success');
                            final successMsg = sheetCtx.tr('nameUpdated');
                            final errorTitle = sheetCtx.tr('error');
                            final errorMsg = sheetCtx.tr('updateNameError');

                            try {
                              await controller.updateDisplayName(input);
                              Get.back();
                              Get.snackbar(
                                successTitle,
                                successMsg,
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.statusSafe
                                    .withValues(alpha: 0.9),
                                colorText: AppColors.surfaceWhite,
                                margin: const EdgeInsets.all(AppSpacing.lg),
                                borderRadius: AppRadius.lg,
                                duration: const Duration(seconds: 3),
                              );
                            } catch (_) {
                              Get.snackbar(
                                errorTitle,
                                errorMsg,
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.error.withValues(
                                  alpha: 0.9,
                                ),
                                colorText: AppColors.surfaceWhite,
                                margin: const EdgeInsets.all(AppSpacing.lg),
                                borderRadius: AppRadius.lg,
                                duration: const Duration(seconds: 4),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkSheet
                          ? AppColors.darkPrimary
                          : AppColors.espressoDark,
                      foregroundColor: isDarkSheet
                          ? AppColors.darkOnPrimary
                          : AppColors.surfaceWhite,
                      disabledBackgroundColor: isDarkSheet
                          ? AppColors.darkSurfaceContainer
                          : AppColors.outlineVariant,
                      minimumSize: const Size(
                        double.infinity,
                        AppSizes.buttonHeightPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusPill,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: saving
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: isDarkSheet
                                  ? AppColors.darkOnPrimary
                                  : AppColors.surfaceWhite,
                            ),
                          )
                        : Text(
                            sheetCtx.tr('save'),
                            style: AppTypography.titleMedium.copyWith(
                              color: isDarkSheet
                                  ? AppColors.darkOnPrimary
                                  : AppColors.surfaceWhite,
                            ),
                          ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Settings Group ────────────────────────────────────────────────────────────

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
            left: AppSpacing.sm,
            bottom: AppSpacing.xs,
            top: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelPill.copyWith(
              color: titleColor,
              letterSpacing: 0.6,
            ),
          ),
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

// ── Settings Tile ─────────────────────────────────────────────────────────────

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
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
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
                child: Text(
                  label,
                  style: AppTypography.bodyMd.copyWith(color: headingColor),
                ),
              ),
              if (trailingLabel != null) ...[
                Text(
                  trailingLabel!,
                  style: AppTypography.caption.copyWith(color: bodyColor),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.isDark(context)
                    ? AppColors.darkOutline
                    : AppColors.tanMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Thin Divider ──────────────────────────────────────────────────────────────

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

// ── Logout Button ─────────────────────────────────────────────────────────────

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
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(label),
              content: Text(
                dialogContext.tr('apakahYakinKeluar').isEmpty
                    ? 'Yakin ingin keluar dari akun?'
                    : dialogContext.tr('apakahYakinKeluar'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    dialogContext.tr('cancel').isEmpty
                        ? 'Batal'
                        : dialogContext.tr('cancel'),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: () async {
                    await Get.find<AppStartupController>().signOut();
                  },
                  child: Text(
                    dialogContext.tr('yes').isEmpty
                        ? 'Ya'
                        : dialogContext.tr('yes'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.errorContainer,
          foregroundColor: AppColors.error,
          elevation: 0,
          minimumSize: const Size(
            double.infinity,
            AppSizes.buttonHeightPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Picker Option ─────────────────────────────────────────────────────────────

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
    final isDark = AppColors.isDark(context);
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;
    final textColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final selectedBg = isDark
        ? AppColors.darkPrimaryContainer.withValues(alpha: 0.40)
        : AppColors.espressoDark.withValues(alpha: 0.07);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSizes.touchTargetMin + 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppSizes.iconMd,
                  color: isSelected ? activeColor : textColor,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isSelected ? activeColor : textColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailingHint != null) ...[
                Text(
                  trailingHint!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textBodyColor(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: activeColor, size: 20)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.outlineColor(context),
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
