import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../map/screens/interactive_map_screen.dart';
import 'dart:math' as math;
import '../../notification/controllers/notification_controller.dart';
import '../../prayer/controllers/prayer_times_controller.dart';
import '../../prayer/screens/prayer_times_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../room/widgets/active_room_card.dart';
import '../../communication/widgets/communication_gesture_dialog.dart';
import '../../smartband/controllers/smartband_ldr_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/rotating_sync_button.dart';

class DashboardJamaahScreen extends StatelessWidget {
  const DashboardJamaahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final state = Get.find<HajiCareController>();
    final prayerCtrl = Get.isRegistered<PrayerTimesController>()
        ? Get.find<PrayerTimesController>()
        : Get.put(PrayerTimesController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      extendBody: true,
      body: Obx(
        () => IndexedStack(
          index: dashboardCtrl.currentIndex.value,
          children: [
            _buildJamaahHome(context, state, dashboardCtrl, prayerCtrl),
            const InteractiveMapScreen(showBottomNav: false),
            const PrayerTimesScreen(showBottomNav: false),
            const ProfileScreen(showBottomNav: false),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => HajiCareBottomNavBar(
          currentIndex: dashboardCtrl.currentIndex.value,
          onTap: dashboardCtrl.changeTab,
        ),
      ),
    );
  }

  Widget _buildJamaahHome(
    BuildContext context,
    HajiCareController state,
    DashboardController dashboardCtrl,
    PrayerTimesController prayerCtrl,
  ) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    final heroGradient = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF1B120B),
              const Color(0xFF281A11),
              const Color(0xFF332115),
            ]
          : [
              const Color(0xFF26170E),
              const Color(0xFF382317),
              const Color(0xFF4A3020),
            ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1B120B)
          : const Color(0xFF26170E),
      body: Container(
        decoration: BoxDecoration(gradient: heroGradient),
        child: Obx(() {
          final jamaah = state.self;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // ── Top Hero Card (Seamless Gradient Canvas) ─────────────
                _buildHeroSection(
                  context: context,
                  jamaah: jamaah,
                  state: state,
                  dashboardCtrl: dashboardCtrl,
                  prayerCtrl: prayerCtrl,
                  isDark: isDark,
                ),

                // ── Curved White/Cream Canvas Sheet ──────────────────────
                _buildCurvedBody(
                  context: context,
                  jamaah: jamaah,
                  state: state,
                  dashboardCtrl: dashboardCtrl,
                  isDark: isDark,
                  headingColor: headingColor,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Hero Section (Top Card with Glowing Details) ───────────────────────────
  Widget _buildHeroSection({
    required BuildContext context,
    required JamaahData jamaah,
    required HajiCareController state,
    required DashboardController dashboardCtrl,
    required PrayerTimesController prayerCtrl,
    required bool isDark,
  }) {
    final topInset = MediaQuery.paddingOf(context).top;

    // Formatting Firebase Data
    final displayName = jamaah.name.trim().isNotEmpty
        ? jamaah.name.trim()
        : (jamaah.shortLabel.isNotEmpty ? jamaah.shortLabel : 'Jamaah Haji');
    final initialLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'J';

    // Firebase Porsi number directly from users collection
    final porsiNumber =
        (jamaah.porsi != null && jamaah.porsi!.trim().isNotEmpty)
        ? jamaah.porsi!.trim()
        : '1300948201';

    // Distance formatting (Promoted to Hero Display)
    final distanceDisplay = jamaah.distance > 0
        ? (jamaah.distance < 1000
              ? '${jamaah.distance.round()} m'
              : '${(jamaah.distance / 1000).toStringAsFixed(1)} km')
        : '20 m';

    // Next prayer time display with timezone suffix stripped to avoid overflow
    final prayerName = prayerCtrl.nextPrayerName.value.isNotEmpty
        ? prayerCtrl.nextPrayerName.value
        : 'Ashar';
    final rawPrayerTime = prayerCtrl.nextPrayerTime.value.isNotEmpty
        ? prayerCtrl.nextPrayerTime.value
        : '15:20';
    final cleanPrayerTime = rawPrayerTime.split(' ').first;

    // Location / GPS status
    final gpsDisplay = jamaah.isGpsActive ? 'Aktif (GPS)' : 'Terhubung';

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Bar: User Greeting & Notification / SOS ───────
          Row(
            children: [
              // User Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4A857), Color(0xFFA67C52)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initialLetter,
                    style: const TextStyle(
                      color: Color(0xFF2E1C12),
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Greeting & Kloter Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahlan wa Sahlan,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kloter ${jamaah.kloter ?? '12'} • Maktab ${jamaah.maktab ?? '48'}',
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification Bell with Glowing Badge
              _buildNotificationButton(context, state, isDark),
            ],
          ),

          const SizedBox(height: 26),

          // ── Big Hero Identification (Jarak Petugas) ──────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      distanceDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        context.tr('officerDistance') != 'officerDistance'
                            ? context.tr('officerDistance')
                            : 'Jarak ke Petugas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sync / Refresh Location Circular Button with spinning animation
              RotatingSyncButton(
                onSync: () async {
                  await state.refreshLocation();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr('locationRefreshed') != 'locationRefreshed'
                              ? context.tr('locationRefreshed')
                              : 'Lokasi GPS berhasil diperbarui',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Subtle Dotted / Dashed Divider ───────────────────────
          _buildDashedLine(Colors.white.withValues(alpha: 0.20)),

          const SizedBox(height: 16),

          // ── 3 Key Metrics Columns ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn(value: porsiNumber, label: 'Nomor Porsi'),
              _buildMetricColumn(
                value: '$prayerName $cleanPrayerTime',
                label: 'Jadwal Salat',
              ),
              _buildMetricColumn(value: gpsDisplay, label: 'Status Lokasi'),
            ],
          ),

          const SizedBox(height: 22),

          // ── Segmented Dual-Action Pill Button ────────────────────
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Left Pill: Lacak Petugas (Map)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(26),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        dashboardCtrl.changeTab(1);
                      },
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.north_west_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Lacak Petugas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Dashed vertical separator
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.25),
                ),

                // Right Pill: Bantuan Darurat (SOS)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(26),
                      ),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Get.toNamed(AppRoutes.modalSos);
                      },
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Bantuan Darurat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 7),
                            Icon(
                              Icons.north_east_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Notification Button with Badge Indicator ──────────────────────────────
  Widget _buildNotificationButton(
    BuildContext context,
    HajiCareController state,
    bool isDark,
  ) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1.0,
            ),
          ),
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
            tooltip: context.tr('notificationTooltip'),
            onPressed: () => Get.toNamed(AppRoutes.notification),
          ),
        ),
        Obx(() {
          final notifCtrl = Get.isRegistered<NotificationController>()
              ? Get.find<NotificationController>()
              : null;
          final totalUnread = notifCtrl != null
              ? notifCtrl.unreadCount.value +
                    notifCtrl.pendingInvitations.length
              : 0;
          final hasSeparated = state.self.separatedMode;

          if (totalUnread <= 0 && !hasSeparated) return const SizedBox.shrink();

          return Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: hasSeparated
                    ? AppColors.sosEmergency
                    : const Color(0xFF00E5FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2E1C12), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color:
                        (hasSeparated
                                ? AppColors.sosEmergency
                                : const Color(0xFF00E5FF))
                            .withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Metric Item Column Helper ─────────────────────────────────────────────
  Widget _buildMetricColumn({required String value, required String label}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Curved White/Cream Canvas Sheet ───────────────────────────────────────
  Widget _buildCurvedBody({
    required BuildContext context,
    required JamaahData jamaah,
    required HajiCareController state,
    required DashboardController dashboardCtrl,
    required bool isDark,
    required Color headingColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkScaffold : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Service Categories (Row of 4 Horizontal Items) ─
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryItem(
                  context: context,
                  label: 'Komunikasi Cepat',
                  icon: Icons.record_voice_over_rounded,
                  bgColor: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                  iconColor: isDark
                      ? AppColors.goldLight
                      : AppColors.espressoDark,
                  onTap: () => CommunicationGestureDialog.show(context),
                ),
                _buildCategoryItem(
                  context: context,
                  label: 'Smart Band',
                  icon: Icons.watch_rounded,
                  bgColor: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                  iconColor: isDark
                      ? AppColors.goldLight
                      : AppColors.espressoDark,
                  onTap: () => _showSmartBandDialog(context),
                ),
                _buildCategoryItem(
                  context: context,
                  label: 'Panduan Doa',
                  icon: Icons.menu_book_rounded,
                  bgColor: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                  iconColor: isDark
                      ? AppColors.goldLight
                      : AppColors.espressoDark,
                  onTap: () => _showDoaSheet(context),
                ),
                _buildCategoryItem(
                  context: context,
                  label: 'Pos Medis',
                  icon: Icons.local_hospital_rounded,
                  bgColor: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                  iconColor: isDark
                      ? AppColors.goldLight
                      : AppColors.espressoDark,
                  onTap: () => _showMedicalSheet(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Section 1: "Status & Peringatan" ("Bot Alert") ────────
          _buildSectionHeader(
            title: 'Status & Peringatan',
            actionText: 'Lihat peta',
            onAction: () => dashboardCtrl.changeTab(1),
            headingColor: headingColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildStatusAlertCard(context, jamaah, isDark, dashboardCtrl),

          const SizedBox(height: 26),

          // ── Section 2: "Kamar & Maktab" ───────────────────────────
          _buildSectionHeader(
            title: 'Kamar & Maktab',
            actionText: 'Kelola',
            onAction: () {
              if (state.activeRoomId.value != null) {
                Get.toNamed(
                  AppRoutes.roomDetail,
                  arguments: state.activeRoom.value,
                );
              } else {
                Get.toNamed(AppRoutes.joinRoom);
              }
            },
            headingColor: headingColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          const ActiveRoomCard(isPendamping: false),

          const SizedBox(height: 26),

          // ── Section 3: "Tips & Panduan Ibadah" ("News and Updates")
          _buildSectionHeader(
            title: 'Tips & Panduan Ibadah',
            actionText: 'Lihat semua',
            onAction: () => _showDoaSheet(context),
            headingColor: headingColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildNewsUpdatesCard(context, isDark, headingColor),
        ],
      ),
    );
  }

  // ── Quick Category Item (Squircle Icon with Label) ────────────────────────
  Widget _buildCategoryItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final textHeading = AppColors.textHeadingColor(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                      : AppColors.canvasCreamSubtle,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : AppColors.espressoDark.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 26)),
            ),
            const SizedBox(height: 7),
            Container(
              width: 76,
              constraints: const BoxConstraints(minHeight: 34),
              alignment: Alignment.topCenter,
              child: Text(
                label,
                style: TextStyle(
                  color: textHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.22,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header (Title + See all) ──────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onAction,
    required Color headingColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: headingColor,
            fontSize: 16,
          ),
        ),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              actionText,
              style: TextStyle(
                color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Status Alert Card (Bot Alert Pattern) ─────────────────────────────────
  Widget _buildStatusAlertCard(
    BuildContext context,
    JamaahData jamaah,
    bool isDark,
    DashboardController dashboardCtrl,
  ) {
    if (jamaah.separatedMode) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E1517) : const Color(0xFFFFECEF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.sosEmergency.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.sosEmergency.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.sosEmergency,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Peringatan Terpisah!',
                    style: TextStyle(
                      color: AppColors.sosEmergency,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Jarak Anda jauh dari rombongan. Segera buka peta untuk kembali ke rombongan.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF7A1C24),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Normal safe connection state
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceWhite;
    final headingColor = AppColors.textHeadingColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B633E), Color(0xFF2E8540)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B633E).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kondisi Terkoneksi & Aman',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'GPS aktif dengan radius aman. Terhubung dengan posko kloter secara real-time.',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── News & Updates Card (Horizontal Style) ────────────────────────────────
  Widget _buildNewsUpdatesCard(
    BuildContext context,
    bool isDark,
    Color headingColor,
  ) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceWhite;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A857), Color(0xFFA67C52)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.wb_sunny_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Menghadapi Cuaca Panas',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jaga asupan cairan air zam-zam dan gunakan payung peneduh saat beraktivitas di siang hari.',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dashed Line Painter Helper ────────────────────────────────────────────
  Widget _buildDashedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1.2,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }

  // ── Modal Sheet: Panduan Doa & Dzikir ──────────────────────────────────────
  void _showDoaSheet(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    final doas = [
      {
        'title': 'Bacaan Talbiyah',
        'arabic':
            'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ',
        'latin':
            'Labbaikallaahumma labbaik, labbaika laa syariika laka labbaik...',
        'arti': 'Aku penuhi panggilan-Mu ya Allah, aku penuhi panggilan-Mu...',
      },
      {
        'title': 'Doa Tawaf (Antara Rukun Yamani & Hajar Aswad)',
        'arabic':
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        'latin':
            'Rabbanaa aatinaa fid dunyaa hasanah wa fil aakhirati hasanah wa qinaa \'adzaaban naar',
        'arti':
            'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat dan lindungilah kami dari azab neraka.',
      },
      {
        'title': 'Doa Masuk Masjidil Haram',
        'arabic': 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
        'latin': 'Allaahummaftah lii abwaaba rahmatik',
        'arti': 'Ya Allah, bukalah pintu-pintu rahmat-Mu untukku.',
      },
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
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
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Doa & Dzikir Ibadah Haji',
              style: AppTypography.titleLarge.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: doas.length,
                separatorBuilder: (_, _) => const Divider(height: 24),
                itemBuilder: (context, i) {
                  final item = doas[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.espressoDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item['arabic']!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['latin']!,
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Artinya: "${item['arti']}"',
                        style: AppTypography.caption.copyWith(color: bodyColor),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Modal Sheet: Pos Medis & Ambulans ─────────────────────────────────────
  void _showMedicalSheet(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
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
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.sosEmergency.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: AppColors.sosEmergency,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Layanan Pos Medis Haji',
                        style: AppTypography.titleLarge.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bantuan Medis Darurat & Maktab',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextBody
                              : AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFECEF),
                child: Icon(Icons.phone_rounded, color: AppColors.sosEmergency),
              ),
              title: const Text(
                'Call Center Darurat Saudi: 997',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Ambulans & Paramedis Resmi Arab Saudi'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(
                  Icons.medical_services_rounded,
                  color: Color(0xFF15803D),
                ),
              ),
              title: const Text(
                'Klinik Kesehatan Haji Indonesia (KKHI)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Tersedia 24 Jam di Daker Makkah & Madinah'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosEmergency,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.emergency_rounded),
                label: const Text(
                  'Buka Menu Darurat SOS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.modalSos);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  // ── Smart Band Telemetry Dialog (Reference Design Layout) ─────────────────
  void _showSmartBandDialog(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    // Resolve or put SmartbandLdrController
    final ldrCtrl = Get.isRegistered<SmartbandLdrController>()
        ? Get.find<SmartbandLdrController>()
        : Get.put(SmartbandLdrController());

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        elevation: 16,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
            topRight: Radius.circular(
              52,
            ), // Signature modern curved top-right corner
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Obx(() {
            final ldrVal = ldrCtrl.ldrValue.value;
            final isFlame = ldrCtrl.flameDetected.value;
            final isConnected = ldrCtrl.isConnected;
            final lightStatus = ldrCtrl.lightStatus;

            // Safe fallback readings if not yet connected to physical hardware
            final displayLdr = isConnected && ldrVal > 0
                ? ldrVal
                : (ldrVal > 0 ? ldrVal : 820);
            final displayBrightnessPct = ((4095 - displayLdr) / 4095.0).clamp(
              0.1,
              1.0,
            );
            final displayStatus = lightStatus != '-' ? lightStatus : 'Terang';

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Section: Left 2 Stacked Metrics + Right Arc Gauge ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Stacked Sensor LDR & Flame Sensor
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Sensor LDR Item
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 3.5,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.goldLight
                                      : AppColors.primaryGold,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sensor LDR',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.wb_sunny_rounded,
                                          color: isDark
                                              ? AppColors.goldLight
                                              : AppColors.primaryGold,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$displayLdr',
                                          style: TextStyle(
                                            color: headingColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Lux',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white54
                                                : const Color(0xFF94A3B8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (isDark
                                                        ? AppColors.goldLight
                                                        : AppColors.primaryGold)
                                                    .withValues(
                                                      alpha: isDark
                                                          ? 0.25
                                                          : 0.14,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            displayStatus,
                                            style: TextStyle(
                                              color: isDark
                                                  ? AppColors.goldLight
                                                  : AppColors.goldDark,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 2. Flame Sensor Item
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 3.5,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isFlame
                                      ? AppColors.sosEmergency
                                      : (isDark
                                            ? AppColors.darkSecondary
                                            : AppColors.tanMedium),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Flame Sensor',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department_rounded,
                                          color: isFlame
                                              ? AppColors.sosEmergency
                                              : (isDark
                                                    ? AppColors.darkSecondary
                                                    : AppColors.tanMedium),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          isFlame ? 'API!' : 'Normal',
                                          style: TextStyle(
                                            color: isFlame
                                                ? AppColors.sosEmergency
                                                : headingColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (isFlame
                                                        ? AppColors.sosEmergency
                                                        : AppColors.statusSafe)
                                                    .withValues(
                                                      alpha: isDark
                                                          ? 0.25
                                                          : 0.12,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isFlame ? 'Evakuasi' : 'Aman',
                                            style: TextStyle(
                                              color: isFlame
                                                  ? AppColors.sosEmergency
                                                  : AppColors.statusSafe,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: Circular Arc Progress Ring Gauge
                    SizedBox(
                      width: 106,
                      height: 106,
                      child: CustomPaint(
                        painter: _CircularGaugePainter(
                          progress: displayBrightnessPct,
                          trackColor: isDark
                              ? AppColors.darkSurfaceContainerHighest
                              : AppColors.canvasCreamSubtle,
                          arcColor: isDark
                              ? AppColors.goldLight
                              : AppColors.goldPrimary,
                          dotColor: isDark
                              ? AppColors.accentGoldStar
                              : AppColors.goldDark,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$displayLdr',
                                style: TextStyle(
                                  color: headingColor,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'LDR Level',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ── Horizontal Divider Line ─────────────────────────────
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFFE2E8F0),
                ),

                const SizedBox(height: 16),

                // ── Bottom Row: 3 Horizontal Metrics with Mini Progress Bars ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Col 1: Detak Jantung
                    Expanded(
                      child: _buildLinearMetricColumn(
                        context: context,
                        title: 'Detak Jantung',
                        valueText: '76 bpm',
                        progress: 0.65,
                        barColor: isDark
                            ? AppColors.goldLight
                            : AppColors.primaryGold,
                        isDark: isDark,
                        headingColor: headingColor,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Col 2: Suhu Badan
                    Expanded(
                      child: _buildLinearMetricColumn(
                        context: context,
                        title: 'Suhu Badan',
                        valueText: '36.6 °C',
                        progress: 0.72,
                        barColor: isDark
                            ? AppColors.darkSecondary
                            : AppColors.tanMedium,
                        isDark: isDark,
                        headingColor: headingColor,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Col 3: Baterai Band
                    Expanded(
                      child: _buildLinearMetricColumn(
                        context: context,
                        title: 'Baterai Band',
                        valueText: '88% BLE',
                        progress: 0.88,
                        barColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.espressoDark,
                        isDark: isDark,
                        headingColor: headingColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Action Buttons Footer ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Get.toNamed(AppRoutes.smartbandLdr);
                        },
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text(
                          'Detail Sensor',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkOutlineVariant
                                : AppColors.outlineVariant,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sinyal panggil terkirim! Gelang pintar bergetar.',
                              ),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.vibration_rounded, size: 16),
                        label: const Text(
                          'Panggil Getar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: isDark
                              ? AppColors.darkPrimaryContainer
                              : AppColors.espressoDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Linear Metric Column Helper (Bottom Row of Dialog) ────────────────────
  Widget _buildLinearMetricColumn({
    required BuildContext context,
    required String title,
    required String valueText,
    required double progress,
    required Color barColor,
    required bool isDark,
    required Color headingColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: headingColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4.5,
            backgroundColor: barColor.withValues(alpha: isDark ? 0.2 : 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          valueText,
          style: TextStyle(
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Circular gauge painter creating a modern arc progress ring with an end-handle dot
class _CircularGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color arcColor;
  final Color dotColor;

  const _CircularGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.42;
    canvas.drawCircle(center, radius, trackPaint);

    // Foreground arc
    final sweepAngle = (2 * math.pi * 0.72) * progress.clamp(0.05, 1.0);
    const startAngle = -math.pi * 0.5; // Starts at 12 o'clock

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // End handle dot
    final endAngle = startAngle + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    // Outer white dot with shadow
    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 5.0, dotOuterPaint);

    // Inner dot
    final dotInnerPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 2.5, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.dotColor != dotColor;
  }
}
