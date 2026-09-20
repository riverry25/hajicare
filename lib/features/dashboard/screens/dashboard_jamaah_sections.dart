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
                    label: 'Komunikasi Cepat',
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
                    label: 'Smart Band',
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
                    label: 'Panduan Doa',
                    icon: Icons.menu_book_rounded,
                    bgColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    iconColor: isDark
                        ? AppColors.goldLight
                        : AppColors.espressoDark,
                    onTap: () => _showDoaSheet(context),
                  ),
                ),
                Expanded(
                  child: _buildCategoryItem(
                    context: context,
                    label: 'Pos Medis',
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
                    label: 'BISINDO',
                    icon: Icons.sign_language_rounded,
                    bgColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    iconColor: isDark
                        ? AppColors.goldLight
                        : AppColors.espressoDark,
                    onTap: () => Get.toNamed(AppRoutes.bisindo),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Section 1: "Status & Peringatan" ("Bot Alert") ────────
          _buildSectionHeader(
            title: 'Status & Peringatan',
            subtitle: 'Koneksi GPS & pemantauan rombongan',
            actionText: 'Lihat peta',
            onAction: () => dashboardCtrl.changeTab(1),
            headingColor: headingColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildStatusAlertCard(context, jamaah, isDark, dashboardCtrl),

          const SizedBox(height: 26),

          // ── Section 2: "Kamar & Maktab" ───────────────────────────
          _buildSectionHeader(
            title: 'Kamar & Maktab',
            subtitle: 'Informasi room & rombongan hotel',
            actionText: 'Kelola',
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
            title: 'Tips & Panduan Ibadah',
            subtitle: 'Doa harian, rukun & info penting',
            actionText: 'Lihat semua',
            onAction: () => _showDoaSheet(context),
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
                  style: AppTypography.titleMedium.copyWith(
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
                  style: AppTypography.captionSmall.copyWith(
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
                  const Text(
                    'Peringatan Terpisah!',
                    style: TextStyle(
                      color: AppColors.sosEmergency,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Jarak Anda jauh dari rombongan. Segera buka peta untuk kembali ke rombongan.',
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
                  'Kondisi Terkoneksi & Aman',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'GPS aktif dengan radius aman. Terhubung dengan posko kloter secara real-time.',
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
                  'Tips Menghadapi Cuaca Panas',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jaga asupan cairan air zam-zam dan gunakan payung peneduh saat beraktivitas di siang hari.',
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

  // ── Modal Sheet: Panduan Doa & Dzikir ──────────────────────────────────────
  void _showDoaSheet(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    final doas = [
      {
        'title': 'Bacaan Talbiyah',
        'arabic':
            'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ',
        'latin':
            'Labbaikallaahumma labbaik, labbaika laa syariika laka labbaik...',
        'arti': 'Aku penuhi panggilan-Mu ya Allah, aku penuhi panggilan-Mu...',
      },
      {
        'title': 'Doa Tawaf (Antara Rukun Yamani & Hajar Aswad)',
        'arabic':
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        'latin':
            'Rabbanaa aatinaa fid dunyaa hasanah wa fil aakhirati hasanah wa qinaa \'adzaaban naar',
        'arti':
            'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat dan lindungilah kami dari azab neraka.',
      },
      {
        'title': 'Doa Masuk Masjidil Haram',
        'arabic': 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
        'latin': 'Allaahummaftah lii abwaaba rahmatik',
        'arti': 'Ya Allah, bukalah pintu-pintu rahmat-Mu untukku.',
      },
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
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
            Text(
              'Doa & Dzikir Ibadah Haji',
              style: AppTypography.titleLarge.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: doas.length,
                separatorBuilder: (_, _) => const Divider(height: 24),
                itemBuilder: (context, i) {
                  final item = doas[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.espressoDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item['arabic']!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['latin']!,
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Artinya: "${item['arti']}"',
                        style: AppTypography.caption.copyWith(color: bodyColor),
                      ),
                    ],
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
                        'Layanan Pos Medis Haji',
                        style: AppTypography.titleLarge.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bantuan Medis Darurat & Maktab',
                        style: AppTypography.caption.copyWith(
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
              title: const Text(
                'Call Center Darurat Saudi: 997',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Ambulans & Paramedis Resmi Arab Saudi'),
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
              title: const Text(
                'Klinik Kesehatan Haji Indonesia (KKHI)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Tersedia 24 Jam di Daker Makkah & Madinah'),
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
                label: const Text(
                  'Buka Menu Darurat SOS',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 620),
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
                padding: const EdgeInsets.fromLTRB(18, 68, 18, 14),
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
                  final ldrVal = ldrCtrl.ldrValue.value;
                  final isFlame = ldrCtrl.flameDetected.value;
                  final isConnected = ldrCtrl.isConnected;
                  final lightStatus = ldrCtrl.lightStatus;

                  // Safe fallback readings if not yet connected to physical hardware
                  final displayLdr = isConnected && ldrVal > 0
                      ? ldrVal
                      : (ldrVal > 0 ? ldrVal : 820);
                  final displayBrightnessPct = ((4095 - displayLdr) / 4095.0)
                      .clamp(0.1, 1.0);
                  final displayStatus = lightStatus != '-'
                      ? lightStatus
                      : 'Terang';

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Subtitle
                        Text(
                          'Pantauan Smartband',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 17.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Telemetri sensor lingkungan & kondisi fisik real-time.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                            height: 1.35,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Top Section: Left 2 Stacked Metrics + Right Arc Gauge ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left: Stacked Sensor LDR & Flame Sensor
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Sensor LDR Item
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 36,
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
                                              'Sensor LDR',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white60
                                                    : const Color(0xFF64748B),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 5,
                                              runSpacing: 2,
                                              children: [
                                                Icon(
                                                  Icons.wb_sunny_rounded,
                                                  color: isDark
                                                      ? AppColors.goldLight
                                                      : AppColors.primaryGold,
                                                  size: 15,
                                                ),
                                                Text(
                                                  '$displayLdr',
                                                  style: TextStyle(
                                                    color: headingColor,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                Text(
                                                  'Lux',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white54
                                                        : const Color(
                                                            0xFF94A3B8,
                                                          ),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 1.5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (isDark
                                                                ? AppColors
                                                                      .goldLight
                                                                : AppColors
                                                                      .primaryGold)
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
                                                  child: Text(
                                                    displayStatus,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? AppColors.goldLight
                                                          : AppColors.goldDark,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  // 2. Flame Sensor Item
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isFlame
                                              ? AppColors.sosEmergency
                                              : (isDark
                                                    ? AppColors.darkSecondary
                                                    : AppColors.tanMedium),
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
                                              'Flame Sensor',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white60
                                                    : const Color(0xFF64748B),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 5,
                                              runSpacing: 2,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .local_fire_department_rounded,
                                                  color: isFlame
                                                      ? AppColors.sosEmergency
                                                      : (isDark
                                                            ? AppColors
                                                                  .darkSecondary
                                                            : AppColors
                                                                  .tanMedium),
                                                  size: 15,
                                                ),
                                                Text(
                                                  isFlame ? 'API!' : 'Normal',
                                                  style: TextStyle(
                                                    color: isFlame
                                                        ? AppColors.sosEmergency
                                                        : headingColor,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 1.5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (isFlame
                                                                ? AppColors
                                                                      .sosEmergency
                                                                : AppColors
                                                                      .statusSafe)
                                                            .withValues(
                                                              alpha: isDark
                                                                  ? 0.25
                                                                  : 0.12,
                                                            ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    isFlame
                                                        ? 'Evakuasi'
                                                        : 'Aman',
                                                    style: TextStyle(
                                                      color: isFlame
                                                          ? AppColors
                                                                .sosEmergency
                                                          : AppColors
                                                                .statusSafe,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
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

                            // Right: Circular Arc Progress Ring Gauge
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CustomPaint(
                                painter: _CircularGaugePainter(
                                  progress: displayBrightnessPct,
                                  trackColor: isDark
                                      ? AppColors.darkSurfaceContainerHighest
                                      : AppColors.canvasCreamSubtle,
                                  arcColor: isDark
                                      ? AppColors.goldLight
                                      : AppColors.goldPrimary,
                                  dotColor: isDark
                                      ? AppColors.accentGoldStar
                                      : AppColors.goldDark,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$displayLdr',
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
                                        'LDR Level',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
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

                        // ── Horizontal Divider Line ──
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.darkCardBorder
                              : const Color(0xFFE2E8F0),
                        ),

                        const SizedBox(height: 14),

                        // ── Bottom Row: 3 Horizontal Metrics with Mini Progress Bars ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildLinearMetricColumn(
                                context: context,
                                title: 'Detak Jantung',
                                valueText: '76 bpm',
                                progress: 0.65,
                                barColor: isDark
                                    ? AppColors.goldLight
                                    : AppColors.primaryGold,
                                isDark: isDark,
                                headingColor: headingColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLinearMetricColumn(
                                context: context,
                                title: 'Suhu Badan',
                                valueText: '36.6 °C',
                                progress: 0.72,
                                barColor: isDark
                                    ? AppColors.darkSecondary
                                    : AppColors.tanMedium,
                                isDark: isDark,
                                headingColor: headingColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLinearMetricColumn(
                                context: context,
                                title: 'Baterai Band',
                                valueText: '88% BLE',
                                progress: 0.88,
                                barColor: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.espressoDark,
                                isDark: isDark,
                                headingColor: headingColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Bottom Row: Detail sensor on left, space reserved for protruding button
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
                              label: const Text(
                                'Detail Sensor',
                                style: TextStyle(
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
                            const Text(
                              'TELEMETRI SMARTBAND',
                              style: TextStyle(
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

              // ── 3. Protruding Ribbon Submit Button (No shadow) ──
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
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sinyal panggil terkirim! Gelang pintar bergetar.',
                              ),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
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
                            horizontal: 20,
                            vertical: 13.5,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.vibration_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'GETARKAN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
