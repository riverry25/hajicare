part of 'admin_dashboard_screen.dart';

extension _AdminDashboardSections on _AdminDashboardHome {
  Widget _buildQuickActions(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color primaryColor,
  ) {
    final activeSos = controller.activeSosCount.value;

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

        // 2x3 Bento Grid of Quick Actions
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: 'Buat Room',
                subtitle: 'Grup/Kloter baru',
                icon: Icons.add_business_rounded,
                color: isDark ? AppColors.tanLight : AppColors.secondary,
                cardBg: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                headingColor: isDark
                    ? AppColors.darkTextHeading
                    : AppColors.primaryContainer,
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
                color: AppColors.statusSafe,
                cardBg: cardBg,
                headingColor: headingColor,
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.adminRooms),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: 'Pantau Map',
                subtitle: 'Lokasi & perimeter',
                icon: Icons.map_rounded,
                color: AppColors.secondary,
                cardBg: cardBg,
                headingColor: headingColor,
                isDark: isDark,
                onTap: () => dashboardCtrl.changeTab(1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                label: 'Pusat Alert',
                subtitle: activeSos > 0
                    ? '$activeSos SOS aktif'
                    : 'Pusat notifikasi',
                icon: Icons.notification_important_rounded,
                color: activeSos > 0
                    ? AppColors.sosEmergency
                    : AppColors.statusSafe,
                cardBg: activeSos > 0
                    ? (isDark
                          ? AppColors.darkSurface
                          : AppColors.errorContainer)
                    : cardBg,
                headingColor: activeSos > 0
                    ? AppColors.sosEmergency
                    : headingColor,
                isDark: isDark,
                onTap: () {
                  if (activeSos > 0) {
                    _showAlertCenterSheet(
                      context,
                      controller,
                      dashboardCtrl,
                      isDark,
                      cardBg,
                      headingColor,
                      isDark ? AppColors.darkTextBody : AppColors.textBody,
                      primaryColor,
                    );
                  } else {
                    Get.toNamed(AppRoutes.notification);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: 'Kirim Siaran',
                subtitle: 'Notifikasi broadcast',
                icon: Icons.campaign_rounded,
                color: AppColors.distanceWarning,
                cardBg: cardBg,
                headingColor: headingColor,
                isDark: isDark,
                onTap: () => NotificationComposerDialog.show(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                label: 'Perimeter Radar',
                subtitle: 'Radius aman jamaah',
                icon: Icons.radar_rounded,
                color: AppColors.emeraldIslamic,
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

    // 4. Ambil 3-4 aktivitas terbaru untuk preview card yang padat dan presisi
    final previewActivities = sortedActivities.take(3).toList();

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
                                sortedActivities.isEmpty
                                    ? 'Realtime - Pemantauan aktif'
                                    : 'Realtime - ${sortedActivities.length} aktivitas',
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

        // Body: Empty State or Activity Cards List
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int idx = 0; idx < previewActivities.length; idx++) ...[
                  if (idx > 0)
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      indent: 58,
                      endIndent: AppSpacing.md,
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.canvasCreamSubtle,
                    ),
                  _ActivityFeedTile(
                    activity: previewActivities[idx],
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    isDark: isDark,
                    onTap: () => _showActivityDetailSheet(
                      context,
                      previewActivities[idx],
                      controller,
                      isDark,
                      headingColor,
                      bodyColor,
                      primaryColor,
                    ),
                  ),
                ],
                if (sortedActivities.length > previewActivities.length) ...[
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.canvasCreamSubtle,
                  ),
                  InkWell(
                    onTap: () => _showAllActivitiesSheet(
                      context,
                      controller,
                      isDark,
                      headingColor,
                      bodyColor,
                      primaryColor,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.lg),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lihat ${sortedActivities.length - previewActivities.length} aktivitas lainnya',
                            style: AppTypography.captionSmall.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
