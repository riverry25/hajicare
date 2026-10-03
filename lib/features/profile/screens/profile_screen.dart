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
import '../../../core/state/hajicare_controller.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/services/app_alert_service.dart';

part 'profile_screen_sections.dart';
part 'profile_screen_components.dart';

class ProfileScreen extends StatelessWidget {
  final bool showBottomNav;
  const ProfileScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final profileCtrl = Get.find<ProfileController>();
    final state = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;

    return Obx(() {
      settings.currentTextScale;
      settings.currentLocale;
      {
        final isDark = AppColors.isDark(context);
        final scaffoldBg = AppColors.scaffoldColor(context);
        final cardBg = AppColors.cardBgColor(context);
        final headingColor = AppColors.textHeadingColor(context);
        final bodyColor = AppColors.textBodyColor(context);

        return Scaffold(
          backgroundColor: scaffoldBg,
          extendBody: true,
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top,
              bottom: 100,
            ),
            children: [
              // ── Custom Page Header (replaces AppBar) ──────────────────────
              _buildPageHeader(context, headingColor, isDark),

              // 1. Profile Identity Header Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdgeGutter,
                ),
                child: _ProfileHeader(
                  controller: profileCtrl,
                  state: state,
                  cardBg: cardBg,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdgeGutter,
                ),
                child: _SettingsGroup(
                  title: context.tr('profile.groupAccountData'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.medical_information_rounded,
                      label: context.tr('profile.medicalData'),
                      trailingLabel: context.tr('profile.view'),
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showMedicalDataSheet(context, state),
                    ),
                    _DividerThin(),
                    _SettingsTile(
                      icon: Icons.groups_rounded,
                      label: context.tr('profile.manageCompanion'),
                      trailingLabel:
                          state?.activeRoom.value?.name ??
                          context.tr('profile.active'),
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showCompanionInfoSheet(context, state),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdgeGutter,
                ),
                child: _SettingsGroup(
                  title: context.tr('profile.accessibility'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.text_fields_rounded,
                      label: context.tr('profile.textSize'),
                      trailingLabel: settings.currentTextScale.localizedLabel(
                        context,
                      ),
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showTextSizePicker(context, settings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdgeGutter,
                ),
                child: _SettingsGroup(
                  title: context.tr('profile.preferencesAndDisplay'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      label: context.tr('profile.language'),
                      trailingLabel: settings.localeName,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showLanguagePicker(context, settings),
                    ),
                    _DividerThin(),
                    _SettingsTile(
                      icon: Icons.brightness_6_rounded,
                      label: context.tr('profile.theme'),
                      trailingLabel: settings.themeModeName,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => _showThemePicker(context, settings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdgeGutter,
                ),
                child: _SettingsGroup(
                  title: context.tr('profile.helpAndInfo'),
                  titleColor: AppColors.tanMedium,
                  cardBg: cardBg,
                  children: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      label: context.tr('profile.helpCenter'),
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => Get.toNamed(AppRoutes.helpCenter),
                    ),
                    _DividerThin(),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: context.tr('profile.aboutApp'),
                      trailingLabel: AppConstants.appVersion,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      onTap: () => Get.toNamed(AppRoutes.about),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdgeGutter,
                ),
                child: _LogoutButton(label: context.tr('profile.logout')),
              ),
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

  // ── Dialogs & Bottom Sheets ───────────────────────────────────────────────
}

// ── Profile Header ────────────────────────────────────────────────────────────
