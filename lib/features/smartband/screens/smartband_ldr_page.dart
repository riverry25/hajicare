import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../controllers/smartband_ldr_controller.dart';
import '../services/smartband_ble_service.dart';

/// Halaman Utama Pemantauan Smartband HajiCare (ESP32-S3 + NEO-6M GPS + MAX30102 Heart Rate)
class SmartbandLdrPage extends GetView<SmartbandLdrController> {
  const SmartbandLdrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    final scaffoldBg = AppColors.scaffoldColor(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: HajiCareHeader(
        title: 'HAJICARE SMARTBAND',
        subtitle: 'Pemantauan Jamaah',
        icon: Icons.watch_rounded,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryGold),
            tooltip: 'Uji BLE Realtime',
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
              // ── BAGIAN 1: STATUS GELANG & KONEKSI ─────────────────────────
              _buildConnectionStatusCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── BAGIAN 2: IDENTITAS SMARTBAND ──────────────────────────────
              _buildDeviceIdentityCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── BAGIAN 3: DETAK JANTUNG (MAX30102) ─────────────────────────
              _buildHeartRateCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── BAGIAN 4 & 5: LOKASI JAMAAH (NEO-6M GPS) & LIHAT DI PETA ───
              _buildGpsLocationCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),

              // ── BAGIAN 6: STATUS UPDATE DATA & LOG KONEKSI ─────────────────
              _buildDataUpdateStatusCard(context, ctrl),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. STATUS GELANG (Card Utama Paling Atas) ─────────────────────────────
  Widget _buildConnectionStatusCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final status = ctrl.bleStatus.value;
      final isConnected = status == SmartbandBleStatus.connected;
      final isScanning = status == SmartbandBleStatus.scanning;
      final isConnecting = status == SmartbandBleStatus.connecting;

      Color badgeBg;
      Color badgeBorder;
      Color statusColor;
      String statusTitle;
      String statusSubtitle;
      Widget actionButton;

