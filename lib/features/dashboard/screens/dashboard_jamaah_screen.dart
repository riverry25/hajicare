import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../../map/screens/interactive_map_screen.dart';
import '../../prayer/screens/prayer_times_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/jamaah_distance_card.dart';
import '../widgets/jamaah_prayer_card.dart';
import '../widgets/jamaah_profile_header.dart';
import '../widgets/jamaah_service_grid.dart';
import '../widgets/jamaah_sos_banner.dart';

class DashboardJamaahScreen extends StatelessWidget {
  const DashboardJamaahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final state = Get.find<HajiCareController>();

    return Obx(() {
      final jamaah = state.self;

      return Scaffold(
        backgroundColor: AppColors.scaffoldColor(context),
        extendBody: true,
        body: IndexedStack(
          index: dashboardCtrl.currentIndex.value,
          children: [
            _buildJamaahHome(context, state, jamaah, dashboardCtrl),
            const InteractiveMapScreen(showBottomNav: false),
            const PrayerTimesScreen(showBottomNav: false),
            const ProfileScreen(showBottomNav: false),
          ],
        ),
        bottomNavigationBar: HajiCareBottomNavBar(
          currentIndex: dashboardCtrl.currentIndex.value,
          onTap: dashboardCtrl.changeTab,
        ),
      );
    });
  }

  Widget _buildJamaahHome(
    BuildContext context,
    HajiCareController state,
    JamaahData jamaah,
    DashboardController dashboardCtrl,
  ) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = AppColors.scaffoldColor(context);
    final headingColor = AppColors.textHeadingColor(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: HajiCareHeader(
        title: 'HajiCare',
        subtitle: context.tr('dashboardSubtitle'),
        icon: Icons.mosque_rounded,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: headingColor),
                tooltip: context.tr('notificationTooltip'),
                onPressed: () => Get.toNamed(AppRoutes.notification),
              ),
              if (jamaah.separatedMode)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.sosEmergency,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkScaffold
                            : AppColors.canvasCream,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenEdgeGutter),
            child: Center(
              child: CircleAvatar(
                backgroundColor: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.errorContainer,
                radius: 18,
                child: IconButton(
                  icon: const Icon(
                    Icons.sos_rounded,
                    color: AppColors.sosEmergency,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: context.tr('sosTooltip'),
                  onPressed: () => Get.toNamed(AppRoutes.modalSos),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdgeGutter,
          AppSpacing.sm,
          AppSpacing.screenEdgeGutter,
          100,
        ),
        children: [
          if (jamaah.separatedMode) _buildSeparatedBanner(context, isDark),
          JamaahProfileHeader(state: state),
          const SizedBox(height: AppSpacing.lg),
          JamaahDistanceCard(
            jamaah: jamaah,
            onViewMap: () => dashboardCtrl.changeTab(1),
          ),
          const SizedBox(height: AppSpacing.lg),
          JamaahSosBanner(state: state),
          const SizedBox(height: AppSpacing.lg),
          const JamaahPrayerCard(),
          const SizedBox(height: AppSpacing.lg),
          const JamaahServiceGrid(),
          const SizedBox(height: AppSpacing.lg),
          _buildTipsBanner(context, isDark, headingColor),
          const SizedBox(height: AppConstants.space3xl),
        ],
      ),
    );
  }

  Widget _buildSeparatedBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.sosEmergency.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.sosEmergency),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.tr('separatedWarning'),
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.sosEmergency,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsBanner(BuildContext context, bool isDark, Color headingColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.secondaryContainer,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.tanMedium.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: isDark ? AppColors.goldLight : AppColors.espressoDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('officerAdviceTitle'),
                  style: AppTypography.captionSmall.copyWith(
                    color: isDark ? AppColors.darkPrimary : AppColors.espressoDark,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('officerAdviceBody'),
                  style: AppTypography.bodySmall.copyWith(
                    color: headingColor,
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
