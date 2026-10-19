import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../controllers/smartband_ble_test_controller.dart';
import '../services/smartband_ble_service.dart';

/// Halaman Uji Coba Koneksi BLE Smartband ESP32-S3 HajiCare
/// Dirancang responsif, bebas overflow dengan text scaling besar, dan mendukung multi bahasa.
class SmartbandBleTestScreen extends GetView<SmartbandBleTestController> {
  const SmartbandBleTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = AppColors.scaffoldColor(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: HajiCareHeader(
        title: 'HAJICARE SMARTBAND BLE',
        subtitle: context.tr('smartband.bleTestTooltip'),
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
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'STATUS KONEKSI BLE',
                      style: AppTypography.labelLarge.copyWith(
                        color: bodyColor.withValues(alpha: 0.7),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
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
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DATA TELEMETRI REALTIME',
                      style: AppTypography.titleMedium.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // 1. Bracelet ID
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

            // 2. MAX30102: Detak Jantung & Kadar Oksigen SpO2
            _buildTelemetryTile(
              context,
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFFF2E63),
              label: 'MAX30102 Detak Jantung & SpO2',
              value: data != null
                  ? '${data.heartRate} BPM • ${data.spo2 != null ? "${data.spo2}% SpO2" : "--% SpO2"}'
                  : '--',
              helper: data != null && data.heartRate == 0
                  ? 'Sensor sedang mengukur...'
                  : (data != null
                        ? 'Denyut nadi & kadar oksigen aktif'
                        : 'Menunggu payload...'),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 3. Sensor Suhu Tubuh (MLX90614 / MCP9808)
            _buildTelemetryTile(
              context,
              icon: Icons.device_thermostat_rounded,
              iconColor: const Color(0xFFD4A857),
              label: 'MLX90614 / Suhu Tubuh Presisi',
              value: data?.temperature != null
                  ? '${data!.temperature!.toStringAsFixed(1)} °C'
                  : '-- °C',
              helper: 'Presisi tinggi sensor I2C digital',
            ),
            const SizedBox(height: AppSpacing.sm),

            // 4. MPU6050: Aktivitas Langkah & Deteksi Jatuh
            _buildTelemetryTile(
              context,
              icon: Icons.directions_walk_rounded,
              iconColor: const Color(0xFF10B981),
              label: 'MPU6050 Langkah & Deteksi Jatuh',
              value: (data?.fallDetected ?? false)
                  ? 'JATUH TERDETEKSI!'
                  : '${data?.stepCount ?? 0} Langkah • Tegak (${data?.accelG?.toStringAsFixed(2) ?? "1.02"} G)',
              helper:
                  'Roll: ${data?.roll?.toStringAsFixed(1) ?? "0.0"}° • Pitch: ${data?.pitch?.toStringAsFixed(1) ?? "0.0"}°',
            ),
            const SizedBox(height: AppSpacing.sm),

            // 5. GPS NEO-6M: Koordinat Satelit Realtime
            _buildTelemetryTile(
              context,
              icon: Icons.satellite_alt_rounded,
              iconColor: const Color(0xFF0284C7),
              label: 'GPS NEO-6M Satelit Realtime',
              value:
                  (data?.isValidLocation ?? false) &&
                      data?.latitude != null &&
                      data?.longitude != null
                  ? '${data!.latitude!.toStringAsFixed(6)}, ${data.longitude!.toStringAsFixed(6)}'
                  : 'Mencari Sinyal Satelit...',
              helper: (data?.isValidLocation ?? false)
                  ? 'Sinyal GPS FIX (${data?.satellites ?? 0} Satelit Terkunci)'
                  : 'Belum FIX (Menunggu akuisisi satelit)',
            ),
            const SizedBox(height: AppSpacing.sm),

            // 6. LCD 16x2 + I2C Backpack: Layar Pergelangan Tangan
            _buildLcdMirrorTile(
              context,
              line1: data?.displayLcdLine1 ?? 'HR: --  SpO2: --%',
              line2: data?.displayLcdLine2 ?? 'STATUS: STANDBY ',
            ),
            const SizedBox(height: AppSpacing.sm),

            // 7. Baterai LiPo 3.7V
            _buildTelemetryTile(
              context,
              icon: Icons.battery_charging_full_rounded,
              iconColor: const Color(0xFF16A34A),
              label: 'Baterai LiPo 3.7V',
              value: data?.batteryLevel != null
                  ? '${data!.batteryLevel}% (${data.batteryVoltage?.toStringAsFixed(2) ?? "3.96"}V)'
                  : '--',
              helper: (data?.isCharging ?? false)
                  ? 'Sedang Mengisi'
                  : 'Siap Pakai',
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

  Widget _buildLcdMirrorTile(
    BuildContext context, {
    required String line1,
    required String line2,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 0.8,
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'I2C 0x27 • 16x2 LCD',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34D399),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'LCD 16x2 / OLED Layar Gelang',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF042F2E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF0D9488), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    line1.padRight(16).substring(0, 16),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: Color(0xFF5EEAD4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    line2.padRight(16).substring(0, 16),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: Color(0xFF5EEAD4),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(top: 2),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: bodyColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                helper,
                style: AppTypography.captionSmall.copyWith(
                  color: bodyColor.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 3. Tombol Aksi BLE ─────────────────────────────────────────────────────
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
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'PUTUSKAN KONEKSI SMARTBAND',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'MENGHUBUNGKAN KE SMARTBAND...',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
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
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isScanning ? 'MEMINDAI SMARTBAND...' : 'PINDAI SMARTBAND BLE',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'CONNECT KE ${foundDevice.platformName.isNotEmpty ? foundDevice.platformName : "SMARTBAND"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  // ── 4. Terminal Log Realtime ────────────────────────────────────────────────
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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.terminal_rounded,
                        size: 18,
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'LOG KOMUNIKASI BLE',
                            style: AppTypography.labelLarge.copyWith(
                              color: bodyColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (logs.isNotEmpty)
                  TextButton(
                    onPressed: () => controller.clearLogs(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.statusDanger,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            Container(
              height: 140,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada log komunikasi BLE.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, idx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            logs[idx],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFF38BDF8),
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
      children: [
        Expanded(
          flex: 4,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: bodyColor.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  color: valueColor,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
