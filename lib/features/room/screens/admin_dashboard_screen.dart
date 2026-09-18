import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../map/screens/interactive_map_screen.dart';
import '../../prayer/screens/prayer_times_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../controllers/admin_room_controller.dart';
import '../models/activity_model.dart';
import '../models/room_model.dart';
import '../widgets/room_qr_dialog.dart';
import '../../notification/widgets/notification_composer_dialog.dart';
import '../../notification/controllers/notification_controller.dart';

/// Shell screen for Admin HajiCare.
/// Follows the exact same navigation architecture as [DashboardJamaahScreen]
/// and [DashboardPendampingScreen], using [IndexedStack] and [HajiCareBottomNavBar].
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());
    final controller = Get.isRegistered<AdminRoomController>()
        ? Get.find<AdminRoomController>()
        : Get.put(AdminRoomController());

    return Obx(() {
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
    });
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
      appBar: HajiCareHeader(
        title: 'HajiCare',
        subtitle: 'Command Center',
        imageAsset: 'assets/icon.jpeg',
        actions: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Icon(Icons.campaign_outlined, color: headingColor),
            tooltip: 'Kirim Notifikasi / Siaran',
            onPressed: () => NotificationComposerDialog.show(context),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(Icons.notifications_outlined, color: headingColor),
                tooltip: 'Notifikasi',
                onPressed: () => Get.toNamed(AppRoutes.notification),
              ),
              Obx(() {
                if (!Get.isRegistered<NotificationController>()) return const SizedBox.shrink();
                final notifCtrl = Get.find<NotificationController>();
                final totalUnread = notifCtrl.unreadCount.value;
                if (totalUnread <= 0) return const SizedBox.shrink();

                return Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.sosEmergency,
                      shape: BoxShape.circle,
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
              }),
              Obx(() {
                if (controller.activeSosCount.value > 0) {
                  return Positioned(
                    top: 8,
                    right: 8,
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
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.error,
            tooltip: 'Keluar Admin',
            onPressed: () => controller.promptSignOut(context),
          ),
          const SizedBox(width: AppSpacing.xs),
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
                  'Memuat Command Center...',
                  style: AppTypography.bodySmall.copyWith(color: bodyColor),
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
              // 1. Welcome Card (Command Center Header Hero)
              _buildWelcomeCard(context, isDark),
              const SizedBox(height: AppSpacing.md),

              // 2. Alert / System Status Banner
              _buildStatusPantauanCard(
                context,
                isDark,
                headingColor,
                bodyColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Overview KPI
              _buildKpiOverview(
                context,
                isDark,
                cardBg,
                headingColor,
                bodyColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Room Pantau
              _buildRoomPantauSection(
                context,
                isDark,
                cardBg,
                headingColor,
                bodyColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Aktivitas Terbaru
              _buildRecentActivitiesSection(
                context,
                isDark,
                cardBg,
                headingColor,
                bodyColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 6. Quick Actions (Aksi Cepat)
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

  // ── 1. Welcome Banner Card ──────────────────────────────────────────────────
  Widget _buildWelcomeCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurfaceContainerHigh, AppColors.darkSurface]
              : [AppColors.primary, AppColors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : AppColors.goldLight.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.espressoDark).withValues(
              alpha: 0.20,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Ambient decorative circles
          Positioned(
            right: -25,
            top: -35,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withValues(
                  alpha: isDark ? 0.08 : 0.12,
                ),
              ),
            ),
          ),
          Positioned(
            right: 45,
            bottom: -40,
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldLight.withValues(
                  alpha: isDark ? 0.05 : 0.08,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Portal Administrator Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.accentGoldStar.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        size: 13,
                        color: AppColors.accentGoldStar,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'COMMAND CENTER OPERASIONAL',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 4),

                // Main Dashboard Title
                Text(
                  'Admin Dashboard',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  'Assalamu\'alaikum, Admin. Pantau seluruh keselamatan jamaah dan koordinasi petugas secara realtime.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Live Sync Status
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Cloud Sync Terhubung',
                      style: AppTypography.captionSmall.copyWith(
                        color: const Color(0xFF81C784),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Command Center / Status Pantauan Card ───────────────────────────────
  Widget _buildStatusPantauanCard(
    BuildContext context,
    bool isDark,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    final sosCount = controller.activeSosCount.value;
    final hasSos = sosCount > 0;

    final jamaahCount = controller.totalJamaah.value;
    final pendampingCount = controller.totalPendamping.value;
    final activeRooms = controller.activeRoomsCount;

    final bgColor = hasSos
        ? (isDark ? const Color(0xFF381418) : const Color(0xFFFFF1F1))
        : (isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite);

    final borderColor = hasSos
        ? AppColors.sosEmergency
        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasSos ? borderColor.withValues(alpha: 0.6) : borderColor,
          width: hasSos ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hasSos
                ? AppColors.sosEmergency.withValues(alpha: 0.12)
                : (isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.04)),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (hasSos
                                  ? AppColors.sosEmergency
                                  : AppColors.statusSafe)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color:
                            (hasSos
                                    ? AppColors.sosEmergency
                                    : AppColors.statusSafe)
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasSos
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          color: hasSos
                              ? AppColors.sosEmergency
                              : AppColors.statusSafe,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasSos
                                ? '$sosCount SOS MEMERLUKAN TINDAKAN'
                                : 'Sistem Operasional Aman',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge.copyWith(
                              color: hasSos
                                  ? AppColors.sosEmergency
                                  : AppColors.statusSafe,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (hasSos) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => dashboardCtrl.changeTab(1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 34,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sosEmergency,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sosEmergency.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Peta SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.sm + 2),

            // Description
            Text(
              hasSos
                  ? 'Terdeteksi sinyal darurat aktif dari jamaah. Mohon prioritaskan penanganan atau koordinasi pendamping.'
                  : 'Seluruh room terpantau normal. Jamaah dan pendamping terhubung dalam pengawasan Command Center.',
              style: AppTypography.bodySmall.copyWith(
                color: headingColor,
                height: 1.4,
              ),
            ),

            const SizedBox(height: AppSpacing.sm + 4),

            // Summary metrics
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMiniBadge(
                  icon: Icons.groups_rounded,
                  label: '$jamaahCount Jamaah',
                  color: const Color(0xFF2E7D32),
                  isDark: isDark,
                ),
                _buildMiniBadge(
                  icon: Icons.health_and_safety_rounded,
                  label: '$pendampingCount Pendamping',
                  color: const Color(0xFF1976D2),
                  isDark: isDark,
                ),
                _buildMiniBadge(
                  icon: Icons.meeting_room_rounded,
                  label: '$activeRooms Room Aktif',
                  color: isDark
                      ? AppColors.darkPrimary
                      : AppColors.accentGoldStar,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Overview KPI Grid ────────────────────────────────────────────────────
  Widget _buildKpiOverview(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    final activeRooms = controller.activeRoomsCount;
    final totalRooms = controller.rooms.length;
    final totalJamaah = controller.totalJamaah.value;
    final totalPendamping = controller.totalPendamping.value;
    final activeSos = controller.activeSosCount.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overview Operasional',
              style: AppTypography.titleMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Realtime metrics',
              style: AppTypography.captionSmall.copyWith(
                color: bodyColor.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Row 1
        Row(
          children: [
            Expanded(
              child: _KpiMetricCard(
                title: 'Room Aktif',
                value: '$activeRooms',
                subtitle: 'dari $totalRooms room',
                icon: Icons.meeting_room_rounded,
                color: isDark
                    ? AppColors.darkPrimary
                    : AppColors.accentGoldStar,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                isDark: isDark,
                onTap: () => _showActiveRoomsSheet(
                  context,
                  controller,
                  isDark,
                  cardBg,
                  headingColor,
                  bodyColor,
                  primaryColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiMetricCard(
                title: 'Total Jamaah',
                value: '$totalJamaah',
                subtitle: 'terdaftar di sistem',
                icon: Icons.groups_rounded,
                color: const Color(0xFF2E7D32),
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                isDark: isDark,
                onTap: () => _showAllJamaahSheet(
                  context,
                  controller,
                  isDark,
                  cardBg,
                  headingColor,
                  bodyColor,
                  primaryColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Row 2
        Row(
          children: [
            Expanded(
              child: _KpiMetricCard(
                title: 'Pendamping',
                value: '$totalPendamping',
                subtitle: 'petugas aktif',
                icon: Icons.health_and_safety_rounded,
                color: const Color(0xFF1976D2),
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                isDark: isDark,
                onTap: () => _showAllPendampingSheet(
                  context,
                  controller,
                  isDark,
                  cardBg,
                  headingColor,
                  bodyColor,
                  primaryColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiMetricCard(
                title: 'Alert Aktif',
                value: '$activeSos',
                subtitle: activeSos > 0 ? 'Perlu tindakan!' : 'Kondisi aman',
                icon: activeSos > 0
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user_rounded,
                color: activeSos > 0
                    ? AppColors.sosEmergency
                    : AppColors.statusSafe,
                isHighlighted: activeSos > 0,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                isDark: isDark,
                onTap: () => _showAlertCenterSheet(
                  context,
                  controller,
                  dashboardCtrl,
                  isDark,
                  cardBg,
                  headingColor,
                  bodyColor,
                  primaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 4. Quick Actions ───────────────────────────────────────────────────────
  Widget _buildQuickActions(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: AppTypography.titleMedium.copyWith(
            color: headingColor,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Row 1
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: 'Buat Room',
                subtitle: 'Grup/Kloter baru',
                icon: Icons.add_business_rounded,
                color: primaryColor,
                isPrimary: true,
                cardBg: cardBg,
                headingColor: headingColor,
                isDark: isDark,
                onTap: () => _showCreateRoomSheet(context, controller),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                label: 'Kelola Jamaah',
                subtitle: 'Daftar semua room',
                icon: Icons.manage_accounts_rounded,
                color: const Color(0xFF2E7D32),
                cardBg: cardBg,
                headingColor: headingColor,
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.adminRooms),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Row 2
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: 'Pantau Map',
                subtitle: 'Lokasi & perimeter',
                icon: Icons.map_rounded,
                color: const Color(0xFF1976D2),
                cardBg: cardBg,
                headingColor: headingColor,
                isDark: isDark,
                onTap: () => dashboardCtrl.changeTab(1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                label: 'Lihat Alert',
                subtitle: controller.activeSosCount.value > 0
                    ? '${controller.activeSosCount.value} SOS aktif'
                    : 'Pusat notifikasi',
                icon: Icons.notification_important_rounded,
                color: controller.activeSosCount.value > 0
                    ? AppColors.sosEmergency
                    : AppColors.statusSafe,
                cardBg: cardBg,
                headingColor: headingColor,
                isDark: isDark,
                onTap: () {
                  if (controller.activeSosCount.value > 0) {
                    dashboardCtrl.changeTab(1);
                  } else {
                    Get.toNamed(AppRoutes.notification);
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Row 3: Broadcast & Geofence
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: 'Kirim Notifikasi',
                subtitle: 'Siaran Admin multi-scope',
                icon: Icons.campaign_rounded,
                color: const Color(0xFFD97706),
                cardBg: cardBg,
                headingColor: headingColor,
                isDark: isDark,
                onTap: () => NotificationComposerDialog.show(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                label: 'Perimeter / Geofence',
                subtitle: 'Radius aman jamaah',
                icon: Icons.radar_rounded,
                color: const Color(0xFF00897B),
                cardBg: cardBg,
                headingColor: headingColor,
                isDark: isDark,
                onTap: () => dashboardCtrl.changeTab(1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 5. Room Pantau Section ─────────────────────────────────────────────────
  Widget _buildRoomPantauSection(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    final recentRooms = controller.recentActiveRooms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Room Pantau',
              style: AppTypography.titleMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Text(
                'Lihat Semua',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              label: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
              onPressed: () => Get.toNamed(AppRoutes.adminRooms),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        if (recentRooms.isEmpty)
          AppCard(
            backgroundColor: cardBg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primaryGold)
                                .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.meeting_room_outlined,
                        size: 30,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Belum Ada Room Pantau Aktif',
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Buat room baru untuk mulai memantau jamaah dan koordinasi pendamping maktab.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: bodyColor),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: isDark
                            ? AppColors.darkOnPrimary
                            : Colors.white,
                        minimumSize: const Size(160, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Buat Room Baru',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () =>
                          _showCreateRoomSheet(context, controller),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: recentRooms.map((room) {
              final jCount = controller.getRoomJamaahCount(room.id);
              final pCount = controller.getRoomPendampingCount(room.id);
              final sCount = controller.getRoomSosCount(room.id);

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _RoomPantauCard(
                  room: room,
                  jamaahCount: jCount,
                  pendampingCount: pCount,
                  sosCount: sCount,
                  cardBg: cardBg,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    controller.selectedRoom.value = room;
                    controller.subscribeToRoomMembers(room.id);
                    Get.toNamed(AppRoutes.roomDetail, arguments: room);
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── 6. Aktivitas Terbaru ───────────────────────────────────────────────────
  Widget _buildRecentActivitiesSection(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    // 1. Ambil semua aktivitas dari source yang tersedia
    // 2. Gunakan timestamp aktual & 3. Urutkan DESCENDING
    final sortedActivities = List<ActivityModel>.from(controller.activities)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 4. Ambil 2 pertama
    final previewActivities = sortedActivities.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Live Stream Pill & View All
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.20 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.35 : 0.20,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: 19,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktivitas Terbaru',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _LivePulseIndicator(
                              color: AppColors.statusSafe,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                previewActivities.isEmpty
                                    ? 'Realtime • Pemantauan aktif'
                                    : 'Realtime • ${previewActivities.length} aktivitas',
                                style: AppTypography.captionSmall.copyWith(
                                  color: bodyColor.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 36),
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Text(
                'Lihat Semua',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              label: const Icon(Icons.arrow_forward_ios_rounded, size: 11),
              onPressed: () => _showAllActivitiesSheet(
                context,
                controller,
                isDark,
                headingColor,
                bodyColor,
                primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 2),

        // Body: Empty State or Activity Cards List (maksimal 2 aktivitas)
        if (previewActivities.isEmpty)
          AppCard(
            backgroundColor: cardBg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.statusSafe.withValues(
                          alpha: isDark ? 0.18 : 0.10,
                        ),
                        border: Border.all(
                          color: AppColors.statusSafe.withValues(
                            alpha: isDark ? 0.35 : 0.25,
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.verified_user_rounded,
                          size: 30,
                          color: AppColors.statusSafe,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Semua Kondisi Terkendali',
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Belum ada insiden darurat, mutasi kamar, atau perubahan operasional tercatat hari ini.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: bodyColor.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.canvasCreamSubtle)
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 13,
                            color: AppColors.statusSafe,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Sinkronisasi Cloud Firestore Aktif',
                            style: AppTypography.captionSmall.copyWith(
                              color: bodyColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          AppCard(
            backgroundColor: cardBg,
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previewActivities.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.8,
                indent: 58,
                endIndent: AppSpacing.md,
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.canvasCreamSubtle,
              ),
              itemBuilder: (context, idx) {
                final act = previewActivities[idx];
                return _ActivityFeedTile(
                  activity: act,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  isDark: isDark,
                  onTap: () => _showActivityDetailSheet(
                    context,
                    act,
                    controller,
                    isDark,
                    headingColor,
                    bodyColor,
                    primaryColor,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── Activity Detail Bottom Sheet ──────────────────────────────────────────
  void _showActivityDetailSheet(
    BuildContext context,
    ActivityModel act,
    AdminRoomController controller,
    bool isDark,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    HapticFeedback.lightImpact();
    final matchingRoom = act.roomId != null
        ? controller.rooms.firstWhereOrNull((r) => r.id == act.roomId)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Header Badge & Type
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: act.color.withValues(alpha: isDark ? 0.22 : 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: act.color.withValues(
                          alpha: isDark ? 0.45 : 0.30,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(act.icon, color: act.color, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: act.color.withValues(
                                  alpha: isDark ? 0.20 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                _activityTypeName(act.type),
                                style: AppTypography.captionSmall.copyWith(
                                  color: act.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              act.timeAgo,
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          act.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Timestamp Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? AppColors.darkCardBorder
                              : AppColors.canvasCreamSubtle)
                          .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: bodyColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatFullDate(act.timestamp),
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Description Box
              Text(
                'Keterangan Aktivitas',
                style: AppTypography.captionSmall.copyWith(
                  color: bodyColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkScaffold.withValues(alpha: 0.5)
                      : AppColors.canvasCream.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.canvasCreamSubtle,
                  ),
                ),
                child: Text(
                  act.description.isNotEmpty
                      ? act.description
                      : 'Tidak ada rincian tambahan untuk peristiwa ini.',
                  style: AppTypography.bodySmall.copyWith(
                    color: headingColor,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ),

              // Room Card info & navigation
              if (act.roomName != null || matchingRoom != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ruang Pantau Terkait',
                  style: AppTypography.captionSmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          Icons.meeting_room_rounded,
                          size: 18,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.roomName ??
                                  matchingRoom?.name ??
                                  'Room Pantau',
                              style: AppTypography.titleSmall.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            if (matchingRoom != null)
                              Text(
                                'Status: ${matchingRoom.isActive ? "Aktif Dipantau" : "Non-Aktif"}',
                                style: AppTypography.captionSmall.copyWith(
                                  color: matchingRoom.isActive
                                      ? AppColors.statusSafe
                                      : bodyColor.withValues(alpha: 0.7),
                                  fontSize: 10.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (matchingRoom != null)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: isDark
                                ? AppColors.darkOnPrimary
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text(
                            'Buka Room',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            controller.selectedRoom.value = matchingRoom;
                            controller.subscribeToRoomMembers(matchingRoom.id);
                            Get.toNamed(
                              AppRoutes.roomDetail,
                              arguments: matchingRoom,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],

              // User/Actor Card
              if (act.userName != null || act.role != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.darkCardBorder
                                : AppColors.canvasCreamSubtle)
                            .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: bodyColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pelaksana / Terkait: ',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${act.userName ?? 'User'} ${act.role != null ? "(${act.role})" : ""}',
                          style: AppTypography.captionSmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: headingColor,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.canvasCreamSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Show All Activities Bottom Sheet (Paginated 10/page) ───────────────────
  void _showAllActivitiesSheet(
    BuildContext context,
    AdminRoomController controller,
    bool isDark,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    HapticFeedback.lightImpact();
    String activeFilter = 'Semua';
    String searchQuery = '';

    // Load initial 10 activities on open
    controller.loadInitialActivities(filter: 'Semua');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                // Attach auto-pagination scroll listener
                scrollController.addListener(() {
                  if (scrollController.hasClients &&
                      scrollController.position.pixels >=
                          scrollController.position.maxScrollExtent - 120) {
                    if (controller.hasMoreActivities.value &&
                        !controller.isActivitiesPageLoadingMore.value) {
                      controller.loadMoreActivities();
                    }
                  }
                });

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: bodyColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Sheet Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Riwayat Aktivitas Lengkap',
                                style: AppTypography.titleMedium.copyWith(
                                  color: headingColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Obx(() => Text(
                                    '${controller.paginatedActivities.length} aktivitas termuat (batch 10/halaman)',
                                    style: AppTypography.captionSmall.copyWith(
                                      color: bodyColor.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: bodyColor,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Search Box
                      Container(
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.darkCardBorder
                                      : AppColors.canvasCreamSubtle)
                                  .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : AppColors.canvasCreamSubtle,
                          ),
                        ),
                        child: TextField(
                          style: TextStyle(color: headingColor, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari aktivitas, kamar, atau jamaah...',
                            hintStyle: TextStyle(
                              color: bodyColor.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: bodyColor.withValues(alpha: 0.7),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildModalFilterChip(
                              'Semua',
                              activeFilter == 'Semua',
                              primaryColor,
                              headingColor,
                              isDark,
                              () {
                                setModalState(() => activeFilter = 'Semua');
                                controller.loadInitialActivities(filter: 'Semua');
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildModalFilterChip(
                              'Darurat / SOS',
                              activeFilter == 'Darurat',
                              AppColors.sosEmergency,
                              headingColor,
                              isDark,
                              () {
                                setModalState(() => activeFilter = 'Darurat');
                                controller.loadInitialActivities(filter: 'Darurat');
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildModalFilterChip(
                              'Room Pantau',
                              activeFilter == 'Kamar',
                              primaryColor,
                              headingColor,
                              isDark,
                              () {
                                setModalState(() => activeFilter = 'Kamar');
                                controller.loadInitialActivities(filter: 'Kamar');
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildModalFilterChip(
                              'Anggota',
                              activeFilter == 'Anggota',
                              AppColors.statusSafe,
                              headingColor,
                              isDark,
                              () {
                                setModalState(() => activeFilter = 'Anggota');
                                controller.loadInitialActivities(filter: 'Anggota');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Paginated Activities List
                      Expanded(
                        child: Obx(() {
                          if (controller.isActivitiesPageLoading.value &&
                              controller.paginatedActivities.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 2.5,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Memuat 10 riwayat terbaru...',
                                    style: AppTypography.captionSmall
                                        .copyWith(color: bodyColor),
                                  ),
                                ],
                              ),
                            );
                          }

                          final activities = controller.paginatedActivities;
                          final filtered = activities.where((a) {
                            if (searchQuery.trim().isNotEmpty) {
                              final q = searchQuery.toLowerCase().trim();
                              final matchTitle = a.title.toLowerCase().contains(q);
                              final matchDesc = a.description.toLowerCase().contains(q);
                              final matchRoom = a.roomName?.toLowerCase().contains(q) ?? false;
                              final matchUser = a.userName?.toLowerCase().contains(q) ?? false;
                              if (!matchTitle && !matchDesc && !matchRoom && !matchUser) {
                                return false;
                              }
                            }
                            return true;
                          }).toList();

                          if (filtered.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 44,
                                    color: bodyColor.withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Tidak Ada Aktivitas Sesuai Filter',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: headingColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Belum ada data aktivitas atau coba ubah kata kunci pencarian.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.captionSmall
                                        .copyWith(color: bodyColor),
                                  ),
                                ],
                              ),
                            );
                          }

                          // List items count + 1 for footer / load more
                          final hasMore = controller.hasMoreActivities.value;
                          final isLoadingMore = controller.isActivitiesPageLoadingMore.value;
                          final totalItems = filtered.length + 1;

                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xl,
                            ),
                            itemCount: totalItems,
                            separatorBuilder: (context, index) {
                              if (index >= filtered.length - 1) {
                                return const SizedBox(height: AppSpacing.sm);
                              }
                              return Divider(
                                height: 1,
                                thickness: 0.8,
                                indent: 58,
                                endIndent: AppSpacing.md,
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.canvasCreamSubtle,
                              );
                            },
                            itemBuilder: (context, idx) {
                              // Footer element
                              if (idx == filtered.length) {
                                if (isLoadingMore) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Memuat 10 riwayat berikutnya...',
                                            style: AppTypography.captionSmall
                                                .copyWith(color: bodyColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                if (hasMore) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: primaryColor,
                                          side: BorderSide(
                                            color: primaryColor.withValues(alpha: 0.4),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.pill,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        icon: const Icon(Icons.expand_more_rounded, size: 18),
                                        label: const Text(
                                          'Muat 10 Riwayat Berikutnya',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () => controller.loadMoreActivities(),
                                      ),
                                    ),
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      '— Semua riwayat telah ditampilkan —',
                                      style: AppTypography.captionSmall.copyWith(
                                        color: bodyColor.withValues(alpha: 0.5),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final act = filtered[idx];
                              return _ActivityFeedTile(
                                activity: act,
                                headingColor: headingColor,
                                bodyColor: bodyColor,
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _showActivityDetailSheet(
                                    context,
                                    act,
                                    controller,
                                    isDark,
                                    headingColor,
                                    bodyColor,
                                    primaryColor,
                                  );
                                },
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildModalFilterChip(
    String label,
    bool isSelected,
    Color activeColor,
    Color headingColor,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark
                        ? AppColors.darkCardBorder
                        : AppColors.canvasCreamSubtle)
                    .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark
                      ? AppColors.darkCardBorder
                      : AppColors.canvasCreamSubtle),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: isSelected
                ? activeColor
                : headingColor.withValues(alpha: 0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  static String _activityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.roomCreated:
        return 'Room Dibuat';
      case ActivityType.roomActivated:
        return 'Room Diaktifkan';
      case ActivityType.roomDeactivated:
        return 'Room Dinonaktifkan';
      case ActivityType.roomUpdated:
        return 'Room Diperbarui';
      case ActivityType.memberJoined:
        return 'Anggota Masuk';
      case ActivityType.memberLeft:
        return 'Anggota Keluar';
      case ActivityType.sosActive:
        return 'Peringatan Darurat SOS';
      case ActivityType.unknown:
        return 'Aktivitas Operasional';
    }
  }

  static String _formatFullDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WIB';
  }

  // ── Create Room Modal Bottom Sheet ─────────────────────────────────────────
  void _showCreateRoomSheet(
    BuildContext context,
    AdminRoomController controller,
  ) {
    final textCtrl = TextEditingController();
    final isDark = AppColors.isDark(context);
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
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
                    color: bodyColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.add_business_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Room Pantau Baru',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: headingColor,
                          ),
                        ),
                        Text(
                          'Kelompok / Maktab / Rombongan',
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Masukkan nama kelompok atau maktab. Kode unik 6-karakter akan di-generate otomatis untuk dibagikan ke jamaah & pendamping.',
                style: AppTypography.bodySmall.copyWith(
                  color: bodyColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: textCtrl,
                autofocus: true,
                style: TextStyle(color: headingColor),
                decoration: InputDecoration(
                  labelText: 'Nama Kelompok / Room',
                  hintText: 'Misal: Maktab 48 Kloter 12',
                  hintStyle: TextStyle(color: bodyColor.withValues(alpha: 0.5)),
                  prefixIcon: Icon(
                    Icons.meeting_room_rounded,
                    color: primaryColor,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.canvasCreamSubtle,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.canvasCreamSubtle,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: primaryColor, width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(() {
                final submitting = controller.isSubmitting.value;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDark
                          ? AppColors.darkOnPrimary
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 2,
                    ),
                    onPressed: submitting
                        ? null
                        : () => controller.createRoom(context, textCtrl.text),
                    child: submitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: isDark
                                  ? AppColors.darkOnPrimary
                                  : Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Simpan & Buat Room',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── 1. Active Rooms Bottom Sheet ───────────────────────────────────────────
  void _showActiveRoomsSheet(
    BuildContext context,
    AdminRoomController controller,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final activeRooms = controller.activeRooms;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: bodyColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.accentGoldStar)
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(
                                Icons.meeting_room_rounded,
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.accentGoldStar,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ROOM AKTIF',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: headingColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '${activeRooms.length} room aktif beroperasi',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: bodyColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: bodyColor,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Active Rooms List
                    Expanded(
                      child: activeRooms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 48,
                                    color: bodyColor.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Tidak ada room aktif saat ini.',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: bodyColor),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: activeRooms.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, idx) {
                                final room = activeRooms[idx];
                                final jCount =
                                    controller.getRoomJamaahCount(room.id);
                                final pCount =
                                    controller.getRoomPendampingCount(room.id);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkCardBorder
                                          : AppColors.lightCardBorder,
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black
                                                .withValues(alpha: 0.15)
                                            : AppColors.primary
                                                .withValues(alpha: 0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        controller.selectedRoom.value = room;
                                        controller
                                            .subscribeToRoomMembers(room.id);
                                        Get.toNamed(
                                          AppRoutes.roomDetail,
                                          arguments: room,
                                        );
                                      },
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.card),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.md),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Top: Icon + Name + Aktif Badge
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.apartment_rounded,
                                                  size: 18,
                                                  color: primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    room.name,
                                                    style: AppTypography
                                                        .titleSmall
                                                        .copyWith(
                                                      color: headingColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 2.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.statusSafe
                                                        .withValues(
                                                      alpha:
                                                          isDark ? 0.2 : 0.12,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      AppRadius.pill,
                                                    ),
                                                    border: Border.all(
                                                      color: AppColors
                                                          .statusSafe
                                                          .withValues(
                                                        alpha: 0.3,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 5,
                                                        height: 5,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: AppColors
                                                              .statusSafe,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Aktif',
                                                        style: AppTypography
                                                            .captionSmall
                                                            .copyWith(
                                                          color: AppColors
                                                              .statusSafe,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),

                                            // Middle: Count
                                            Text(
                                              '$jCount Jamaah • $pCount Pendamping',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: bodyColor
                                                    .withValues(alpha: 0.85),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),

                                            // Bottom: Kode + Arrow
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Kode: ${room.code}',
                                                  style: AppTypography
                                                      .captionSmall
                                                      .copyWith(
                                                    color: headingColor,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  size: 11,
                                                  color: headingColor
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              );
            });
          },
        );
      },
    );
  }

  // ── 2. Total Jamaah Bottom Sheet ───────────────────────────────────────────
  void _showAllJamaahSheet(
    BuildContext context,
    AdminRoomController controller,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    HapticFeedback.lightImpact();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Obx(() {
                  final allJamaah = controller.allJamaah;
                  final q = searchQuery.toLowerCase().trim();
                  final filtered = allJamaah.where((j) {
                    final name = (j['name'] ?? j['displayName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final room = controller.rooms
                            .firstWhereOrNull((r) => r.id == j['activeRoomId'])
                            ?.name
                            .toLowerCase() ??
                        '';
                    if (q.isEmpty) return true;
                    return name.contains(q) || room.contains(q);
                  }).toList();

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        // Drag handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: bodyColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: const Icon(
                                    Icons.groups_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL JAMAAH',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: headingColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      '${filtered.length} dari ${allJamaah.length} jamaah terdaftar',
                                      style:
                                          AppTypography.captionSmall.copyWith(
                                        color: bodyColor.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              color: bodyColor,
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Search Field
                        TextField(
                          onChanged: (val) {
                            setSheetState(() {
                              searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari jamaah atau maktab...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: bodyColor.withValues(alpha: 0.6),
                              size: 18,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkScaffold.withValues(alpha: 0.5)
                                : AppColors.canvasCream.withValues(alpha: 0.4),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.lightCardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.lightCardBorder,
                              ),
                            ),
                          ),
                          style: TextStyle(color: headingColor, fontSize: 13),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // List
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_search_rounded,
                                        size: 48,
                                        color:
                                            bodyColor.withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        searchQuery.isEmpty
                                            ? 'Belum ada data jamaah terdaftar.'
                                            : 'Tidak ada jamaah yang cocok dengan "$searchQuery".',
                                        style: AppTypography.bodySmall
                                            .copyWith(color: bodyColor),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (context, idx) {
                                    final j = filtered[idx];
                                    final name = (j['name'] ??
                                            j['displayName'] ??
                                            'Jamaah')
                                        .toString();
                                    final room = controller.rooms
                                        .firstWhereOrNull(
                                            (r) => r.id == j['activeRoomId']);
                                    final roomName = room?.name ??
                                        'Belum terdaftar di room';
                                    final isSos = j['sosActive'] == true;
                                    final isGps = j['isGpsActive'] == true;
                                    final locUpdatedAt =
                                        j['locationUpdatedAt'] is Timestamp
                                            ? (j['locationUpdatedAt']
                                                    as Timestamp)
                                                .toDate()
                                            : null;

                                    // Determine status dot & text
                                    final Color dotColor;
                                    final String statusLabel;

                                    if (isSos) {
                                      dotColor = AppColors.sosEmergency;
                                      statusLabel = '● SOS Aktif';
                                    } else if (locUpdatedAt != null) {
                                      final diff = DateTime.now()
                                          .difference(locUpdatedAt);
                                      if (diff.inMinutes <= 5 || isGps) {
                                        dotColor = AppColors.statusSafe;
                                        statusLabel = '● Online';
                                      } else {
                                        dotColor = const Color(
                                            0xFFF57C00); // Amber
                                        statusLabel =
                                            'Lokasi terakhir ${_formatMinutesAgo(diff)}';
                                      }
                                    } else if (isGps) {
                                      dotColor = AppColors.statusSafe;
                                      statusLabel = '● Online';
                                    } else {
                                      dotColor =
                                          bodyColor.withValues(alpha: 0.5);
                                      statusLabel = 'Offline';
                                    }

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.card),
                                        border: Border.all(
                                          color: isSos
                                              ? AppColors.sosEmergency
                                                  .withValues(alpha: 0.6)
                                              : (isDark
                                                  ? AppColors.darkCardBorder
                                                  : AppColors.lightCardBorder),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black
                                                    .withValues(alpha: 0.15)
                                                : AppColors.primary
                                                    .withValues(alpha: 0.03),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            if (room != null) {
                                              Navigator.pop(ctx);
                                              controller.selectedRoom.value =
                                                  room;
                                              controller
                                                  .subscribeToRoomMembers(
                                                      room.id);
                                              Get.toNamed(
                                                AppRoutes.roomDetail,
                                                arguments: room,
                                              );
                                            } else {
                                              AppAlert.info(
                                                context,
                                                title: name,
                                                message:
                                                    'Jamaah ini belum terdaftar di dalam room manapun.',
                                              );
                                            }
                                          },
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.card),
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                // Status indicator circle
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: dotColor,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),

                                                // Info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: AppTypography
                                                            .titleSmall
                                                            .copyWith(
                                                          color: headingColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(
                                                          height: 2),
                                                      Text(
                                                        roomName,
                                                        style: AppTypography
                                                            .captionSmall
                                                            .copyWith(
                                                          color: bodyColor
                                                              .withValues(
                                                                  alpha: 0.8),
                                                          fontSize: 11.5,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(
                                                          height: 3),
                                                      Text(
                                                        statusLabel,
                                                        style: AppTypography
                                                            .captionSmall
                                                            .copyWith(
                                                          color: dotColor,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 10.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  size: 11,
                                                  color: headingColor
                                                      .withValues(alpha: 0.35),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  );
                });
              },
            );
          },
        );
      },
    );
  }

  // ── 3. Pendamping Bottom Sheet ─────────────────────────────────────────────
  void _showAllPendampingSheet(
    BuildContext context,
    AdminRoomController controller,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final allPendamping = controller.allPendamping;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: bodyColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2)
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Icon(
                                Icons.health_and_safety_rounded,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PENDAMPING',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: headingColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '${allPendamping.length} petugas aktif terdaftar',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: bodyColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: bodyColor,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // List
                    Expanded(
                      child: allPendamping.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.health_and_safety_outlined,
                                    size: 48,
                                    color: bodyColor.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Belum ada petugas pendamping terdaftar.',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: bodyColor),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: allPendamping.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, idx) {
                                final p = allPendamping[idx];
                                final name = (p['name'] ??
                                        p['displayName'] ??
                                        'Pendamping')
                                    .toString();
                                final activeRoomId =
                                    p['activeRoomId'] as String?;
                                final room = activeRoomId != null &&
                                        activeRoomId.isNotEmpty
                                    ? controller.rooms.firstWhereOrNull(
                                        (r) => r.id == activeRoomId)
                                    : null;
                                final roomName =
                                    room?.name ?? 'Belum mengelola room';
                                final jamaahCount = activeRoomId != null
                                    ? controller
                                        .getRoomJamaahCount(activeRoomId)
                                    : null;
                                final isOnline =
                                    p['isGpsActive'] == true || room != null;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkCardBorder
                                          : AppColors.lightCardBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black
                                                .withValues(alpha: 0.15)
                                            : AppColors.primary
                                                .withValues(alpha: 0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        if (room != null) {
                                          Navigator.pop(ctx);
                                          controller.selectedRoom.value =
                                              room;
                                          controller
                                              .subscribeToRoomMembers(
                                                  room.id);
                                          Get.toNamed(
                                            AppRoutes.roomDetail,
                                            arguments: room,
                                          );
                                        } else {
                                          AppAlert.info(
                                            context,
                                            title: name,
                                            message:
                                                'Petugas ini belum ditugaskan ke room manapun.',
                                          );
                                        }
                                      },
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.card),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.md),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Avatar shield icon
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1976D2)
                                                    .withValues(
                                                  alpha: isDark ? 0.22 : 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  AppRadius.md,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.shield_rounded,
                                                color: Color(0xFF1976D2),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: AppTypography
                                                              .titleSmall
                                                              .copyWith(
                                                            color: headingColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 7,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: (isOnline
                                                                  ? AppColors
                                                                      .statusSafe
                                                                  : AppColors
                                                                      .textSecondary)
                                                              .withValues(
                                                            alpha: isDark
                                                                ? 0.2
                                                                : 0.12,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            AppRadius.pill,
                                                          ),
                                                          border: Border.all(
                                                            color: (isOnline
                                                                    ? AppColors
                                                                        .statusSafe
                                                                    : AppColors
                                                                        .textSecondary)
                                                                .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Container(
                                                              width: 5,
                                                              height: 5,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: isOnline
                                                                    ? AppColors
                                                                        .statusSafe
                                                                    : AppColors
                                                                        .textSecondary,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              isOnline
                                                                  ? 'Aktif'
                                                                  : 'Offline',
                                                              style: AppTypography
                                                                  .captionSmall
                                                                  .copyWith(
                                                                color: isOnline
                                                                    ? AppColors
                                                                        .statusSafe
                                                                    : AppColors
                                                                        .textSecondary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    roomName,
                                                    style: AppTypography
                                                        .captionSmall
                                                        .copyWith(
                                                      color: bodyColor
                                                          .withValues(
                                                              alpha: 0.8),
                                                      fontSize: 11.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                  if (jamaahCount != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '$jamaahCount Jamaah dipantau',
                                                      style: AppTypography
                                                          .captionSmall
                                                          .copyWith(
                                                        color: primaryColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 11,
                                              color: headingColor
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              );
            });
          },
        );
      },
    );
  }

  // ── 4. Alert Center Bottom Sheet ───────────────────────────────────────────
  void _showAlertCenterSheet(
    BuildContext context,
    AdminRoomController controller,
    DashboardController dashboardCtrl,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final activeSosList = controller.activeSosList;
              final attentionList = controller.attentionJamaahList;
              final resolvedList = controller.resolvedSosList;
              final hasActiveAlerts =
                  activeSosList.isNotEmpty || attentionList.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: bodyColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (hasActiveAlerts
                                        ? AppColors.sosEmergency
                                        : AppColors.statusSafe)
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(
                                hasActiveAlerts
                                    ? Icons.warning_amber_rounded
                                    : Icons.verified_user_rounded,
                                color: hasActiveAlerts
                                    ? AppColors.sosEmergency
                                    : AppColors.statusSafe,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALERT CENTER',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: headingColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  hasActiveAlerts
                                      ? '${activeSosList.length + attentionList.length} kondisi perlu perhatian'
                                      : 'Semua sistem aman & terkendali',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: bodyColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: bodyColor,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          if (!hasActiveAlerts) ...[
                            // Safe condition card
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 36,
                                horizontal: AppSpacing.lg,
                              ),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkCardBorder
                                      : AppColors.lightCardBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.statusSafe
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        size: 36,
                                        color: AppColors.statusSafe,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Tidak ada alert aktif',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: headingColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Semua kondisi jamaah saat ini aman.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: bodyColor.withValues(alpha: 0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          // 1. PRIORITAS TINGGI (SOS)
                          if (activeSosList.isNotEmpty) ...[
                            Text(
                              'PRIORITAS TINGGI',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.sosEmergency,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs + 2),
                            ...activeSosList.map((sos) {
                              final userName = sos['userName'] ?? 'Jamaah';
                              final roomName = sos['roomName'] ?? 'Room';
                              final timestamp = (sos['timestamp'] ??
                                  sos['createdAt']) as Timestamp?;
                              final timeAgo = timestamp != null
                                  ? _formatMinutesAgo(DateTime.now()
                                      .difference(timestamp.toDate()))
                                  : 'Baru saja';

                              return Container(
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.card),
                                  border: Border.all(
                                    color: AppColors.sosEmergency
                                        .withValues(alpha: 0.6),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.sosEmergency
                                          .withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.sosEmergency
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppRadius.pill,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('🚨',
                                                    style:
                                                        TextStyle(fontSize: 12)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'SOS',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.sosEmergency,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            timeAgo,
                                            style: AppTypography.captionSmall
                                                .copyWith(
                                              color: bodyColor
                                                  .withValues(alpha: 0.65),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        userName,
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          color: headingColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        roomName,
                                        style:
                                            AppTypography.bodySmall.copyWith(
                                          color: bodyColor
                                              .withValues(alpha: 0.75),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          dashboardCtrl.changeTab(1);
                                        },
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.sm),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Lihat di Peta',
                                                style: AppTypography
                                                    .captionSmall
                                                    .copyWith(
                                                  color:
                                                      AppColors.sosEmergency,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 11,
                                                color: AppColors.sosEmergency,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: AppSpacing.sm),
                          ],

                          // 2. PERLU PERHATIAN (Stale location / GPS inactive)
                          if (attentionList.isNotEmpty) ...[
                            Text(
                              'PERLU PERHATIAN',
                              style: AppTypography.captionSmall.copyWith(
                                color: const Color(0xFFF57C00),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs + 2),
                            ...attentionList.map((j) {
                              final name = (j['name'] ??
                                      j['displayName'] ??
                                      'Jamaah')
                                  .toString();
                              final room = controller.rooms.firstWhereOrNull(
                                  (r) => r.id == j['activeRoomId']);
                              final roomName = room?.name ?? 'Room';
                              final timestamp =
                                  j['locationUpdatedAt'] is Timestamp
                                      ? (j['locationUpdatedAt'] as Timestamp)
                                          .toDate()
                                      : null;
                              final timeAgo = timestamp != null
                                  ? _formatMinutesAgo(DateTime.now()
                                      .difference(timestamp))
                                  : 'Belum update';

                              return Container(
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.card),
                                  border: Border.all(
                                    color: const Color(0xFFF57C00)
                                        .withValues(alpha: 0.45),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black
                                              .withValues(alpha: 0.15)
                                          : AppColors.primary
                                              .withValues(alpha: 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (room != null) {
                                        Navigator.pop(ctx);
                                        controller.selectedRoom.value = room;
                                        controller
                                            .subscribeToRoomMembers(room.id);
                                        Get.toNamed(
                                          AppRoutes.roomDetail,
                                          arguments: room,
                                        );
                                      } else {
                                        Navigator.pop(ctx);
                                        dashboardCtrl.changeTab(1);
                                      }
                                    },
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.md),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text('📍',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Lokasi Tidak Diperbarui',
                                                    style: AppTypography
                                                        .captionSmall
                                                        .copyWith(
                                                      color: const Color(
                                                          0xFFF57C00),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                timeAgo,
                                                style: AppTypography
                                                    .captionSmall
                                                    .copyWith(
                                                  color: bodyColor
                                                      .withValues(alpha: 0.65),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: AppTypography
                                                          .titleSmall
                                                          .copyWith(
                                                        color: headingColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      roomName,
                                                      style: AppTypography
                                                          .captionSmall
                                                          .copyWith(
                                                        color: bodyColor
                                                            .withValues(
                                                                alpha: 0.75),
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 11,
                                                color: headingColor
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: AppSpacing.sm),
                          ],

                          // 3. Riwayat Terakhir (jika tersedia)
                          if (resolvedList.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Riwayat Terakhir',
                              style: AppTypography.captionSmall.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs + 2),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkCardBorder
                                      : AppColors.lightCardBorder,
                                ),
                              ),
                              child: Column(
                                children: resolvedList.map((res) {
                                  final name = res['userName'] ?? 'Jamaah';
                                  final resTime = (res['resolvedAt'] ??
                                      res['timestamp']) as Timestamp?;
                                  final timeAgo = resTime != null
                                      ? _formatMinutesAgo(DateTime.now()
                                          .difference(resTime.toDate()))
                                      : 'Selesai';

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 14,
                                          color: AppColors.statusSafe,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'SOS selesai ($name)',
                                            style: AppTypography.captionSmall
                                                .copyWith(
                                              color: headingColor,
                                              fontSize: 11.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          timeAgo,
                                          style: AppTypography.captionSmall
                                              .copyWith(
                                            color: bodyColor
                                                .withValues(alpha: 0.65),
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              );
            });
          },
        );
      },
    );
  }

  static String _formatMinutesAgo(Duration diff) {
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

// ── KPI Metric Card ─────────────────────────────────────────────────────────
class _KpiMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isHighlighted;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _KpiMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isHighlighted = false,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isHighlighted
        ? color.withValues(alpha: isDark ? 0.18 : 0.10)
        : cardBg;

    final borderColor = isHighlighted
        ? color.withValues(alpha: 0.6)
        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);

    return Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? color.withValues(alpha: 0.15)
                : (isDark
                      ? Colors.black.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.03)),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  value,
                  style: AppTypography.displayLarge.copyWith(
                    color: isHighlighted ? color : headingColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    color: isHighlighted
                        ? color
                        : bodyColor.withValues(alpha: 0.75),
                    fontSize: 10.5,
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

// ── Quick Action Button ───────────────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color cardBg;
  final Color headingColor;
  final bool isPrimary;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.cardBg,
    required this.headingColor,
    this.isPrimary = false,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: effectiveBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),

                const SizedBox(width: AppSpacing.sm),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          color: headingColor.withValues(alpha: 0.65),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: headingColor.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Room Pantau Card ─────────────────────────────────────────────────────────
class _RoomPantauCard extends StatelessWidget {
  final RoomModel room;
  final int jamaahCount;
  final int pendampingCount;
  final int sosCount;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _RoomPantauCard({
    required this.room,
    required this.jamaahCount,
    required this.pendampingCount,
    required this.sosCount,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSos = sosCount > 0;
    final borderColor = hasSos
        ? AppColors.sosEmergency
        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: hasSos ? AppColors.sosEmergency.withValues(alpha: 0.65) : borderColor,
          width: hasSos ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hasSos
                ? AppColors.sosEmergency.withValues(alpha: 0.08)
                : (isDark
                      ? Colors.black.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.03)),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Room Name + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (room.isActive
                                    ? AppColors.statusSafe
                                    : AppColors.textSecondary)
                                .withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color:
                              (room.isActive
                                      ? AppColors.statusSafe
                                      : AppColors.textSecondary)
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: room.isActive
                                  ? AppColors.statusSafe
                                  : AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            room.isActive ? 'Aktif' : 'Nonaktif',
                            style: AppTypography.captionSmall.copyWith(
                              color: room.isActive
                                  ? AppColors.statusSafe
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Metrics
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _BadgeCount(
                      icon: Icons.groups_rounded,
                      label: '$jamaahCount Jamaah',
                      color: const Color(0xFF2E7D32),
                      isDark: isDark,
                    ),

                    _BadgeCount(
                      icon: Icons.health_and_safety_rounded,
                      label: '$pendampingCount Pendamping',
                      color: const Color(0xFF1976D2),
                      isDark: isDark,
                    ),

                    if (hasSos)
                      _BadgeCount(
                        icon: Icons.warning_amber_rounded,
                        label: '$sosCount SOS',
                        color: AppColors.sosEmergency,
                        isDark: isDark,
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm + 4),

                // Divider subtle
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.canvasCreamSubtle,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Bottom Row: Room Code + Copy + Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: room.code));
                          AppAlert.info(
                            context,
                            title: 'Kode Disalin',
                            message:
                                'Kode room "${room.code}" berhasil disalin ke clipboard.',
                          );
                        },
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Kode: ',
                                style: AppTypography.captionSmall.copyWith(
                                  color: bodyColor,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  room.code,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: primaryColor.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.qr_code_2_rounded,
                            size: 18,
                            color: primaryColor,
                          ),
                          tooltip: 'Lihat QR Code',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => RoomQrDialog.show(context, room: room),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pantau Ruangan',
                          style: AppTypography.captionSmall.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeCount extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _BadgeCount({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulseIndicator extends StatefulWidget {
  final Color color;
  final bool isDark;

  const _LivePulseIndicator({required this.color, required this.isDark});

  @override
  State<_LivePulseIndicator> createState() => _LivePulseIndicatorState();
}

class _LivePulseIndicatorState extends State<_LivePulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.65 * _pulseAnimation.value,
                ),
                blurRadius: 6 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityFeedTile extends StatelessWidget {
  final ActivityModel activity;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _ActivityFeedTile({
    required this.activity,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSos = activity.type == ActivityType.sosActive;

    return Material(
      color: isSos
          ? AppColors.sosEmergency.withValues(alpha: isDark ? 0.12 : 0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: activity.color.withValues(alpha: 0.12),
        highlightColor: activity.color.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge with alert styling
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: activity.color.withValues(alpha: isDark ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activity.color.withValues(
                      alpha: isDark ? 0.40 : 0.25,
                    ),
                    width: 1.2,
                  ),
                  boxShadow: isSos
                      ? [
                          BoxShadow(
                            color: AppColors.sosEmergency.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(activity.icon, color: activity.color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Time & Alert pill
                    Row(
                      children: [
                        if (isSos) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.sosEmergency,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: const Text(
                              'DARURAT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            activity.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: isSos
                                  ? (isDark
                                        ? const Color(0xFFFF6B6B)
                                        : AppColors.sosEmergency)
                                  : headingColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: bodyColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              activity.timeAgo,
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Description
                    Text(
                      activity.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: bodyColor,
                        height: 1.38,
                        fontSize: 12.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Context Chips (Room / Actor)
                    if (activity.roomName != null ||
                        activity.userName != null ||
                        activity.role != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (activity.roomName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppColors.darkCardBorder
                                            : AppColors.canvasCreamSubtle)
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 11,
                                    color: bodyColor.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.roomName!,
                                    style: AppTypography.captionSmall.copyWith(
                                      color: bodyColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (activity.userName != null ||
                              activity.role != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppColors.darkCardBorder
                                            : AppColors.canvasCreamSubtle)
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 11,
                                    color: bodyColor.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${activity.userName ?? ""}${activity.role != null ? " (${activity.role})" : ""}'
                                        .trim(),
                                    style: AppTypography.captionSmall.copyWith(
                                      color: bodyColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing chevron icon
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: bodyColor.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
