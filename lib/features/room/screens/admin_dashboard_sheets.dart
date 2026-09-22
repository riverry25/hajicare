part of 'admin_dashboard_screen.dart';

extension _AdminDashboardActivitySheets on _AdminDashboardHome {
  void _showActivityDetailSheet(
    BuildContext context,
    ActivityModel act,
    AdminRoomController controller,
    bool isDark,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    HapticFeedback.lightImpact();
    final matchingRoom = act.roomId != null
        ? controller.rooms.firstWhereOrNull((r) => r.id == act.roomId)
        : null;

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
            top: AppSpacing.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Header Badge & Type
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: act.color.withValues(alpha: isDark ? 0.22 : 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: act.color.withValues(
                          alpha: isDark ? 0.45 : 0.30,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(act.icon, color: act.color, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: act.color.withValues(
                                  alpha: isDark ? 0.20 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                _activityTypeName(act.type),
                                style: DashboardTypography.captionSmall
                                    .copyWith(
                                      color: act.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.5,
                                    ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              act.timeAgo,
                              style: DashboardTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          act.title,
                          style: DashboardTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Timestamp Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? AppColors.darkCardBorder
                              : AppColors.canvasCreamSubtle)
                          .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: bodyColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatFullDate(act.timestamp),
                      style: DashboardTypography.captionSmall.copyWith(
                        color: bodyColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Description Box
              Text(
                context.tr('adminDashboard.activityDetails'),
                style: DashboardTypography.captionSmall.copyWith(
                  color: bodyColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkScaffold.withValues(alpha: 0.5)
                      : AppColors.canvasCream.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.canvasCreamSubtle,
                  ),
                ),
                child: Text(
                  act.description.isNotEmpty
                      ? act.description
                      : context.tr('adminDashboard.noActivityDetails'),
                  style: DashboardTypography.bodySmall.copyWith(
                    color: headingColor,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ),

              // Room Card info & navigation
              if (act.roomName != null || matchingRoom != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr('adminDashboard.relatedRoom'),
                  style: DashboardTypography.captionSmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          Icons.meeting_room_rounded,
                          size: 18,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.roomName ??
                                  matchingRoom?.name ??
                                  context.tr('adminDashboard.monitoringRooms'),
                              style: DashboardTypography.titleSmall.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            if (matchingRoom != null)
                              Text(
                                '${context.tr('adminDashboard.status')}: ${matchingRoom.isActive ? context.tr('adminDashboard.monitoredActive') : context.tr('adminDashboard.inactive')}',
                                style: DashboardTypography.captionSmall
                                    .copyWith(
                                      color: matchingRoom.isActive
                                          ? AppColors.statusSafe
                                          : bodyColor.withValues(alpha: 0.7),
                                      fontSize: 10.5,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      if (matchingRoom != null)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: isDark
                                ? AppColors.darkOnPrimary
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: Text(
                            context.tr('adminDashboard.openRoom'),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            controller.selectedRoom.value = matchingRoom;
                            controller.subscribeToRoomMembers(matchingRoom.id);
                            Get.toNamed(
                              AppRoutes.roomDetail,
                              arguments: matchingRoom,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],

              // User/Actor Card
              if (act.userName != null || act.role != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.darkCardBorder
                                : AppColors.canvasCreamSubtle)
                            .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: bodyColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${context.tr('adminDashboard.actor')} ',
                        style: DashboardTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${act.userName ?? 'User'} ${act.role != null ? "(${act.role})" : ""}',
                          style: DashboardTypography.captionSmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: headingColor,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.canvasCreamSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    context.tr('common.close'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Paginated activity list bottom sheet
  void _showAllActivitiesSheet(
    BuildContext context,
    AdminRoomController controller,
    bool isDark,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    HapticFeedback.lightImpact();
    String activeFilter = 'Semua';
    String searchQuery = '';

    // Load initial 10 activities on open
    controller.loadInitialActivities(filter: 'Semua');

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
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                // Attach auto-pagination scroll listener
                scrollController.addListener(() {
                  if (scrollController.hasClients &&
                      scrollController.position.pixels >=
                          scrollController.position.maxScrollExtent - 120) {
                    if (controller.hasMoreActivities.value &&
                        !controller.isActivitiesPageLoadingMore.value) {
                      controller.loadMoreActivities();
                    }
                  }
                });

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

                      // Sheet Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  'adminDashboard.fullActivityHistory',
                                ),
                                style: DashboardTypography.titleMedium.copyWith(
                                  color: headingColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Obx(
                                () => Text(
                                  context.tr(
                                    'adminDashboard.activitiesLoaded',
                                    {
                                      'count':
                                          controller.paginatedActivities.length,
                                    },
                                  ),
                                  style: DashboardTypography.captionSmall
                                      .copyWith(
                                        color: bodyColor.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
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

                      // Search Box
                      Container(
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.darkCardBorder
                                      : AppColors.canvasCreamSubtle)
                                  .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : AppColors.canvasCreamSubtle,
                          ),
                        ),
                        child: TextField(
                          style: TextStyle(color: headingColor, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: context.tr(
                              'room.searchActivityOrPilgrim',
                            ),
                            hintStyle: TextStyle(
                              color: bodyColor.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: bodyColor.withValues(alpha: 0.7),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildModalFilterChip(
                              context.tr('adminDashboard.all'),
                              activeFilter == 'Semua',
                              primaryColor,
                              headingColor,
                              isDark,
                              () {
                                setModalState(() => activeFilter = 'Semua');
                                controller.loadInitialActivities(
                                  filter: 'Semua',
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildModalFilterChip(
                              context.tr('adminDashboard.emergencyFilter'),
                              activeFilter == 'Darurat',
                              AppColors.sosEmergency,
                              headingColor,
                              isDark,
                              () {
                                setModalState(() => activeFilter = 'Darurat');
                                controller.loadInitialActivities(
                                  filter: 'Darurat',
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildModalFilterChip(
                              context.tr('adminDashboard.monitoringRooms'),
                              activeFilter == 'Kamar',
                              primaryColor,
                              headingColor,
                              isDark,
                              () {
                                setModalState(() => activeFilter = 'Kamar');
                                controller.loadInitialActivities(
                                  filter: 'Kamar',
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildModalFilterChip(
                              context.tr('adminDashboard.members'),
                              activeFilter == 'Anggota',
                              AppColors.statusSafe,
                              headingColor,
                              isDark,
                              () {
                                setModalState(() => activeFilter = 'Anggota');
                                controller.loadInitialActivities(
                                  filter: 'Anggota',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Paginated Activities List
                      Expanded(
                        child: Obx(() {
                          if (controller.isActivitiesPageLoading.value &&
                              controller.paginatedActivities.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 2.5,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    context.tr('adminDashboard.loadingHistory'),
                                    style: DashboardTypography.captionSmall
                                        .copyWith(color: bodyColor),
                                  ),
                                ],
                              ),
                            );
                          }

                          final activities = controller.paginatedActivities;
                          final filtered = activities.where((a) {
                            if (searchQuery.trim().isNotEmpty) {
                              final q = searchQuery.toLowerCase().trim();
                              final matchTitle = a.title.toLowerCase().contains(
                                q,
                              );
                              final matchDesc = a.description
                                  .toLowerCase()
                                  .contains(q);
                              final matchRoom =
                                  a.roomName?.toLowerCase().contains(q) ??
                                  false;
                              final matchUser =
                                  a.userName?.toLowerCase().contains(q) ??
                                  false;
                              if (!matchTitle &&
                                  !matchDesc &&
                                  !matchRoom &&
                                  !matchUser) {
                                return false;
                              }
                            }
                            return true;
                          }).toList();

                          if (filtered.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 44,
                                    color: bodyColor.withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    context.tr(
                                      'adminDashboard.noFilteredActivity',
                                    ),
                                    style: DashboardTypography.titleSmall
                                        .copyWith(
                                          color: headingColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr(
                                      'adminDashboard.noActivityFilterDesc',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: DashboardTypography.captionSmall
                                        .copyWith(color: bodyColor),
                                  ),
                                ],
                              ),
                            );
                          }

                          // List items count + 1 for footer / load more
                          final hasMore = controller.hasMoreActivities.value;
                          final isLoadingMore =
                              controller.isActivitiesPageLoadingMore.value;
                          final totalItems = filtered.length + 1;

                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xl,
                            ),
                            itemCount: totalItems,
                            separatorBuilder: (context, index) {
                              if (index >= filtered.length - 1) {
                                return const SizedBox(height: AppSpacing.sm);
                              }
                              return Divider(
                                height: 1,
                                thickness: 0.8,
                                indent: 58,
                                endIndent: AppSpacing.md,
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.canvasCreamSubtle,
                              );
                            },
                            itemBuilder: (context, idx) {
                              // Footer element
                              if (idx == filtered.length) {
                                if (isLoadingMore) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            context.tr(
                                              'adminDashboard.loadingHistory',
                                            ),
                                            style: DashboardTypography
                                                .captionSmall
                                                .copyWith(color: bodyColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                if (hasMore) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Center(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: primaryColor,
                                          side: BorderSide(
                                            color: primaryColor.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.pill,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.expand_more_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          context.tr('adminDashboard.loadMore'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () =>
                                            controller.loadMoreActivities(),
                                      ),
                                    ),
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      context.tr(
                                        'adminDashboard.allHistoryShown',
                                      ),
                                      style: DashboardTypography.captionSmall
                                          .copyWith(
                                            color: bodyColor.withValues(
                                              alpha: 0.5,
                                            ),
                                            fontSize: 11,
                                          ),
                                    ),
                                  ),
                                );
                              }

                              final act = filtered[idx];
                              return _ActivityFeedTile(
                                activity: act,
                                headingColor: headingColor,
                                bodyColor: bodyColor,
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _showActivityDetailSheet(
                                    context,
                                    act,
                                    controller,
                                    isDark,
                                    headingColor,
                                    bodyColor,
                                    primaryColor,
                                  );
                                },
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildModalFilterChip(
    String label,
    bool isSelected,
    Color activeColor,
    Color headingColor,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark
                        ? AppColors.darkCardBorder
                        : AppColors.canvasCreamSubtle)
                    .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark
                      ? AppColors.darkCardBorder
                      : AppColors.canvasCreamSubtle),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: DashboardTypography.captionSmall.copyWith(
            color: isSelected
                ? activeColor
                : headingColor.withValues(alpha: 0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  static String _activityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.roomCreated:
        return AppTranslations.tr('adminDashboard.activityRoomCreated');
      case ActivityType.roomActivated:
        return AppTranslations.tr('adminDashboard.activityRoomActivated');
      case ActivityType.roomDeactivated:
        return AppTranslations.tr('adminDashboard.activityRoomDeactivated');
      case ActivityType.roomUpdated:
        return AppTranslations.tr('adminDashboard.activityRoomUpdated');
      case ActivityType.memberJoined:
        return AppTranslations.tr('adminDashboard.activityMemberJoined');
      case ActivityType.memberLeft:
        return AppTranslations.tr('adminDashboard.activityMemberLeft');
      case ActivityType.sosActive:
        return AppTranslations.tr('adminDashboard.activitySos');
      case ActivityType.unknown:
        return AppTranslations.tr('adminDashboard.activityOperational');
    }
  }

  static String _formatFullDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = AppTranslations.tr('adminDashboard.shortMonth${dt.month}');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WIB';
  }

  // Create-room bottom sheet
}
