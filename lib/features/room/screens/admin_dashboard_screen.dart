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
        icon: Icons.shield_rounded,
        actions: [
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
              // 1. Welcome Card (Luxury Islamic Command Center Banner)
              _buildWelcomeCard(context, isDark),
              const SizedBox(height: AppSpacing.md),

              // 2. Command Center / System Status Banner
              _buildStatusPantauanCard(
                context,
                isDark,
                headingColor,
                bodyColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Overview KPI (Adaptive, text-scale safe)
              _buildKpiOverview(context, isDark, cardBg, headingColor, bodyColor),
              const SizedBox(height: AppSpacing.lg),

              // 4. Quick Actions (Aksi Cepat)
              _buildQuickActions(
                context,
                isDark,
                cardBg,
                headingColor,
                primaryColor,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Room Pantau
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
              ? [
                  AppColors.darkSurfaceContainerHigh,
                  AppColors.darkSurface,
                ]
              : [
                  AppColors.primary,
                  AppColors.primaryContainer,
                ],
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
          color: hasSos
              ? borderColor.withValues(alpha: 0.6)
              : borderColor,
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
                      color: (hasSos
                              ? AppColors.sosEmergency
                              : AppColors.statusSafe)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: (hasSos
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
                              color: AppColors.sosEmergency.withValues(alpha: 0.35),
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
                  color: isDark ? AppColors.darkPrimary : AppColors.accentGoldStar,
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
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
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
                color: isDark ? AppColors.darkPrimary : AppColors.accentGoldStar,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
                isDark: isDark,
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
                        color: (isDark
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
                      style: AppTypography.bodySmall.copyWith(
                        color: bodyColor,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
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
    final activities = controller.activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terbaru',
              style: AppTypography.titleMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Realtime Stream',
                    style: AppTypography.captionSmall.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activities.isEmpty)
          AppCard(
            backgroundColor: cardBg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 38,
                      color: bodyColor.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Semua Kondisi Terkendali',
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Belum ada aktivitas operasional darurat atau mutasi kamar tercatat hari ini.',
                      textAlign: TextAlign.center,
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor,
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
              itemCount: activities.length > 5 ? 5 : activities.length,
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
                final act = activities[idx];
                return _ActivityFeedTile(
                  activity: act,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  isDark: isDark,
                );
              },
            ),
          ),
      ],
    );
  }

  // ── Create Room Modal Bottom Sheet ─────────────────────────────────────────
  void _showCreateRoomSheet(
    BuildContext context,
    AdminRoomController controller,
  ) {
    final textCtrl = TextEditingController();
    final isDark = AppColors.isDark(context);
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
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
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
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
                  prefixIcon: Icon(Icons.meeting_room_rounded, color: primaryColor),
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
                      foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
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
                              color: isDark ? AppColors.darkOnPrimary : Colors.white,
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
        border: Border.all(color: borderColor, width: isHighlighted ? 1.4 : 1.0),
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
                color: isHighlighted ? color : bodyColor.withValues(alpha: 0.75),
                fontSize: 10.5,
              ),
            ),
          ],
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
    final effectiveBg = isPrimary
        ? color.withValues(alpha: isDark ? 0.16 : 0.10)
        : cardBg;

    final effectiveBorder = isPrimary
        ? color.withValues(alpha: 0.5)
        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);

    return Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: effectiveBorder, width: isPrimary ? 1.3 : 1.0),
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
                    color: color.withValues(alpha: isDark ? 0.22 : 0.14),
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
                          fontWeight: isPrimary ? FontWeight.w800 : FontWeight.bold,
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
        color: hasSos
            ? (isDark ? const Color(0xFF381418) : const Color(0xFFFFF4F4))
            : cardBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: hasSos
              ? borderColor.withValues(alpha: 0.7)
              : borderColor,
          width: hasSos ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hasSos
                ? AppColors.sosEmergency.withValues(alpha: 0.12)
                : (isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.04)),
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
                        color: (room.isActive
                                ? AppColors.statusSafe
                                : AppColors.textSecondary)
                            .withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: (room.isActive
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
                            message: 'Kode room "${room.code}" berhasil disalin ke clipboard.',
                          );
                        },
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
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

class _ActivityFeedTile extends StatelessWidget {
  final ActivityModel activity;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _ActivityFeedTile({
    required this.activity,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: isDark ? 0.20 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: activity.color.withValues(alpha: isDark ? 0.35 : 0.25),
              ),
            ),
            child: Icon(activity.icon, color: activity.color, size: 17),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: AppTypography.titleSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activity.timeAgo,
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  activity.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyColor,
                    height: 1.35,
                    fontSize: 12.5,
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

