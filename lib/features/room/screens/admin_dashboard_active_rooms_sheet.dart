part of 'admin_dashboard_screen.dart';

extension _AdminDashboardActiveRoomsSheet on _AdminDashboardHome {
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
                                color:
                                    (isDark
                                            ? AppColors.darkPrimary
                                            : AppColors.accentGoldStar)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
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
                                    style: AppTypography.bodySmall.copyWith(
                                      color: bodyColor,
                                    ),
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
                                final jCount = controller.getRoomJamaahCount(
                                  room.id,
                                );
                                final pCount = controller
                                    .getRoomPendampingCount(room.id);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.card,
                                    ),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkCardBorder
                                          : AppColors.lightCardBorder,
                                      width: 1.0,
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
                                        Navigator.pop(ctx);
                                        controller.selectedRoom.value = room;
                                        controller.subscribeToRoomMembers(
                                          room.id,
                                        );
                                        Get.toNamed(
                                          AppRoutes.roomDetail,
                                          arguments: room,
                                        );
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
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2.5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.statusSafe
                                                        .withValues(
                                                          alpha: isDark
                                                              ? 0.2
                                                              : 0.12,
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
                                                              shape: BoxShape
                                                                  .circle,
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
                                            const SizedBox(height: 6),

                                            // Middle: Count
                                            Text(
                                              '$jCount Jamaah - $pCount Pendamping',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                    color: bodyColor.withValues(
                                                      alpha: 0.85,
                                                    ),
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

  // Total jamaah bottom sheet
}
