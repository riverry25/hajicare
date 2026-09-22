part of 'dashboard_jamaah_screen.dart';

extension _DashboardJamaahSections on DashboardJamaahScreen {
  Widget _buildCurvedBody({
    required BuildContext context,
    required JamaahData jamaah,
    required HajiCareController state,
    required DashboardController dashboardCtrl,
    required bool isDark,
    required Color headingColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkScaffold : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Service Categories (Row of 5 Horizontal Items) ─
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCategoryItem(
                    context: context,
                    label: context.tr('dashboard.quickComm'),
                    icon: Icons.record_voice_over_rounded,
                    bgColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    iconColor: isDark
                        ? AppColors.goldLight
                        : AppColors.espressoDark,
                    onTap: () => CommunicationGestureDialog.show(context),
                  ),
                ),
                Expanded(
                  child: _buildCategoryItem(
                    context: context,
                    label: context.tr('dashboard.smartband'),
                    icon: Icons.watch_rounded,
                    bgColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    iconColor: isDark
                        ? AppColors.goldLight
                        : AppColors.espressoDark,
                    onTap: () => _showSmartBandDialog(context),
                  ),
                ),
                Expanded(
                  child: _buildCategoryItem(
                    context: context,
                    label: context.tr('dashboard.medicalPost'),
                    icon: Icons.local_hospital_rounded,
                    bgColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    iconColor: isDark
                        ? AppColors.goldLight
                        : AppColors.espressoDark,
                    onTap: () => _showMedicalSheet(context),
                  ),
                ),
                Expanded(
                  child: _buildCategoryItem(
                    context: context,
                    label: context.tr('dashboard.moneyDetection'),
                    icon: Icons.payments_rounded,
                    bgColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    iconColor: isDark
                        ? AppColors.goldLight
                        : AppColors.espressoDark,
                    onTap: () => Get.toNamed(AppRoutes.moneyRecognition),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Bento Grid: Layanan & Fitur Utama Jamaah ─────────────
          _buildJamaahBentoSection(
            context: context,
            state: state,
            jamaah: jamaah,
            isDark: isDark,
            headingColor: headingColor,
          ),

          const SizedBox(height: 24),

          // ── Section 1: "Status & Peringatan" ("Bot Alert") ────────
          _buildSectionHeader(
            title: context.tr('dashboard.statusAndAlert'),
            subtitle: context.tr('dashboard.gpsMonitoringSub'),
            actionText: context.tr('dashboard.viewMap'),
            onAction: () => dashboardCtrl.changeTab(1),
            headingColor: headingColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildStatusAlertCard(context, jamaah, isDark, dashboardCtrl),

          const SizedBox(height: 26),

          // ── Section 2: "Kamar & Maktab" ───────────────────────────
          _buildSectionHeader(
            title: context.tr('dashboard.roomAndMaktab'),
            subtitle: context.tr('dashboard.hotelRoomSub'),
            actionText: context.tr('dashboard.manage'),
            onAction: () {
              if (state.activeRoomId.value != null) {
                Get.toNamed(
                  AppRoutes.roomDetail,
                  arguments: state.activeRoom.value,
                );
              } else {
                Get.toNamed(AppRoutes.joinRoom);
              }
            },
            headingColor: headingColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          const ActiveRoomCard(isPendamping: false),

          const SizedBox(height: 26),

          // ── Section 3: "Tips & Panduan Ibadah" ("News and Updates")
          _buildSectionHeader(
            title: context.tr('dashboard.worshipTips'),
            subtitle: context.tr('dashboard.worshipTipsSub'),
            actionText: context.tr('dashboard.viewAll'),
            onAction: () => Get.toNamed(AppRoutes.hajjDua),
            headingColor: headingColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildNewsUpdatesCard(context, isDark, headingColor),
        ],
      ),
    );
  }

  // ── Quick Category Item (Squircle Icon with Label) ────────────────────────
  Widget _buildCategoryItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final textHeading = AppColors.textHeadingColor(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                      : AppColors.canvasCreamSubtle,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : AppColors.espressoDark.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 24)),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(minHeight: 32),
              alignment: Alignment.topCenter,
              child: Text(
                label,
                style: TextStyle(
                  color: textHeading,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header (Title + Subtitle + Action) ─────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
    required Color headingColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: headingColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTypography.captionSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextBody.withValues(alpha: 0.8)
                        : AppColors.textMuted,
                    height: 1.3,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                actionText,
                style: TextStyle(
                  color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Alert Card (Bot Alert Pattern) ─────────────────────────────────
  Widget _buildStatusAlertCard(
    BuildContext context,
    JamaahData jamaah,
    bool isDark,
    DashboardController dashboardCtrl,
  ) {
    if (jamaah.separatedMode) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E1517) : const Color(0xFFFFECEF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.sosEmergency.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.sosEmergency.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.sosEmergency,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('dashboard.separationWarning'),
                    style: const TextStyle(
                      color: AppColors.sosEmergency,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr('dashboard.separationWarningDesc'),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF7A1C24),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Normal safe connection state
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceWhite;
    final headingColor = AppColors.textHeadingColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B633E), Color(0xFF2E8540)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B633E).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('dashboard.connectedSafe'),
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr('dashboard.connectedSafeDesc'),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── News & Updates Card (Horizontal Style) ────────────────────────────────
  Widget _buildNewsUpdatesCard(
    BuildContext context,
    bool isDark,
    Color headingColor,
  ) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceWhite;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A857), Color(0xFFA67C52)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.wb_sunny_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('dashboard.hotWeatherTip'),
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('dashboard.hotWeatherTipDesc'),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dashed Line Painter Helper ────────────────────────────────────────────
  Widget _buildDashedLine(Color color) {
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

  // ── Bento Grid: Layanan & Fitur Utama Jamaah ──────────────────────────────
  Widget _buildJamaahBentoSection({
    required BuildContext context,
    required HajiCareController state,
    required JamaahData jamaah,
    required bool isDark,
    required Color headingColor,
  }) {
    final cardBg = AppColors.cardBgColor(context);
    final borderColor = AppColors.cardBorderColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (Matching Reference Aesthetic)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('dashboard.servicesAndGuides'),
                      style: DashboardTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),

                    Text(
                      context.tr('dashboard.servicesAndGuidesSub'),
                      style: DashboardTypography.captionSmall.copyWith(
                        color: bodyColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 4 Staggered Bento Cards matching reference layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: BISINDO (Tall: 162) & Panduan Doa (Short: 126)
            Expanded(
              child: Column(
                children: [
                  _buildBentoFeatureCard(
                    context: context,
                    title: context.tr('dashboard.signLanguage'),
                    value: 'BISINDO',
                    subtitle: context.tr('dashboard.openCamera'),
                    icon: Icons.sign_language_rounded,
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
                    onTap: () => Get.toNamed(AppRoutes.bisindo),
                  ),
                  const SizedBox(height: 12),
                  _buildBentoFeatureCard(
                    context: context,
                    title: context.tr('dashboard.prayerGuide'),
                    value: context.tr('hajjDuaDashboardCardValue'),
                    subtitle: context.tr('dashboard.prayerAndDhikr'),
                    icon: Icons.menu_book_rounded,
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
                    onTap: () => Get.toNamed(AppRoutes.hajjDua),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right Column: Guide Haji & pusat komunikasi pendamping
            Expanded(
              child: Column(
                children: [
                  _buildBentoFeatureCard(
                    context: context,
                    title: context.tr('dashboard.scheduleAndPillars'),
                    value: context.tr('dashboard.hajjGuide'),
                    subtitle: context.tr('dashboard.viewSeries'),
                    icon: Icons.event_note_rounded,
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
                    onTap: () => _showHajiScheduleGuideSheet(context),
                  ),
                  const SizedBox(height: 12),
                  _buildBentoFeatureCard(
                    context: context,
                    title: context.tr('dashboard.companion'),
                    value: context.tr('dashboard.contactCompanion'),
                    subtitle: context.tr('dashboard.messageAndLocation'),
                    icon: Icons.support_agent_rounded,
                    height: 162,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    circleBg: isDark
                        ? const Color(0xFF3E2723)
                        : const Color(0xFFFBE9E7),
                    iconColor: const Color(0xFFE64A19),
                    accentColor: const Color(0xFFD84315),
                    onTap: () => _showCompanionContactDialog(context, state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoFeatureCard({
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
  }) {
    final isTall = height > 135;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.espressoDark).withValues(
              alpha: isDark ? 0.28 : 0.04,
            ),
            blurRadius: 10,
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
          splashColor: accentColor.withValues(alpha: 0.12),
          highlightColor: accentColor.withValues(alpha: 0.06),
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
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTall ? 17 : 15,
                    fontWeight: FontWeight.w700,
                    color: headingColor,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: DashboardTypography.captionSmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: isTall ? 11.5 : 10.5,
                  ),
                ),
                if (isTall) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: isDark ? 0.18 : 0.08,
                      ),
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
                            style: DashboardTypography.captionSmall.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 7.5,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: DashboardTypography.captionSmall.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
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

  // ── Modal Sheet: Jadwal & Guide Ibadah Haji ────────────────────────────────
  void _showHajiScheduleGuideSheet(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    final scheduleStages = [
      {
        'day': context.tr('dashboard.stageTarwiyahDay'),
        'title': context.tr('dashboard.stageTarwiyahTitle'),
        'icon': Icons.location_city_rounded,
        'color': AppColors.emeraldIslamic,
        'desc': context.tr('dashboard.stageTarwiyahDesc'),
      },
      {
        'day': context.tr('dashboard.stageArafahDay'),
        'title': context.tr('dashboard.stageArafahTitle'),
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFE65100),
        'desc': context.tr('dashboard.stageArafahDesc'),
      },
      {
        'day': context.tr('dashboard.stageMuzdalifahDay'),
        'title': context.tr('dashboard.stageMuzdalifahTitle'),
        'icon': Icons.nights_stay_rounded,
        'color': const Color(0xFF5C6BC0),
        'desc': context.tr('dashboard.stageMuzdalifahDesc'),
      },
      {
        'day': context.tr('dashboard.stageNaharDay'),
        'title': context.tr('dashboard.stageNaharTitle'),
        'icon': Icons.flag_rounded,
        'color': const Color(0xFFC2185B),
        'desc': context.tr('dashboard.stageNaharDesc'),
      },
      {
        'day': context.tr('dashboard.stageTasyrikDay'),
        'title': context.tr('dashboard.stageTasyrikTitle'),
        'icon': Icons.alt_route_rounded,
        'color': const Color(0xFF00897B),
        'desc': context.tr('dashboard.stageTasyrikDesc'),
      },
      {
        'day': context.tr('dashboard.stageWadaDay'),
        'title': context.tr('dashboard.stageWadaTitle'),
        'icon': Icons.mosque_rounded,
        'color': AppColors.secondary,
        'desc': context.tr('dashboard.stageWadaDesc'),
      },
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tanMedium.withValues(
                      alpha: isDark ? 0.25 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.tanMedium,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('dashboard.hajjStagesTitle'),
                        style: DashboardTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.tr('dashboard.hajjStagesSub'),
                        style: DashboardTypography.captionSmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: scheduleStages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = scheduleStages[index];
                  final stageColor = item['color'] as Color;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: stageColor.withValues(alpha: isDark ? 0.3 : 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: stageColor.withValues(
                                  alpha: isDark ? 0.25 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                item['day'] as String,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: stageColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 18,
                              color: stageColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: DashboardTypography.labelLarge.copyWith(
                                  color: headingColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['desc'] as String,
                          style: DashboardTypography.bodySmall.copyWith(
                            color: bodyColor.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Hubungi Pendamping: informasi, pesan, dan berbagi lokasi ───────────────
  Future<void> _showCompanionContactDialog(
    BuildContext context,
    HajiCareController state,
  ) async {
    final roomId = state.activeRoomId.value?.trim();
    if (roomId == null || roomId.isEmpty) {
      AppAlert.error(
        context,
        title: context.tr('dashboard.notInRoom'),
        message: context.tr('dashboard.notInRoomContactDesc'),
        okText: context.tr('dashboard.joinGroup'),
        onOk: () => Get.toNamed(AppRoutes.joinRoom),
      );
      return;
    }

    late final List<RoomMemberModel> pendampings;
    try {
      final members = await RoomQueryService()
          .getRoomMembersStream(roomId)
          .first;
      pendampings = members
          .where((member) => member.isPendamping)
          .toList(growable: false);
    } catch (_) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: context.tr('dashboard.companionLoadFailed'),
          message: context.tr('dashboard.companionLoadFailedDesc'),
        );
      }
      return;
    }

    if (!context.mounted) return;
    if (pendampings.isEmpty) {
      AppAlert.error(
        context,
        title: context.tr('dashboard.companionUnavailable'),
        message: context.tr('dashboard.noActiveCompanion'),
      );
      return;
    }

    await Get.bottomSheet<void>(
      CompanionContactSheet(
        roomId: roomId,
        pendampings: pendampings,
        state: state,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      enableDrag: false,
    );
  }

  // ── Modal Sheet: Fitur Jemput Saya (Kirim Notifikasi ke Pendamping) ─────────
  // ignore: unused_element
  Future<void> _showPickupRequestDialog(
    BuildContext context,
    HajiCareController state,
    JamaahData jamaah,
  ) async {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final roomId = state.activeRoomId.value?.trim();

    if (roomId == null || roomId.isEmpty) {
      AppAlert.error(
        context,
        title: context.tr('dashboard.notInRoom'),
        message: context.tr('dashboard.pickupRequiresRoom'),
        okText: context.tr('dashboard.joinGroup'),
        onOk: () => Get.toNamed(AppRoutes.joinRoom),
      );
      return;
    }

    late final List<RoomMemberModel> pendampings;
    try {
      final members = await RoomQueryService()
          .getRoomMembersStream(roomId)
          .first;
      pendampings = members
          .where((member) => member.isPendamping)
          .toList(growable: false);
    } catch (_) {
      if (context.mounted) {
        AppAlert.error(
          context,
          title: context.tr('dashboard.companionLoadFailed'),
          message: context.tr('dashboard.companionLoadFailedDesc'),
        );
      }
      return;
    }

    if (!context.mounted) return;
    if (pendampings.isEmpty) {
      AppAlert.error(
        context,
        title: context.tr('dashboard.companionUnavailable'),
        message: context.tr('dashboard.noActiveCompanion'),
      );
      return;
    }

    final presets = [
      context.tr('dashboard.pickupMosqueDoor'),
      context.tr('dashboard.pickupHotelLobby'),
      context.tr('dashboard.pickupBusStop'),
      context.tr('dashboard.pickupJamarat'),
      context.tr('dashboard.pickupSeparated'),
    ];
    String selectedPreset = presets[0];
    String? selectedPendampingUid;
    String? selectedPendampingName;
    final noteController = TextEditingController(text: presets[0]);
    final isSending = false.obs;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final myPos = state.myCurrentPosition.value;

          return Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE64A19,
                          ).withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.hail_rounded,
                          color: Color(0xFFE64A19),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('dashboard.requestPickup'),
                              style: DashboardTypography.titleMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              context.tr('dashboard.requestPickupSub'),
                              style: DashboardTypography.captionSmall.copyWith(
                                color: bodyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    context.tr('dashboard.companionLabel'),
                    style: DashboardTypography.labelLarge.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPendampingUid,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surfaceWhite,
                    decoration: InputDecoration(
                      hintText: context.tr('dashboard.selectTargetCompanion'),
                      prefixIcon: const Icon(Icons.support_agent_rounded),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder,
                        ),
                      ),
                    ),
                    items: pendampings
                        .map(
                          (pendamping) => DropdownMenuItem<String>(
                            value: pendamping.uid,
                            child: Text(
                              pendamping.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isSending.value
                        ? null
                        : (uid) {
                            setModalState(() {
                              selectedPendampingUid = uid;
                              selectedPendampingName = pendampings
                                  .where((item) => item.uid == uid)
                                  .firstOrNull
                                  ?.name;
                            });
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // GPS Location card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.statusSafe.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.statusSafe,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                myPos != null
                                    ? context.tr('dashboard.gpsDetected')
                                    : context.tr('dashboard.gpsNotLocked'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: headingColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                myPos != null
                                    ? '${myPos.latitude.toStringAsFixed(5)}, ${myPos.longitude.toStringAsFixed(5)}'
                                    : context.tr(
                                        'dashboard.enableLocationPermission',
                                      ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: bodyColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quick preset chips
                  Text(
                    context.tr('dashboard.locationReference'),
                    style: DashboardTypography.labelLarge.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((preset) {
                      final isSelected = selectedPreset == preset;
                      return ChoiceChip(
                        label: Text(preset),
                        selected: isSelected,
                        selectedColor: const Color(
                          0xFFE64A19,
                        ).withValues(alpha: isDark ? 0.35 : 0.15),
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.canvasCream,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFE64A19)
                              : bodyColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedPreset = preset;
                              noteController.text = preset;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes TextField
                  Text(
                    context.tr('dashboard.locationNotes'),
                    style: DashboardTypography.labelLarge.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: context.tr('dashboard.locationNotesHint'),
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: bodyColor.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Submit button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE64A19),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          elevation: 2,
                        ),
                        icon: isSending.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.hail_rounded),
                        label: Text(
                          isSending.value
                              ? context.tr('dashboard.sendingRequest')
                              : context.tr('dashboard.sendPickupRequest'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        onPressed:
                            isSending.value || selectedPendampingUid == null
                            ? null
                            : () async {
                                isSending.value = true;
                                final noteText = noteController.text.trim();
                                final finalNote = noteText.isNotEmpty
                                    ? noteText
                                    : context.tr('dashboard.pickupDefaultNote');

                                try {
                                  final recipientName =
                                      await NotificationService()
                                          .sendPickupRequest(
                                            roomId: roomId,
                                            pendampingUid:
                                                selectedPendampingUid!,
                                            notes: finalNote,
                                            latitude: myPos?.latitude,
                                            longitude: myPos?.longitude,
                                          );

                                  if (context.mounted) {
                                    Get.back();
                                    AppAlert.success(
                                      context,
                                      title: context.tr(
                                        'dashboard.requestSent',
                                      ),
                                      message: context
                                          .tr('dashboard.requestSentDesc', {
                                            'name':
                                                selectedPendampingName ??
                                                recipientName,
                                          }),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppAlert.error(
                                      context,
                                      title: context.tr('dashboard.sendError'),
                                      message: context.tr(
                                        'dashboard.pickupSendError',
                                        {'error': e},
                                      ),
                                    );
                                  }
                                } finally {
                                  isSending.value = false;
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  // ── Modal Sheet: Pos Medis & Ambulans ─────────────────────────────────────
  void _showMedicalSheet(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.sosEmergency.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: AppColors.sosEmergency,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('dashboard.medicalService'),
                        style: DashboardTypography.titleLarge.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.tr('dashboard.medicalServiceSub'),
                        style: DashboardTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextBody
                              : AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFECEF),
                child: Icon(Icons.phone_rounded, color: AppColors.sosEmergency),
              ),
              title: Text(
                context.tr('dashboard.saudiEmergencyCall'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(context.tr('dashboard.saudiEmergencyCallSub')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(
                  Icons.medical_services_rounded,
                  color: Color(0xFF15803D),
                ),
              ),
              title: Text(
                context.tr('dashboard.kkhi'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(context.tr('dashboard.kkhiSub')),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosEmergency,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.emergency_rounded),
                label: Text(
                  context.tr('dashboard.openEmergencyMenu'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.modalSos);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  // ── Smart Band Telemetry Dialog (Reference Design Layout) ─────────────────
  void _showSmartBandDialog(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    final ldrCtrl = Get.find<SmartbandLdrController>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // ── 1. Main Card Body ──
              Container(
                margin: const EdgeInsets.only(
                  top: 28,
                  bottom: 12,
                  right: 10,
                  left: 10,
                ),
                padding: const EdgeInsets.fromLTRB(16, 68, 16, 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.goldLight.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.45 : 0.09,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Obx(() {
                  final isConnected = ldrCtrl.isConnected;
                  final isAvailable = ldrCtrl.isSensorAvailable.value;
                  final temp = ldrCtrl.temperature.value;
                  final hum = ldrCtrl.humidity.value;
                  final hi = ldrCtrl.heatIndex.value;
                  final statusLabel = ldrCtrl.environmentStatusLabel;
                  final statusColor = ldrCtrl.environmentStatusColor;
                  final statusIcon = ldrCtrl.environmentStatusIcon;
                  final hasPriorData =
                      !isConnected && (temp != null || hum != null);

                  // 1. Suhu Lingkungan (No fake static fallback)
                  final String displayTemp;
                  if (isConnected && isAvailable && temp != null) {
                    displayTemp = '${temp.toStringAsFixed(1)} °C';
                  } else if (hasPriorData && temp != null) {
                    displayTemp = '${temp.toStringAsFixed(1)} °C';
                  } else {
                    displayTemp = '-';
                  }

                  // 2. Kelembapan Udara (No fake static fallback)
                  final String displayHum;
                  if (isConnected && isAvailable && hum != null) {
                    displayHum = '${hum.round()} %';
                  } else if (hasPriorData && hum != null) {
                    displayHum = '${hum.round()} %';
                  } else {
                    displayHum = '-';
                  }

                  // 3. Heat Index (No fake static fallback)
                  final String displayHiText;
                  final double displayGaugePct;
                  if (isConnected && isAvailable && hi != null) {
                    displayHiText = '${hi.round()}°';
                    displayGaugePct = ((hi - 20.0) / 30.0).clamp(0.05, 1.0);
                  } else if (hasPriorData && hi != null) {
                    displayHiText = '${hi.round()}°';
                    displayGaugePct = ((hi - 20.0) / 30.0).clamp(0.05, 1.0);
                  } else {
                    displayHiText = '-°';
                    displayGaugePct = 0.0;
                  }

                  // 4. Status Lingkungan Pill
                  final String displayStatus;
                  if (isConnected && isAvailable) {
                    displayStatus = statusLabel;
                  } else if (hasPriorData) {
                    displayStatus = 'Data Lalu';
                  } else {
                    displayStatus = '-';
                  }

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Subtitle
                        Text(
                          context.tr('dashboard.smartbandMonitoring'),
                          style: DashboardTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 17.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Telemetri sensor lingkungan DHT11 & kondisi fisik.',
                          style: DashboardTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                            height: 1.35,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Connection State Notice Banner ──
                        if (isConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isDark
                                          ? AppColors.emeraldIslamic
                                          : const Color(0xFF059669))
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    (isDark
                                            ? AppColors.emeraldLight
                                            : const Color(0xFF10B981))
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'HajiCare Watch Terhubung • Data Realtime',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.emeraldLight
                                          : const Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (hasPriorData)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD97706,
                              ).withValues(alpha: isDark ? 0.22 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFD97706,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.history_rounded,
                                  size: 16,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Data Sebelumnya (Gelang Terputus)',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Data terakhir disimpan (${ldrCtrl.relativeTimeStr.value.isNotEmpty ? ldrCtrl.relativeTimeStr.value : "sebelum terputus"}). Hubungkan kembali untuk data langsung.',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          height: 1.3,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkCardBorder
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.sensors_off_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gelang Belum Terhubung',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: headingColor,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Data sensor belum tersedia (-). Dekatkan gelang HajiCare Watch Anda.',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          height: 1.3,
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 14),

                        // ── Top Section: Left 2 Stacked Metrics + Right Arc Gauge ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left: Stacked Suhu Lingkungan & Kelembapan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Suhu Lingkungan Item
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.goldLight
                                              : AppColors.primaryGold,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Suhu Lingkungan',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white60
                                                    : const Color(0xFF64748B),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 5,
                                              runSpacing: 2,
                                              children: [
                                                const Icon(
                                                  Icons.thermostat_rounded,
                                                  color: Color(0xFFE11D48),
                                                  size: 16,
                                                ),
                                                Text(
                                                  displayTemp,
                                                  style: TextStyle(
                                                    color: headingColor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                if (displayStatus != '-')
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 5.5,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          (hasPriorData
                                                                  ? const Color(
                                                                      0xFFD97706,
                                                                    )
                                                                  : statusColor)
                                                              .withValues(
                                                                alpha: isDark
                                                                    ? 0.25
                                                                    : 0.14,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          hasPriorData
                                                              ? Icons
                                                                    .history_rounded
                                                              : statusIcon,
                                                          color: hasPriorData
                                                              ? const Color(
                                                                  0xFFD97706,
                                                                )
                                                              : statusColor,
                                                          size: 11,
                                                        ),
                                                        const SizedBox(
                                                          width: 3,
                                                        ),
                                                        Text(
                                                          displayStatus,
                                                          style: TextStyle(
                                                            color: hasPriorData
                                                                ? const Color(
                                                                    0xFFD97706,
                                                                  )
                                                                : statusColor,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
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

                                  // 2. Kelembapan Item
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Kelembapan Udara',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white60
                                                    : const Color(0xFF64748B),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 5,
                                              runSpacing: 2,
                                              children: [
                                                const Icon(
                                                  Icons.water_drop_rounded,
                                                  color: Color(0xFF0284C7),
                                                  size: 16,
                                                ),
                                                Text(
                                                  displayHum,
                                                  style: TextStyle(
                                                    color: headingColor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Right: Circular Arc Progress Ring Gauge for Heat Index
                            SizedBox(
                              width: 98,
                              height: 98,
                              child: CustomPaint(
                                painter: _CircularGaugePainter(
                                  progress: displayGaugePct,
                                  trackColor: isDark
                                      ? AppColors.darkSurfaceContainerHighest
                                      : AppColors.canvasCreamSubtle,
                                  arcColor: displayGaugePct > 0
                                      ? (hasPriorData
                                            ? const Color(0xFFD97706)
                                            : (isDark
                                                  ? AppColors.goldLight
                                                  : AppColors.goldPrimary))
                                      : (isDark
                                            ? Colors.white24
                                            : const Color(0xFFCBD5E1)),
                                  dotColor: displayGaugePct > 0
                                      ? (isDark
                                            ? AppColors.accentGoldStar
                                            : AppColors.goldDark)
                                      : Colors.transparent,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        displayHiText,
                                        style: TextStyle(
                                          color: headingColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Heat Index',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── Interactive Heartbeat Waveform (Lansia / Senior Friendly) ──
                        _InteractiveHeartbeatWave(
                          isConnected: isConnected,
                          hasPriorData: hasPriorData,
                          priorTime: ldrCtrl.relativeTimeStr.value,
                          onConnectTap: () {
                            ldrCtrl.connectSmartband();
                          },
                        ),

                        const SizedBox(height: 14),

                        // ── Bottom Row: 3 Non-Static Status Metrics ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildLinearMetricColumn(
                                context: context,
                                title: 'Kondisi Udara',
                                valueText: isConnected && isAvailable
                                    ? statusLabel
                                    : (hasPriorData ? '$statusLabel*' : '-'),
                                progress:
                                    (isConnected || hasPriorData) && isAvailable
                                    ? 0.75
                                    : 0.0,
                                barColor: hasPriorData
                                    ? const Color(0xFFD97706)
                                    : (isConnected && isAvailable
                                          ? statusColor
                                          : (isDark
                                                ? Colors.white24
                                                : const Color(0xFFCBD5E1))),
                                isDark: isDark,
                                headingColor: headingColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLinearMetricColumn(
                                context: context,
                                title: 'Sinyal Gelang',
                                valueText: isConnected
                                    ? 'Terhubung'
                                    : (hasPriorData ? 'Terputus' : '-'),
                                progress: isConnected
                                    ? 1.0
                                    : (hasPriorData ? 0.25 : 0.0),
                                barColor: isConnected
                                    ? const Color(0xFF0284C7)
                                    : (hasPriorData
                                          ? const Color(0xFFD97706)
                                          : (isDark
                                                ? Colors.white24
                                                : const Color(0xFFCBD5E1))),
                                isDark: isDark,
                                headingColor: headingColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLinearMetricColumn(
                                context: context,
                                title: 'Sensor DHT11',
                                valueText: isConnected && isAvailable
                                    ? 'Aktif'
                                    : (hasPriorData ? 'Tersimpan' : '-'),
                                progress: isConnected && isAvailable
                                    ? 1.0
                                    : (hasPriorData ? 0.5 : 0.0),
                                barColor: isConnected && isAvailable
                                    ? const Color(0xFF10B981)
                                    : (hasPriorData
                                          ? const Color(0xFFD97706)
                                          : (isDark
                                                ? Colors.white24
                                                : const Color(0xFFCBD5E1))),
                                isDark: isDark,
                                headingColor: headingColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Bottom Row: Detail sensor on left, space reserved for protruding ribbon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? AppColors.goldLight
                                    : AppColors.espressoDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                Get.toNamed(AppRoutes.smartbandLdr);
                              },
                              icon: const Icon(Icons.tune_rounded, size: 16),
                              label: Text(
                                context.tr('dashboard.sensorDetails'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 145),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),

              // ── 2. Floating Hero Card ──
              Positioned(
                top: 0,
                left: 22,
                right: 22,
                height: 86,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF38251A), const Color(0xFF1F140D)]
                          : [AppColors.espressoDark, const Color(0xFF563B2A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espressoDark.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -15,
                        right: -15,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldPrimary.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -15,
                        child: Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldPrimary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.goldPrimary.withValues(
                                      alpha: 0.25,
                                    ),
                                    AppColors.goldPrimary.withValues(
                                      alpha: 0.08,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: AppColors.goldPrimary.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.watch_rounded,
                                  color: AppColors.accentGoldStar,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('dashboard.bandTelemetry'),
                              style: const TextStyle(
                                color: AppColors.goldLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 3. Protruding Ribbon Action Button (No shadow) ──
              Positioned(
                bottom: 0,
                right: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -10,
                      right: 0,
                      child: CustomPaint(
                        size: const Size(10, 10),
                        painter: RibbonFoldPainter(
                          color: isDark
                              ? const Color(0xFF140D08)
                              : const Color(0xFF160D07),
                        ),
                      ),
                    ),
                    Obx(() {
                      final isConnected = ldrCtrl.isConnected;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (isConnected) {
                              Navigator.of(ctx).pop();
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr('dashboard.bandSignalSent'),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              Navigator.of(ctx).pop();
                              Get.toNamed(AppRoutes.smartbandLdr);
                            }
                          },
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(5),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkPrimaryContainer
                                  : AppColors.espressoDark,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(5),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13.5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isConnected
                                      ? Icons.vibration_rounded
                                      : Icons.bluetooth_searching_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isConnected
                                      ? context.tr('dashboard.vibrate')
                                      : 'HUBUNGKAN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Linear Metric Column Helper (Bottom Row of Dialog) ────────────────────
  Widget _buildLinearMetricColumn({
    required BuildContext context,
    required String title,
    required String valueText,
    required double progress,
    required Color barColor,
    required bool isDark,
    required Color headingColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: headingColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4.5,
            backgroundColor: barColor.withValues(alpha: isDark ? 0.2 : 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          valueText,
          style: TextStyle(
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
