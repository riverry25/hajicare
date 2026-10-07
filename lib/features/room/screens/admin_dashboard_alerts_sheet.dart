part of 'admin_dashboard_screen.dart';

extension _AdminDashboardAlertsSheet on _AdminDashboardHome {
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
              final totalAlertCount =
                  activeSosList.length + attentionList.length;
              final hasActiveAlerts = totalAlertCount > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Drag handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: bodyColor.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      (hasActiveAlerts
                                              ? AppColors.sosEmergency
                                              : AppColors.statusSafe)
                                          .withValues(
                                            alpha: isDark ? 0.2 : 0.12,
                                          ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(
                                    color:
                                        (hasActiveAlerts
                                                ? AppColors.sosEmergency
                                                : AppColors.statusSafe)
                                            .withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    hasActiveAlerts
                                        ? Icons.crisis_alert_rounded
                                        : Icons.verified_user_rounded,
                                    color: hasActiveAlerts
                                        ? AppColors.sosEmergency
                                        : AppColors.statusSafe,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            context.tr(
                                              'adminDashboard.alertCenterUpper',
                                            ),
                                            style: DashboardTypography
                                                .titleMedium
                                                .copyWith(
                                                  color: headingColor,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  fontSize: 16,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (hasActiveAlerts) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.sosEmergency,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.pill,
                                                  ),
                                            ),
                                            child: Text(
                                              '$totalAlertCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasActiveAlerts
                                          ? context.tr(
                                              'adminDashboard.conditionsNeedAttention',
                                              {'count': totalAlertCount},
                                            )
                                          : context.tr(
                                              'adminDashboard.systemSafe',
                                            ),
                                      style: DashboardTypography.captionSmall
                                          .copyWith(
                                            color: bodyColor.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 12,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.05),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(ctx),
                            child: Padding(
                              padding: const EdgeInsets.all(7),
                              child: Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: bodyColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          if (!hasActiveAlerts) ...[
                            // Safe condition card
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 36,
                                horizontal: AppSpacing.lg,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.canvasCreamSubtle.withValues(
                                        alpha: 0.3,
                                      ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkCardBorder
                                      : AppColors.lightCardBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.statusSafe.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        size: 34,
                                        color: AppColors.statusSafe,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    context.tr('adminDashboard.noActiveAlert'),
                                    style: DashboardTypography.titleSmall
                                        .copyWith(
                                          color: headingColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.5,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    context.tr(
                                      'adminDashboard.allPilgrimsSafe',
                                    ),
                                    style: DashboardTypography.bodySmall
                                        .copyWith(
                                          color: bodyColor.withValues(
                                            alpha: 0.8,
                                          ),
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
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.sosEmergency,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  context.tr('adminDashboard.highPriority'),
                                  style: DashboardTypography.captionSmall
                                      .copyWith(
                                        color: AppColors.sosEmergency,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                        fontSize: 12,
                                      ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.sosEmergency.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    '${activeSosList.length}',
                                    style: const TextStyle(
                                      color: AppColors.sosEmergency,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs + 4),
                            ...activeSosList.map((sos) {
                              final userName =
                                  (sos['userName'] ??
                                          context.tr('room.roleJamaah'))
                                      .toString();
                              final roomName =
                                  (sos['roomName'] ??
                                          context.tr('adminDashboard.room'))
                                      .toString();
                              final timestamp =
                                  (sos['timestamp'] ?? sos['createdAt'])
                                      as Timestamp?;
                              final timeAgo = timestamp != null
                                  ? _formatMinutesAgo(
                                      DateTime.now().difference(
                                        timestamp.toDate(),
                                      ),
                                    )
                                  : context.tr('dashboard.justNow');
                              final initial = userName.trim().isNotEmpty
                                  ? userName.trim()[0].toUpperCase()
                                  : 'J';

                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF231416)
                                      : const Color(0xFFFFF6F6),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.card,
                                  ),
                                  border: Border.all(
                                    color: AppColors.sosEmergency.withValues(
                                      alpha: 0.45,
                                    ),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.sosEmergency.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top Badges Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.sosEmergency
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.pill,
                                                  ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.emergency_rounded,
                                                  size: 13,
                                                  color: AppColors.sosEmergency,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'SOS',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.sosEmergency,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 12,
                                                color: bodyColor.withValues(
                                                  alpha: 0.55,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                timeAgo,
                                                style: DashboardTypography
                                                    .captionSmall
                                                    .copyWith(
                                                      color: bodyColor
                                                          .withValues(
                                                            alpha: 0.65,
                                                          ),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // User Profile Info
                                      Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.sosEmergency
                                                  .withValues(alpha: 0.12),
                                              border: Border.all(
                                                color: AppColors.sosEmergency
                                                    .withValues(alpha: 0.35),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                initial,
                                                style: const TextStyle(
                                                  color: AppColors.sosEmergency,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userName,
                                                  style: DashboardTypography
                                                      .titleSmall
                                                      .copyWith(
                                                        color: headingColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .meeting_room_outlined,
                                                      size: 13,
                                                      color: bodyColor
                                                          .withValues(
                                                            alpha: 0.65,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        roomName,
                                                        style: DashboardTypography
                                                            .captionSmall
                                                            .copyWith(
                                                              color: bodyColor
                                                                  .withValues(
                                                                    alpha: 0.75,
                                                                  ),
                                                              fontSize: 12,
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Map Action Button
                                      Material(
                                        color: AppColors.sosEmergency
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.sm + 2,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            _focusMemberOnMap(
                                              context: context,
                                              sheetContext: ctx,
                                              dashboardCtrl: dashboardCtrl,
                                              controller: controller,
                                              userId:
                                                  (sos['userId'] ??
                                                          sos['jamaahId'])
                                                      ?.toString(),
                                              userName: userName,
                                              roomId:
                                                  (sos['roomId'] ??
                                                          sos['activeRoomId'])
                                                      ?.toString(),
                                              rawLocation: sos['location'],
                                              extraData: sos,
                                              timestamp: timestamp?.toDate(),
                                              isSos: true,
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.sm + 2,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8.5,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.near_me_rounded,
                                                  size: 15,
                                                  color: AppColors.sosEmergency,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  context.tr('room.viewOnMap'),
                                                  style: DashboardTypography
                                                      .captionSmall
                                                      .copyWith(
                                                        color: AppColors
                                                            .sosEmergency,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.5,
                                                      ),
                                                ),
                                                const Spacer(),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 14,
                                                  color: AppColors.sosEmergency,
                                                ),
                                              ],
                                            ),
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
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.distanceWarning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  context.tr('adminDashboard.needsAttention'),
                                  style: DashboardTypography.captionSmall
                                      .copyWith(
                                        color: AppColors.distanceWarning,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                        fontSize: 12,
                                      ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.distanceWarning.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    '${attentionList.length}',
                                    style: const TextStyle(
                                      color: AppColors.distanceWarning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs + 4),
                            ...attentionList.map((j) {
                              final name =
                                  (j['name'] ??
                                          j['displayName'] ??
                                          context.tr('room.roleJamaah'))
                                      .toString();
                              final room = controller.rooms.firstWhereOrNull(
                                (r) => r.id == j['activeRoomId'],
                              );
                              final roomName = room?.name ?? 'Room';
                              final timestamp =
                                  j['locationUpdatedAt'] is Timestamp
                                  ? (j['locationUpdatedAt'] as Timestamp)
                                        .toDate()
                                  : null;
                              final timeAgo = timestamp != null
                                  ? _formatMinutesAgo(
                                      DateTime.now().difference(timestamp),
                                    )
                                  : context.tr('adminDashboard.notUpdated');
                              final initial = name.trim().isNotEmpty
                                  ? name.trim()[0].toUpperCase()
                                  : 'J';

                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF221A12)
                                      : const Color(0xFFFFFBF4),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.card,
                                  ),
                                  border: Border.all(
                                    color: AppColors.distanceWarning.withValues(
                                      alpha: 0.38,
                                    ),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.15)
                                          : AppColors.distanceWarning
                                                .withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      if (room != null) {
                                        Navigator.pop(ctx);
                                        controller.selectedRoom.value = room;
                                        controller.subscribeToRoomMembers(
                                          room.id,
                                        );
                                        Get.toNamed(
                                          AppRoutes.roomDetail,
                                          arguments: room,
                                        );
                                      } else {
                                        Navigator.pop(ctx);
                                        dashboardCtrl.changeTab(1);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.card,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Top status row
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .distanceWarning
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppRadius.pill,
                                                      ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .location_off_rounded,
                                                      size: 13,
                                                      color: AppColors
                                                          .distanceWarning,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      context.tr(
                                                        'adminDashboard.locationNotUpdated',
                                                      ),
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .distanceWarning,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 12,
                                                    color: bodyColor.withValues(
                                                      alpha: 0.55,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    timeAgo,
                                                    style: DashboardTypography
                                                        .captionSmall
                                                        .copyWith(
                                                          color: bodyColor
                                                              .withValues(
                                                                alpha: 0.65,
                                                              ),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          // User info row
                                          Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppColors
                                                      .distanceWarning
                                                      .withValues(alpha: 0.12),
                                                  border: Border.all(
                                                    color: AppColors
                                                        .distanceWarning
                                                        .withValues(alpha: 0.3),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    initial,
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .distanceWarning,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: DashboardTypography
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
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .meeting_room_outlined,
                                                          size: 12,
                                                          color: bodyColor
                                                              .withValues(
                                                                alpha: 0.65,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            roomName,
                                                            style: DashboardTypography
                                                                .captionSmall
                                                                .copyWith(
                                                                  color: bodyColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.75,
                                                                      ),
                                                                  fontSize: 12,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      (isDark
                                                              ? Colors.white
                                                              : Colors.black)
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons
                                                        .arrow_forward_ios_rounded,
                                                    size: 11,
                                                    color: bodyColor.withValues(
                                                      alpha: 0.6,
                                                    ),
                                                  ),
                                                ),
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
                            Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 15,
                                  color: bodyColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('adminDashboard.lastHistory'),
                                  style: DashboardTypography.captionSmall
                                      .copyWith(
                                        color: headingColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs + 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkCardBorder
                                      : AppColors.lightCardBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < resolvedList.length;
                                    i++
                                  ) ...[
                                    if (i > 0)
                                      Divider(
                                        height: 12,
                                        thickness: 0.7,
                                        color: isDark
                                            ? AppColors.darkCardBorder
                                            : AppColors.lightCardBorder,
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(3.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.statusSafe
                                                  .withValues(alpha: 0.14),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              size: 12,
                                              color: AppColors.statusSafe,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              context.tr(
                                                'adminDashboard.sosResolved',
                                                {
                                                  'name':
                                                      resolvedList[i]['userName'] ??
                                                      context.tr(
                                                        'room.roleJamaah',
                                                      ),
                                                },
                                              ),
                                              style: DashboardTypography
                                                  .captionSmall
                                                  .copyWith(
                                                    color: headingColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            _formatMinutesAgo(
                                              DateTime.now().difference(
                                                ((resolvedList[i]['resolvedAt'] ??
                                                                resolvedList[i]['timestamp'])
                                                            as Timestamp?)
                                                        ?.toDate() ??
                                                    DateTime.now(),
                                              ),
                                            ),
                                            style: DashboardTypography
                                                .captionSmall
                                                .copyWith(
                                                  color: bodyColor.withValues(
                                                    alpha: 0.65,
                                                  ),
                                                  fontSize: 10.5,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
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
    if (diff.isNegative || diff.inSeconds < 60) {
      return AppTranslations.tr('dashboard.justNow');
    }
    if (diff.inMinutes < 60) {
      return AppTranslations.tr('dashboard.minutesAgo', {
        'minutes': diff.inMinutes,
      });
    }
    if (diff.inHours < 24) {
      return AppTranslations.tr('adminDashboard.hoursAgo', {
        'hours': diff.inHours,
      });
    }
    return AppTranslations.tr('adminDashboard.daysAgo', {'days': diff.inDays});
  }

  void _focusMemberOnMap({
    required BuildContext context,
    required BuildContext sheetContext,
    required DashboardController dashboardCtrl,
    required AdminRoomController controller,
    required String? userId,
    required String userName,
    required String? roomId,
    required dynamic rawLocation,
    Map<String, dynamic>? extraData,
    required DateTime? timestamp,
    required bool isSos,
  }) {
    HapticFeedback.lightImpact();
    Navigator.pop(sheetContext);

    LatLng? parseCoord(dynamic loc, [Map<String, dynamic>? data]) {
      if (loc is GeoPoint) {
        return LatLng(loc.latitude, loc.longitude);
      }
      if (loc is Map) {
        final lat = (loc['latitude'] ?? loc['lat'] ?? loc['_latitude']) as num?;
        final lng =
            (loc['longitude'] ?? loc['lng'] ?? loc['_longitude']) as num?;
        if (lat != null && lng != null) {
          return LatLng(lat.toDouble(), lng.toDouble());
        }
      }
      if (loc is String && loc.contains(',')) {
        final parts = loc.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) return LatLng(lat, lng);
        }
      }
      if (data != null) {
        final lat =
            (data['latitude'] ?? data['lat'] ?? data['_latitude']) as num?;
        final lng =
            (data['longitude'] ?? data['lng'] ?? data['_longitude']) as num?;
        if (lat != null && lng != null) {
          return LatLng(lat.toDouble(), lng.toDouble());
        }
      }
      return null;
    }

    // 1. Resolve Target Coordinate
    LatLng? targetCoord = parseCoord(rawLocation, extraData);

    final cleanUid = userId?.trim();
    final cleanName = userName.trim().toLowerCase();

    // Fallback A: Search across controller.allUsers
    if (targetCoord == null) {
      final matchedUser = controller.allUsers.firstWhereOrNull((u) {
        final uId = (u['uid'] ?? u['id'])?.toString().trim();
        if (cleanUid != null && cleanUid.isNotEmpty && uId == cleanUid) {
          return true;
        }
        final uName = (u['name'] ?? u['displayName'])
            ?.toString()
            .trim()
            .toLowerCase();
        if (uName != null &&
            cleanName.isNotEmpty &&
            (uName == cleanName ||
                uName.contains(cleanName) ||
                cleanName.contains(uName))) {
          return true;
        }
        return false;
      });

      if (matchedUser != null) {
        final uLoc =
            matchedUser['currentLocation'] ??
            matchedUser['location'] ??
            matchedUser['lastLocation'];
        targetCoord = parseCoord(uLoc, matchedUser);
      }
    }

    // Fallback B: Search across controller.roomMembers
    if (targetCoord == null) {
      final m = controller.roomMembers.firstWhereOrNull((mem) {
        if (cleanUid != null && cleanUid.isNotEmpty && mem.uid == cleanUid) {
          return true;
        }
        final mName = mem.name.trim().toLowerCase();
        return cleanName.isNotEmpty &&
            (mName == cleanName ||
                mName.contains(cleanName) ||
                cleanName.contains(mName));
      });
      if (m != null && m.hasLocation) {
        targetCoord = LatLng(m.latitude!, m.longitude!);
      }
    }

    // Fallback C: Search across HajiCareController
    if (targetCoord == null && Get.isRegistered<HajiCareController>()) {
      final hajiCtrl = Get.find<HajiCareController>();
      final j = hajiCtrl.jamaahList.firstWhereOrNull((item) {
        if (cleanUid != null && cleanUid.isNotEmpty && item.id == cleanUid) {
          return true;
        }
        final jName = item.name.trim().toLowerCase();
        return cleanName.isNotEmpty &&
            (jName == cleanName ||
                jName.contains(cleanName) ||
                cleanName.contains(jName));
      });
      if (j?.currentLocation != null) {
        targetCoord = LatLng(
          j!.currentLocation!.latitude,
          j.currentLocation!.longitude,
        );
      }

      if (targetCoord == null) {
        final mem = hajiCtrl.activeRoomMembers.firstWhereOrNull((item) {
          if (cleanUid != null && cleanUid.isNotEmpty && item.uid == cleanUid) {
            return true;
          }
          final memName = item.name.trim().toLowerCase();
          return cleanName.isNotEmpty &&
              (memName == cleanName ||
                  memName.contains(cleanName) ||
                  cleanName.contains(memName));
        });
        if (mem != null && mem.hasLocation) {
          targetCoord = LatLng(mem.latitude!, mem.longitude!);
        }
      }
    }

    // 2. Synchronize Room
    if (roomId != null && roomId.isNotEmpty) {
      final room = controller.rooms.firstWhereOrNull((r) => r.id == roomId);
      if (room != null) {
        controller.selectedRoom.value = room;
        controller.subscribeToRoomMembers(room.id);
      }
      if (Get.isRegistered<HajiCareController>()) {
        final hajiCtrl = Get.find<HajiCareController>();
        hajiCtrl.activeRoomId.value = roomId;
        if (room != null) hajiCtrl.activeRoom.value = room;
      }
    }

    // 3. Obtain MapController & configure selection
    final mapCtrl = Get.isRegistered<MapController>()
        ? Get.find<MapController>()
        : Get.put(MapController());

    final member = RoomMemberModel(
      uid: userId ?? '',
      name: userName,
      role: 'jamaah',
      currentLocation: targetCoord != null
          ? GeoPoint(targetCoord.latitude, targetCoord.longitude)
          : (rawLocation is GeoPoint ? rawLocation : null),
      locationUpdatedAt: timestamp ?? DateTime.now(),
      sosActive: isSos,
    );

    mapCtrl.selectedFilter.value = 0;
    mapCtrl.selectedPoi.value = null;
    mapCtrl.selectedJamaah.value = null;
    mapCtrl.selectedMember.value = member;
    mapCtrl.isBottomSheetOpen.value = true;

    if (targetCoord != null) {
      mapCtrl.pendingFocusCoordinate = targetCoord;
      mapCtrl.pendingFocusZoom = 17.5;
    }

    // 4. Switch to Map Tab
    dashboardCtrl.changeTab(1);

    // 5. Ensure camera immediately pans & focuses on the member
    if (targetCoord != null) {
      final dest = targetCoord;
      void triggerFocus() {
        if (mapCtrl.isMapAttached) {
          mapCtrl.animatedMove(dest, 17.5);
        } else {
          mapCtrl.focusCoordinate(dest, destZoom: 17.5);
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        triggerFocus();
        Future.delayed(const Duration(milliseconds: 150), triggerFocus);
        Future.delayed(const Duration(milliseconds: 300), triggerFocus);
      });
    } else {
      // Async lookup from Firestore if not yet cached in memory
      if (cleanUid != null && cleanUid.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(cleanUid)
            .get()
            .then((doc) {
              if (!doc.exists) return;
              final data = doc.data();
              if (data == null) return;
              final loc =
                  data['currentLocation'] ??
                  data['location'] ??
                  data['lastLocation'];
              final parsed = parseCoord(loc, data);
              if (parsed != null) {
                final updatedMember = member.copyWith(
                  currentLocation: GeoPoint(parsed.latitude, parsed.longitude),
                );
                mapCtrl.selectedMember.value = updatedMember;
                mapCtrl.pendingFocusCoordinate = parsed;
                mapCtrl.pendingFocusZoom = 17.5;
                if (mapCtrl.isMapAttached) {
                  mapCtrl.animatedMove(parsed, 17.5);
                }
              }
            })
            .catchError((_) {});
      }

      // Inform user gracefully if GPS is completely unavailable
      AppAlert.warning(
        context,
        title: context.tr('maps.locationUnavailable'),
        message: 'Lokasi jamaah $userName belum tersedia di GPS.',
      );
    }
  }
}
