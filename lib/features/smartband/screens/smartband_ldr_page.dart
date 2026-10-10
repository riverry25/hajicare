import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../controllers/smartband_ldr_controller.dart';
import '../services/smartband_ble_service.dart';

/// Halaman Utama Pemantauan Smartband HajiCare ESP32-S3
/// Mengintegrasikan telemetri 5 sensor:
/// 1. MAX30102 (Detak Jantung)
/// 2. MCP9808 (Suhu Tubuh)
/// 3. MPU6050 (Deteksi Jatuh & Horizon Gerak)
/// 4. NEO-6M (GPS Satelit)
/// 5. Baterai LiPo 3.7V
class SmartbandLdrPage extends GetView<SmartbandLdrController> {
  const SmartbandLdrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    final scaffoldBg = AppColors.scaffoldColor(context);

    // Otomatis aktifkan mode simulasi jika hardware belum terhubung,
    // sehingga user langsung dapat mengeksplorasi sensor secara realistis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctrl.isConnected && !ctrl.isSimulationMode.value) {
        ctrl.toggleSimulation(true);
      }
    });

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: HajiCareHeader(
        title: context.tr('smartband.pageTitle'),
        subtitle: context.tr('smartband.pageSubtitle'),
        icon: Icons.watch_rounded,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryGold),
            tooltip: context.tr('smartband.bleTestTooltip'),
            onPressed: () => Get.toNamed(AppRoutes.smartbandBleTest),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionSheet(context, ctrl),
        backgroundColor: const Color(0xFFFF1493),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdgeGutter,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 0. BANNER PERINGATAN DARURAT JATUH (MPU6050) ──────────────
              _buildEmergencyFallBanner(context, ctrl),

              // ── 1. STATUS GELANG & TOGGLE SIMULASI MODE ───────────────────
              _buildTopStatusBar(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 2. HERO METRIC ARC GAUGE (Inspirasi Gambar 1) ─────────────
              _buildHeroMetricArcCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 3. TIGA LINGKARAN PROGRESS RING (Inspirasi Gambar 2) ──────
              _buildThreeProgressRingsCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 4. GRAFIK TREN SENSOR BEZIER CURVE (Inspirasi Gambar 1) ───
              _buildTrendSectionCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 5. WIDGET SPESIAL: DETEKSI JATUH & GYRO (MPU6050) ─────────
              _buildMpu6050FallAndGyroCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 6. JADWAL PEMANTAUAN HARI INI (Inspirasi Gambar 2) ────────
              _buildMilestoneTimelineCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 7. PILIHAN KATEGORI SENSOR HARDWARE ───────────────────────
              _buildSensorCategorySelector(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 8. LOKASI SATELIT GPS NEO-6M ──────────────────────────────
              _buildGpsSatelliteCard(context, ctrl),
              const SizedBox(height: 80), // Ruang ekstra untuk FAB
            ],
          ),
        ),
      ),
    );
  }

  // ── 0. BANNER PERINGATAN DARURAT JATUH (MPU6050) ───────────────────────────
  Widget _buildEmergencyFallBanner(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    return Obx(() {
      if (!ctrl.isFallDetected.value) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.gapCards),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.tr('smartband.fallAlertTitle'),
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('smartband.fallAlertDesc'),
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                context.tr('smartband.autoSosIn', {
                  'seconds': ctrl.fallCountdownSeconds.value,
                }),
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => ctrl.cancelFallAlert(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('smartband.cancelAlert'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 1. STATUS GELANG & TOGGLE SIMULASI MODE ───────────────────────────────
  Widget _buildTopStatusBar(BuildContext context, SmartbandLdrController ctrl) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isSim = ctrl.isSimulationMode.value;
      final isConn = ctrl.bleStatus.value == SmartbandBleStatus.connected;

      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConn
                    ? AppColors.statusSafe
                    : (isSim ? AppColors.primaryGold : AppColors.statusDanger),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isConn
                          ? context.tr('smartband.statusConnected')
                          : (isSim
                                ? '${context.tr('smartband.simMode')} (ESP32-S3)'
                                : context.tr('smartband.statusDisconnected')),
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'ID: ${ctrl.braceletId.value} • ${ctrl.relativeTimeText.value}',
                    style: AppTypography.captionSmall.copyWith(
                      color: bodyColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Switch mode simulasi (karena hardware baru setengah jadi)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isSim ? 'Demo' : 'BLE',
                    style: AppTypography.captionSmall.copyWith(
                      color: isSim ? AppColors.primaryGold : bodyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: isSim,
                    activeThumbColor: AppColors.primaryGold,
                    onChanged: (val) => ctrl.toggleSimulation(val),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── 2. HERO METRIC ARC GAUGE (Inspirasi Gambar 1) ─────────────────────────
  Widget _buildHeroMetricArcCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final sensorIdx = ctrl.selectedSensorIndex.value;

      String heroTitle;
      String heroValue;
      String heroUnit;
      double arcPercent;
      Color arcColor;
      String statusPillText;
      Color statusPillBg;
      Color statusPillColor;

      switch (sensorIdx) {
        case 1: // MCP9808 Suhu
          heroTitle = context.tr('smartband.heroTemperature');
          final temp = ctrl.mcpTemperature.value ?? 36.6;
          heroValue = temp.toStringAsFixed(1);
          heroUnit = '°C';
          arcPercent = ((temp - 35.0) / (40.0 - 35.0)).clamp(0.1, 1.0);
          arcColor = const Color(0xFFD4A857);
          statusPillText = temp >= 37.5
              ? context.tr('smartband.warning')
              : context.tr('smartband.normal');
          statusPillBg = temp >= 37.5
              ? AppColors.statusWarning.withValues(alpha: 0.15)
              : AppColors.statusSafe.withValues(alpha: 0.15);
          statusPillColor = temp >= 37.5
              ? AppColors.statusWarning
              : AppColors.statusSafe;
          break;
        case 2: // MPU6050 Keseimbangan
          heroTitle = context.tr('smartband.heroFall');
          heroValue = '${ctrl.stabilityScore.value}';
          heroUnit = '%';
          arcPercent = (ctrl.stabilityScore.value / 100.0).clamp(0.0, 1.0);
          arcColor = ctrl.isFallDetected.value
              ? AppColors.statusDanger
              : const Color(0xFF10B981);
          statusPillText = ctrl.isFallDetected.value
              ? context.tr('smartband.danger')
              : context.tr('smartband.optimal');
          statusPillBg = ctrl.isFallDetected.value
              ? AppColors.statusDanger.withValues(alpha: 0.15)
              : AppColors.statusSafe.withValues(alpha: 0.15);
          statusPillColor = ctrl.isFallDetected.value
              ? AppColors.statusDanger
              : AppColors.statusSafe;
          break;
        case 3: // NEO-6M GPS
          heroTitle = context.tr('smartband.heroGps');
          heroValue = '${ctrl.gpsSatellites.value}';
          heroUnit = 'SATS';
          arcPercent = (ctrl.gpsSatellites.value / 12.0).clamp(0.1, 1.0);
          arcColor = const Color(0xFF0284C7);
          statusPillText = 'GPS FIX';
          statusPillBg = AppColors.statusSafe.withValues(alpha: 0.15);
          statusPillColor = AppColors.statusSafe;
          break;
        case 4: // LiPo Baterai
          heroTitle = context.tr('smartband.heroBattery');
          heroValue = '${ctrl.batteryPercent.value}';
          heroUnit = '%';
          arcPercent = (ctrl.batteryPercent.value / 100.0).clamp(0.0, 1.0);
          arcColor = const Color(0xFF10B981);
          statusPillText = '${ctrl.batteryVoltage.value}V';
          statusPillBg = AppColors.statusSafe.withValues(alpha: 0.15);
          statusPillColor = AppColors.statusSafe;
          break;
        default: // MAX30102 Detak Jantung
          heroTitle = context.tr('smartband.heroHeartRate');
          final hr =
              ctrl.heartRate.value ?? (ctrl.isSimulationMode.value ? 78 : 0);
          heroValue = hr > 0 ? '$hr' : '--';
          heroUnit = context.tr('smartband.heartRateUnit');
          arcPercent = hr > 0 ? ((hr - 40) / (140 - 40)).clamp(0.1, 1.0) : 0.0;
          arcColor = const Color(0xFF10B981);
          statusPillText = hr >= 100
              ? context.tr('smartband.warning')
              : context.tr('smartband.normal');
          statusPillBg = AppColors.statusSafe.withValues(alpha: 0.15);
          statusPillColor = AppColors.statusSafe;
          break;
      }

      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Judul Sensor Aktif
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                heroTitle,
                style: AppTypography.titleLarge.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Semi-circular Arc Gauge Visualizer
            SizedBox(
              width: 220,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220, 170),
                    painter: MetricArcGaugePainter(
                      progress: arcPercent,
                      primaryColor: arcColor,
                      trackColor: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            heroValue,
                            style: AppTypography.headlineLarge.copyWith(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              color: headingColor,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          heroUnit,
                          style: AppTypography.labelLarge.copyWith(
                            color: bodyColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2026.10.10',
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusPillBg,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            statusPillText,
                            style: AppTypography.captionSmall.copyWith(
                              color: statusPillColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 3. TIGA LINGKARAN PROGRESS RING (Inspirasi Gambar 2) ──────────────────
  Widget _buildThreeProgressRingsCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final hr = ctrl.currentHeartRate;
      final temp = ctrl.currentTemperature;
      final bat = ctrl.currentBattery;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'STATUS KESEHATAN & DAYA',
                          style: AppTypography.labelLarge.copyWith(
                            color: bodyColor.withValues(alpha: 0.6),
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ringkasan 3 Sensor Utama',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusSafe.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(
                      color: AppColors.statusSafe.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppColors.statusSafe,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('smartband.allHealthy'),
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.statusSafe,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Baris 3 Ring Gauges (Responsive dengan FittedBox)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Ring Detak Jantung (MAX30102)
                Expanded(
                  child: _buildSingleRingItem(
                    context,
                    progress: (hr / 100.0).clamp(0.1, 1.0),
                    displayPercent: hr > 0 ? '$hr' : '--',
                    unit: 'BPM',
                    ringColor: const Color(0xFF10B981),
                    title: context.tr('smartband.heartRateLabel'),
                    subtitle: context.tr('smartband.optimal'),
                  ),
                ),
                // 2. Ring Suhu Tubuh (MCP9808)
                Expanded(
                  child: _buildSingleRingItem(
                    context,
                    progress: ((temp - 35.0) / 5.0).clamp(0.1, 1.0),
                    displayPercent: temp.toStringAsFixed(1),
                    unit: '°C',
                    ringColor: const Color(0xFFD4A857),
                    title: context.tr('smartband.tempLabel'),
                    subtitle: context.tr('smartband.normal'),
                  ),
                ),
                // 3. Ring Baterai LiPo
                Expanded(
                  child: _buildSingleRingItem(
                    context,
                    progress: (bat / 100.0).clamp(0.0, 1.0),
                    displayPercent: '$bat',
                    unit: '%',
                    ringColor: const Color(0xFF0284C7),
                    title: context.tr('smartband.batteryLabel'),
                    subtitle: 'LiPo 3.96V',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSingleRingItem(
    BuildContext context, {
    required double progress,
    required String displayPercent,
    required String unit,
    required Color ringColor,
    required String title,
    required String subtitle,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(72, 72),
                painter: CircularProgressRingPainter(
                  progress: progress,
                  strokeWidth: 7,
                  primaryColor: ringColor,
                  trackColor: Colors.black.withValues(alpha: 0.06),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayPercent,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: headingColor,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: bodyColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: headingColor,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            subtitle,
            style: AppTypography.captionSmall.copyWith(
              color: bodyColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. GRAFIK TREN SENSOR BEZIER CURVE (Inspirasi Gambar 1) ───────────────
  Widget _buildTrendSectionCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);

    return Obx(() {
      final period = ctrl.trendPeriod.value;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Tren + Icon Ungu Gradient
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.show_chart_rounded,
                        color: Color(0xFF9333EA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.tr('smartband.trendTitle'),
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Detail',
                    style: TextStyle(
                      color: const Color(0xFFFF1493),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tab Selector Periode (Hari Ini / Minggu / Bulan)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _buildPeriodTab(
                    context,
                    label: context.tr('smartband.trendToday'),
                    isSelected: period == 'today',
                    onTap: () => ctrl.setTrendPeriod('today'),
                  ),
                  _buildPeriodTab(
                    context,
                    label: context.tr('smartband.trendWeek'),
                    isSelected: period == 'week',
                    onTap: () => ctrl.setTrendPeriod('week'),
                  ),
                  _buildPeriodTab(
                    context,
                    label: context.tr('smartband.trendMonth'),
                    isSelected: period == 'month',
                    onTap: () => ctrl.setTrendPeriod('month'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cubic Bezier Spline Chart
            SizedBox(
              height: 160,
              child: CustomPaint(
                size: const Size(double.infinity, 160),
                painter: CubicBezierTrendChartPainter(
                  dataPoints: ctrl.trendData.toList(),
                  lineColor: const Color(0xFFFF2E63),
                  fillGradientColor: const Color(0xFFFF2E63),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Sumbu X (Hari)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAxisLabel('Sen'),
                _buildAxisLabel('Sel'),
                _buildAxisLabel('Rab'),
                _buildAxisLabel('Kam'),
                _buildAxisLabel('Jum'),
                _buildAxisLabel('Sab'),
                _buildAxisLabel('Min'),
              ],
            ),
            const SizedBox(height: 20),

            // 3 Kartu Mini Ringkasan (Rata-rata, MAX, MIN)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMiniCard(
                    context,
                    title: context.tr('smartband.avg'),
                    value: ctrl.trendAverage.toStringAsFixed(0),
                    unit: 'BPM',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMiniCard(
                    context,
                    title: context.tr('smartband.max'),
                    value: ctrl.trendMax.toStringAsFixed(0),
                    unit: 'BPM',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMiniCard(
                    context,
                    title: context.tr('smartband.min'),
                    value: ctrl.trendMin.toStringAsFixed(0),
                    unit: 'BPM',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPeriodTab(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.black45,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAxisLabel(String text) {
    return Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMiniCard(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: AppTypography.captionSmall.copyWith(
                color: bodyColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: headingColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: bodyColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5. WIDGET SPESIAL: DETEKSI JATUH & GYRO (MPU6050) ─────────────────────
  Widget _buildMpu6050FallAndGyroCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isFall = ctrl.isFallDetected.value;
      final roll = ctrl.gyroRoll.value;
      final pitch = ctrl.gyroPitch.value;
      final gVal = ctrl.accelG.value;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFall
                        ? AppColors.statusDanger.withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    isFall
                        ? Icons.personal_injury_rounded
                        : Icons.accessibility_new_rounded,
                    color: isFall
                        ? AppColors.statusDanger
                        : const Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.tr('smartband.fallDetectionTitle'),
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'MPU6050 6-Axis Inersia & Postur Jamaah',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display Gyro Artificial Horizon + Telemetri Sudut
            Row(
              children: [
                // Artificial Horizon Dial
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    size: const Size(110, 110),
                    painter: GyroHorizonPainter(
                      rollDegrees: roll,
                      pitchDegrees: pitch,
                      isFall: isFall,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Data Roll, Pitch, G-Force & Stabilitas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Postur Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isFall
                              ? AppColors.statusDanger.withValues(alpha: 0.15)
                              : (roll.abs() > 30 || pitch.abs() > 30
                                    ? AppColors.statusWarning.withValues(
                                        alpha: 0.15,
                                      )
                                    : AppColors.statusSafe.withValues(
                                        alpha: 0.15,
                                      )),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          context.tr(ctrl.postureKey.value),
                          style: AppTypography.captionSmall.copyWith(
                            color: isFall
                                ? AppColors.statusDanger
                                : (roll.abs() > 30 || pitch.abs() > 30
                                      ? AppColors.statusWarning
                                      : AppColors.statusSafe),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGyroTelemetryText(
                        label: 'Roll (Kemiringan)',
                        value: '${roll.toStringAsFixed(1)}°',
                      ),
                      _buildGyroTelemetryText(
                        label: 'Pitch (Sudut Vertikal)',
                        value: '${pitch.toStringAsFixed(1)}°',
                      ),
                      _buildGyroTelemetryText(
                        label: 'Akselerasi Impak',
                        value: '${gVal.toStringAsFixed(2)} G',
                      ),
                      _buildGyroTelemetryText(
                        label: 'Skor Keseimbangan',
                        value: '${ctrl.stabilityScore.value}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tombol Simulasi Uji Sensor Jatuh
            OutlinedButton.icon(
              onPressed: () => ctrl.triggerFallSimulation(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              icon: const Icon(Icons.touch_app_rounded, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('smartband.testFallButton'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGyroTelemetryText({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. JADWAL PEMANTAUAN HARI INI (Inspirasi Gambar 2) ─────────────────────
  Widget _buildMilestoneTimelineCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.checklist_rounded,
                        color: AppColors.goldDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.tr('smartband.milestoneTitle'),
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      context.tr('smartband.milestoneCount', {
                        'done': '2',
                        'total': '3',
                      }),
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: bodyColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stepper Timeline Horisontal
          Row(
            children: [
              Expanded(
                child: _buildTimelineStep(
                  context,
                  time: '06:00',
                  title: 'Vital Pagi',
                  status: context.tr('smartband.done'),
                  isCompleted: true,
                  showTrailingLine: true,
                ),
              ),
              Expanded(
                child: _buildTimelineStep(
                  context,
                  time: '12:00',
                  title: 'Tawaf & Suhu',
                  status: context.tr('smartband.done'),
                  isCompleted: true,
                  showTrailingLine: true,
                ),
              ),
              Expanded(
                child: _buildTimelineStep(
                  context,
                  time: '20:00',
                  title: 'Evaluasi Malam',
                  status: context.tr('smartband.upcoming'),
                  isCompleted: false,
                  showTrailingLine: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required String time,
    required String title,
    required String status,
    required bool isCompleted,
    required bool showTrailingLine,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.transparent,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : Colors.black.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            Expanded(
              child: Container(
                height: 2,
                color: showTrailingLine
                    ? (isCompleted
                          ? const Color(0xFF10B981)
                          : Colors.black.withValues(alpha: 0.1))
                    : Colors.transparent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : const Color(0xFFD4A857),
            ),
          ),
        ),
      ],
    );
  }

  // ── 7. PILIHAN KATEGORI SENSOR HARDWARE ────────────────────────────────────
  Widget _buildSensorCategorySelector(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'KATEGORI SENSOR SMARTBAND',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.black45,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSensorPillCard(
                context,
                index: 0,
                sensorCode: 'MAX30102',
                sensorName: 'Detak Jantung',
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFFF2E63),
                ctrl: ctrl,
              ),
              const SizedBox(width: 8),
              _buildSensorPillCard(
                context,
                index: 1,
                sensorCode: 'MCP9808',
                sensorName: 'Suhu Tubuh',
                icon: Icons.device_thermostat_rounded,
                iconColor: const Color(0xFFD4A857),
                ctrl: ctrl,
              ),
              const SizedBox(width: 8),
              _buildSensorPillCard(
                context,
                index: 2,
                sensorCode: 'MPU6050',
                sensorName: 'Deteksi Jatuh',
                icon: Icons.directions_walk_rounded,
                iconColor: const Color(0xFF10B981),
                ctrl: ctrl,
              ),
              const SizedBox(width: 8),
              _buildSensorPillCard(
                context,
                index: 3,
                sensorCode: 'NEO-6M',
                sensorName: 'GPS Satelit',
                icon: Icons.satellite_alt_rounded,
                iconColor: const Color(0xFF0284C7),
                ctrl: ctrl,
              ),
              const SizedBox(width: 8),
              _buildSensorPillCard(
                context,
                index: 4,
                sensorCode: 'LiPo 3.7V',
                sensorName: 'Baterai',
                icon: Icons.battery_charging_full_rounded,
                iconColor: const Color(0xFF16A34A),
                ctrl: ctrl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorPillCard(
    BuildContext context, {
    required int index,
    required String sensorCode,
    required String sensorName,
    required IconData icon,
    required Color iconColor,
    required SmartbandLdrController ctrl,
  }) {
    return Obx(() {
      final isSelected = ctrl.selectedSensorIndex.value == index;

      return GestureDetector(
        onTap: () => ctrl.selectSensor(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected
                  ? iconColor
                  : Colors.black.withValues(alpha: 0.08),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                sensorCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                sensorName,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── 8. LOKASI SATELIT GPS NEO-6M ──────────────────────────────────────────
  Widget _buildGpsSatelliteCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final lat =
          ctrl.latitude.value ?? SmartbandLdrController.staticGpsLatitude;
      final lng =
          ctrl.longitude.value ?? SmartbandLdrController.staticGpsLongitude;
      final sats = ctrl.gpsSatellites.value;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.share_location_rounded,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.tr('smartband.gpsTitle'),
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        context.tr('smartband.satellitesCount', {
                          'count': sats,
                        }),
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusSafe.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    'FIX',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.statusSafe,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    color: Color(0xFF0284C7),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)} (Pelataran Masjidil Haram)',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ctrl.navigateToMap(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('smartband.openMap'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── MODAL QUICK ACTION ────────────────────────────────────────────────────
  void _showQuickActionSheet(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Aksi Cepat Smartband',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.personal_injury_rounded,
                    color: Color(0xFFDC2626),
                  ),
                  title: const Text('Simulasi Deteksi Jatuh (MPU6050)'),
                  subtitle: const Text('Tes alarm darurat dan countdown SOS'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ctrl.triggerFallSimulation();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primaryGold,
                  ),
                  title: const Text('Buka Uji Coba BLE Realtime'),
                  subtitle: const Text('Cek GATT service & raw payload ESP32'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(AppRoutes.smartbandBleTest);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFF0284C7),
                  ),
                  title: const Text('Buka Lokasi Jamaah di Peta'),
                  subtitle: const Text('Pusatkan koordinat GPS Smartband'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ctrl.navigateToMap(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS: ARC GAUGE, PROGRESS RING, TREND CHART & GYRO HORIZON
// ─────────────────────────────────────────────────────────────────────────────

/// Painter untuk Semi-circular Arc Gauge di Kartu Hero (Inspirasi Gambar 1)
class MetricArcGaugePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;

  MetricArcGaugePainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.width * 0.40;
    const strokeWidth = 14.0;

    // Arc membentang dari 145 derajat ke 395 derajat (250 derajat sweep)
    const startAngle = 145.0 * (pi / 180.0);
    const sweepAngle = 250.0 * (pi / 180.0);

    // Track Background
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active Progress Arc
    final activePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activeSweep = sweepAngle * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant MetricArcGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}

/// Painter untuk Lingkaran Progress (Inspirasi Gambar 2)
class CircularProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color primaryColor;
  final Color trackColor;

  CircularProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Active Arc
    final activePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}

/// Painter untuk Grafik Tren Garis Cubic Bezier (Inspirasi Gambar 1)
class CubicBezierTrendChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  final Color fillGradientColor;

  CubicBezierTrendChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.fillGradientColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final minY = dataPoints.reduce(min) * 0.9;
    final maxY = dataPoints.reduce(max) * 1.1;
    final yRange = (maxY - minY) > 0 ? (maxY - minY) : 1.0;

    // Hitung posisi koordinat titik (Offset)
    final points = <Offset>[];
    final dxStep = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * dxStep;
      final normalizedY = (dataPoints[i] - minY) / yRange;
      final y = size.height - (normalizedY * size.height * 0.8) - 10;
      points.add(Offset(x, y));
    }

    // 1. Gambar Garis Kisi Dotted Horizontal
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int g = 1; g <= 3; g++) {
      final gy = size.height * (g / 4);
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    // 2. Buat Path Kurva Cubic Bezier yang mulus
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    // 3. Gambar Gradien Isi di Bawah Garis
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillGradient = LinearGradient(
      colors: [
        fillGradientColor.withValues(alpha: 0.25),
        fillGradientColor.withValues(alpha: 0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(fillPath, fillPaint);

    // 4. Gambar Garis Stroke Kurva
    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // 5. Gambar Titik Dot Lingkaran di setiap data point
    for (final pt in points) {
      final outerDot = Paint()..color = lineColor;
      final innerDot = Paint()..color = Colors.white;

      canvas.drawCircle(pt, 4.5, outerDot);
      canvas.drawCircle(pt, 2.5, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant CubicBezierTrendChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.lineColor != lineColor;
  }
}

/// Painter untuk Artificial Horizon (Gyro MPU6050)
class GyroHorizonPainter extends CustomPainter {
  final double rollDegrees;
  final double pitchDegrees;
  final bool isFall;

  GyroHorizonPainter({
    required this.rollDegrees,
    required this.pitchDegrees,
    required this.isFall,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Clip lingkaran agar tidak meluber keluar bezel
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - 2));
    canvas.clipPath(clipPath);

    // Hitung offset vertikal berdasarkan pitch (-90 s/d +90)
    final pitchOffset = (pitchDegrees / 90.0) * (radius * 0.6);

    // Transformasi rotasi canvas sesuai sudut roll
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rollDegrees * (pi / 180.0));
    canvas.translate(-center.dx, -center.dy);

    // 1. Langit (Atas)
    final skyPaint = Paint()
      ..color = isFall ? const Color(0xFFEF4444) : const Color(0xFF38BDF8);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - radius * 2,
        center.dy - radius * 2 + pitchOffset,
        radius * 4,
        radius * 2,
      ),
      skyPaint,
    );

    // 2. Bumi (Bawah)
    final groundPaint = Paint()
      ..color = isFall ? const Color(0xFF991B1B) : const Color(0xFF78350F);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - radius * 2,
        center.dy + pitchOffset,
        radius * 4,
        radius * 2,
      ),
      groundPaint,
    );

    // 3. Garis Horizon Pemisah
    final horizonPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(center.dx - radius * 2, center.dy + pitchOffset),
      Offset(center.dx + radius * 2, center.dy + pitchOffset),
      horizonPaint,
    );

    canvas.restore();

    // 4. Reticle Crosshair di Tengah (Statik terhadap dial)
    final reticlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(center.dx - 18, center.dy),
      Offset(center.dx - 6, center.dy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx + 6, center.dy),
      Offset(center.dx + 18, center.dy),
      reticlePaint,
    );
    canvas.drawCircle(center, 3.0, reticlePaint..style = PaintingStyle.fill);

    // 5. Bezel Dial Luar
    final bezelPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius - 1.5, bezelPaint);
  }

  @override
  bool shouldRepaint(covariant GyroHorizonPainter oldDelegate) {
    return oldDelegate.rollDegrees != rollDegrees ||
        oldDelegate.pitchDegrees != pitchDegrees ||
        oldDelegate.isFall != isFall;
  }
}
