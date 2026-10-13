import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../controllers/smartband_ldr_controller.dart';

/// Halaman Utama Pemantauan Smartband HajiCare ESP32-S3
/// Mengintegrasikan telemetri kesehatan & keselamatan jemaah haji:
/// 1. Detak Jantung
/// 2. Suhu Tubuh
/// 3. Deteksi Jatuh & Stabilitas Gerak
/// 4. Lokasi Satelit GPS
/// 5. Baterai LiPo
class SmartbandLdrPage extends GetView<SmartbandLdrController> {
  const SmartbandLdrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : Colors.white;

    // Otomatis aktifkan mode simulasi jika hardware belum terhubung
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

              // ── 2. HERO METRIC ARC GAUGE (Fokus Sensor Terpilih) ───────────
              _buildHeroMetricArcCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 3. RINGKASAN SENSOR KESEHATAN (Interactive Vitals Grid) ────
              _buildVitalsSummaryCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 4. GRAFIK TREN SENSOR BEZIER SPLINE ───────────────────────
              _buildTrendSectionCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 5. DETEKSI JATUH & KEAMANAN JAMAAH ────────────────────────
              _buildFallDetectionCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── 6. LOKASI TERKINI JAMAAH (PREVIEW MAP CARTO) ──────────────
              _buildGpsSatelliteCard(context, ctrl),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── 0. BANNER PERINGATAN DARURAT JATUH ─────────────────────────────────────
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
              color: const Color(0xFFDC2626).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 26,
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
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.25,
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
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                context.tr('smartband.autoSosIn', {
                  'seconds': '${ctrl.fallCountdownSeconds.value}',
                }),
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => ctrl.cancelFallAlert(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 0,
              ),
              child: FittedBox(
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
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isConn = ctrl.isConnected;
      final isSim = ctrl.isSimulationMode.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
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
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${ctrl.braceletId.value} • ${ctrl.relativeTimeText.value}',
                    style: AppTypography.captionSmall.copyWith(
                      color: bodyColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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

  // ── 2. HERO METRIC ARC GAUGE (Fokus Sensor Terpilih) ──────────────────────
  Widget _buildHeroMetricArcCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final isDark = AppColors.isDark(context);
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
        case 1: // MCP9808 Suhu Tubuh
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
          statusPillText = 'GPS AKTIF';
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          children: [
            // Judul Sensor Aktif
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                heroTitle,
                style: AppTypography.titleMedium.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Semi-circular Arc Gauge Visualizer (Proporsional & Rapi)
            SizedBox(
              width: 190,
              height: 145,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(190, 145),
                      painter: MetricArcGaugePainter(
                        progress: arcPercent,
                        primaryColor: arcColor,
                        trackColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 32,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            heroValue,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: headingColor,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          heroUnit,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: bodyColor.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
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

  // ── 3. RINGKASAN SENSOR KESEHATAN (Interactive Vitals Grid) ───────────────
  Widget _buildVitalsSummaryCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final hr = ctrl.currentHeartRate;
      final temp = ctrl.currentTemperature;
      final stability = ctrl.stabilityScore.value;
      final bat = ctrl.currentBattery;
      final selected = ctrl.selectedSensorIndex.value;

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
                          'PEMANTAUAN FISIK & DAYA',
                          style: AppTypography.labelLarge.copyWith(
                            color: bodyColor.withValues(alpha: 0.65),
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ringkasan 4 Parameter',
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
                    horizontal: 9,
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
                        size: 13,
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
            const SizedBox(height: 16),

            // Baris 4 Sensor Ringkas Interaktif
            Row(
              children: [
                Expanded(
                  child: _buildInteractiveVitalItem(
                    context,
                    index: 0,
                    isSelected: selected == 0,
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFEF4444),
                    valueText: hr > 0 ? '$hr' : '--',
                    unit: 'BPM',
                    title: context.tr('smartband.heartRateLabel'),
                    subtitle: hr >= 100
                        ? context.tr('smartband.warning')
                        : context.tr('smartband.normal'),
                    onTap: () => ctrl.selectSensor(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInteractiveVitalItem(
                    context,
                    index: 1,
                    isSelected: selected == 1,
                    icon: Icons.device_thermostat_rounded,
                    iconColor: const Color(0xFFD4A857),
                    valueText: temp.toStringAsFixed(1),
                    unit: '°C',
                    title: context.tr('smartband.tempLabel'),
                    subtitle: temp >= 37.5
                        ? context.tr('smartband.warning')
                        : context.tr('smartband.normal'),
                    onTap: () => ctrl.selectSensor(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInteractiveVitalItem(
                    context,
                    index: 2,
                    isSelected: selected == 2,
                    icon: Icons.directions_walk_rounded,
                    iconColor: const Color(0xFF10B981),
                    valueText: '$stability',
                    unit: '%',
                    title: 'Stabilitas',
                    subtitle: 'Normal',
                    onTap: () => ctrl.selectSensor(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInteractiveVitalItem(
                    context,
                    index: 4,
                    isSelected: selected == 4,
                    icon: Icons.battery_charging_full_rounded,
                    iconColor: const Color(0xFF0284C7),
                    valueText: '$bat',
                    unit: '%',
                    title: context.tr('smartband.batteryLabel'),
                    subtitle: 'LiPo 3.96V',
                    onTap: () => ctrl.selectSensor(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInteractiveVitalItem(
    BuildContext context, {
    required int index,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required String valueText,
    required String unit,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected
                    ? AppColors.darkSurfaceContainerHighest
                    : AppColors.darkSurfaceContainer)
              : (isSelected
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGold
                : (isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: headingColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    valueText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: headingColor,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: bodyColor.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. GRAFIK TREN SENSOR BEZIER CURVE ─────────────────────────────────────
  Widget _buildTrendSectionCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    return Obx(() {
      final period = ctrl.trendPeriod.value;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('smartband.trendTitle'),
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Selector Periode (Hari Ini / Minggu / Bulan)
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : const Color(0xFFF1F5F9),
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
            const SizedBox(height: 18),

            // Cubic Bezier Spline Chart (Emerald & Soft Gradient)
            SizedBox(
              height: 150,
              child: CustomPaint(
                size: const Size(double.infinity, 150),
                painter: CubicBezierTrendChartPainter(
                  dataPoints: ctrl.trendData.toList(),
                  lineColor: const Color(0xFF10B981),
                  fillGradientColor: const Color(0xFF10B981),
                  gridColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Sumbu X (Hari)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAxisLabel(context, 'Sen'),
                _buildAxisLabel(context, 'Sel'),
                _buildAxisLabel(context, 'Rab'),
                _buildAxisLabel(context, 'Kam'),
                _buildAxisLabel(context, 'Jum'),
                _buildAxisLabel(context, 'Sab'),
                _buildAxisLabel(context, 'Min'),
              ],
            ),
            const SizedBox(height: 16),

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
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.darkSurfaceContainerHighest
                      : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.05,
                      ),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? headingColor
                    : bodyColor.withValues(alpha: 0.7),
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAxisLabel(BuildContext context, String text) {
    final bodyColor = AppColors.textBodyColor(context);
    return Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: bodyColor.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
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
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: AppTypography.captionSmall.copyWith(
                color: bodyColor.withValues(alpha: 0.7),
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
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
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
                    color: bodyColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5. DETEKSI JATUH & KEAMANAN JAMAAH ─────────────────────────────────────
  Widget _buildFallDetectionCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isFall = ctrl.isFallDetected.value;
      final stability = ctrl.stabilityScore.value;

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
                      const SizedBox(height: 1),
                      Text(
                        'Sensor Keseimbangan & Deteksi Gerak Tubuh',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isFall
                        ? AppColors.statusDanger.withValues(alpha: 0.15)
                        : AppColors.statusSafe.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    isFall ? 'Jatuh' : 'Stabil',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isFall
                          ? AppColors.statusDanger
                          : AppColors.statusSafe,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Card Penjelasan Ramah Lansia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kondisi Postur',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: bodyColor.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(ctrl.postureKey.value),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isFall
                                ? AppColors.statusDanger
                                : AppColors.statusSafe,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tingkat Stabilitas',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: bodyColor.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$stability% (Aman)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: headingColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

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

  // ── 6. LOKASI TERKINI JAMAAH (PREVIEW MAP CARTO) ──────────────────────────
  Widget _buildGpsSatelliteCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final lat =
          ctrl.latitude.value ?? SmartbandLdrController.staticGpsLatitude;
      final lng =
          ctrl.longitude.value ?? SmartbandLdrController.staticGpsLongitude;
      final target = LatLng(lat, lng);
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
                          'Lokasi Terkini Smartband',
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
                          color: bodyColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusSafe.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: const Text(
                    'GPS FIX',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.statusSafe,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mini Map Preview dengan CARTO Basemap
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                height: 145,
                width: double.infinity,
                child: Stack(
                  children: [
                    fmap.FlutterMap(
                      options: fmap.MapOptions(
                        initialCenter: target,
                        initialZoom: 16.0,
                        interactionOptions: const fmap.InteractionOptions(
                          flags: fmap.InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        fmap.TileLayer(
                          urlTemplate: isDark
                              ? AppConstants.cartoDarkMatterUrl
                              : AppConstants.cartoVoyagerUrl,
                          userAgentPackageName: 'com.example.hajicare',
                        ),
                        fmap.MarkerLayer(
                          markers: [
                            fmap.Marker(
                              point: target,
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryGold,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const fmap.RichAttributionWidget(
                          attributions: [
                            fmap.TextSourceAttribution('OSM / CARTO'),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark ? AppColors.espressoDark : Colors.white)
                                  .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 12,
                              color: AppColors.primaryGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Area Masjidil Haram, Makkah',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.espressoDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Buka Peta
            ElevatedButton.icon(
              onPressed: () => ctrl.navigateToMap(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.espressoDark,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS: ARC GAUGE, PROGRESS RING & TREND CHART
// ─────────────────────────────────────────────────────────────────────────────

/// Painter untuk Semi-circular Arc Gauge di Kartu Hero
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
    const strokeWidth = 13.0;

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
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}

/// Painter untuk Lingkaran Progress
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
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}

/// Painter untuk Grafik Tren Garis Cubic Bezier
class CubicBezierTrendChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  final Color fillGradientColor;
  final Color gridColor;

  CubicBezierTrendChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.fillGradientColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final minY = dataPoints.reduce(min) * 0.9;
    final maxY = dataPoints.reduce(max) * 1.1;
    final yRange = (maxY - minY) > 0 ? (maxY - minY) : 1.0;

    final points = <Offset>[];
    final dxStep = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * dxStep;
      final normalizedY = (dataPoints[i] - minY) / yRange;
      final y = size.height - (normalizedY * size.height * 0.78) - 10;
      points.add(Offset(x, y));
    }

    // 1. Garis Kisi Horizontal
    final gridPaint = Paint()
      ..color = gridColor
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

    // 3. Gradien Isi di Bawah Garis
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillGradient = LinearGradient(
      colors: [
        fillGradientColor.withValues(alpha: 0.22),
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

    // 4. Garis Stroke Kurva
    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // 5. Titik Dot Lingkaran di setiap data point
    for (final pt in points) {
      final outerDot = Paint()..color = lineColor;
      final innerDot = Paint()..color = Colors.white;

      canvas.drawCircle(pt, 4.0, outerDot);
      canvas.drawCircle(pt, 2.0, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant CubicBezierTrendChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
