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
                                color:
                                    (hasActiveAlerts
                                            ? AppColors.sosEmergency
                                            : AppColors.statusSafe)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
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
                                  context.tr('adminDashboard.alertCenterUpper'),
                                  style: DashboardTypography.titleMedium
                                      .copyWith(
                                        color: headingColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                Text(
                                  hasActiveAlerts
                                      ? context.tr(
                                          'adminDashboard.conditionsNeedAttention',
                                          {
                                            'count':
                                                activeSosList.length +
                                                attentionList.length,
                                          },
                                        )
                                      : context.tr('adminDashboard.systemSafe'),
                                  style: DashboardTypography.captionSmall
                                      .copyWith(
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
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.statusSafe.withValues(
                                        alpha: 0.12,
                                      ),
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
                                    context.tr('adminDashboard.noActiveAlert'),
                                    style: DashboardTypography.titleSmall
                                        .copyWith(
                                          color: headingColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
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
                            Text(
                              context.tr('adminDashboard.highPriority'),
                              style: DashboardTypography.captionSmall.copyWith(
                                color: AppColors.sosEmergency,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs + 2),
                            ...activeSosList.map((sos) {
                              final userName =
                                  sos['userName'] ??
                                  context.tr('room.roleJamaah');
                              final roomName =
                                  sos['roomName'] ??
                                  context.tr('adminDashboard.room');
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

                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.card,
                                  ),
                                  border: Border.all(
                                    color: AppColors.sosEmergency.withValues(
                                      alpha: 0.6,
                                    ),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.sosEmergency.withValues(
                                        alpha: 0.08,
                                      ),
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
                                                Text(
                                                  'ðŸš¨',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
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
                                            style: DashboardTypography
                                                .captionSmall
                                                .copyWith(
                                                  color: bodyColor.withValues(
                                                    alpha: 0.65,
                                                  ),
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        userName,
                                        style: DashboardTypography.titleSmall
                                            .copyWith(
                                              color: headingColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                      ),
                                      Text(
                                        roomName,
                                        style: DashboardTypography.bodySmall
                                            .copyWith(
                                              color: bodyColor.withValues(
                                                alpha: 0.75,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          dashboardCtrl.changeTab(1);
                                        },
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.sm,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
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
                              context.tr('adminDashboard.needsAttention'),
                              style: DashboardTypography.captionSmall.copyWith(
                                color: AppColors.distanceWarning,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs + 2),
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

                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.card,
                                  ),
                                  border: Border.all(
                                    color: AppColors.distanceWarning.withValues(
                                      alpha: 0.45,
                                    ),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(
                                              alpha: 0.03,
                                            ),
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
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text(
                                                    'âš ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    context.tr(
                                                      'adminDashboard.locationNotUpdated',
                                                    ),
                                                    style: DashboardTypography
                                                        .captionSmall
                                                        .copyWith(
                                                          color: AppColors
                                                              .distanceWarning,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 11.5,
                                                        ),
                                                  ),
                                                ],
                                              ),
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
                                                      style: DashboardTypography
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
                                                      style: DashboardTypography
                                                          .captionSmall
                                                          .copyWith(
                                                            color: bodyColor
                                                                .withValues(
                                                                  alpha: 0.75,
                                                                ),
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
                                                color: headingColor.withValues(
                                                  alpha: 0.35,
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
                            Text(
                              context.tr('adminDashboard.lastHistory'),
                              style: DashboardTypography.captionSmall.copyWith(
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
                                children: resolvedList.map((res) {
                                  final name =
                                      res['userName'] ??
                                      context.tr('room.roleJamaah');
                                  final resTime =
                                      (res['resolvedAt'] ?? res['timestamp'])
                                          as Timestamp?;
                                  final timeAgo = resTime != null
                                      ? _formatMinutesAgo(
                                          DateTime.now().difference(
                                            resTime.toDate(),
                                          ),
                                        )
                                      : context.tr('adminDashboard.completed');

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
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
                                            context.tr(
                                              'adminDashboard.sosResolved',
                                              {'name': name},
                                            ),
                                            style: DashboardTypography
                                                .captionSmall
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
    if (diff.inSeconds < 60) return AppTranslations.tr('dashboard.justNow');
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
}
