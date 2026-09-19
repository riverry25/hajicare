import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../map/screens/interactive_map_screen.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../notification/widgets/notification_composer_dialog.dart';
import '../../prayer/controllers/prayer_times_controller.dart';
import '../../prayer/screens/prayer_times_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../room/widgets/active_room_card.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/pendamping_radar_card.dart';
import '../widgets/pendamping_sos_banner.dart';
import '../widgets/rotating_sync_button.dart';

class DashboardPendampingScreen extends StatelessWidget {
  const DashboardPendampingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final state = Get.find<HajiCareController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      extendBody: true,
      body: Obx(
        () => IndexedStack(
          index: dashboardCtrl.currentIndex.value,
          children: [
            _buildHome(context, state, dashboardCtrl),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // HOME TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHome(
    BuildContext context,
    HajiCareController state,
    DashboardController dashboardCtrl,
  ) {
    final isDark = AppColors.isDark(context);
    final prayerCtrl = Get.isRegistered<PrayerTimesController>()
        ? Get.find<PrayerTimesController>()
        : Get.put(PrayerTimesController());

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
        child: Obx(
          () => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                _hero(context, state, dashboardCtrl, prayerCtrl, isDark),
                _body(context, state, dashboardCtrl, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _hero(
    BuildContext context,
    HajiCareController state,
    DashboardController dashboardCtrl,
    PrayerTimesController prayerCtrl,
    bool isDark,
  ) {
    final topInset = MediaQuery.paddingOf(context).top;

    final displayName = state.pendampingName.value.isNotEmpty
        ? state.pendampingName.value
        : (state.self.name.trim().isNotEmpty
              ? state.self.name.trim()
              : 'Pendamping');
    final initialLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'P';

    final kloterStr = state.effectiveKloter ?? '-';
    final maktabStr = state.effectiveMaktab ?? '-';
    final roomName = state.activeRoom.value?.name ?? 'Belum Ada Room';
    final jamaahCount = state.jamaahList.length;

    final prayerName = prayerCtrl.nextPrayerName.value.isNotEmpty
        ? prayerCtrl.nextPrayerName.value
        : 'Ashar';
    final cleanTime =
        (prayerCtrl.nextPrayerTime.value.isNotEmpty
                ? prayerCtrl.nextPrayerTime.value
                : '15:20')
            .split(' ')
            .first;
    final gpsDisplay = state.isMyGpsActive.value ? 'GPS Aktif' : 'GPS Mati';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────────────
          Row(
            children: [
              // Avatar
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
                    colors: [AppColors.accentGoldStar, AppColors.tanMedium],
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
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Assalamu'alaikum,",
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
                      '${kloterStr.toLowerCase().startsWith('kloter') ? kloterStr : 'Kloter $kloterStr'} · ${maktabStr.toLowerCase().startsWith('maktab') ? maktabStr : 'Maktab $maktabStr'}',
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _notifButton(context, state),
            ],
          ),

          const SizedBox(height: 26),

          // ── Big hero number ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$jamaahCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'jamaah',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.statusSafe,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Jamaah Terpantau',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Sync + room chip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RotatingSyncButton(
                    onSync: () async {
                      await state.refreshLocation();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lokasi GPS berhasil diperbarui'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      roomName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),
          _dashedLine(Colors.white.withValues(alpha: 0.20)),
          const SizedBox(height: 16),

          // ── 3 mini metrics ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _broadcastChip(context),
              _metricCol(
                value: '$prayerName $cleanTime',
                label: 'Jadwal Salat',
              ),
              _metricCol(value: gpsDisplay, label: 'Status Lokasi'),
            ],
          ),

          const SizedBox(height: 22),

          // ── Dual-action pill ──────────────────────────────────────
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
                              'Lacak Jamaah',
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
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(26),
                      ),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        NotificationComposerDialog.show(context);
                      },
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Broadcast Notif',
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

  // ═══════════════════════════════════════════════════════════════════════════
  // CURVED BODY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _body(
    BuildContext context,
    HajiCareController state,
    DashboardController dashboardCtrl,
    bool isDark,
  ) {
    final headingColor = AppColors.textHeadingColor(context);

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
      child: Obx(() {
        final selectedJamaah =
            (state.jamaahList.isNotEmpty &&
                state.jamaahList.length >
                    dashboardCtrl.selectedJamaahIndex.value)
            ? state.jamaahList[dashboardCtrl.selectedJamaahIndex.value]
            : (state.jamaahList.isNotEmpty
                  ? state.jamaahList.first
                  : state.self);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4 Quick icons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconItem(
                    context: context,
                    label: 'Kelola Room',
                    icon: Icons.meeting_room_rounded,
                    isDark: isDark,
                    onTap: () => state.activeRoomId.value != null
                        ? Get.toNamed(
                            AppRoutes.roomDetail,
                            arguments: state.activeRoom.value,
                          )
                        : Get.toNamed(AppRoutes.joinRoom),
                  ),
                  _iconItem(
                    context: context,
                    label: 'Undang Jamaah',
                    icon: Icons.person_add_alt_1_rounded,
                    isDark: isDark,
                    onTap: () => Get.toNamed(AppRoutes.joinRoom),
                  ),
                  _iconItem(
                    context: context,
                    label: 'Jadwal Salat',
                    icon: Icons.access_time_rounded,
                    isDark: isDark,
                    onTap: () => dashboardCtrl.changeTab(2),
                  ),
                  _iconItem(
                    context: context,
                    label: 'Darurat SOS',
                    icon: Icons.emergency_rounded,
                    isDark: isDark,
                    iconColor: AppColors.sosEmergency,
                    onTap: () => Get.toNamed(AppRoutes.modalSos),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Darurat (only when active)
            if (state.anySosActive || state.anyJamaahSeparated) ...[
              _sectionHeader(
                title: 'Status Darurat',
                actionText: 'Lihat peta',
                onAction: () => dashboardCtrl.changeTab(1),
                headingColor: headingColor,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              if (state.activeRoomId.value != null)
                PendampingSosBanner(
                  state: state,
                  onDismissSos: (jamaahId) async {
                    AppAlert.confirm(
                      context,
                      title: 'Akhiri Darurat SOS',
                      message:
                          'Apakah situasi darurat jamaah sudah teratasi? Sinyal SOS akan dinonaktifkan.',
                      confirmText: 'Ya, Akhiri SOS',
                      cancelText: 'Batal',
                      onConfirm: () async {
                        await state.dismissSos(jamaahId);
                        if (context.mounted) {
                          AppAlert.success(
                            context,
                            title: 'SOS Diakhiri',
                            message: 'Sinyal darurat berhasil dinonaktifkan.',
                          );
                        }
                      },
                    );
                  },
                ),
              if (state.anyJamaahSeparated)
                _separatedAlert(context, state, isDark),
              const SizedBox(height: 26),
            ],

            // Monitored Pilgrims Pills
            if (state.activeRoomId.value != null &&
                state.jamaahList.isNotEmpty) ...[
              _sectionHeader(
                title: 'Pantauan Jamaah',
                actionText: 'Lihat peta',
                onAction: () => dashboardCtrl.changeTab(1),
                headingColor: headingColor,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _pilgrimsPills(context, state, dashboardCtrl, isDark),
              const SizedBox(height: 26),
            ],

            // Detail posisi jamaah terpilih
            if (state.activeRoomId.value != null &&
                state.jamaahList.isNotEmpty) ...[
              _sectionHeader(
                title: 'Detail Posisi',
                actionText: 'Buka navigasi',
                onAction: () => dashboardCtrl.changeTab(1),
                headingColor: headingColor,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              PendampingRadarCard(
                jamaah: selectedJamaah,
                onTrackMap: () => dashboardCtrl.changeTab(1),
              ),
              const SizedBox(height: 26),
            ],

            // Kamar & Maktab
            _sectionHeader(
              title: 'Kamar & Maktab',
              actionText: 'Kelola',
              onAction: () => state.activeRoomId.value != null
                  ? Get.toNamed(
                      AppRoutes.roomDetail,
                      arguments: state.activeRoom.value,
                    )
                  : Get.toNamed(AppRoutes.joinRoom),
              headingColor: headingColor,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            const ActiveRoomCard(isPendamping: true),

            const SizedBox(height: 26),

            // Tips
            _sectionHeader(
              title: 'Tips & Panduan Tugas',
              actionText: 'Selengkapnya',
              onAction: () {},
              headingColor: headingColor,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _tipsCard(isDark, headingColor),
          ],
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MONITORED PILGRIMS PILLS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _pilgrimsPills(
    BuildContext context,
    HajiCareController state,
    DashboardController dashboardCtrl,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;

    return Container(
      width: double.infinity,
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
      child: state.jamaahList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada jamaah terdaftar',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(state.jamaahList.length, (i) {
                final j = state.jamaahList[i];
                final hasSos = j.sosActive;
                final isSep = j.separatedMode;
                final dist = j.distance;
                final distText = dist > 0
                    ? (dist < 1000
                          ? '${dist.round()} m'
                          : '${(dist / 1000).toStringAsFixed(1)} km')
                    : '—';
                final isSelected = dashboardCtrl.selectedJamaahIndex.value == i;

                final Color pill = hasSos
                    ? AppColors.sosEmergency
                    : (isSep ? AppColors.statusWarning : AppColors.statusSafe);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    dashboardCtrl.selectJamaah(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 13 : 11,
                      vertical: isSelected ? 7.5 : 6.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                ? AppColors.darkPrimaryContainer
                                : AppColors.canvasCreamSubtle)
                          : pill.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.goldLight
                                  : AppColors.espressoDark)
                            : pill.withValues(alpha: isDark ? 0.38 : 0.28),
                        width: isSelected ? 1.8 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    (isDark
                                            ? Colors.black
                                            : AppColors.espressoDark)
                                        .withValues(alpha: 0.16),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: pill,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: pill.withValues(alpha: 0.55),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          j.shortLabel.isNotEmpty
                              ? j.shortLabel
                              : (j.name.isNotEmpty
                                    ? j.name.split(' ').first
                                    : 'Jamaah ${i + 1}'),
                          style: TextStyle(
                            color: isSelected
                                ? (isDark
                                      ? AppColors.goldLight
                                      : AppColors.espressoDark)
                                : (isDark
                                      ? AppColors.darkTextHeading
                                      : AppColors.espressoDark),
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: pill.withValues(alpha: isDark ? 0.22 : 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            distText,
                            style: TextStyle(
                              color: pill,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        if (hasSos) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.emergency_rounded,
                            color: AppColors.sosEmergency,
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _notifButton(BuildContext context, HajiCareController state) {
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
          final unread = notifCtrl != null
              ? notifCtrl.unreadCount.value +
                    notifCtrl.pendingInvitations.length
              : 0;
          final hasSos = state.anySosActive;
          if (unread <= 0 && !hasSos) return const SizedBox.shrink();
          return Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: hasSos
                    ? AppColors.sosEmergency
                    : const Color(0xFF00E5FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2E1C12), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color:
                        (hasSos
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

  Widget _broadcastChip(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          NotificationComposerDialog.show(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.goldLight.withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.campaign_rounded,
                    color: AppColors.goldLight,
                    size: 13,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Broadcast',
                    style: TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Kirim Notif',
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
      ),
    );
  }

  Widget _metricCol({required String value, required String label}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
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

  Widget _dashedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: 1.2,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
        );
      },
    );
  }

  Widget _iconItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final effectiveColor =
        iconColor ?? (isDark ? AppColors.goldLight : AppColors.espressoDark);
    final bg = isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream;
    final textColor = AppColors.textHeadingColor(context);

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
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: bg,
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
              child: Center(child: Icon(icon, color: effectiveColor, size: 26)),
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: 76,
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
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

  Widget _sectionHeader({
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

  Widget _separatedAlert(
    BuildContext context,
    HajiCareController state,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerHighest
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusWarning.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.statusWarning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_off_rounded,
              color: AppColors.statusWarning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${state.separatedJamaahName} terdeteksi jauh dari rombongan. Segera cek posisi di peta.',
              style: TextStyle(
                color: isDark ? AppColors.statusWarning : AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard(bool isDark, Color headingColor) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceWhite;

    final tips = [
      (
        Icons.groups_rounded,
        'Absensi Rutin',
        'Cek kehadiran jamaah minimal 3× sehari: subuh, zuhur, dan isya.',
      ),
      (
        Icons.local_hospital_rounded,
        'Kondisi Kesehatan',
        'Pantau jamaah lanjut usia dan yang memiliki riwayat penyakit kronis.',
      ),
      (
        Icons.wifi_tethering_rounded,
        'Koneksi GPS',
        'Pastikan jamaah mengaktifkan GPS agar posisi terpantau secara real-time.',
      ),
    ];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tips.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, title, desc) = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: headingColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextBody
                                : AppColors.textBody,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
