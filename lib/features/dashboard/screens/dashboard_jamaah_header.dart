part of 'dashboard_jamaah_screen.dart';

extension _DashboardJamaahHeader on DashboardJamaahScreen {
  Widget _buildHeroSection({
    required BuildContext context,
    required JamaahData jamaah,
    required HajiCareController state,
    required DashboardController dashboardCtrl,
    required PrayerTimesController prayerCtrl,
    required bool isDark,
  }) {
    final topInset = MediaQuery.paddingOf(context).top;

    // Formatting Firebase Data
    final displayName = jamaah.name.trim().isNotEmpty
        ? jamaah.name.trim()
        : (jamaah.shortLabel.isNotEmpty
              ? jamaah.shortLabel
              : context.tr('dashboard.pilgrimFallback'));
    final initialLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'J';

    // Money Recognition shortcut (replaces Nomor Porsi — not available in Firebase)

    // Distance formatting (Promoted to Hero Display)
    final hasRoom =
        (state.activeRoomId.value != null &&
            state.activeRoomId.value!.trim().isNotEmpty) ||
        (jamaah.activeRoomId != null && jamaah.activeRoomId!.trim().isNotEmpty);

    final realDistance =
        state.calculatedDistance.value ?? (hasRoom ? jamaah.distance : 0.0);

    final distanceDisplay = (hasRoom && realDistance > 0)
        ? (realDistance < 1000
              ? '${realDistance.round()} m'
              : '${(realDistance / 1000).toStringAsFixed(1)} km')
        : '—';

    // Next prayer time display with timezone suffix stripped to avoid overflow
    final prayerName = prayerCtrl.nextPrayerName.value.isNotEmpty
        ? prayerCtrl.nextPrayerName.value
        : context.tr('ashar');
    final rawPrayerTime = prayerCtrl.nextPrayerTime.value.isNotEmpty
        ? prayerCtrl.nextPrayerTime.value
        : '15:20';
    final cleanPrayerTime = rawPrayerTime.split(' ').first;

    // Location / GPS status
    final gpsDisplay = jamaah.isGpsActive
        ? context.tr('dashboard.gpsActive')
        : context.tr('dashboard.gpsConnected');

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Bar: User Greeting & Notification / SOS ───────
          Row(
            children: [
              // User Avatar
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
                    colors: [Color(0xFFD4A857), Color(0xFFA67C52)],
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
                      color: Color(0xFF2E1C12),
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
                      context.tr('dashboard.groupIdentity', {
                        'kloter': jamaah.kloter ?? '12',
                        'maktab': jamaah.maktab ?? '48',
                      }),
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification Bell with Glowing Badge
              _buildNotificationButton(context, state, isDark),
            ],
          ),

          const SizedBox(height: 26),

          // ── Big Hero Identification (Jarak Petugas) ──────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      distanceDisplay,
                      style: const TextStyle(
                        color: Colors.white,
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
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        hasRoom
                            ? context.tr('dashboard.officerDistance')
                            : context.tr('dashboard.notConnectedToRoom'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sync / Refresh Location Circular Button with spinning animation
              // Distance-reactive sparkline wave (replaces static sync button)
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
          ),

          const SizedBox(height: 18),

          // ── Subtle Dotted / Dashed Divider ───────────────────────
          _buildDashedLine(Colors.white.withValues(alpha: 0.20)),

          const SizedBox(height: 16),

          // ── 3 Key Metrics Columns ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMoneyRecognitionMetric(context),
              _buildMetricColumn(
                value: '$prayerName $cleanPrayerTime',
                label: context.tr('dashboard.prayerSchedule'),
              ),
              _buildMetricColumn(
                value: gpsDisplay,
                label: context.tr('dashboard.locationStatus'),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ── Segmented Dual-Action Pill Button ────────────────────
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
                // Left Pill: Lacak Petugas (Map)
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
                          children: [
                            const Icon(
                              Icons.north_west_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              context.tr('dashboard.trackOfficer'),
                              style: const TextStyle(
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

                // Dashed vertical separator
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.25),
                ),

                // Right Pill: Bantuan Darurat (SOS)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(26),
                      ),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Get.toNamed(AppRoutes.modalSos);
                      },
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('dashboard.emergencyHelp'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Icon(
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

  // ── Notification Button with Badge Indicator ──────────────────────────────
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
          final totalUnread = notifCtrl != null
              ? notifCtrl.unreadCount.value +
                    notifCtrl.pendingInvitations.length
              : 0;
          final hasSeparated = state.self.separatedMode;

          if (totalUnread <= 0 && !hasSeparated) return const SizedBox.shrink();

          return Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: hasSeparated
                    ? AppColors.sosEmergency
                    : const Color(0xFF00E5FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2E1C12), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color:
                        (hasSeparated
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

  // ── Money Recognition Metric (Camera Shortcut) ───────────────────────────
  Widget _buildMoneyRecognitionMetric(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(AppRoutes.moneyRecognition);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon chip — same height as the value text (fontSize 16 ≈ 20px)
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
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.goldLight,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('dashboard.scanRiyal'),
                    style: const TextStyle(
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
              context.tr('dashboard.recognizeMoney'),
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

  // ── Metric Item Column Helper ─────────────────────────────────────────────
  Widget _buildMetricColumn({required String value, required String label}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
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

  // ── Curved White/Cream Canvas Sheet ───────────────────────────────────────
}
