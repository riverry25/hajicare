part of 'dashboard_jamaah_screen.dart';

extension _DashboardJamaahSections on DashboardJamaahScreen {
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
        color: context.hc.canvas,
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
          const ActiveAdhanDashboardBanner(),
          // ── Quick Service Categories (Row of 4 Horizontal Items) ─
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCategoryItem(
                    context: context,
                    label: context.tr('dashboard.quickComm'),
                    icon: Icons.record_voice_over_rounded,
                    bgColor: context.hc.surfaceVariant,
                    iconColor: context.hc.primary,
                    onTap: () => CommunicationGestureDialog.show(context),
                  ),
                ),
                Expanded(
                  child: _buildCategoryItem(
                    context: context,
                    label: context.tr('dashboard.smartband'),
                    icon: Icons.watch_rounded,
                    bgColor: context.hc.surfaceVariant,
                    iconColor: context.hc.primary,
                    onTap: () => _showSmartBandDialog(context),
                  ),
                ),
                Expanded(
                  child: _buildCategoryItem(
                    context: context,
                    label: context.tr('dashboard.medicalPost'),
                    icon: Icons.local_hospital_rounded,
                    bgColor: context.hc.surfaceVariant,
                    iconColor: context.hc.primary,
                    onTap: () => _showMedicalSheet(context),
                  ),
                ),
                Expanded(
                  child: _buildCategoryItem(
                    context: context,
                    label: context.tr('dashboard.textToSign'),
                    icon: Icons.interpreter_mode_rounded,
                    bgColor: context.hc.surfaceVariant,
                    iconColor: context.hc.success,
                    onTap: () => Get.toNamed(AppRoutes.textToSign),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Active Assistance Banner (when request is in progress) ──
          Obx(() {
            final activeReq =
                AssistanceRequestService.instance.activeRequest.value;
            if (activeReq == null || !activeReq.isActive) {
              return const SizedBox.shrink();
            }
            return JamaahActiveAssistanceBanner(
              request: activeReq,
              isDark: isDark,
            );
          }),

          // ── Bento Grid: Layanan & Fitur Utama Jamaah ─────────────
          _buildJamaahBentoSection(
            context: context,
            state: state,
            jamaah: jamaah,
            isDark: isDark,
            headingColor: headingColor,
          ),

          const SizedBox(height: 24),

          // ── Section 1: "Status & Peringatan" ("Bot Alert") ────────
          // Hanya ditampilkan jika jamaah sudah tergabung dalam room pemantauan
          // atau terdapat alarm darurat SOS aktif. Jika belum memiliki room, section
          // ini disembunyikan agar tidak menampilkan status "Terkoneksi & Aman" semu.
          Obx(() {
            final hasRoom =
                (state.activeRoomId.value != null &&
                    state.activeRoomId.value!.trim().isNotEmpty) ||
                (state.activeRoom.value != null);
            final hasSos = state.anySosActive || jamaah.sosActive;

            if (!hasRoom && !hasSos) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context: context,
                  title: context.tr('dashboard.statusAndAlert'),
                  subtitle: context.tr('dashboard.gpsMonitoringSub'),
                  actionText: context.tr('dashboard.viewMap'),
                  onAction: () => dashboardCtrl.changeTab(1),
                  headingColor: headingColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildStatusAlertCard(context, jamaah, isDark, dashboardCtrl),
                const SizedBox(height: 26),
              ],
            );
          }),

          // ── Section 2: "Kamar & Maktab" ───────────────────────────
          _buildSectionHeader(
            context: context,
            title: context.tr('dashboard.roomAndMaktab'),
            subtitle: context.tr('dashboard.hotelRoomSub'),
            actionText: context.tr('dashboard.manage'),
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

          // ── Section 3: "Info & Pengumuman" (Dynamic Info Notifications from Companion & Admin)
          _buildSectionHeader(
            context: context,
            title: context.tr('dashboard.companionAndAdminInfo'),
            subtitle: context.tr('dashboard.companionAndAdminInfoSub'),
            actionText: context.tr('dashboard.viewAll'),
            onAction: () => Get.toNamed(AppRoutes.notification),
            headingColor: headingColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildDynamicInfoList(context, isDark, headingColor),
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
    final isDark = context.hc.isDark;
    final textHeading = context.hc.textPrimary;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.hc.border, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 24)),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(minHeight: 32),
              alignment: Alignment.topCenter,
              child: Text(
                label,
                style: TextStyle(
                  color: textHeading,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
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

  // ── Section Header (Title + Subtitle + Action) ─────────────────────────────
  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
    required Color headingColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: headingColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTypography.captionSmall.copyWith(
                    color: context.hc.textSecondary,
                    height: 1.3,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                actionText,
                style: TextStyle(
                  color: context.hc.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Alert Card – fully dynamic: GPS state + safe radius tier ───────
  Widget _buildStatusAlertCard(
    BuildContext context,
    JamaahData jamaah,
    bool isDark,
    DashboardController dashboardCtrl,
  ) {
    // Wrap with Obx so card re-renders whenever safeRadiusMeters changes
    // (pendamping can update it at any time).
    final hc = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;

    return Obx(() {
      // ── 1. Read live safe radius (reactive) ──────────────────────────────
      final safeRadius = hc?.safeRadiusMeters.value ?? 200.0;

      // ── 2. Recompute tier against current safeRadius ──────────────────────
      // JamaahData.tier may be stale; we recompute inline.
      DistanceTier liveTier;
      if (jamaah.distance <= safeRadius * 0.5) {
        liveTier = DistanceTier.aman;
      } else if (jamaah.distance <= safeRadius) {
        liveTier = DistanceTier.waspada;
      } else {
        liveTier = DistanceTier.terlalujJauh;
      }

      final bool gpsOn = jamaah.isGpsActive;
      final bool hasLocation = jamaah.currentLocation != null;

      // Staleness: more than 5 minutes without location update
      final bool locationStale =
          hasLocation &&
          jamaah.locationUpdatedAt != null &&
          DateTime.now().difference(jamaah.locationUpdatedAt!).inMinutes >= 5;

      // ── Helpers ───────────────────────────────────────────────────────────
      Widget buildStatusIcon({
        required Color color,
        required IconData icon,
        bool isGradient = false,
        List<Color>? gradientColors,
      }) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: isGradient && gradientColors != null
                ? LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isGradient ? null : color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isGradient
                ? [
                    BoxShadow(
                      color: gradientColors!.first.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              color: isGradient ? Colors.white : color,
              size: 24,
            ),
          ),
        );
      }

      Widget buildStatusText({
        required String title,
        required String subtitle,
        required Color titleColor,
        Color? subtitleColor,
      }) {
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      subtitleColor ??
                      (isDark ? AppColors.darkTextBody : AppColors.textBody),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      }

      Widget buildRadiusBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.hc.success.withValues(alpha: isDark ? 0.25 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.hc.success.withValues(alpha: 0.45)),
        ),
        child: Text(
          '≤ ${safeRadius.toInt()} m',
          style: TextStyle(
            color: context.hc.success,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

      Widget buildStatusCard({
        required Color borderColor,
        required Color bgTint,
        required Widget icon,
        required Widget content,
        Widget? trailing,
      }) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.hc.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: bgTint.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              content,
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        );
      }

      // ── STATE SOS: Sinyal Darurat SOS Aktif ──────────────────────────────
      if (hc?.anySosActive == true || jamaah.sosActive) {
        return buildStatusCard(
          borderColor: context.hc.danger,
          bgTint: context.hc.danger,
          icon: buildStatusIcon(
            color: context.hc.danger,
            icon: Icons.emergency_rounded,
            isGradient: true,
            gradientColors: [context.hc.danger, context.hc.dangerContainer],
          ),
          content: buildStatusText(
            title: context.tr('dashboard.sosSignalActive'),
            subtitle: context.tr('dashboard.sosEmergencyConnected'),
            titleColor: context.hc.danger,
            subtitleColor: isDark ? Colors.white70 : context.hc.danger,
          ),
          trailing: InkWell(
            onTap: () => Get.toNamed(AppRoutes.modalSos),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.hc.danger,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.tr('dashboard.viewStatus'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }

      // ── STATE NO ROOM: Belum terhubung ke room ───────────────────────────
      final hasRoom =
          (hc?.activeRoomId.value != null &&
              hc!.activeRoomId.value!.trim().isNotEmpty) ||
          hc?.activeRoom.value != null;
      if (!hasRoom) {
        final headingColor = context.hc.textPrimary;
        return buildStatusCard(
          borderColor: context.hc.border,
          bgTint: context.hc.surfaceVariant,
          icon: buildStatusIcon(
            color: context.hc.warning,
            icon: Icons.meeting_room_outlined,
          ),
          content: buildStatusText(
            title: context.tr('dashboard.notConnectedToRoom'),
            subtitle: context.tr('dashboard.jamaahNoRoomDesc'),
            titleColor: headingColor,
          ),
        );
      }

      // ── STATE A: GPS mati ─────────────────────────────────────────────────
      if (!gpsOn) {
        return buildStatusCard(
          borderColor: context.hc.danger.withValues(alpha: isDark ? 0.55 : 0.4),
          bgTint: context.hc.danger,
          icon: buildStatusIcon(
            color: context.hc.danger,
            icon: Icons.location_off_rounded,
          ),
          content: buildStatusText(
            title: context.tr('dashboard.yourGpsInactive'),
            subtitle: context.tr('dashboard.yourGpsInactiveDesc'),
            titleColor: context.hc.danger,
            subtitleColor: isDark ? Colors.white60 : context.hc.danger,
          ),
        );
      }

      // ── STATE B: GPS nyala tapi sinyal stale / lokasi tidak diperbarui ────
      if (locationStale) {
        return buildStatusCard(
          borderColor: context.hc.warning.withValues(alpha: 0.55),
          bgTint: context.hc.warning,
          icon: buildStatusIcon(
            color: context.hc.warning,
            icon: Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
          ),
          content: buildStatusText(
            title: context.tr('dashboard.gpsSignalWeak'),
            subtitle: context.tr('dashboard.gpsSignalWeakDesc'),
            titleColor: context.hc.warning,
            subtitleColor: isDark ? Colors.white60 : context.hc.warning,
          ),
        );
      }

      // ── STATE C: GPS nyala, dalam safe radius (aman) ──────────────────────
      if (liveTier == DistanceTier.aman) {
        return buildStatusCard(
          borderColor: context.hc.success.withValues(
            alpha: isDark ? 0.5 : 0.35,
          ),
          bgTint: context.hc.success,
          icon: buildStatusIcon(
            color: context.hc.success,
            icon: Icons.verified_user_rounded,
            isGradient: true,
            gradientColors: [context.hc.success, context.hc.successContainer],
          ),
          content: buildStatusText(
            title: context.tr('dashboard.connectedSafe'),
            subtitle: context.tr('dashboard.connectedSafeDesc'),
            titleColor: context.hc.textPrimary,
          ),
          trailing: buildRadiusBadge(),
        );
      }

      // ── STATE D: GPS nyala, mendekati batas radius (waspada) ─────────────
      if (liveTier == DistanceTier.waspada) {
        return buildStatusCard(
          borderColor: context.hc.warning.withValues(alpha: 0.55),
          bgTint: context.hc.warning,
          icon: buildStatusIcon(
            color: context.hc.warning,
            icon: Icons.warning_amber_rounded,
          ),
          content: buildStatusText(
            title: context.tr('dashboard.nearingRadius'),
            subtitle: context.tr('dashboard.nearingRadiusDesc'),
            titleColor: context.hc.warning,
            subtitleColor: isDark ? Colors.white60 : context.hc.warning,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.hc.warning.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.hc.warning.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              '${jamaah.distance.toInt()} m',
              style: TextStyle(
                color: context.hc.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }

      // ── STATE E: Keluar safe radius (terlalu jauh / separatedMode) ────────
      return buildStatusCard(
        borderColor: context.hc.danger.withValues(alpha: 0.55),
        bgTint: context.hc.danger,
        icon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.hc.danger,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        content: buildStatusText(
          title: context.tr('dashboard.outsideRadius'),
          subtitle: context.tr('dashboard.outsideRadiusDesc'),
          titleColor: context.hc.danger,
          subtitleColor: isDark ? Colors.white60 : context.hc.danger,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.hc.danger.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.hc.danger.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            '${jamaah.distance.toInt()} m',
            style: TextStyle(
              color: context.hc.danger,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
  }

  // ── Dynamic Info Notifications Section (Up to 3 newest items from Companion & Admin) ──
  Widget _buildDynamicInfoList(
    BuildContext context,
    bool isDark,
    Color headingColor,
  ) {
    final notifCtrl = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : null;

    if (notifCtrl == null) {
      return _buildEmptyInfoCard(context, isDark, headingColor);
    }

    return Obx(() {
      final allNotifs = notifCtrl.notifications;
      // Filter for notifications of type info, companion_info, announcement, or companion_message
      final infoItems = allNotifs.where((n) {
        final t = n.type.toLowerCase().trim();
        return t == 'info' ||
            t == 'companion_info' ||
            t == 'announcement' ||
            t == 'companion_message';
      }).toList();

      // Sort newest first
      infoItems.sort((a, b) {
        final timeA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

      // Max 3 latest items
      final displayList = infoItems.take(3).toList();

      if (displayList.isEmpty) {
        return _buildEmptyInfoCard(context, isDark, headingColor);
      }

      return Column(
        children: displayList.map((notif) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildInfoItemCard(
              context: context,
              notif: notif,
              notifCtrl: notifCtrl,
              isDark: isDark,
              headingColor: headingColor,
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildInfoItemCard({
    required BuildContext context,
    required AppNotificationModel notif,
    required NotificationController notifCtrl,
    required bool isDark,
    required Color headingColor,
  }) {
    final bodyColor = context.hc.textSecondary;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    final isAdmin = (notif.senderRole ?? '').toLowerCase() == 'admin';
    final isPendamping = (notif.senderRole ?? '').toLowerCase() == 'pendamping';

    // Role-based gradient & badge styling
    final List<Color> iconGradient;
    final IconData cardIcon;
    final String roleBadgeText;
    final Color roleBadgeColor;
    final Color roleBadgeBg;

    if (isAdmin) {
      iconGradient = [context.hc.primaryContainer, context.hc.primary];
      cardIcon = Icons.admin_panel_settings_rounded;
      roleBadgeText = context.tr('dashboard.adminUpper');
      roleBadgeColor = context.hc.primary;
      roleBadgeBg = context.hc.surfaceVariant;
    } else if (isPendamping) {
      iconGradient = [context.hc.sand, context.hc.sandDark];
      cardIcon = Icons.support_agent_rounded;
      roleBadgeText = context.tr('dashboard.companionUpper');
      roleBadgeColor = context.hc.primary;
      roleBadgeBg = context.hc.surfaceVariant;
    } else {
      iconGradient = [context.hc.success, context.hc.successContainer];
      cardIcon = Icons.campaign_rounded;
      roleBadgeText = context.tr('dashboard.infoUpper');
      roleBadgeColor = context.hc.success;
      roleBadgeBg = context.hc.success.withValues(alpha: isDark ? 0.2 : 0.1);
    }

    final formattedTime = _formatNotificationTime(context, notif.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: context.hc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !notif.isRead
              ? context.hc.sandDark.withValues(alpha: 0.55)
              : context.hc.border,
          width: !notif.isRead ? 1.4 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            if (!notif.isRead) {
              notifCtrl.markNotificationRead(notif.id);
            }
            Get.toNamed(AppRoutes.notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: iconGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient.first.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(cardIcon, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: Role badge, sender name, time & unread indicator
                      if (textScale > 1.2) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: roleBadgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleBadgeText,
                                style: TextStyle(
                                  color: roleBadgeColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (notif.senderName != null &&
                                notif.senderName!.trim().isNotEmpty)
                              Text(
                                notif.senderName!.trim(),
                                style: TextStyle(
                                  color: bodyColor.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: bodyColor.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: roleBadgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleBadgeText,
                                style: TextStyle(
                                  color: roleBadgeColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (notif.senderName != null &&
                                notif.senderName!.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  notif.senderName!.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: bodyColor.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: bodyColor.withValues(alpha: 0.6),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!notif.isRead) ...[
                              const SizedBox(width: 5),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        notif.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notif.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextBody
                              : AppColors.textBody,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInfoCard(
    BuildContext context,
    bool isDark,
    Color headingColor,
  ) {
    final cardBg = context.hc.surface;
    final bodyColor = context.hc.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.hc.border, width: 1.2),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.hc.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Icon(
                Icons.campaign_outlined,
                color: context.hc.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('dashboard.noInfoYet'),
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('dashboard.noInfoYetDesc'),
                  style: TextStyle(
                    color: bodyColor,
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

  String _formatNotificationTime(BuildContext context, DateTime? createdAt) {
    if (createdAt == null) return context.tr('dashboard.justNow');
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) {
      return context.tr('dashboard.justNow');
    } else if (diff.inHours < 1) {
      return context.tr('dashboard.minutesAgo', {
        'minutes': '${diff.inMinutes}',
      });
    } else if (diff.inDays < 1) {
      return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
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

  // ── Bento Grid: Layanan & Fitur Utama Jamaah ──────────────────────────────
  Widget _buildJamaahBentoSection({
    required BuildContext context,
    required HajiCareController state,
    required JamaahData jamaah,
    required bool isDark,
    required Color headingColor,
  }) {
    final cardBg = context.hc.surface;
    final borderColor = context.hc.border;
    final bodyColor = context.hc.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (Matching Reference Aesthetic)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('dashboard.servicesAndGuides'),
                      style: DashboardTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),

                    Text(
                      context.tr('dashboard.servicesAndGuidesSub'),
                      style: DashboardTypography.captionSmall.copyWith(
                        color: bodyColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 4 Staggered Bento Cards matching reference layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: BISINDO (Tall: 162) & Panduan Doa (Short: 126)
            Expanded(
              child: Column(
                children: [
                  _buildBentoFeatureCard(
                    context: context,
                    title: context.tr('dashboard.signLanguage'),
                    value: 'SIBI / BISINDO',
                    subtitle: context.tr('dashboard.openCamera'),
                    icon: Icons.sign_language_rounded,
                    height: 162,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    circleBg: context.hc.success.withValues(
                      alpha: isDark ? 0.22 : 0.12,
                    ),
                    iconColor: context.hc.success,
                    accentColor: context.hc.success,
                    onTap: () => Get.toNamed(AppRoutes.signLanguage),
                  ),
                  const SizedBox(height: 12),
                  _buildBentoFeatureCard(
                    context: context,
                    title: context.tr('dashboard.prayerGuide'),
                    value: context.tr('hajjDuaDashboardCardValue'),
                    subtitle: context.tr('dashboard.prayerAndDhikr'),
                    icon: Icons.menu_book_rounded,
                    height: 126,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    circleBg: context.hc.surfaceVariant,
                    iconColor: context.hc.primary,
                    accentColor: context.hc.sandDark,
                    onTap: () => Get.toNamed(AppRoutes.hajjDua),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right Column: Guide Haji & pusat komunikasi pendamping
            Expanded(
              child: Column(
                children: [
                  _buildBentoFeatureCard(
                    context: context,
                    title: context.tr('dashboard.scheduleAndPillars'),
                    value: context.tr('dashboard.hajjGuide'),
                    subtitle: context.tr('dashboard.viewSeries'),
                    icon: Icons.event_note_rounded,
                    height: 126,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    circleBg: context.hc.surfaceVariant,
                    iconColor: context.hc.primary,
                    accentColor: context.hc.sandDark,
                    onTap: () => _showHajiScheduleGuideSheet(context),
                  ),
                  const SizedBox(height: 12),
                  _buildBentoFeatureCard(
                    context: context,
                    title: context.tr('dashboard.companion'),
                    value: context.tr('dashboard.contactCompanion'),
                    subtitle: context.tr('dashboard.messageAndLocation'),
                    icon: Icons.support_agent_rounded,
                    height: 162,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    circleBg: context.hc.primary.withValues(
                      alpha: isDark ? 0.22 : 0.12,
                    ),
                    iconColor: context.hc.primary,
                    accentColor: context.hc.primary,
                    onTap: () => _showCompanionContactDialog(context, state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoFeatureCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required double height,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color headingColor,
    required Color bodyColor,
    required Color circleBg,
    required Color iconColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isTall = height > 135;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.espressoDark).withValues(
              alpha: isDark ? 0.28 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: accentColor.withValues(alpha: 0.12),
          highlightColor: accentColor.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTall ? 12 : 8,
              vertical: isTall ? 10 : 6,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: isTall ? 42 : 32,
                  height: isTall ? 42 : 32,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : iconColor).withValues(
                          alpha: isDark ? 0.2 : 0.08,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: isTall ? 20 : 16, color: iconColor),
                ),
                SizedBox(height: isTall ? 6 : 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTall ? 17 : 15,
                    fontWeight: FontWeight.w700,
                    color: headingColor,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: DashboardTypography.captionSmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: isTall ? 11.5 : 10.5,
                  ),
                ),
                if (isTall) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: isDark ? 0.18 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DashboardTypography.captionSmall.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 7.5,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: DashboardTypography.captionSmall.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Modal Sheet: Jadwal & Guide Ibadah Haji ────────────────────────────────
  void _showHajiScheduleGuideSheet(BuildContext context) {
    Get.bottomSheet(
      const HajjScheduleGuideSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── Hubungi Pendamping: informasi, pesan, dan berbagi lokasi ───────────────
  Future<void> _showCompanionContactDialog(
    BuildContext context,
    HajiCareController state,
  ) async {
    final roomId = state.activeRoomId.value?.trim();
    if (roomId == null || roomId.isEmpty) {
      AppAlert.error(
        context,
        title: context.tr('dashboard.notInRoom'),
        message: context.tr('dashboard.notInRoomContactDesc'),
        okText: context.tr('dashboard.joinGroup'),
        onOk: () => Get.toNamed(AppRoutes.joinRoom),
      );
      return;
    }

    late final List<RoomMemberModel> pendampings;
    try {
      final members = await RoomQueryService()
          .getRoomMembersStream(roomId)
          .first;
      pendampings = members
          .where((member) => member.isPendamping)
          .toList(growable: false);
    } catch (_) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: context.tr('dashboard.companionLoadFailed'),
          message: context.tr('dashboard.companionLoadFailedDesc'),
        );
      }
      return;
    }

    if (!context.mounted) return;
    if (pendampings.isEmpty) {
      AppAlert.error(
        context,
        title: context.tr('dashboard.companionUnavailable'),
        message: context.tr('dashboard.noActiveCompanion'),
      );
      return;
    }

    await Get.bottomSheet<void>(
      CompanionContactSheet(
        roomId: roomId,
        pendampings: pendampings,
        state: state,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      enableDrag: false,
    );
  }

  // ── Modal Sheet: Fitur Jemput Saya (Kirim Notifikasi ke Pendamping) ─────────
  // ignore: unused_element
  Future<void> _showPickupRequestDialog(
    BuildContext context,
    HajiCareController state,
    JamaahData jamaah,
  ) async {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final roomId = state.activeRoomId.value?.trim();

    if (roomId == null || roomId.isEmpty) {
      AppAlert.error(
        context,
        title: context.tr('dashboard.notInRoom'),
        message: context.tr('dashboard.pickupRequiresRoom'),
        okText: context.tr('dashboard.joinGroup'),
        onOk: () => Get.toNamed(AppRoutes.joinRoom),
      );
      return;
    }

    late final List<RoomMemberModel> pendampings;
    try {
      final members = await RoomQueryService()
          .getRoomMembersStream(roomId)
          .first;
      pendampings = members
          .where((member) => member.isPendamping)
          .toList(growable: false);
    } catch (_) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: context.tr('dashboard.companionLoadFailed'),
          message: context.tr('dashboard.companionLoadFailedDesc'),
        );
      }
      return;
    }

    if (!context.mounted) return;
    if (pendampings.isEmpty) {
      AppAlert.error(
        context,
        title: context.tr('dashboard.companionUnavailable'),
        message: context.tr('dashboard.noActiveCompanion'),
      );
      return;
    }

    final presets = [
      context.tr('dashboard.pickupMosqueDoor'),
      context.tr('dashboard.pickupHotelLobby'),
      context.tr('dashboard.pickupBusStop'),
      context.tr('dashboard.pickupJamarat'),
      context.tr('dashboard.pickupSeparated'),
    ];
    String selectedPreset = presets[0];
    String? selectedPendampingUid;
    String? selectedPendampingName;
    final noteController = TextEditingController(text: presets[0]);
    final isSending = false.obs;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final myPos = state.myCurrentPosition.value;

          return Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
            ),
            child: SingleChildScrollView(
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE64A19,
                          ).withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.hail_rounded,
                          color: Color(0xFFE64A19),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('dashboard.requestPickup'),
                              style: DashboardTypography.titleMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              context.tr('dashboard.requestPickupSub'),
                              style: DashboardTypography.captionSmall.copyWith(
                                color: bodyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    context.tr('dashboard.companionLabel'),
                    style: DashboardTypography.labelLarge.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPendampingUid,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surfaceWhite,
                    decoration: InputDecoration(
                      hintText: context.tr('dashboard.selectTargetCompanion'),
                      prefixIcon: const Icon(Icons.support_agent_rounded),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder,
                        ),
                      ),
                    ),
                    items: pendampings
                        .map(
                          (pendamping) => DropdownMenuItem<String>(
                            value: pendamping.uid,
                            child: Text(
                              pendamping.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isSending.value
                        ? null
                        : (uid) {
                            setModalState(() {
                              selectedPendampingUid = uid;
                              selectedPendampingName = pendampings
                                  .where((item) => item.uid == uid)
                                  .firstOrNull
                                  ?.name;
                            });
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // GPS Location card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.statusSafe.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.statusSafe,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                myPos != null
                                    ? context.tr('dashboard.gpsDetected')
                                    : context.tr('dashboard.gpsNotLocked'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: headingColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                myPos != null
                                    ? '${myPos.latitude.toStringAsFixed(5)}, ${myPos.longitude.toStringAsFixed(5)}'
                                    : context.tr(
                                        'dashboard.enableLocationPermission',
                                      ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: bodyColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quick preset chips
                  Text(
                    context.tr('dashboard.locationReference'),
                    style: DashboardTypography.labelLarge.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((preset) {
                      final isSelected = selectedPreset == preset;
                      return ChoiceChip(
                        label: Text(preset),
                        selected: isSelected,
                        selectedColor: const Color(
                          0xFFE64A19,
                        ).withValues(alpha: isDark ? 0.35 : 0.15),
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.canvasCream,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFE64A19)
                              : bodyColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedPreset = preset;
                              noteController.text = preset;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes TextField
                  Text(
                    context.tr('dashboard.locationNotes'),
                    style: DashboardTypography.labelLarge.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: context.tr('dashboard.locationNotesHint'),
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: bodyColor.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Submit button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE64A19),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          elevation: 2,
                        ),
                        icon: isSending.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.hail_rounded),
                        label: Text(
                          isSending.value
                              ? context.tr('dashboard.sendingRequest')
                              : context.tr('dashboard.sendPickupRequest'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        onPressed:
                            isSending.value || selectedPendampingUid == null
                            ? null
                            : () async {
                                isSending.value = true;
                                final noteText = noteController.text.trim();
                                final finalNote = noteText.isNotEmpty
                                    ? noteText
                                    : context.tr('dashboard.pickupDefaultNote');

                                try {
                                  final recipientName =
                                      await NotificationService()
                                          .sendPickupRequest(
                                            roomId: roomId,
                                            pendampingUid:
                                                selectedPendampingUid!,
                                            notes: finalNote,
                                            latitude: myPos?.latitude,
                                            longitude: myPos?.longitude,
                                          );

                                  if (context.mounted) {
                                    Get.back();
                                    AppAlert.success(
                                      context,
                                      title: context.tr(
                                        'dashboard.requestSent',
                                      ),
                                      message: context
                                          .tr('dashboard.requestSentDesc', {
                                            'name':
                                                selectedPendampingName ??
                                                recipientName,
                                          }),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppAlert.error(
                                      context,
                                      title: context.tr('dashboard.sendError'),
                                      message: context.tr(
                                        'dashboard.pickupSendError',
                                        {'error': e},
                                      ),
                                    );
                                  }
                                } finally {
                                  isSending.value = false;
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    ).whenComplete(noteController.dispose);
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
                        context.tr('dashboard.medicalService'),
                        style: DashboardTypography.titleLarge.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.tr('dashboard.medicalServiceSub'),
                        style: DashboardTypography.caption.copyWith(
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
              title: Text(
                context.tr('dashboard.saudiEmergencyCall'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(context.tr('dashboard.saudiEmergencyCallSub')),
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
              title: Text(
                context.tr('dashboard.kkhi'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(context.tr('dashboard.kkhiSub')),
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
                label: Text(
                  context.tr('dashboard.openEmergencyMenu'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Get.back();
                  final state = Get.find<HajiCareController>();
                  final hasRoom =
                      (state.activeRoomId.value?.trim().isNotEmpty ?? false) ||
                      state.activeRoom.value != null;
                  if (!hasRoom) {
                    AppAlert.warning(
                      context,
                      title: context.tr('dashboard.notRegisteredInRoom'),
                      message: context.tr('dashboard.sosNeedsRoomDesc'),
                      okText: context.tr('room.joinRoomTitle'),
                      onOk: () => Get.toNamed(AppRoutes.joinRoom),
                    );
                    return;
                  }
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

  // ── Smart Band Telemetry Dialog (Smartband ESP32-S3 + GPS NEO-6M + Heart Rate MAX30102) ──
  void _showSmartBandDialog(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    final ldrCtrl = Get.find<SmartbandLdrController>();

    showDialog(
      context: context,
      builder: (ctx) => HajiTransparentDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // ── 1. Main Card Body ──
              Container(
                margin: const EdgeInsets.only(
                  top: 28,
                  bottom: 12,
                  right: 10,
                  left: 10,
                ),
                padding: const EdgeInsets.fromLTRB(16, 68, 16, 18),
                decoration: BoxDecoration(
                  color: context.hc.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.hc.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.45 : 0.08,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Obx(() {
                  final isConnected = ldrCtrl.isConnected;
                  final hr = ldrCtrl.heartRate.value;
                  final lat = ldrCtrl.latitude.value;
                  final lng = ldrCtrl.longitude.value;
                  final lastLat = ldrCtrl.lastKnownLatitude.value;
                  final lastLng = ldrCtrl.lastKnownLongitude.value;
                  final relativeTime = ldrCtrl.relativeTimeText.value;
                  final hasLocation =
                      (isConnected && lat != null && lng != null) ||
                      (ldrCtrl.lastDataReceivedAt.value != null &&
                          lastLat != null &&
                          lastLng != null) ||
                      (ldrCtrl.isSimulationMode.value &&
                          (lat != null || lastLat != null));
                  final LatLng? activeTarget = hasLocation
                      ? LatLng(lat ?? lastLat!, lng ?? lastLng!)
                      : null;

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Subtitle
                        Text(
                          context.tr('dashboard.smartbandMonitoring'),
                          style: DashboardTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 17.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr('dashboard.smartbandMonitoringSub'),
                          style: DashboardTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                            height: 1.35,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── STATUS GELANG CARD ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isConnected
                                ? context.hc.success.withValues(
                                    alpha: isDark ? 0.15 : 0.08,
                                  )
                                : context.hc.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isConnected
                                  ? context.hc.success.withValues(alpha: 0.35)
                                  : context.hc.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConnected
                                      ? context.hc.success.withValues(
                                          alpha: 0.18,
                                        )
                                      : (ldrCtrl.isBusy
                                            ? context.hc.primary.withValues(
                                                alpha: 0.18,
                                              )
                                            : context.hc.textTertiary
                                                  .withValues(alpha: 0.15)),
                                ),
                                child: Icon(
                                  isConnected
                                      ? Icons.watch_rounded
                                      : (ldrCtrl.isBusy
                                            ? Icons.sync_rounded
                                            : Icons.watch_off_rounded),
                                  size: 18,
                                  color: isConnected
                                      ? context.hc.success
                                      : (ldrCtrl.isBusy
                                            ? context.hc.primary
                                            : context.hc.textTertiary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            isConnected
                                                ? context.tr(
                                                    'smartband.statusConnected',
                                                  )
                                                : (ldrCtrl.isScanning
                                                      ? context.tr(
                                                          'smartband.statusScanning',
                                                        )
                                                      : (ldrCtrl.isConnecting
                                                            ? context.tr(
                                                                'smartband.statusConnecting',
                                                              )
                                                            : context.tr(
                                                                'smartband.statusDisconnected',
                                                              ))),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isConnected
                                                  ? context.hc.success
                                                  : (ldrCtrl.isBusy
                                                        ? context.hc.primary
                                                        : headingColor),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isConnected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.hc.success
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${ldrCtrl.batteryPercent.value}%',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: context.hc.success,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isConnected
                                          ? 'ID: ${ldrCtrl.braceletId.value} • ${context.tr('smartband.justNow')}'
                                          : (ldrCtrl.lastDataReceivedAt.value !=
                                                    null
                                                ? context.tr(
                                                    'smartband.lastUpdate',
                                                    {'time': relativeTime},
                                                  )
                                                : context.tr(
                                                    'dashboard.connectBandDesc',
                                                  )),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: bodyColor.withValues(
                                          alpha: 0.75,
                                        ),
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── CARD 1: DETAK JANTUNG (MAX30102) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.hc.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: context.hc.border,
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.hc.danger.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: context.hc.danger,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('dashboard.heartRate'),
                                      style: TextStyle(
                                        color: headingColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isConnected && hr != null && hr > 0
                                          ? (hr >= 100
                                                ? context.tr(
                                                    'smartband.warning',
                                                  )
                                                : context.tr(
                                                    'smartband.normal',
                                                  ))
                                          : (isConnected
                                                ? context.tr(
                                                    'dashboard.measuring',
                                                  )
                                                : context.tr(
                                                    'dashboard.notAvailable',
                                                  )),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isConnected && hr != null && hr > 0
                                            ? (hr >= 100
                                                  ? context.hc.warning
                                                  : context.hc.success)
                                            : bodyColor.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    isConnected && hr != null && hr > 0
                                        ? '$hr'
                                        : '—',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: isConnected && hr != null && hr > 0
                                          ? headingColor
                                          : AppColors.textMuted,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'BPM',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: bodyColor.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── CARD 2: LOKASI JAMAAH (PREVIEW MAP / FALLBACK) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF141A24)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkCardBorder
                                  : const Color(0xFFE2E8F0),
                              width: 1.1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primaryGold
                                                .withValues(alpha: 0.15),
                                          ),
                                          child: const Icon(
                                            Icons.location_on_rounded,
                                            color: AppColors.primaryGold,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            context.tr(
                                              'dashboard.pilgrimLocation',
                                            ),
                                            style: TextStyle(
                                              color: headingColor,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activeTarget != null
                                          ? AppColors.statusSafe.withValues(
                                              alpha: 0.12,
                                            )
                                          : Colors.grey.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      activeTarget != null
                                          ? (isConnected
                                                ? 'GPS Aktif'
                                                : 'Lokasi Terakhir')
                                          : 'Belum Ada Sinyal',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: activeTarget != null
                                            ? AppColors.statusSafe
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (activeTarget != null) ...[
                                // ── LIVE MINI MAP PREVIEW ──
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    ldrCtrl.navigateToMap(context);
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      height: 135,
                                      width: double.infinity,
                                      child: Stack(
                                        children: [
                                          fmap.FlutterMap(
                                            options: fmap.MapOptions(
                                              initialCenter: activeTarget,
                                              initialZoom: 16.2,
                                              interactionOptions:
                                                  const fmap.InteractionOptions(
                                                    flags: fmap
                                                        .InteractiveFlag
                                                        .none,
                                                  ),
                                            ),
                                            children: [
                                              fmap.TileLayer(
                                                urlTemplate: isDark
                                                    ? AppConstants
                                                          .cartoDarkMatterUrl
                                                    : AppConstants
                                                          .cartoVoyagerUrl,
                                                userAgentPackageName:
                                                    'com.example.hajicare',
                                              ),
                                              fmap.MarkerLayer(
                                                markers: [
                                                  fmap.Marker(
                                                    point: activeTarget,
                                                    width: 36,
                                                    height: 36,
                                                    alignment: Alignment.center,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppColors
                                                            .primaryGold,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 2.2,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.25,
                                                                ),
                                                            blurRadius: 6,
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .person_pin_circle_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const fmap.RichAttributionWidget(
                                                attributions: [
                                                  fmap.TextSourceAttribution(
                                                    'OSM / CARTO',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (isDark
                                                            ? AppColors
                                                                  .espressoDark
                                                            : Colors.white)
                                                        .withValues(
                                                          alpha: 0.92,
                                                        ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.place_rounded,
                                                    size: 12,
                                                    color:
                                                        AppColors.primaryGold,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Area Masjidil Haram, Makkah',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDark
                                                          ? Colors.white
                                                          : AppColors
                                                                .espressoDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.6,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.touch_app_rounded,
                                                    size: 11,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'Ketuk untuk perbesar',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      ldrCtrl.navigateToMap(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark
                                          ? AppColors.goldLight
                                          : AppColors.espressoDark,
                                      side: BorderSide(
                                        color: AppColors.primaryGold.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.map_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      context.tr(
                                        'dashboard.viewLocationOnMapUpper',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // ── FALLBACK KETIKA BELUM ADA LOKASI / BELUM UPDATE ──
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.black.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.location_searching_rounded,
                                        size: 32,
                                        color: bodyColor.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Lokasi Belum Terdeteksi',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: headingColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Hubungkan smartband di area terbuka untuk memperbarui posisi jemaah secara otomatis.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: bodyColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          Get.toNamed(AppRoutes.map);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 7,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.explore_rounded,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Buka Peta Utama',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Tombol Hubungkan / Putuskan Gelang (Primary Action) ──
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: ldrCtrl.isBusy
                                ? null
                                : () {
                                    if (isConnected) {
                                      ldrCtrl.disconnectSmartband();
                                      HapticFeedback.lightImpact();
                                    } else {
                                      ldrCtrl.connectSmartband();
                                      HapticFeedback.lightImpact();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isConnected
                                  ? context.hc.danger
                                  : context.hc.primary,
                              foregroundColor: Colors.white,
                              elevation: 1.5,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              isConnected
                                  ? Icons.link_off_rounded
                                  : (ldrCtrl.isBusy
                                        ? Icons.sync_rounded
                                        : Icons.bluetooth_searching_rounded),
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              isConnected
                                  ? context.tr('dashboard.disconnectBandUpper')
                                  : (ldrCtrl.isBusy
                                        ? context.tr(
                                            'dashboard.processingUpper',
                                          )
                                        : context.tr(
                                            'dashboard.connectBandUpper',
                                          )),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Buka Halaman Penuh (Secondary Action) ──
                        Center(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: context.hc.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Get.toNamed(AppRoutes.smartbandLdr);
                            },
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 15,
                            ),
                            label: Text(
                              context.tr('dashboard.openFullScreen'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              // ── 2. Floating Hero Card ──
              Positioned(
                top: 0,
                left: 22,
                right: 22,
                child: HajiDialogHeroHeader(
                  icon: Icons.watch_rounded,
                  title: 'HAJICARE SMARTBAND',
                  onClose: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
