import '../../../core/locales/app_localizations.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../dashboard/presentation/dashboard_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../map/screens/interactive_map_screen.dart';
import '../../prayer/screens/prayer_times_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../controllers/admin_room_controller.dart';
import '../models/activity_model.dart';
import '../models/room_model.dart';
import '../widgets/room_qr_dialog.dart';
import '../widgets/create_room_dialog.dart';
import '../../notification/widgets/notification_composer_dialog.dart';
import '../../notification/controllers/notification_controller.dart';

/// Shell screen for Admin HajiCare.
/// Follows the exact same navigation architecture as [DashboardJamaahScreen]
/// and [DashboardPendampingScreen], using [IndexedStack] and [HajiCareBottomNavBar].
part 'admin_dashboard_sections.dart';
part 'admin_dashboard_components.dart';
part 'admin_dashboard_metrics.dart';
part 'admin_dashboard_sheets.dart';
part 'admin_dashboard_create_room_sheet.dart';
part 'admin_dashboard_active_rooms_sheet.dart';
part 'admin_dashboard_jamaah_sheet.dart';
part 'admin_dashboard_pendamping_sheet.dart';
part 'admin_dashboard_alerts_sheet.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final controller = Get.find<AdminRoomController>();

    return Theme(
      data: DashboardTypography.applyTo(Theme.of(context)),
      child: Obx(() {
        return Scaffold(
          backgroundColor: AppColors.scaffoldColor(context),
          extendBody: true,
          body: IndexedStack(
            index: dashboardCtrl.currentIndex.value,
            children: [
              _AdminDashboardHome(
                controller: controller,
                dashboardCtrl: dashboardCtrl,
              ),
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
      }),
    );
  }
}

/// Operational Command Center Home View for Admin (Tab 0).
class _AdminDashboardHome extends StatelessWidget {
  final AdminRoomController controller;
  final DashboardController dashboardCtrl;

  const _AdminDashboardHome({
    required this.controller,
    required this.dashboardCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = AppColors.scaffoldColor(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        titleSpacing: AppSpacing.screenEdgeGutter,
        title: Row(
          children: [
            // Circular Avatar (Reference: circle photo on the left)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.goldLight.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => CircleAvatar(
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.surfaceWhite,
                    child: Icon(Icons.person, color: headingColor, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('adminDashboard.greeting'),
                  style: DashboardTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('adminDashboard.commandCenter'),
                  style: DashboardTypography.captionSmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Broadcast Button
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.campaign_outlined,
                color: headingColor,
                size: 21,
              ),
              tooltip: context.tr('adminDashboard.sendBroadcastTooltip'),
              onPressed: () => NotificationComposerDialog.show(context),
            ),
          ),

          const SizedBox(width: 4),

          // Notification with Badge Dot tightly hugging the bell
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: headingColor,
                    size: 21,
                  ),
                  tooltip: context.tr('adminDashboard.notifications'),
                  onPressed: () => Get.toNamed(AppRoutes.notification),
                ),
                Obx(() {
                  final totalUnread =
                      Get.find<NotificationController>().unreadCount.value;
                  final hasSos = controller.activeSosCount.value > 0;

                  if (totalUnread <= 0 && !hasSos) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    top: 5,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency,
                        shape: BoxShape.circle,
                        border: Border.all(color: scaffoldBg, width: 1.5),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Logout Button
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
              tooltip: context.tr('adminDashboard.logout'),
              onPressed: () => controller.promptSignOut(context),
            ),
          ),

          const SizedBox(width: AppSpacing.screenEdgeGutter),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr('adminDashboard.loading'),
                  style: DashboardTypography.bodySmall.copyWith(
                    color: bodyColor,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: primaryColor,
          onRefresh: () async {
            controller.subscribeToAllStreams();
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenEdgeGutter,
              AppSpacing.sm,
              AppSpacing.screenEdgeGutter,
              100, // Inset for floating HajiCareBottomNavBar
            ),
            children: [
              // 1. Hero Featured Progress Bento Card (Pastel Sky-Cyan)
              _buildHeroProgressCard(context, isDark),
              const SizedBox(height: AppSpacing.md),

              // 3. Operational Status & 4-Metric Breakdown (Pastel Sage-Mint Green)
              _buildStatusBreakdownCard(
                context,
                isDark,
                headingColor,
                bodyColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Room Pantau Section
              _buildRoomPantauSection(
                context,
                isDark,
                cardBg,
                headingColor,
                bodyColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 6. Aktivitas Terbaru
              _buildRecentActivitiesSection(
                context,
                isDark,
                cardBg,
                headingColor,
                bodyColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 7. Bottom Action Pill Button (Reference: Calorie count >>>)
              // 7. Aksi Cepat - PALING BAWAH
              _buildQuickActions(
                context,
                isDark,
                cardBg,
                headingColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      }),
    );
  }

  // 1. Hero progress card
  String _getMonthName(BuildContext context, int month) {
    return month >= 1 && month <= 12
        ? context.tr('adminDashboard.month$month')
        : '';
  }

  // 5. Room monitoring section
  // 6. Recent activities
  // Activity detail bottom sheet
}
