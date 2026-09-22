part of 'admin_dashboard_screen.dart';

extension _AdminDashboardJamaahSheet on _AdminDashboardHome {
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
                    final room =
                        controller.rooms
                            .firstWhereOrNull((r) => r.id == j['activeRoomId'])
                            ?.name
                            .toLowerCase() ??
                        '';
                    if (q.isEmpty) return true;
                    return name.contains(q) || room.contains(q);
                  }).toList();

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

                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusSafe.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.groups_rounded,
                                    color: AppColors.statusSafe,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr(
                                        'adminDashboard.totalPilgrimsUpper',
                                      ),
                                      style: DashboardTypography.titleMedium
                                          .copyWith(
                                            color: headingColor,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                    Text(
                                      context.tr(
                                        'adminDashboard.registeredPilgrims',
                                        {
                                          'shown': filtered.length,
                                          'total': allJamaah.length,
                                        },
                                      ),
                                      style: DashboardTypography.captionSmall
                                          .copyWith(
                                            color: bodyColor.withValues(
                                              alpha: 0.7,
                                            ),
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
                            hintText: context.tr('room.searchJamaahOrMaktab'),
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
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.lightCardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_search_rounded,
                                        size: 48,
                                        color: bodyColor.withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        searchQuery.isEmpty
                                            ? context.tr(
                                                'adminDashboard.noPilgrimData',
                                              )
                                            : context.tr(
                                                'adminDashboard.noSearchResult',
                                                {'query': searchQuery},
                                              ),
                                        style: DashboardTypography.bodySmall
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
                                    final name =
                                        (j['name'] ??
                                                j['displayName'] ??
                                                context.tr('room.roleJamaah'))
                                            .toString();
                                    final room = controller.rooms
                                        .firstWhereOrNull(
                                          (r) => r.id == j['activeRoomId'],
                                        );
                                    final roomName =
                                        room?.name ??
                                        context.tr(
                                          'adminDashboard.notRegisteredRoom',
                                        );
                                    final isSos = j['sosActive'] == true;
                                    final isGps = j['isGpsActive'] == true;
                                    final locUpdatedAt =
                                        j['locationUpdatedAt'] is Timestamp
                                        ? (j['locationUpdatedAt'] as Timestamp)
                                              .toDate()
                                        : null;

                                    // Determine status dot & text
                                    final Color dotColor;
                                    final String statusLabel;

                                    if (isSos) {
                                      dotColor = AppColors.sosEmergency;
                                      statusLabel =
                                          '• ${context.tr('adminDashboard.sosActive')}';
                                    } else if (locUpdatedAt != null) {
                                      final diff = DateTime.now().difference(
                                        locUpdatedAt,
                                      );
                                      if (diff.inMinutes <= 5 || isGps) {
                                        dotColor = AppColors.statusSafe;
                                        statusLabel =
                                            '• ${context.tr('adminDashboard.online')}';
                                      } else {
                                        dotColor = const Color(
                                          0xFFF57C00,
                                        ); // Amber (stale location)
                                        statusLabel = context.tr(
                                          'adminDashboard.lastLocation',
                                          {'time': _formatMinutesAgo(diff)},
                                        );
                                      }
                                    } else if (isGps) {
                                      dotColor = AppColors.statusSafe;
                                      statusLabel =
                                          '• ${context.tr('adminDashboard.online')}';
                                    } else {
                                      dotColor = bodyColor.withValues(
                                        alpha: 0.5,
                                      );
                                      statusLabel = context.tr(
                                        'adminDashboard.offline',
                                      );
                                    }

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.card,
                                        ),
                                        border: Border.all(
                                          color: isSos
                                              ? AppColors.sosEmergency
                                                    .withValues(alpha: 0.6)
                                              : (isDark
                                                    ? AppColors.darkCardBorder
                                                    : AppColors
                                                          .lightCardBorder),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black.withValues(
                                                    alpha: 0.15,
                                                  )
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
                                              controller.selectedRoom.value =
                                                  room;
                                              controller.subscribeToRoomMembers(
                                                room.id,
                                              );
                                              Get.toNamed(
                                                AppRoutes.roomDetail,
                                                arguments: room,
                                              );
                                            } else {
                                              AppAlert.info(
                                                context,
                                                title: name,
                                                message: context.tr(
                                                  'adminDashboard.pilgrimNoRoom',
                                                ),
                                              );
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.card,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
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
                                                        style: DashboardTypography
                                                            .titleSmall
                                                            .copyWith(
                                                              color:
                                                                  headingColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        roomName,
                                                        style: DashboardTypography
                                                            .captionSmall
                                                            .copyWith(
                                                              color: bodyColor
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  ),
                                                              fontSize: 11.5,
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        statusLabel,
                                                        style:
                                                            DashboardTypography
                                                                .captionSmall
                                                                .copyWith(
                                                                  color:
                                                                      dotColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      10.5,
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

  // Pendamping bottom sheet
}
