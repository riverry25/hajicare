import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
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
                    top: 10,
                    right: 10,
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
              // 1. Welcome Card (Styled after Login Welcome Banner)
              _buildWelcomeCard(context, isDark),
              const SizedBox(height: AppSpacing.md),

              // 2. Command Center / System Status Banner
              _buildStatusPantauanCard(
                context,
                isDark,
                headingColor,
                bodyColor,
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Overview KPI (Adaptive, text-scale safe)
              _buildKpiOverview(context, cardBg, headingColor, bodyColor),
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
        color: isDark ? AppColors.darkSurface : AppColors.espressoDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.goldLight.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.espressoDark).withValues(
              alpha: 0.16,
            ),
            blurRadius: 20,
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withValues(
                  alpha: isDark ? 0.08 : 0.12,
                ),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -45,
            child: Container(
              width: 80,
              height: 80,
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
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.goldLight.withValues(alpha: 0.25),
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
                          letterSpacing: 0.6,
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
                  'Assalamu\'alaikum, Admin. Pantau seluruh aktivitas dan keselamatan jamaah secara realtime.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.35,
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
                      'Live Sync Terhubung',
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
  ) {
    final sosCount = controller.activeSosCount.value;
    final hasSos = sosCount > 0;

    final jamaahCount = controller.totalJamaah.value;
    final pendampingCount = controller.totalPendamping.value;
    final activeRooms = controller.activeRoomsCount;

    final bgColor = hasSos
        ? (isDark ? const Color(0xFF3B1518) : const Color(0xFFFDE8E8))
        : (isDark ? const Color(0xFF132B1A) : const Color(0xFFE8F5E9));

    final borderColor = hasSos ? AppColors.sosEmergency : AppColors.statusSafe;

    return AppCard(
      backgroundColor: bgColor,
      borderColor: borderColor.withValues(alpha: 0.4),
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
                              .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasSos
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
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
                                : 'Sistem Normal',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMedium.copyWith(
                              color: hasSos
                                  ? AppColors.sosEmergency
                                  : AppColors.statusSafe,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
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
                  InkWell(
                    onTap: () => dashboardCtrl.changeTab(1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 36,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Peta',
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
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              hasSos
                  ? 'Terdeteksi sinyal darurat aktif dari jamaah. Harap segera lakukan tindakan atau arahkan pendamping.'
                  : 'Seluruh sistem aman. Jamaah dan pendamping terhubung dalam pengawasan Command Center.',
              style: AppTypography.bodySmall.copyWith(
                color: headingColor,
                height: 1.35,
              ),
            ),

            const SizedBox(height: AppSpacing.sm + 2),

            // Summary metrics
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMiniBadge(
                  icon: Icons.groups_rounded,
                  label: '$jamaahCount Jamaah',
                  color: const Color(0xFF2E7D32),
                ),
                _buildMiniBadge(
                  icon: Icons.health_and_safety_rounded,
                  label: '$pendampingCount Pendamping',
                  color: const Color(0xFF1976D2),
                ),
                _buildMiniBadge(
                  icon: Icons.meeting_room_rounded,
                  label: '$activeRooms Room Aktif',
                  color: AppColors.accentGoldStar,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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

  // ── 3. Overview KPI Grid ────────────────────────────────────────────────────
  Widget _buildKpiOverview(
    BuildContext context,
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
        Text(
          'Overview Operasional',
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
              child: _KpiMetricCard(
                title: 'Room Aktif',
                value: '$activeRooms',
                subtitle: 'dari $totalRooms room',
                icon: Icons.meeting_room_rounded,
                color: AppColors.accentGoldStar,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
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
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiMetricCard(
                title: 'Alert Aktif',
                value: '$activeSos',
                subtitle: activeSos > 0 ? 'Perlu tindakan!' : 'Kondisi aman',
                icon: activeSos > 0
                    ? Icons.warning_rounded
                    : Icons.verified_user_rounded,
                color: activeSos > 0
                    ? AppColors.sosEmergency
                    : AppColors.statusSafe,
                isHighlighted: activeSos > 0,
                cardBg: cardBg,
                headingColor: headingColor,
                bodyColor: bodyColor,
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
                icon: Icons.add_business_rounded,
                color: primaryColor,
                isPrimary: true,
                cardBg: cardBg,
                headingColor: headingColor,
                onTap: () => _showCreateRoomSheet(context, controller),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                label: 'Kelola Jamaah',
                icon: Icons.manage_accounts_rounded,
                color: const Color(0xFF2E7D32),
                cardBg: cardBg,
                headingColor: headingColor,
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
                icon: Icons.map_rounded,
                color: const Color(0xFF1976D2),
                cardBg: cardBg,
                headingColor: headingColor,
                onTap: () => dashboardCtrl.changeTab(1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                label: 'Lihat Alert',
                icon: Icons.notification_important_rounded,
                color: controller.activeSosCount.value > 0
                    ? AppColors.sosEmergency
                    : AppColors.statusSafe,
                cardBg: cardBg,
                headingColor: headingColor,
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
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 44,
                      color: bodyColor.withValues(alpha: 0.45),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Belum ada Room Pantau aktif',
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      'Buat room baru untuk mulai memantau jamaah dan pendamping.',
                      textAlign: TextAlign.center,
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(140, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Buat Room',
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Realtime',
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 36,
                      color: bodyColor.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Semua aman',
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Belum ada aktivitas operasional tercatat hari ini.',
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 5 ? 5 : activities.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 52,
                endIndent: AppSpacing.md,
                color: bodyColor.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, idx) {
                final act = activities[idx];
                return _ActivityFeedTile(
                  activity: act,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
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
            top: AppSpacing.lg,
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
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Buat Room Pantau Baru',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextHeading
                      : AppColors.espressoDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Masukkan nama kelompok/maktab. Kode room akan di-generate otomatis untuk dibagikan.',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: textCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nama Kelompok / Room',
                  hintText: 'Contoh: Maktab 48 Kloter 12',
                  prefixIcon: const Icon(Icons.meeting_room_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(() {
                final submitting = controller.isSubmitting.value;
                return SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 2,
                    ),
                    onPressed: submitting
                        ? null
                        : () => controller.createRoom(context, textCtrl.text),
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Buat Room Pantau',
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
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: isHighlighted ? color.withValues(alpha: 0.12) : cardBg,
      borderColor: isHighlighted ? color.withValues(alpha: 0.5) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
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
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              value,
              style: AppTypography.headlineLarge.copyWith(
                color: isHighlighted ? color : headingColor,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(
                color: isHighlighted ? color : bodyColor.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color cardBg;
  final Color headingColor;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.cardBg,
    required this.headingColor,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isPrimary ? color.withValues(alpha: 0.12) : cardBg;

    final effectiveBorder = isPrimary ? color.withValues(alpha: 0.4) : null;

    return AppCard(
      backgroundColor: effectiveBg,
      borderColor: effectiveBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: headingColor,
                    fontWeight: isPrimary ? FontWeight.w800 : FontWeight.bold,
                  ),
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: headingColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomPantauCard extends StatelessWidget {
  final RoomModel room;
  final int jamaahCount;
  final int pendampingCount;
  final int sosCount;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final Color primaryColor;
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
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSos = sosCount > 0;

    return AppCard(
      backgroundColor: cardBg,
      borderColor: hasSos
          ? AppColors.sosEmergency.withValues(alpha: 0.5)
          : null,
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
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      room.isActive ? 'Aktif' : 'Nonaktif',
                      style: AppTypography.captionSmall.copyWith(
                        color: room.isActive
                            ? AppColors.statusSafe
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
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
                  ),

                  _BadgeCount(
                    icon: Icons.health_and_safety_rounded,
                    label: '$pendampingCount Pendamping',
                    color: const Color(0xFF1976D2),
                  ),

                  if (hasSos)
                    _BadgeCount(
                      icon: Icons.warning_rounded,
                      label: '$sosCount SOS',
                      color: AppColors.sosEmergency,
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm + 2),

              // Bottom Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
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
                            style: AppTypography.labelMedium.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Pantauan',
                        style: AppTypography.captionSmall.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
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
    );
  }
}

class _BadgeCount extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BadgeCount({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
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

  const _ActivityFeedTile({
    required this.activity,
    required this.headingColor,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(activity.icon, color: activity.color, size: 18),
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
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyColor,
                    height: 1.3,
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
