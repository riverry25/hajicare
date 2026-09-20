part of 'admin_dashboard_screen.dart';

extension _AdminDashboardPendampingSheet on _AdminDashboardHome {
  void _showAllPendampingSheet(
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
              final allPendamping = controller.allPendamping;

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
                                color: AppColors.secondary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: const Icon(
                                Icons.health_and_safety_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PENDAMPING',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: headingColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '${allPendamping.length} petugas aktif terdaftar',
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

                    // List
                    Expanded(
                      child: allPendamping.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.health_and_safety_outlined,
                                    size: 48,
                                    color: bodyColor.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Belum ada petugas pendamping terdaftar.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: bodyColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: allPendamping.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, idx) {
                                final p = allPendamping[idx];
                                final name =
                                    (p['name'] ??
                                            p['displayName'] ??
                                            'Pendamping')
                                        .toString();
                                final activeRoomId =
                                    p['activeRoomId'] as String?;
                                final room =
                                    activeRoomId != null &&
                                        activeRoomId.isNotEmpty
                                    ? controller.rooms.firstWhereOrNull(
                                        (r) => r.id == activeRoomId,
                                      )
                                    : null;
                                final roomName =
                                    room?.name ?? 'Belum mengelola room';
                                final jamaahCount = activeRoomId != null
                                    ? controller.getRoomJamaahCount(
                                        activeRoomId,
                                      )
                                    : null;
                                final isOnline =
                                    p['isGpsActive'] == true || room != null;

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
                                          controller.selectedRoom.value = room;
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
                                            message:
                                                'Petugas ini belum ditugaskan ke room manapun.',
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.card,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Avatar shield icon
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary
                                                    .withValues(
                                                      alpha: isDark
                                                          ? 0.22
                                                          : 0.12,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.md,
                                                    ),
                                              ),
                                              child: const Icon(
                                                Icons.shield_rounded,
                                                color: AppColors.secondary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: AppTypography
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
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 7,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              (isOnline
                                                                      ? AppColors
                                                                            .statusSafe
                                                                      : AppColors
                                                                            .textSecondary)
                                                                  .withValues(
                                                                    alpha:
                                                                        isDark
                                                                        ? 0.2
                                                                        : 0.12,
                                                                  ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                AppRadius.pill,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                (isOnline
                                                                        ? AppColors
                                                                              .statusSafe
                                                                        : AppColors
                                                                              .textSecondary)
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
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
                                                              decoration: BoxDecoration(
                                                                color: isOnline
                                                                    ? AppColors
                                                                          .statusSafe
                                                                    : AppColors
                                                                          .textSecondary,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              isOnline
                                                                  ? 'Aktif'
                                                                  : 'Offline',
                                                              style: AppTypography
                                                                  .captionSmall
                                                                  .copyWith(
                                                                    color:
                                                                        isOnline
                                                                        ? AppColors
                                                                              .statusSafe
                                                                        : AppColors
                                                                              .textSecondary,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    roomName,
                                                    style: AppTypography
                                                        .captionSmall
                                                        .copyWith(
                                                          color: bodyColor
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                          fontSize: 11.5,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (jamaahCount != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '$jamaahCount Jamaah dipantau',
                                                      style: AppTypography
                                                          .captionSmall
                                                          .copyWith(
                                                            color: primaryColor,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 11,
                                                          ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 11,
                                              color: headingColor.withValues(
                                                alpha: 0.35,
                                              ),
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

  // Alert center bottom sheet
}
