import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
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
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: headingColor),
          onPressed: () {},
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mosque,
                color: AppColors.accentGoldStar,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm2),
            Text(
              'HajiCare',
              style: AppTypography.titleLarge.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: headingColor),
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
                        color: isDark ? AppColors.darkScaffold : AppColors.canvasCream,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: CircleAvatar(
              backgroundColor: AppColors.errorContainer,
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.sos, color: AppColors.sosEmergency, size: 20),
                padding: EdgeInsets.zero,
                onPressed: () => Get.toNamed(AppRoutes.modalSos),
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
          if (jamaah.separatedMode) _buildSeparatedBanner(),
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
          _buildTipsBanner(),
          const SizedBox(height: AppConstants.space3xl),
        ],
      ),
    );
  }

  Widget _buildSeparatedBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.sosEmergency.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.sosEmergency),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Kemungkinan terpisah dari pendamping! Tetap tenang di tempat Anda.',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.sosEmergency,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tanMedium.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: AppColors.espressoDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HIMBAUAN PETUGAS SEKTOR',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.espressoDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tetap bersama rombongan saat menuju jamarat. Pastikan botol air minum terisi penuh dan kenakan selalu gelang identitas Anda.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textHeading,
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
