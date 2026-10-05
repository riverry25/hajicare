import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../controllers/smartband_ble_test_controller.dart';
import '../services/smartband_ble_service.dart';

/// Halaman Uji Coba Koneksi BLE Smartband ESP32-S3 HajiCare
class SmartbandBleTestScreen extends GetView<SmartbandBleTestController> {
  const SmartbandBleTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = AppColors.scaffoldColor(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: const HajiCareHeader(
        title: 'HAJICARE SMARTBAND BLE',
        subtitle: 'Uji Coba BLE Realtime ESP32-S3',
        icon: Icons.bluetooth_audio_rounded,
        showBackButton: true,
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
              _buildStatusCard(context),
              const SizedBox(height: AppSpacing.gapCards),
              _buildDataCard(context),
              const SizedBox(height: AppSpacing.gapCards),
              _buildActionSection(context),
              const SizedBox(height: AppSpacing.gapCards),
              _buildLogsCard(context),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Status Koneksi & Perangkat ──────────────────────────────────────────
  Widget _buildStatusCard(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final status = controller.connectionStatus.value;
      final foundDevice = controller.foundDevice.value;
      final error = controller.errorMessage.value;

      Color badgeBg;
      Color badgeBorder;
      Color statusColor;
      IconData statusIcon;
      String statusText;

      switch (status) {
        case SmartbandBleStatus.scanning:
          badgeBg = AppColors.primaryGold.withValues(alpha: 0.15);
          badgeBorder = AppColors.primaryGold.withValues(alpha: 0.4);
          statusColor = AppColors.primaryGold;
          statusIcon = Icons.bluetooth_searching_rounded;
          statusText = 'SCANNING';
          break;
        case SmartbandBleStatus.connecting:
          badgeBg = AppColors.primaryGold.withValues(alpha: 0.15);
          badgeBorder = AppColors.primaryGold.withValues(alpha: 0.4);
          statusColor = AppColors.primaryGold;
          statusIcon = Icons.bluetooth_connected_rounded;
          statusText = 'CONNECTING';
          break;
        case SmartbandBleStatus.connected:
          badgeBg = AppColors.statusSafe.withValues(alpha: 0.15);
          badgeBorder = AppColors.statusSafe.withValues(alpha: 0.4);
          statusColor = AppColors.statusSafe;
          statusIcon = Icons.bluetooth_connected_rounded;
          statusText = 'CONNECTED';
          break;
        case SmartbandBleStatus.disconnected:
          badgeBg = isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05);
          badgeBorder = isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.15);
          statusColor = AppColors.statusDanger;
          statusIcon = Icons.bluetooth_disabled_rounded;
          statusText = 'DISCONNECTED';
          break;
      }

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STATUS KONEKSI',
                  style: AppTypography.labelLarge.copyWith(
                    color: bodyColor.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: AppTypography.captionSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow(
              context,
              label: 'Target Device',
              value: SmartbandBleService.targetDeviceName,
              valueColor: headingColor,
              isBold: true,
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              context,
              label: 'Perangkat Ditemukan',
              value: foundDevice != null
                  ? '${foundDevice.platformName} (${foundDevice.remoteId})'
                  : 'Belum ditemukan',
              valueColor: foundDevice != null
                  ? AppColors.statusSafe
                  : bodyColor.withValues(alpha: 0.6),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusDanger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.statusDanger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.statusDanger,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.statusDanger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── 2. Data Telemetri Realtime ─────────────────────────────────────────────
  Widget _buildDataCard(BuildContext context) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final data = controller.currentData.value;
      final isConnected =
          controller.connectionStatus.value == SmartbandBleStatus.connected;

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
                Text(
                  'DATA TELEMETRI REALTIME',
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // Bracelet ID
            _buildTelemetryTile(
              context,
              icon: Icons.tag_rounded,
              iconColor: Colors.blueAccent,
              label: 'Bracelet ID',
              value: data?.braceletId ?? SmartbandBleService.targetBraceletId,
              helper: isConnected
                  ? 'Dari notifikasi BLE'
                  : 'Menunggu koneksi...',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Latitude
            _buildTelemetryTile(
              context,
              icon: Icons.location_on_outlined,
              iconColor: Colors.redAccent,
              label: 'Latitude',
              value: data?.latitude != null
                  ? data!.latitude!.toStringAsFixed(6)
                  : '-',
              helper: (data?.isValidLocation ?? false)
                  ? 'Lokasi Valid'
                  : 'Menunggu sinyal GPS valid',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Longitude
            _buildTelemetryTile(
              context,
              icon: Icons.explore_outlined,
              iconColor: Colors.teal,
              label: 'Longitude',
              value: data?.longitude != null
                  ? data!.longitude!.toStringAsFixed(6)
                  : '-',
              helper: (data?.isValidLocation ?? false)
                  ? 'Lokasi Valid'
                  : 'Menunggu sinyal GPS valid',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Heart Rate
            _buildTelemetryTile(
              context,
              icon: Icons.favorite_rounded,
              iconColor: Colors.pinkAccent,
              label: 'Heart Rate',
              value: data != null ? '${data.heartRate} BPM' : '-',
              helper: data != null && data.heartRate == 0
                  ? 'Sensor sedang mengukur...'
                  : (data != null
                        ? 'Detak jantung realtime'
                        : 'Menunggu data...'),
            ),

            if (data?.rawJson.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: 6),
              Text(
                'Raw JSON Payload:',
                style: AppTypography.caption.copyWith(
                  color: bodyColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  data!.rawJson,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTelemetryTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String helper,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: bodyColor.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          helper,
          style: AppTypography.caption.copyWith(
            color: bodyColor.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ── 3. Tombol Aksi ────────────────────────────────────────────────────────
  Widget _buildActionSection(BuildContext context) {
    return Obx(() {
      final status = controller.connectionStatus.value;
      final foundDevice = controller.foundDevice.value;

      final isScanning = status == SmartbandBleStatus.scanning;
      final isConnecting = status == SmartbandBleStatus.connecting;
      final isConnected = status == SmartbandBleStatus.connected;

      if (isConnected) {
        return ElevatedButton.icon(
          onPressed: () => controller.disconnect(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusDanger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          icon: const Icon(Icons.link_off_rounded),
          label: const Text(
            'PUTUSKAN KONEKSI (DISCONNECT)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }

      if (isConnecting) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.primaryGold),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGold,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Menghubungkan ke Smartband...',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: isScanning ? null : () => controller.startScan(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            icon: isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.search_rounded),
            label: Text(
              isScanning ? 'SEDANG MEMINDAI...' : 'SCAN SMARTBAND',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (foundDevice != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => controller.connect(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusSafe,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              icon: const Icon(Icons.bluetooth_connected_rounded),
              label: Text(
                'CONNECT KE ${foundDevice.platformName.isNotEmpty ? foundDevice.platformName : "SMARTBAND"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      );
    });
  }

  // ── 4. Log Realtime ────────────────────────────────────────────────────────
  Widget _buildLogsCard(BuildContext context) {
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final logs = controller.logs;

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
                    const Icon(
                      Icons.terminal_rounded,
                      size: 18,
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'STATUS LOG',
                      style: AppTypography.labelLarge.copyWith(
                        color: bodyColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                if (logs.isNotEmpty)
                  TextButton(
                    onPressed: () => controller.clearLogs(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Bersihkan',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(),
            const SizedBox(height: 6),
            Container(
              height: 160,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada aktivitas. Tekan [SCAN SMARTBAND] untuk memulai.',
                        style: AppTypography.caption.copyWith(
                          color: bodyColor.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            logs[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    final bodyColor = AppColors.textBodyColor(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: bodyColor.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
