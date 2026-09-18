import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
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
import '../../room/widgets/active_room_card.dart';
import '../../notification/controllers/notification_controller.dart';

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.notifications_outlined, color: headingColor, size: 24),
                    tooltip: context.tr('notificationTooltip'),
                    onPressed: () => Get.toNamed(AppRoutes.notification),
                  ),
                  Obx(() {
                    final notifCtrl = Get.isRegistered<NotificationController>()
                        ? Get.find<NotificationController>()
                        : null;
                    final totalUnread = notifCtrl != null
                        ? notifCtrl.unreadCount.value + notifCtrl.pendingInvitations.length
                        : 0;
                    final hasSeparated = jamaah.separatedMode;

                    if (totalUnread <= 0 && !hasSeparated) return const SizedBox.shrink();

                    if (totalUnread > 0) {
                      return Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.sosEmergency,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isDark ? AppColors.darkScaffold : AppColors.canvasCream,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              totalUnread > 9 ? '9+' : '$totalUnread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.sosEmergency,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkScaffold : AppColors.canvasCream,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }
                  }),
                ],
              ),
              const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenEdgeGutter),
            child: Center(
              child: InkWell(
                onTap: () {
                  if ((state.activeRoomId.value ?? '').isEmpty) {
                    AppAlert.warning(
                      context,
                      title: 'Room Diperlukan',
                      message: 'Silakan bergabung ke room terlebih dahulu sebelum dapat menggunakan fitur darurat SOS.',
                    );
                  } else {
                    Get.toNamed(AppRoutes.modalSos);
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.sosEmergency.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sos_rounded,
                        color: AppColors.sosEmergency,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SOS',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.sosEmergency,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
          const SizedBox(height: AppSpacing.md),
          const JamaahPrayerCard(),
          const SizedBox(height: AppSpacing.lg),
          JamaahDistanceCard(
            jamaah: jamaah,
            onViewMap: () => dashboardCtrl.changeTab(1),
            onRefreshGps: () => state.refreshLocation(),
          ),
          const SizedBox(height: AppSpacing.lg),
          JamaahSosBanner(state: state),
          const SizedBox(height: AppSpacing.lg),
          const ActiveRoomCard(isPendamping: false),
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
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.sosEmergency.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sosEmergency.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.sosEmergency,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peringatan Terpisah',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.sosEmergency,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('separatedWarning'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.sosEmergency,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsBanner(
    BuildContext context,
    bool isDark,
    Color headingColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.canvasCream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: isDark ? AppColors.goldLight : AppColors.espressoDark,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('officerAdviceTitle'),
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.espressoDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('officerAdviceBody'),
                  style: AppTypography.bodySmall.copyWith(
                    color: headingColor,
                    height: 1.45,
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
