import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../controllers/smartband_ldr_controller.dart';
import '../widgets/battery_optimization_sheet.dart';
import '../services/smartband_ble_service.dart';

/// Halaman Utama Pemantauan Smartband HajiCare ESP32-S3 Pro v2.0
/// Telemetri dinamis murni dari sensor:
/// 1. MAX30102: Detak Jantung & Kontak Kulit
/// 2. DFRobot MCP9808: Suhu Sensor Presisi
/// 3. MPU6050: Motion totalG & Monitor Jatuh
/// 4. GPS ATGM336H: Satelit & Posisi
/// 5. Dynamic Safe Radius: Jarak & Peringatan
/// 6. OLED SSD1306 128x64 & Action Button
class SmartbandLdrPage extends GetView<SmartbandLdrController> {
  const SmartbandLdrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: HajiCareHeader(
        title: 'HAJICARE SMARTBAND PRO',
        subtitle: 'ESP32-S3 • ATGM336H • MAX30102 • MCP9808 • MPU6050',
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
              // 0A. BANNER PERINGATAN DARURAT JATUH (MPU6050)
              _buildEmergencyFallBanner(context, ctrl),

              // 0B. BANNER PERINGATAN DARURAT TOMBOL SOS
              _buildEmergencySosBanner(context, ctrl),

              // 0C. BANNER PERINGATAN KELUAR BATAS AMAN (SAFE RADIUS)
              _buildSafeRadiusAlertBanner(context, ctrl),

              // 1. STATUS GELANG & KONTROL KONEKSI BLE DINAMIS
              _buildTopStatusBar(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // 2. HERO METRIC ARC GAUGE (Fokus Sensor Terpilih)
              _buildHeroMetricArcCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // 3. RINGKASAN SENSOR HARDWARE (6 Sensor Telemetri Dinamis)
              _buildVitalsSummaryCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // 4. KONTROL DYNAMIC SAFE RADIUS (Sinkronisasi BLE ke Gelang)
              _buildSafeRadiusControlCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // 5. LAYAR OLED SSD1306 128x64 (Pergelangan Tangan) & KONTROL PAGE
              _buildOledScreenCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // 6. GRAFIK TREN SENSOR DINAMIS (Riwayat Data Telemetri Nyata)
              _buildTrendSectionCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // 7. LOKASI SATELIT GPS ATGM336H (Map Live)
              _buildGpsSatelliteCard(context, ctrl),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 0A. BANNER PERINGATAN DARURAT JATUH (MPU6050)
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
                      Text(
                        'PERINGATAN JATUH TERDETEKSI!',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sensor MPU6050 mendeteksi impak & perubahan postur mendadak.',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
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
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                'Kirim sinyal darurat dalam ${ctrl.fallCountdownSeconds.value} detik...',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => ctrl.cancelAlarm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Saya Aman (Batalkan Alarm)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    });
  }

