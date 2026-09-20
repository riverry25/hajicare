part of 'admin_dashboard_screen.dart';

extension _AdminDashboardMetrics on _AdminDashboardHome {
  Widget _buildHeroProgressCard(BuildContext context, bool isDark) {
    final activeSos = controller.activeSosCount.value;
    final totalJamaah = controller.totalJamaah.value;
    final activeRooms = controller.activeRoomsCount;
    final hasSos = activeSos > 0;

    final safePercentage = totalJamaah > 0
        ? (((totalJamaah - activeSos) / totalJamaah) * 100)
              .clamp(0, 100)
              .round()
        : 100;

    // Signature HajiCare Hero Gradient (matches dashboard_jamaah_screen)
    final heroGradient = LinearGradient(
      colors: isDark
          ? const [Color(0xFF1B120B), Color(0xFF281A11), Color(0xFF332115)]
          : const [Color(0xFF26170E), Color(0xFF382317), Color(0xFF4A3020)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.primaryGold.withValues(alpha: 0.35);
    final textColor = isDark ? AppColors.darkTextHeading : Colors.white;
    final subtextColor = isDark ? AppColors.goldLight : const Color(0xFFF5D6B8);
    final gaugeProgress = activeRooms > 0
        ? (activeRooms / math.max(activeRooms, 10)).clamp(0.15, 1.0)
        : 0.25;

    return Container(
      decoration: BoxDecoration(
        gradient: heroGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Pill Status + Live Sync
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasSos
                            ? Icons.warning_amber_rounded
                            : Icons.shield_rounded,
                        size: 14,
                        color: hasSos
                            ? AppColors.sosEmergency
                            : (isDark
                                  ? AppColors.goldLight
                                  : AppColors.primaryGold),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasSos
                            ? '$activeSos SOS PERLU TINDAKAN'
                            : 'Command Center Aman',
                        style: AppTypography.captionSmall.copyWith(
                          color: hasSos
                              ? const Color(0xFFFF8080)
                              : (isDark
                                    ? AppColors.goldLight
                                    : const Color(0xFFFBF4ED)),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.statusSafe,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live Sync',
                      style: AppTypography.captionSmall.copyWith(
                        color: subtextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md + 4),

            // Middle: Left (Big % + Date Pill) & Right (Circular Arc Gauge)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$safePercentage%',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: textColor,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                            style: AppTypography.captionSmall.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: subtextColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Circular Gauge
                InkWell(
                  onTap: () => _showActiveRoomsSheet(
                    context,
                    controller,
                    isDark,
                    isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                    isDark ? AppColors.darkTextHeading : AppColors.espressoDark,
                    isDark ? AppColors.darkTextBody : AppColors.textBody,
                    isDark ? AppColors.darkPrimary : AppColors.primaryGold,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  child: CustomPaint(
                    size: const Size(92, 92),
                    painter: _HeroGaugePainter(
                      progress: gaugeProgress,
                      trackColor: Colors.white.withValues(alpha: 0.14),
                      progressColor: isDark
                          ? AppColors.goldLight
                          : AppColors.primaryGold,
                      dotColor: isDark ? Colors.white : AppColors.goldLight,
                    ),
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$activeRooms',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'Room Aktif',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. Primary KPI metrics

  // 3. Operational status and metric breakdown
  // ── 3. Operational Status Cards (Reference: 4-Card Staggered Bento Grid) ──
  Widget _buildStatusBreakdownCard(
    BuildContext context,
    bool isDark,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    final activeRooms = controller.activeRoomsCount;
    final totalJamaah = controller.totalJamaah.value;
    final totalPendamping = controller.totalPendamping.value;
    final activeSos = controller.activeSosCount.value;
    final hasSos = activeSos > 0;

    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceWhite;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header: Section Title + SOS Warning + Create Room Action (+)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainerHigh
                        : AppColors.canvasCreamSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.dashboard_customize_rounded,
                    size: 16,
                    color: headingColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status & Koordinasi',
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      hasSos
                          ? '$activeSos SOS Memerlukan Tindakan Segera'
                          : 'Kondisi Seluruh Room Aman & Normal',
                      style: AppTypography.captionSmall.copyWith(
                        color: hasSos
                            ? AppColors.sosEmergency
                            : bodyColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            InkWell(
              onTap: () => _showCreateRoomSheet(context, controller),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.surfaceWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.add_rounded, size: 20, color: headingColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 4 Staggered Bento Cards matching reference layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Jamaah (Tall) & Room (Short)
            Expanded(
              child: Column(
                children: [
                  _buildMetricBentoCard(
                    context: context,
                    title: 'Jamaah',
                    value: '$totalJamaah',
                    subtitle: 'Data Jamaah',
                    icon: Icons.groups_rounded,
                    height: 162,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    circleBg: isDark
                        ? AppColors.emeraldIslamic.withValues(alpha: 0.22)
                        : AppColors.emeraldLight,
                    iconColor: AppColors.emeraldIslamic,
                    accentColor: AppColors.emeraldIslamic,
                    onTap: () => _showAllJamaahSheet(
                      context,
                      controller,
                      isDark,
                      cardBg,
                      headingColor,
                      bodyColor,
                      primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricBentoCard(
                    context: context,
                    title: 'Room',
                    value: '$activeRooms',
                    subtitle: 'Room Aktif',
                    icon: Icons.meeting_room_rounded,
                    height: 126,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    circleBg: isDark
                        ? AppColors.darkSurfaceContainerHighest
                        : AppColors.canvasCreamSubtle,
                    iconColor: isDark
                        ? AppColors.goldLight
                        : AppColors.secondary,
                    accentColor: AppColors.secondary,
                    onTap: () => _showActiveRoomsSheet(
                      context,
                      controller,
                      isDark,
                      cardBg,
                      headingColor,
                      bodyColor,
                      primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right Column: Petugas (Short) & Pusat Alert / SOS (Tall)
            Expanded(
              child: Column(
                children: [
                  _buildMetricBentoCard(
                    context: context,
                    title: 'Petugas',
                    value: '$totalPendamping',
                    subtitle: 'Siaga Maktab',
                    icon: Icons.badge_rounded,
                    height: 126,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    circleBg: isDark
                        ? AppColors.tanMedium.withValues(alpha: 0.22)
                        : AppColors.secondaryContainer.withValues(alpha: 0.45),
                    iconColor: isDark
                        ? AppColors.tanLight
                        : AppColors.espressoDark,
                    accentColor: AppColors.tanMedium,
                    onTap: () => _showAllPendampingSheet(
                      context,
                      controller,
                      isDark,
                      cardBg,
                      headingColor,
                      bodyColor,
                      primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricBentoCard(
                    context: context,
                    title: 'Pusat Alert',
                    value: '$activeSos',
                    subtitle: hasSos ? '$activeSos Perlu Aksi' : 'Kondisi Aman',
                    icon: hasSos
                        ? Icons.warning_amber_rounded
                        : Icons.health_and_safety_rounded,
                    height: 162,
                    isDark: isDark,
                    cardBg: hasSos
                        ? (isDark
                              ? const Color(0xFF381418)
                              : AppColors.errorContainer.withValues(
                                  alpha: 0.35,
                                ))
                        : cardBg,
                    borderColor: hasSos
                        ? AppColors.sosEmergency.withValues(alpha: 0.5)
                        : borderColor,
                    headingColor: hasSos
                        ? AppColors.sosEmergency
                        : headingColor,
                    bodyColor: hasSos ? AppColors.sosEmergency : bodyColor,
                    circleBg: hasSos
                        ? AppColors.sosEmergency.withValues(alpha: 0.2)
                        : (isDark
                              ? AppColors.statusSafe.withValues(alpha: 0.15)
                              : AppColors.emeraldLight),
                    iconColor: hasSos
                        ? AppColors.sosEmergency
                        : AppColors.statusSafe,
                    accentColor: hasSos
                        ? AppColors.sosEmergency
                        : AppColors.statusSafe,
                    isAlert: hasSos,
                    onTap: () => _showAlertCenterSheet(
                      context,
                      controller,
                      dashboardCtrl,
                      isDark,
                      cardBg,
                      headingColor,
                      bodyColor,
                      primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricBentoCard({
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
    bool isAlert = false,
  }) {
    final isTall = height > 135;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: isAlert ? 1.4 : 1.0),
        boxShadow: [
          BoxShadow(
            color:
                (isAlert
                        ? AppColors.sosEmergency
                        : (isDark ? Colors.black : AppColors.espressoDark))
                    .withValues(alpha: isDark ? 0.28 : (isAlert ? 0.12 : 0.04)),
            blurRadius: isAlert ? 12 : 10,
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
          splashColor: (isAlert ? AppColors.sosEmergency : accentColor)
              .withValues(alpha: 0.12),
          highlightColor: (isAlert ? AppColors.sosEmergency : accentColor)
              .withValues(alpha: 0.06),
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
                // Circular Icon (Reference: circle icon badge)
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

                // Metric Number / Count
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTall ? 22 : 18,
                    fontWeight: FontWeight.w900,
                    color: isAlert ? AppColors.sosEmergency : headingColor,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1.5),

                // Title Label
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.captionSmall.copyWith(
                    color: isAlert ? AppColors.sosEmergency : headingColor,
                    fontWeight: FontWeight.w800,
                    fontSize: isTall ? 12.5 : 11.0,
                  ),
                ),

                // Subtitle / Pill Badge
                if (isTall) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: (isAlert ? AppColors.sosEmergency : accentColor)
                          .withValues(alpha: isDark ? 0.18 : 0.08),
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
                            style: AppTypography.captionSmall.copyWith(
                              color: isAlert
                                  ? AppColors.sosEmergency
                                  : accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 7.5,
                          color: isAlert ? AppColors.sosEmergency : accentColor,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 1.5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.captionSmall.copyWith(
                      color: bodyColor.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
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

  // 4. Quick actions
}
