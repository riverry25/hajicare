part of 'dashboard_jamaah_screen.dart';


/// Extracted StatelessWidget with cached element tree and granular Obx bindings.
/// Isolates sensor, location, and prayer tick updates from rebuilding the full page.
class DashboardJamaahHeroSection extends StatelessWidget {
  final HajiCareController state;
  final DashboardController dashboardCtrl;
  final PrayerTimesController prayerCtrl;
  final bool isDark;

  const DashboardJamaahHeroSection({
    super.key,
    required this.state,
    required this.dashboardCtrl,
    required this.prayerCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroFg = context.hc.dashboardHeroOnSurface;
    final heroAccent = context.hc.dashboardHeroAccent;

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar: User Greeting & Notification / SOS
          Row(
            children: [
              // User Avatar & Greeting (Granular Obx)
              Expanded(
                child: Obx(() {
                  // Rule 1: Always evaluate true Rx observables at line 1
                  final _ = state.jamaahList.length;
                  final _ = state.activeRoomId.value;
                  final jamaah = state.self;
                  final displayName = jamaah.name.trim().isNotEmpty
                      ? jamaah.name.trim()
                      : (jamaah.shortLabel.isNotEmpty
                            ? jamaah.shortLabel
                            : context.tr('dashboard.pilgrimFallback'));
                  final initialLetter = displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : 'J';

                  return Row(
                    children: [
                      // User Avatar (Glassmorphic)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.85),
                            width: 1.2,
                          ),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.white.withValues(alpha: 0.65),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.05,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initialLetter,
                            style: TextStyle(
                              color: heroAccent,
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
                              context.tr('dashboard.greeting'),
                              style: TextStyle(
                                color: heroFg.withValues(alpha: 0.72),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              displayName,
                              style: TextStyle(
                                color: heroFg,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('dashboard.groupIdentity', {
                                'kloter': jamaah.kloter ?? '12',
                                'maktab': jamaah.maktab ?? '48',
                              }),
                              style: TextStyle(
                                color: heroAccent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),

              // Notification Bell with Glowing Badge
              _buildNotificationButton(context, state, isDark),
            ],
          ),

          const SizedBox(height: 26),

          // Big Hero Identification (Jarak Petugas) - Granular Obx
          Obx(() {
            // Rule 1: Evaluate .obs at top line before any conditionals
            final calculatedDist = state.calculatedDistance.value;
            final activeRoomId = state.activeRoomId.value;
            final activeRoom = state.activeRoom.value;
            final jamaah = state.self;
            final nearest = state.nearestPendamping.value;

            final hasRoom =
                (activeRoomId != null && activeRoomId.trim().isNotEmpty) ||
                (jamaah.activeRoomId != null &&
                    jamaah.activeRoomId!.trim().isNotEmpty) ||
                activeRoom != null;

            final realDistance =
                calculatedDist ?? (hasRoom ? jamaah.distance : 0.0);

            final distanceDisplay = (hasRoom && realDistance > 0)
                ? (realDistance < 1000
                      ? '${realDistance.round()} m'
                      : '${(realDistance / 1000).toStringAsFixed(1)} km')
                : '—';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        distanceDisplay,
                        style: TextStyle(
                          color: heroFg,
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
                          color: heroFg.withValues(alpha: isDark ? 0.10 : 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: heroFg.withValues(alpha: 0.20),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          hasRoom
                              ? (nearest != null
                                    ? '${context.tr('room.nearestCompanion')}: ${nearest.name}'
                                    : context.tr('dashboard.officerDistance'))
                              : context.tr('dashboard.notConnectedToRoom'),
                          style: TextStyle(
                            color: heroFg,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Distance-reactive sparkline wave
                DistanceSparklineWidget(
                  distance: hasRoom ? realDistance : 0.0,
                  tooltip: hasRoom
                      ? context.tr('dashboard.refreshGps')
                      : context.tr('dashboard.notConnectedToRoom'),
                  onSync: () async {
                    await state.refreshLocation();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr('dashboard.locationRefreshed'),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          }),

          const SizedBox(height: 18),

          // Subtle Dotted / Dashed Divider (Static Widget)
          _DashboardDashedDivider(color: heroFg.withValues(alpha: 0.22)),

          const SizedBox(height: 16),

          // 3 Key Metrics Columns
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Prayer Schedule Metric
              Expanded(
                child: Obx(() {
                  // Rule 1: Evaluate .obs at top line before any conditionals
                  final rawPrayerName = prayerCtrl.nextPrayerName.value;
                  final rawPrayerTime = prayerCtrl.nextPrayerTime.value;

                  final prayerName = rawPrayerName.isNotEmpty
                    ? context.localizedPrayerName(rawPrayerName)
                    : context.tr('ashar');
                  final cleanPrayerTime = rawPrayerTime.isNotEmpty
                      ? rawPrayerTime.split(' ').first
                      : '15:20';

                  return _buildMetricColumn(
                    context: context,
                    value: '$prayerName $cleanPrayerTime',
                    label: context.tr('dashboard.prayerSchedule'),
                  );
                }),
              ),

              // Location / GPS Status Metric
              Expanded(
                child: Obx(() {
                  // Rule 1: Evaluate .obs at top line before any conditionals
                  final isGps = state.isMyGpsActive.value;
                  final gpsDisplay = isGps
                      ? context.tr('dashboard.gpsActive')
                      : context.tr('dashboard.gpsConnected');

                  return _buildMetricColumn(
                    context: context,
                    value: gpsDisplay,
                    label: context.tr('dashboard.locationStatus'),
                  );
                }),
              ),

              // Money Recognition Metric (Static)
              _buildMoneyRecognitionMetric(context),
            ],
          ),

          const SizedBox(height: 22),

          // Segmented Dual-Action Pill Button (Frosted Glassmorphism)
          _DashboardDualActionPill(
            state: state,
            dashboardCtrl: dashboardCtrl,
            isDark: isDark,
            heroFg: heroFg,
          ),
        ],
      ),
    );
  }

  // Notification Button with Badge Indicator
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
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.85),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: IconButton(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.notifications_outlined,
                color: context.hc.dashboardHeroOnSurface,
                size: 22,
              ),
              tooltip: context.tr('notificationTooltip'),
              onPressed: () => Get.toNamed(AppRoutes.notification),
            ),
          ),
        ),
        Obx(() {
          // Rule 1: Always evaluate an .obs at top line before any conditionals
          final _ = state.activeSosCount.value;
          final notifCtrl = Get.isRegistered<NotificationController>()
              ? Get.find<NotificationController>()
              : null;
          final totalUnread = notifCtrl != null
              ? notifCtrl.unreadCount.value +
                    notifCtrl.pendingInvitations.length
              : 0;

          if (totalUnread <= 0) return const SizedBox.shrink();

          return Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: context.hc.danger,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1E1510) : Colors.white,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.hc.danger.withValues(alpha: 0.55),
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

  // Money Recognition Metric (Scanner Icon Shortcut)
  Widget _buildMoneyRecognitionMetric(BuildContext context) {
    final colors = context.hc;
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Get.toNamed(AppRoutes.moneyRecognition);
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: colors.accent.withValues(alpha: 0.15),
          highlightColor: colors.accent.withValues(alpha: 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.isDark
                      ? colors.surfaceSand
                      : Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: colors.accentText,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr('dashboard.scanRiyal'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Metric Item Column Helper
  Widget _buildMetricColumn({
    required BuildContext context,
    required String value,
    required String label,
  }) {
    final colors = context.hc;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
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
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
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

/// Static dashed divider widget for dashboard metrics
class _DashboardDashedDivider extends StatelessWidget {
  final Color color;

  const _DashboardDashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
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
}

/// Frosted glassmorphism dual-action pill button (Lacak Pendamping & Bantuan SOS)
class _DashboardDualActionPill extends StatelessWidget {
  final HajiCareController state;
  final DashboardController dashboardCtrl;
  final bool isDark;
  final Color heroFg;

  const _DashboardDualActionPill({
    required this.state,
    required this.dashboardCtrl,
    required this.isDark,
    required this.heroFg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.88),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Pill: Lacak Pendamping (Map)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(26),
                ),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final mapCtrl = MapController.to;

                  final companion = await mapCtrl.focusOnCompanion();
                  if (companion == null) {
                    if (context.mounted) {
                      AppAlert.info(
                        context,
                        title: context.tr('dashboard.companionNotConnected'),
                        message: context.tr(
                          'dashboard.companionNotConnectedDesc',
                        ),
                      );
                    }
                    return;
                  }

                  dashboardCtrl.changeTab(1);

                  if (!companion.hasLocation && context.mounted) {
                    AppAlert.warning(
                      context,
                      title: context.tr('dashboard.locationUnavailable'),
                      message: context.tr(
                        'dashboard.companionGpsUnavailableDesc',
                        {'name': companion.name},
                      ),
                    );
                  }
                },
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.north_west_rounded,
                        color: heroFg,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        context.tr('dashboard.trackOfficer'),
                        style: TextStyle(
                          color: heroFg,
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
          Container(width: 1, height: 24, color: context.hc.border),

          // Right Pill: Bantuan Darurat (SOS)
          Expanded(
            child: Obx(() {
              // Rule 1: Evaluate .obs at top line before any conditionals
              final activeRoomId = state.activeRoomId.value;
              final activeRoom = state.activeRoom.value;
              final activeSosCount = state.activeSosCount.value;

              final hasRoom =
                  (activeRoomId?.trim().isNotEmpty ?? false) ||
                  activeRoom != null;
              final hasSos =
                  hasRoom && (activeSosCount > 0 || state.anySosActive);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(26),
                  ),
                  onTap: () {
                    HapticFeedback.mediumImpact();
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
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: hasSos
                          ? LinearGradient(
                              colors: [
                                context.hc.danger,
                                context.hc.dangerContainer,
                              ],
                            )
                          : null,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(26),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasSos) ...[
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            hasSos
                                ? (activeSosCount > 0
                                      ? 'SOS ($activeSosCount)'
                                      : context.tr('dashboard.sosActiveUpper'))
                                : context.tr('dashboard.emergencyHelp'),
                            style: TextStyle(
                              color: hasSos
                                  ? Colors.white
                                  : context.hc.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Icon(
                            hasSos
                                ? Icons.arrow_forward_rounded
                                : Icons.north_east_rounded,
                            color: hasSos
                                ? Colors.white
                                : context.hc.textPrimary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