  // 0B. BANNER PERINGATAN DARURAT TOMBOL SOS
  Widget _buildEmergencySosBanner(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    return Obx(() {
      if (!ctrl.isSosButtonPressed.value) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.gapCards),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB91C1C).withValues(alpha: 0.4),
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
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sos_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOMBOL SOS SMARTBAND AKTIF!',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tombol Action fisik pada gelang telah ditekan & ditahan 3 detik.',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    ctrl.isSosTransmitted.value
                        ? Icons.check_circle_rounded
                        : Icons.wifi_tethering_rounded,
                    color: ctrl.isSosTransmitted.value
                        ? const Color(0xFF4ADE80)
                        : Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ctrl.isSosTransmitted.value
                        ? 'Sinyal Darurat Terkirim ke Pendamping'
                        : 'Meneruskan Sinyal Darurat ke Pendamping...',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => ctrl.cancelAlarm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFB91C1C),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Matikan Alarm SOS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    });
  }

  // 0C. BANNER PERINGATAN KELUAR BATAS AMAN
  Widget _buildSafeRadiusAlertBanner(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    return Obx(() {
      if (!ctrl.radiusAlertActive.value) return const SizedBox.shrink();

      final dist = ctrl.currentDistanceM.value;
      final rad = ctrl.safeRadiusMeters.value;

      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.gapCards),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEA580C).withValues(alpha: 0.35),
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
                    Icons.radar_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERINGATAN: DI LUAR BATAS AMAN!',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dist != null
                            ? 'Jarak jamaah (${dist.toStringAsFixed(1)} m) telah melebihi batas radius aman (${rad.round()} m).'
                            : 'Jamaah berada di luar batas aman pendamping.',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => ctrl.cancelAlarm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFEA580C),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Senyapkan Getaran Gelang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    });
  }

  // 1. STATUS GELANG & KONTROL KONEKSI BLE DINAMIS
  Widget _buildTopStatusBar(BuildContext context, SmartbandLdrController ctrl) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isConn = ctrl.isConnected;
      final isBusy = ctrl.isBusy;
      final status = ctrl.bleStatus.value;

      Color dotColor = AppColors.statusDanger;
      String statusTitle = 'Gelang Belum Terhubung';

      if (isConn) {
        dotColor = AppColors.statusSafe;
        statusTitle = 'Smartband Terhubung (HCG-001)';
      } else if (status == SmartbandBleStatus.scanning) {
        dotColor = AppColors.primaryGold;
        statusTitle = 'Memindai Sinyal Gelang...';
      } else if (status == SmartbandBleStatus.connecting) {
        dotColor = AppColors.primaryGold;
        statusTitle = 'Menghubungkan ke Gelang...';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isConn
                ? AppColors.statusSafe.withValues(alpha: 0.3)
                : (isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFFE2E8F0)),
            width: isConn ? 1.5 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: isConn
                  ? AppColors.statusSafe.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: isDark ? 0.35 : 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: isConn
                    ? [
                        BoxShadow(
                          color: AppColors.statusSafe.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
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
                      statusTitle,
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isConn
                        ? 'Telemetri Realtime • ${ctrl.relativeTimeText.value}'
                        : 'Nyalakan ESP32-S3 lalu hubungkan via BLE',
                    style: AppTypography.captionSmall.copyWith(
                      color: bodyColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => BatteryOptimizationSheet.show(context),
              icon: const Icon(Icons.battery_saver_rounded, size: 20),
              tooltip: 'Setelan Latar Belakang 24/7',
              color: AppColors.primaryGold,
            ),
            const SizedBox(width: 4),
            isConn
                ? OutlinedButton.icon(
                    onPressed: () => ctrl.disconnectSmartband(),
                    icon: const Icon(Icons.bluetooth_disabled_rounded, size: 16),
                    label: const Text('Putus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusDanger,
                      side: BorderSide(
                        color: AppColors.statusDanger.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 34),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: isBusy ? null : () => ctrl.connectSmartband(),
                    icon: isBusy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bluetooth_searching_rounded, size: 16),
                    label: Text(isBusy ? 'Memproses...' : 'Hubungkan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
          ],
        ),
      );
    });
  }

  // 2. HERO METRIC ARC GAUGE (Fokus Sensor Terpilih)
  Widget _buildHeroMetricArcCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    return Obx(() {
      final isConn = ctrl.isConnected;
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
        case 1: // DFRobot MCP9808 Suhu
          heroTitle = 'MCP9808 Suhu Sensor (°C)';
          final temp = ctrl.mcpTemperature.value;
          heroValue = temp != null ? temp.toStringAsFixed(1) : '--.-';
          heroUnit = '°C (Presisi 0.125°C)';
          arcPercent = (temp != null && !temp.isNaN && !temp.isInfinite)
              ? ((temp - 20.0) / (42.0 - 20.0)).clamp(0.05, 1.0)
              : 0.0;
          arcColor = const Color(0xFFD4A857);
          statusPillText = !isConn
              ? 'MENUNGGU BLE'
              : (temp != null
                    ? (temp >= 37.5 ? 'WASPADA SUHU TINGGI' : 'SENSOR AKTIF • NORMAL')
                    : 'MENGUKUR...');
          statusPillBg = (temp != null && temp >= 37.5)
              ? AppColors.statusWarning.withValues(alpha: 0.15)
              : AppColors.statusSafe.withValues(alpha: 0.15);
          statusPillColor = (temp != null && temp >= 37.5)
              ? AppColors.statusWarning
              : AppColors.statusSafe;
          break;

        case 2: // MPU6050 Motion G, Fall & Pedometer
          heroTitle = 'MPU6050 Motion & Pedometer';
          final g = ctrl.accelG.value;
          final steps = ctrl.effectiveSteps;
          final stepDist = ctrl.smartbandStepDistanceM.value > 0
              ? ctrl.smartbandStepDistanceM.value
              : (steps * SmartbandLdrController.strideLengthMeters);
          heroValue = g != null ? g.toStringAsFixed(2) : '--';
          heroUnit = 'g • $steps Langkah (${stepDist.toStringAsFixed(1)} m)';
          arcPercent = g != null ? (g / 3.0).clamp(0.05, 1.0) : 0.0;
          arcColor = ctrl.isFallDetected.value
              ? AppColors.statusDanger
              : const Color(0xFF10B981);
          statusPillText = !isConn
              ? 'MENUNGGU BLE'
              : (ctrl.isFallDetected.value
                    ? 'JATUH TERDETEKSI'
                    : '${ctrl.fallStatus.value} • $steps LANGKAH');
          statusPillBg = ctrl.isFallDetected.value
              ? AppColors.statusDanger.withValues(alpha: 0.15)
              : AppColors.statusSafe.withValues(alpha: 0.15);
          statusPillColor = ctrl.isFallDetected.value
              ? AppColors.statusDanger
              : AppColors.statusSafe;
          break;

        case 3: // ATGM336H GPS
          heroTitle = 'GPS ATGM336H Satelit & Koordinat';
          final sats = ctrl.gpsSatellites.value;
          heroValue = sats != null ? '$sats' : '--';
          heroUnit = ctrl.isGpsFix.value ? 'Sats (GPS FIX)' : 'Sats (Mencari)';
          arcPercent = sats != null ? (sats / 12.0).clamp(0.05, 1.0) : 0.0;
          arcColor = const Color(0xFF0284C7);
          statusPillText = !isConn
              ? 'MENUNGGU BLE'
              : (ctrl.isGpsFix.value ? 'GPS FIX TERKUNCI' : 'MENCARI SINYAL');
          statusPillBg = ctrl.isGpsFix.value
              ? AppColors.statusSafe.withValues(alpha: 0.15)
              : AppColors.primaryGold.withValues(alpha: 0.15);
          statusPillColor = ctrl.isGpsFix.value
              ? AppColors.statusSafe
              : AppColors.primaryGold;
          break;

        case 4: // Dynamic Safe Radius
          heroTitle = 'Dynamic Safe Radius (Batas Aman)';
          final dist = ctrl.currentDistanceM.value;
          final rad = ctrl.safeRadiusMeters.value;
          heroValue = rad <= 0
              ? 'OFF'
              : (dist != null ? dist.toStringAsFixed(1) : '--');
          heroUnit = rad <= 0 ? 'Radius Nonaktif' : 'Meter ke Pendamping';
          arcPercent = (dist != null && rad > 0 && !dist.isNaN && !dist.isInfinite)
              ? (dist / (rad * 1.5)).clamp(0.05, 1.0)
              : 0.0;
          arcColor = ctrl.radiusAlertActive.value
              ? AppColors.statusDanger
              : const Color(0xFF0D9488);
          statusPillText = !isConn
              ? 'MENUNGGU BLE'
              : (rad <= 0
                    ? 'SAFE RADIUS OFF'
                    : (dist == null
                          ? 'MENUNGGU GPS PENDAMPING'
                          : (ctrl.radiusAlertActive.value
                                ? 'DI LUAR RADIUS (${dist.toStringAsFixed(1)} m > ${rad.round()} m)'
                                : 'DALAM RADIUS AMAN (Batas ${rad.round()} m)')));
          statusPillBg = ctrl.radiusAlertActive.value
              ? AppColors.statusDanger.withValues(alpha: 0.15)
              : const Color(0xFF0D9488).withValues(alpha: 0.15);
          statusPillColor = ctrl.radiusAlertActive.value
              ? AppColors.statusDanger
              : const Color(0xFF0D9488);
          break;

        case 5: // Action Button, SOS & INMP441 AI Mic
          heroTitle = 'Action Button • SOS & AI Voice (INMP441)';
          final isSos = ctrl.isSosButtonPressed.value;
          final isAiRec = ctrl.isSmartbandRecordingVoice.value;
          final steps = ctrl.effectiveSteps;
          heroValue = isSos
              ? 'SOS!'
              : (isAiRec ? 'REKAM' : '$steps');
          heroUnit = isSos
              ? 'SINYAL DARURAT AKTIF'
              : (isAiRec ? 'MENDENGARKAN SUARA (8kHz PCM)' : 'Langkah • Tombol Siap');
          arcPercent = isSos || isAiRec
              ? 1.0
              : (steps > 0 ? (steps / 1000.0).clamp(0.1, 1.0) : 0.25);
          arcColor = isSos
              ? AppColors.statusDanger
              : (isAiRec ? const Color(0xFF8B5CF6) : const Color(0xFFEF4444));
          statusPillText = !isConn
              ? 'MENUNGGU BLE'
              : (isSos
                    ? 'DARURAT SOS AKTIF'
                    : (isAiRec
                          ? 'MIKROFON INMP441 AKTIF'
                          : '1x Page • 2x AI Voice • Hold 3s SOS'));
          statusPillBg = isSos
              ? AppColors.statusDanger.withValues(alpha: 0.15)
              : AppColors.primaryGold.withValues(alpha: 0.15);
          statusPillColor = isSos
              ? AppColors.statusDanger
              : AppColors.primaryGold;
          break;

        default: // MAX30102 Detak Jantung BPM
          heroTitle = 'MAX30102 Detak Jantung';
          final hr = ctrl.heartRate.value;
          final finger = ctrl.fingerDetected.value;
          heroValue = (hr != null && hr > 0) ? '$hr' : '--';
          heroUnit = !finger
              ? 'TEMPELKAN KULIT / JARI'
              : (hr != null && hr > 0 ? 'BPM' : 'Mendeteksi denyut nadi...');
          arcPercent = (hr != null && hr > 0)
              ? ((hr - 40) / (140 - 40)).clamp(0.05, 1.0)
              : 0.0;
          arcColor = const Color(0xFFFF2E63);
          statusPillText = !isConn
              ? 'MENUNGGU BLE'
              : (!finger
                    ? 'KULIT TIDAK TERDETEKSI'
                    : (hr != null && hr >= 100
                          ? 'DENYUT CEPAT'
                          : 'SENSOR AKTIF'));
          statusPillBg = (finger && hr != null && hr > 0)
              ? AppColors.statusSafe.withValues(alpha: 0.15)
              : AppColors.primaryGold.withValues(alpha: 0.15);
          statusPillColor = (finger && hr != null && hr > 0)
              ? AppColors.statusSafe
              : AppColors.primaryGold;
          break;
      }

      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          children: [
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

            // Semi-circular Arc Gauge Visualizer
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
                    bottom: 22,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          heroValue,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: headingColor,
                          ),
                        ),
                        Text(
                          heroUnit,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBodyColor(context).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: statusPillBg,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                statusPillText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusPillColor,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // 3. RINGKASAN SENSOR HARDWARE (Interactive Vitals Grid)
  Widget _buildVitalsSummaryCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);

    return Obx(() {
      final selected = ctrl.selectedSensorIndex.value;
      final isConn = ctrl.isConnected;

      final hr = ctrl.heartRate.value;
      final finger = ctrl.fingerDetected.value;
      final temp = ctrl.mcpTemperature.value;
      final g = ctrl.accelG.value;
      final sats = ctrl.gpsSatellites.value;
      final dist = ctrl.currentDistanceM.value;
      final rad = ctrl.safeRadiusMeters.value;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sensors_rounded,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TELEMETRI SENSOR DINAMIS (ESP32-S3)',
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Baris 1: MAX30102 & MCP9808
            Row(
              children: [
                Expanded(
                  child: _buildInteractiveVitalItem(
                    context,
                    index: 0,
                    isSelected: selected == 0,
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFFF2E63),
                    valueText: isConn && hr != null && hr > 0 ? '$hr' : '--',
                    unit: 'BPM',
                    title: 'MAX30102 Jantung',
                    subtitle: !isConn
                        ? 'Menunggu BLE'
                        : (!finger ? 'Tempelkan Kulit' : 'Sensor Aktif'),
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
                    valueText: isConn && temp != null
                        ? temp.toStringAsFixed(1)
                        : '--.-',
                    unit: '°C',
                    title: 'MCP9808 Suhu',
                    subtitle: !isConn
                        ? 'Menunggu BLE'
                        : (temp != null ? 'Presisi 0.125°C' : 'Membaca...'),
                    onTap: () => ctrl.selectSensor(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Baris 2: MPU6050 & GPS ATGM336H
            Row(
              children: [
                Expanded(
                  child: _buildInteractiveVitalItem(
                    context,
                    index: 2,
                    isSelected: selected == 2,
                    icon: Icons.directions_run_rounded,
                    iconColor: const Color(0xFF10B981),
                    valueText: isConn && g != null ? g.toStringAsFixed(2) : '--',
                    unit: 'g',
                    title: 'MPU6050 Motion',
                    subtitle: !isConn
                        ? 'Menunggu BLE'
                        : (ctrl.isFallDetected.value
                              ? 'JATUH!'
                              : '${ctrl.effectiveSteps} lkh • ${ctrl.fallStatus.value}'),
                    onTap: () => ctrl.selectSensor(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInteractiveVitalItem(
                    context,
                    index: 3,
                    isSelected: selected == 3,
                    icon: Icons.satellite_alt_rounded,
                    iconColor: const Color(0xFF0284C7),
                    valueText: isConn && sats != null ? '$sats' : '--',
                    unit: 'Sats',
                    title: 'GPS ATGM336H',
                    subtitle: !isConn
                        ? 'Menunggu BLE'
                        : (ctrl.isGpsFix.value ? 'GPS FIX' : 'Mencari...'),
                    onTap: () => ctrl.selectSensor(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Baris 3: Dynamic Safe Radius & Action Button SOS / AI
            Row(
              children: [
                Expanded(
                  child: _buildInteractiveVitalItem(
                    context,
                    index: 4,
                    isSelected: selected == 4,
                    icon: Icons.radar_rounded,
                    iconColor: const Color(0xFF0D9488),
                    valueText: rad <= 0
                        ? 'OFF'
                        : (isConn && dist != null ? dist.toStringAsFixed(1) : '--'),
                    unit: rad <= 0 ? '' : 'Meter',
                    title: 'Safe Radius',
                    subtitle: isConn
                        ? (rad <= 0
                              ? 'Radius Nonaktif'
                              : (dist != null
                                    ? (ctrl.radiusAlertActive.value
                                          ? 'Di Luar Batas!'
                                          : 'Ke Pendamping • Batas ${rad.round()}m')
                                    : 'Batas ${rad.round()}m • Mencari GPS'))
                        : 'Menunggu BLE',
                    onTap: () => ctrl.selectSensor(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInteractiveVitalItem(
                    context,
                    index: 5,
                    isSelected: selected == 5,
                    icon: ctrl.isSmartbandRecordingVoice.value
                        ? Icons.mic_rounded
                        : Icons.touch_app_rounded,
                    iconColor: ctrl.isSmartbandRecordingVoice.value
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFFEF4444),
                    valueText: ctrl.isSosButtonPressed.value
                        ? 'SOS!'
                        : (ctrl.isSmartbandRecordingVoice.value ? 'REKAM' : 'SIAP'),
                    unit: ctrl.isSmartbandRecordingVoice.value ? 'AI' : 'SOS',
                    title: 'Tombol Action',
                    subtitle: ctrl.isSosButtonPressed.value
                        ? 'DARURAT SOS'
                        : (ctrl.isSmartbandRecordingVoice.value
                              ? 'Mic INMP441 Aktif'
                              : '1x Page • 2x AI • 3s SOS'),
                    onTap: () => ctrl.selectSensor(5),
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
            Row(
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
            const SizedBox(height: 4),
            Container(
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
          ],
        ),
      ),
    );
  }

  // 4. MONITOR SAFE RADIUS PENDAMPING & PEDOMETER (Sinkronisasi BLE ke Gelang)
  Widget _buildSafeRadiusControlCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isConn = ctrl.isConnected;
      final currentRadius = ctrl.safeRadiusMeters.value;
      final dist = ctrl.currentDistanceM.value;
      final canEdit = ctrl.canManageSafeRadius;
      final pendampingName = ctrl.activePendampingName;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFF0D9488),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canEdit
                        ? 'KONTROL DYNAMIC SAFE RADIUS'
                        : 'MONITOR SAFE RADIUS PENDAMPING',
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    currentRadius <= 0 ? 'OFF' : '${currentRadius.round()} m',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              canEdit
                  ? 'Ubah batas radius toleransi pergerakan jamaah langsung ke memori hardware gelang via BLE.'
                  : 'Batas radius aman diatur secara terpusat oleh Pendamping Rombongan dan disinkronkan otomatis ke memori gelang via BLE.',
              style: AppTypography.caption.copyWith(color: bodyColor),
            ),
            const SizedBox(height: 12),

            if (canEdit) ...[
              // Preset Buttons (Hanya muncul untuk Pendamping / Admin): 50m, 100m, 150m, 200m, 300m, 500m
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRadiusChip(50, currentRadius, () => ctrl.setSafeRadius(50)),
                    const SizedBox(width: 8),
                    _buildRadiusChip(100, currentRadius, () => ctrl.setSafeRadius(100)),
                    const SizedBox(width: 8),
                    _buildRadiusChip(150, currentRadius, () => ctrl.setSafeRadius(150)),
                    const SizedBox(width: 8),
                    _buildRadiusChip(200, currentRadius, () => ctrl.setSafeRadius(200)),
                    const SizedBox(width: 8),
                    _buildRadiusChip(300, currentRadius, () => ctrl.setSafeRadius(300)),
                    const SizedBox(width: 8),
                    _buildRadiusChip(500, currentRadius, () => ctrl.setSafeRadius(500)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // Badge Read-Only untuk Jamaah (Hanya Pendamping yang dapat mengubah Safe Radius)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.isDark(context)
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.isDark(context)
                        ? AppColors.darkCardBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dikendalikan oleh $pendampingName • Batas Aktif: ${currentRadius.round()} Meter',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: bodyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Distance Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ctrl.radiusAlertActive.value
                    ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                    : const Color(0xFF0D9488).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: ctrl.radiusAlertActive.value
                      ? const Color(0xFFDC2626).withValues(alpha: 0.3)
                      : const Color(0xFF0D9488).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ctrl.radiusAlertActive.value
                        ? Icons.warning_rounded
                        : Icons.check_circle_rounded,
                    color: ctrl.radiusAlertActive.value
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF0D9488),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentRadius <= 0
                          ? 'Safe Radius Nonaktif (OFF)'
                          : (dist != null
                                ? 'Jarak ke Pendamping: ${dist.toStringAsFixed(1)} m • Batas: ${currentRadius.round()} m'
                                : (isConn
                                      ? 'Menghitung koordinat GPS pendamping...'
                                      : 'Menunggu Smartband Terhubung...')),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ctrl.radiusAlertActive.value
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Kontrol Pedometer MPU6050 & Mikrofon AI INMP441
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !isConn
                        ? null
                        : () => ctrl.isSmartbandRecordingVoice.value
                              ? ctrl.stopSmartbandMic()
                              : ctrl.startSmartbandMic(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ctrl.isSmartbandRecordingVoice.value
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0D9488),
                      side: BorderSide(
                        color: ctrl.isSmartbandRecordingVoice.value
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF0D9488),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    icon: Icon(
                      ctrl.isSmartbandRecordingVoice.value
                          ? Icons.stop_circle_rounded
                          : Icons.mic_rounded,
                      size: 16,
                    ),
                    label: Text(
                      ctrl.isSmartbandRecordingVoice.value
                          ? 'Stop Mic AI'
                          : 'Rekam Suara AI',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !isConn ? null : () => ctrl.resetStepDistance(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: Text(
                      'Reset Langkah (${ctrl.effectiveSteps})',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRadiusChip(double meters, double current, VoidCallback onTap) {
    final isSelected = (current.round() == meters.round());
    final labelText = meters <= 0 ? 'OFF (0m)' : '${meters.round()} Meter';
    return ChoiceChip(
      label: Text(labelText),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF0D9488),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : const Color(0xFF0D9488),
      ),
    );
  }

  // 5. LAYAR OLED SSD1306 128x64 & KONTROL PAGE (7 Halaman)
  Widget _buildOledScreenCard(BuildContext context, SmartbandLdrController ctrl) {
    final headingColor = AppColors.textHeadingColor(context);

    return Obx(() {
      final page = ctrl.oledPage.value.clamp(0, 6);
      final isConn = ctrl.isConnected;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tv_rounded,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SSD1306 0.96" OLED PERGELANGAN TANGAN',
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Halaman ${page + 1}/7',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Frame Layar OLED Hitam 128x64 Asli Hardware
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // OLED Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HAJICARE',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        isConn ? 'BLE ON' : 'BLE --',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isConn ? const Color(0xFF4ADE80) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white, height: 8, thickness: 1),
                  const SizedBox(height: 4),

                  // OLED Dynamic Content (Tergantung Halaman Terpilih / Alarm)
                  _buildOledPageContent(ctrl, page),

                  const SizedBox(height: 8),
                  const Divider(color: Colors.white, height: 8, thickness: 0.5),

                  // OLED Footer Dots (7 Halaman)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (i) {
                      final active = (i == page);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 6 : 4,
                        height: active ? 6 : 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? Colors.white : const Color(0xFF475569),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Kontrol Tombol Pindah Halaman Remote ke Gelang via BLE
            Text(
              'Pindah Halaman OLED via Perintah BLE:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildOledPageButton('0: HR', 0, page, () => ctrl.setOledPage(0)),
                  const SizedBox(width: 6),
                  _buildOledPageButton('1: GPS', 1, page, () => ctrl.setOledPage(1)),
                  const SizedBox(width: 6),
                  _buildOledPageButton('2: Suhu', 2, page, () => ctrl.setOledPage(2)),
                  const SizedBox(width: 6),
                  _buildOledPageButton('3: Jatuh', 3, page, () => ctrl.setOledPage(3)),
                  const SizedBox(width: 6),
                  _buildOledPageButton('4: Langkah', 4, page, () => ctrl.setOledPage(4)),
                  const SizedBox(width: 6),
                  _buildOledPageButton('5: Radius', 5, page, () => ctrl.setOledPage(5)),
                  const SizedBox(width: 6),
                  _buildOledPageButton('6: AI Voice', 6, page, () => ctrl.setOledPage(6)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOledPageContent(SmartbandLdrController ctrl, int page) {
    final hr = ctrl.heartRate.value;
    final finger = ctrl.fingerDetected.value;
    final temp = ctrl.mcpTemperature.value;
    final g = ctrl.accelG.value;
    final sats = ctrl.gpsSatellites.value;
    final lat = ctrl.latitude.value;
    final lng = ctrl.longitude.value;
    final dist = ctrl.currentDistanceM.value;
    final rad = ctrl.safeRadiusMeters.value;

    // Prioritas tampilan layar darurat OLED sama persis dengan firmware v2.8.1
    if (ctrl.isSosButtonPressed.value) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOS!',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          Text(
            'SINYAL DARURAT AKTIF',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.white,
            ),
          ),
          Text(
            '1x tekan: matikan getar',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }

    if (ctrl.isFallDetected.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TERJATUH!',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          Text(
            'Kirim darurat ${ctrl.fallCountdownSeconds.value} dtk',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.white,
            ),
          ),
          const Text(
            'Tekan 1x jika aman',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }

    if (ctrl.radiusAlertActive.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERINGATAN JARAK! MENJAUH',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          Text(
            dist != null ? '${dist.round()}m' : 'JAUH!',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Batas: ${rad.round()}m | Klik=Diam',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }

    switch (page) {
      case 1: // GPS ATGM336H
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SAT:${sats ?? 0} ${ctrl.isGpsFix.value ? "[LOCKED]" : "[SEARCH]"}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              lat != null ? 'LAT: ${lat.toStringAsFixed(6)}' : 'LAT: --',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
            Text(
              lng != null ? 'LON: ${lng.toStringAsFixed(6)}' : 'LON: --',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ],
        );

      case 2: // Suhu MCP9808
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SUHU SENSOR',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
            Text(
              temp != null ? '${temp.toStringAsFixed(1)} C' : '--.- C',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Tekan 1x: Next Page',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        );

      case 3: // Motion MPU6050
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MONITOR JATUH',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
            Text(
              g != null ? '${g.toStringAsFixed(2)} g' : 'SENSOR ERR',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              ctrl.fallStatus.value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        );

      case 4: // Langkah Jalan (Pedometer MPU6050)
        final steps = ctrl.effectiveSteps;
        final stepDist = ctrl.smartbandStepDistanceM.value > 0
            ? ctrl.smartbandStepDistanceM.value
            : (steps * SmartbandLdrController.strideLengthMeters);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LANGKAH JALAN',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
            Text(
              '$steps',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Jarak: ${stepDist.toStringAsFixed(1)} m',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        );

      case 5: // Safe Radius (Refreshed v2.8.1 UI)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SAFE RADIUS',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
                Text(
                  rad <= 0 ? 'OFF' : 'ON ${rad.round()}m',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ],
            ),
            Text(
              rad <= 0
                  ? 'Mode: Nonaktif'
                  : (dist != null
                        ? 'HP: ${dist.round()} m'
                        : 'HP: Mencari GPS'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              rad <= 0
                  ? 'Set di aplikasi [OFF]'
                  : (ctrl.radiusAlertActive.value
                        ? 'Batas: ${rad.round()}m [JAUH!]'
                        : 'Batas: ${rad.round()}m [AMAN]'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: ctrl.radiusAlertActive.value
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF4ADE80),
              ),
            ),
          ],
        );

      case 6: // AI Voice Assistant (INMP441)
        final isRec = ctrl.isSmartbandRecordingVoice.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRec ? 'MENDENGARKAN' : 'HAJICARE AI',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isRec ? const Color(0xFF4ADE80) : Colors.white,
                  ),
                ),
                Text(
                  isRec ? 'REC ●' : 'INMP441',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: isRec ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              isRec
                  ? 'Silakan bicara ke mikrofon gelang (1x klik = selesai)...'
                  : ctrl.aiDisplayText.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ],
        );

      default: // MAX30102 Heart Rate
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              finger ? 'DETAK JANTUNG' : 'TEMPELKAN KULIT',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                Text(
                  hr != null && hr > 0 && finger ? '$hr' : '--',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'BPM',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF2E63),
                  size: 20,
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildOledPageButton(
    String label,
    int pageIndex,
    int activePage,
    VoidCallback onTap,
  ) {
    final isSelected = (pageIndex == activePage);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold
              : const Color(0xFF334155).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : const Color(0xFF64748B),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  // 6. GRAFIK TREN SENSOR DINAMIS (Riwayat Telemetri Nyata)
  Widget _buildTrendSectionCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final data = ctrl.activeTrendData;
      final isConn = ctrl.isConnected;

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
                    'GRAFIK TELEMETRI DINAMIS (LIVE)',
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (data.isEmpty) ...[
              Container(
                height: 120,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.isDark(context)
                      ? AppColors.darkSurfaceContainer
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.isDark(context)
                        ? AppColors.darkCardBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConn
                          ? Icons.hourglass_top_rounded
                          : Icons.bluetooth_disabled_rounded,
                      color: bodyColor.withValues(alpha: 0.5),
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isConn
                          ? 'Merekam paket telemetri baru dari sensor...'
                          : 'Hubungkan smartband via BLE untuk mulai merekam data dinamis.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(color: bodyColor),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                height: 120,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: SplineTrendChartPainter(
                      data: data,
                      lineColor: const Color(0xFF10B981),
                      gradientStart: const Color(0xFF10B981).withValues(alpha: 0.3),
                      gradientEnd: const Color(0xFF10B981).withValues(alpha: 0.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Rata-rata', ctrl.trendAverage.toStringAsFixed(1), bodyColor, headingColor),
                  _buildStatItem('Maksimum', ctrl.trendMax.toStringAsFixed(1), bodyColor, headingColor),
                  _buildStatItem('Minimum', ctrl.trendMin.toStringAsFixed(1), bodyColor, headingColor),
                  _buildStatItem('Sampel', '${data.length}', bodyColor, headingColor),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String val, Color labelColor, Color valColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: labelColor.withValues(alpha: 0.7))),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }

  // 7. LOKASI SATELIT GPS ATGM336H
  Widget _buildGpsSatelliteCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isConnected = ctrl.isConnected;
      final isFix = isConnected &&
          ctrl.isGpsFix.value &&
          ctrl.latitude.value != null &&
          ctrl.longitude.value != null &&
          (ctrl.latitude.value!.abs() > 0.0001 || ctrl.longitude.value!.abs() > 0.0001);
      final lat = isFix ? ctrl.latitude.value! : null;
      final lng = isFix ? ctrl.longitude.value! : null;
      final target = (lat != null && lng != null) ? LatLng(lat, lng) : null;
      final sats = ctrl.gpsSatellites.value ?? 0;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.map_rounded,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS ATGM336H Posisi Satelit',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        !isConnected
                            ? 'Menunggu koneksi Smartband...'
                            : (isFix
                                ? 'Sinyal Terkunci ($sats Satelit Aktif)'
                                : (sats > 0
                                    ? 'Sinkronisasi ($sats Satelit Terdeteksi)...'
                                    : 'Mencari sinyal satelit GPS...')),
                        style: AppTypography.captionSmall.copyWith(
                          color: isFix ? AppColors.statusSafe : bodyColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFix
                        ? AppColors.statusSafe.withValues(alpha: 0.15)
                        : AppColors.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    !isConnected
                        ? 'OFFLINE'
                        : (isFix ? 'GPS FIX' : 'MENCARI FIX'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isFix
                          ? AppColors.statusSafe
                          : (isConnected ? AppColors.primaryGold : Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Map Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: target != null
                    ? fmap.FlutterMap(
                        options: fmap.MapOptions(
                          initialCenter: target,
                          initialZoom: 16.0,
                          interactionOptions: const fmap.InteractionOptions(
                            flags: fmap.InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          fmap.TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.hajicare.app',
                          ),
                          fmap.MarkerLayer(
                            markers: [
                              fmap.Marker(
                                point: target,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Color(0xFFDC2626),
                                  size: 38,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Container(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              !isConnected
                                  ? Icons.bluetooth_disabled_rounded
                                  : Icons.satellite_alt_rounded,
                              size: 32,
                              color: isConnected
                                  ? AppColors.primaryGold
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              !isConnected
                                  ? 'Smartband Belum Terhubung'
                                  : (sats > 0
                                      ? 'Menunggu Kuncian ($sats Satelit)...'
                                      : 'Menunggu Sinyal GPS Terkunci (GPS FIX)...'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              !isConnected
                                  ? 'Hubungkan gelang via Bluetooth untuk membaca koordinat GPS realtime.'
                                  : 'Peta lokasi hanya akan tampil saat Smartband berhasil mengunci koordinat GPS di area terbuka langit.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: bodyColor),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),

            if (target != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Koordinat Terkunci: ${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusSafe,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            ElevatedButton.icon(
              onPressed: target != null ? () => ctrl.navigateToMap(context) : null,
              icon: const Icon(Icons.fullscreen_rounded, size: 18),
              label: Text(
                target != null
                    ? 'Buka Peta Navigasi Lengkap'
                    : 'Menunggu GPS Satelit Fix...',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: target != null
                    ? AppColors.primaryGold
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08)),
                foregroundColor: target != null
                    ? Colors.black
                    : (isDark ? Colors.white38 : Colors.black38),
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Custom Painter Arc Gauge
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
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;

    const startAngle = pi * 0.85;
    const sweepTotal = pi * 1.3;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    final activePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * progress.clamp(0.0, 1.0),
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

/// Custom Painter Spline Trend Chart
class SplineTrendChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color gradientStart;
  final Color gradientEnd;

  SplineTrendChartPainter({
    required this.data,
    required this.lineColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final dx = size.width / (data.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final norm = (data[i] - minVal) / range;
      final y = size.height - (norm * (size.height * 0.8) + size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * dx;
        final prevNorm = (data[i - 1] - minVal) / range;
        final prevY =
            size.height - (prevNorm * (size.height * 0.8) + size.height * 0.1);

        final midX = (prevX + x) / 2;
        path.cubicTo(midX, prevY, midX, y, x, y);
        fillPath.cubicTo(midX, prevY, midX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [gradientStart, gradientEnd],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant SplineTrendChartPainter oldDelegate) {
    return true;
  }
}