      if (isConnected) {
        badgeBg = AppColors.statusSafe.withValues(alpha: 0.12);
        badgeBorder = AppColors.statusSafe.withValues(alpha: 0.35);
        statusColor = AppColors.statusSafe;
        statusTitle = '🟢 Gelang Terhubung';
        statusSubtitle = 'ID: ${ctrl.braceletId.value}';

        actionButton = ElevatedButton.icon(
          onPressed: () => ctrl.disconnectSmartband(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusDanger.withValues(alpha: 0.1),
            foregroundColor: AppColors.statusDanger,
            elevation: 0,
            side: const BorderSide(color: AppColors.statusDanger, width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          icon: const Icon(Icons.link_off_rounded, size: 20),
          label: const Text(
            'PUTUSKAN GELANG',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
      } else if (isScanning || isConnecting) {
        badgeBg = AppColors.primaryGold.withValues(alpha: 0.12);
        badgeBorder = AppColors.primaryGold.withValues(alpha: 0.35);
        statusColor = AppColors.primaryGold;
        statusTitle = isScanning
            ? '🟡 Memindai Gelang...'
            : '🟡 Menghubungkan...';
        statusSubtitle = isScanning
            ? 'Mencari HajiCare-Gelang-001...'
            : 'Menyiapkan sensor telemetri...';

        actionButton = OutlinedButton.icon(
          onPressed: () => ctrl.disconnectSmartband(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text(
            'BATALKAN',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        badgeBg = AppColors.statusDanger.withValues(alpha: 0.1);
        badgeBorder = AppColors.statusDanger.withValues(alpha: 0.3);
        statusColor = AppColors.statusDanger;
        statusTitle = '🔴 Gelang Belum Terhubung';
        statusSubtitle =
            'Hubungkan gelang untuk menerima data GPS dan detak jantung.';

        actionButton = ElevatedButton.icon(
          onPressed: () => ctrl.connectSmartband(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGold,
            foregroundColor: Colors.black,
            elevation: 1,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          icon: const Icon(Icons.bluetooth_searching_rounded, size: 20),
          label: const Text(
            'HUBUNGKAN GELANG',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
      }

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        borderColor: badgeBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(color: badgeBorder),
                  ),
                  child: Text(
                    statusTitle,
                    style: AppTypography.captionSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ctrl.deviceName.value,
              style: AppTypography.titleLarge.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: bodyColor.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            actionButton,
          ],
        ),
      );
    });
  }

  // ── 2. IDENTITAS SMARTBAND ────────────────────────────────────────────────
  Widget _buildDeviceIdentityCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final status = ctrl.bleStatus.value;

      String statusDisplay;
      Color statusDisplayColor;

      switch (status) {
        case SmartbandBleStatus.connected:
          statusDisplay = 'Connected';
          statusDisplayColor = AppColors.statusSafe;
          break;
        case SmartbandBleStatus.connecting:
          statusDisplay = 'Connecting';
          statusDisplayColor = AppColors.primaryGold;
          break;
        case SmartbandBleStatus.scanning:
          statusDisplay = 'Scanning';
          statusDisplayColor = AppColors.primaryGold;
          break;
        case SmartbandBleStatus.disconnected:
          statusDisplay = 'Disconnected';
          statusDisplayColor = AppColors.statusDanger;
          break;
      }

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'IDENTITAS SMARTBAND',
                  style: AppTypography.labelLarge.copyWith(
                    color: bodyColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            _buildDataRow(
              label: 'Nama Perangkat',
              value: ctrl.deviceName.value,
              valueColor: headingColor,
              bodyColor: bodyColor,
            ),
            const SizedBox(height: 8),
            _buildDataRow(
              label: 'Bracelet ID',
              value: ctrl.braceletId.value,
              valueColor: headingColor,
              bodyColor: bodyColor,
            ),
            const SizedBox(height: 8),
            _buildDataRow(
              label: 'Status Koneksi',
              value: statusDisplay,
              valueColor: statusDisplayColor,
              bodyColor: bodyColor,
              isBold: true,
            ),
          ],
        ),
      );
    });
  }

  // ── 3. DETAK JANTUNG (MAX30102) ───────────────────────────────────────────
  Widget _buildHeartRateCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final hr = ctrl.heartRate.value;
      final isConnected = ctrl.isConnected;
      final statusText = ctrl.heartRateStatus.value;

      final bool hasReading = isConnected && hr != null && hr > 0;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Detak Jantung',
                      style: AppTypography.titleMedium.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasReading
                          ? AppColors.statusSafe.withValues(alpha: 0.12)
                          : (isConnected
                                ? AppColors.primaryGold.withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      statusText,
                      style: AppTypography.captionSmall.copyWith(
                        color: hasReading
                            ? AppColors.statusSafe
                            : (isConnected
                                  ? AppColors.primaryGold
                                  : AppColors.textMuted),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // BPM Big Readout
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hasReading ? '$hr' : '—',
                  style: TextStyle(
                    fontFamily: AppTypography.headingFontFamily,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: hasReading ? headingColor : AppColors.textMuted,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'BPM',
                  style: AppTypography.titleMedium.copyWith(
                    color: bodyColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasReading
                  ? 'Pengukuran detak jantung aktif secara realtime.'
                  : (isConnected
                        ? 'Sensor MAX30102 sedang mengukur detak nadi...'
                        : 'Hubungkan gelang untuk memantau detak jantung lansia.'),
              style: AppTypography.caption.copyWith(
                color: bodyColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 4 & 5. LOKASI JAMAAH (NEO-6M GPS) & TOMBOL LIHAT DI PETA ──────────────
  Widget _buildGpsLocationCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isConnected = ctrl.isConnected;
      final isGpsFix = ctrl.isGpsFix.value;
      final lat = ctrl.latitude.value;
      final lng = ctrl.longitude.value;
      final lastLat = ctrl.lastKnownLatitude.value;
      final lastLng = ctrl.lastKnownLongitude.value;
      final relativeTime = ctrl.relativeTimeText.value;

      String gpsStatusText;
      Color gpsStatusColor;
      Color gpsStatusBg;

      if (!isConnected) {
        gpsStatusText = '🔴 Gelang Terputus';
        gpsStatusColor = AppColors.statusDanger;
        gpsStatusBg = AppColors.statusDanger.withValues(alpha: 0.1);
      } else if (isGpsFix && lat != null && lng != null) {
        gpsStatusText = '🟢 FIX (Statis)';
        gpsStatusColor = AppColors.statusSafe;
        gpsStatusBg = AppColors.statusSafe.withValues(alpha: 0.12);
      } else {
        gpsStatusText = '🟡 Mencari GPS';
        gpsStatusColor = AppColors.primaryGold;
        gpsStatusBg = AppColors.primaryGold.withValues(alpha: 0.12);
      }

      final String displayLat;
      final String displayLng;
      if (lat != null && lng != null) {
        displayLat = lat.toStringAsFixed(6);
        displayLng = lng.toStringAsFixed(6);
      } else if (lastLat != null && lastLng != null) {
        displayLat = '${lastLat.toStringAsFixed(6)} (Terakhir)';
        displayLng = '${lastLng.toStringAsFixed(6)} (Terakhir)';
      } else {
        displayLat = '—';
        displayLng = '—';
      }

      final bool canViewOnMap =
          (isGpsFix && lat != null && lng != null) ||
          (lastLat != null && lastLng != null);

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primaryGold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Lokasi Jamaah',
                      style: AppTypography.titleMedium.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: gpsStatusBg,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      gpsStatusText,
                      style: AppTypography.captionSmall.copyWith(
                        color: gpsStatusColor,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),

            _buildDataRow(
              label: 'Latitude',
              value: displayLat,
              valueColor: headingColor,
              bodyColor: bodyColor,
            ),
            const SizedBox(height: 8),
            _buildDataRow(
              label: 'Longitude',
              value: displayLng,
              valueColor: headingColor,
              bodyColor: bodyColor,
            ),
            const SizedBox(height: 8),
            _buildDataRow(
              label: 'Sumber Lokasi',
              value: 'Smartband (GPS Statis)',
              valueColor: headingColor,
              bodyColor: bodyColor,
            ),
            const SizedBox(height: 8),
            _buildDataRow(
              label: 'Update Terakhir',
              value: relativeTime,
              valueColor: bodyColor,
              bodyColor: bodyColor,
            ),

            const SizedBox(height: AppSpacing.md),
            // ── BAGIAN 5: TOMBOL LIHAT DI PETA ──
            ElevatedButton.icon(
              onPressed: () => ctrl.navigateToMap(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: canViewOnMap
                    ? const Color(0xFF1E293B)
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                elevation: canViewOnMap ? 1 : 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              icon: const Icon(Icons.map_rounded, size: 20),
              label: const Text(
                'LIHAT DI PETA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 6. STATUS UPDATE DATA ──────────────────────────────────────────────────
  Widget _buildDataUpdateStatusCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final relativeTime = ctrl.relativeTimeText.value;
      final error = ctrl.errorMessage.value;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 16,
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status Update:',
                      style: AppTypography.caption.copyWith(
                        color: bodyColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Text(
                  relativeTime,
                  style: AppTypography.caption.copyWith(
                    color: bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statusDanger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.statusDanger,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.statusDanger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildDataRow({
    required String label,
    required String value,
    required Color valueColor,
    required Color bodyColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: bodyColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
