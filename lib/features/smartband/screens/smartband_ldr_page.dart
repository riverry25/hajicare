import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_ping_dot.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../controllers/smartband_ldr_controller.dart';

class SmartbandLdrPage extends GetView<SmartbandLdrController> {
  const SmartbandLdrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    final scaffoldBg = AppColors.scaffoldColor(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: HajiCareHeader(
        title: context.tr('smartband.hajjSmartband'),
        subtitle: 'Sensor Lingkungan DHT11',
        icon: Icons.watch_rounded,
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
              _buildConnectionCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),
              _buildDhtMainCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),
              _buildRealtimeIndicator(context, ctrl),
              const SizedBox(height: AppSpacing.gapCards),
              _buildRawDataCard(context, ctrl),
              const SizedBox(height: AppSpacing.gapSection),
              _buildActionButton(context, ctrl),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Connection Card ──────────────────────────────────────────────────────
  Widget _buildConnectionCard(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final state = ctrl.connectionState.value;

      Color badgeBg;
      Color badgeBorder;
      Color iconColor;
      IconData iconData;
      String titleText;
      String subtitleText;
      String noteText;
      bool showSpinner = false;

      switch (state) {
        case SmartbandConnectionState.scanning:
          badgeBg = AppColors.primaryGold.withValues(alpha: 0.15);
          badgeBorder = AppColors.primaryGold.withValues(alpha: 0.4);
          iconColor = AppColors.primaryGold;
          iconData = Icons.bluetooth_searching_rounded;
          titleText = 'Bluetooth';
          subtitleText = 'Mencari HajiCare Watch...';
          noteText = 'Memindai sinyal BLE di sekitar...';
          showSpinner = true;
          break;

        case SmartbandConnectionState.connecting:
          badgeBg = AppColors.primaryGold.withValues(alpha: 0.15);
          badgeBorder = AppColors.primaryGold.withValues(alpha: 0.4);
          iconColor = AppColors.primaryGold;
          iconData = Icons.bluetooth_connected_rounded;
          titleText = 'Bluetooth';
          subtitleText = 'Menghubungkan...';
          noteText = 'Menyiapkan sensor DHT11...';
          showSpinner = true;
          break;

        case SmartbandConnectionState.connected:
          badgeBg = AppColors.statusSafe.withValues(alpha: 0.15);
          badgeBorder = AppColors.statusSafe.withValues(alpha: 0.35);
          iconColor = AppColors.statusSafe;
          iconData = Icons.watch_rounded;
          titleText = 'HajiCare Watch';
          subtitleText = 'Terhubung';
          noteText = ctrl.isSensorAvailable.value
              ? 'Data sensor DHT11 aktif'
              : 'Menunggu pembacaan sensor...';
          break;

        case SmartbandConnectionState.disconnected:
          final isExplicitDisconnected =
              ctrl.statusMessage.value == 'Gelang terputus';
          badgeBg = isDark
              ? AppColors.darkSurfaceContainerHighest
              : AppColors.canvasCreamSubtle;
          badgeBorder = isDark
              ? AppColors.darkOutlineVariant
              : AppColors.outlineVariant;
          iconColor = isExplicitDisconnected
              ? AppColors.textCaption
              : AppColors.primaryGold;
          iconData = Icons.bluetooth_disabled_rounded;
          titleText = 'HajiCare Watch';
          subtitleText = isExplicitDisconnected
              ? 'Terputus'
              : 'Belum terhubung';
          noteText = isExplicitDisconnected
              ? 'Data sensor berhenti diterima'
              : 'Tekan tombol Hubungkan Gelang';
          break;
      }

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        borderColor: badgeBorder,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: badgeBorder, width: 1.5),
              ),
              child: showSpinner
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    )
                  : Icon(iconData, color: iconColor, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: state == SmartbandConnectionState.connected
                          ? AppColors.statusSafe
                          : headingColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    noteText,
                    style: AppTypography.caption.copyWith(
                      color: bodyColor.withValues(alpha: 0.8),
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

  // ── 2. DHT11 Main Card (4 Metrics) ──────────────────────────────────────────
  Widget _buildDhtMainCard(BuildContext context, SmartbandLdrController ctrl) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isConnected = ctrl.isConnected;
      final isAvailable = ctrl.isSensorAvailable.value;
      final tempText = ctrl.formattedTemperature;
      final humText = ctrl.formattedHumidity;
      final heatIndexText = ctrl.formattedHeatIndex;
      final statusLabel = ctrl.environmentStatusLabel;
      final statusColor = ctrl.environmentStatusColor;
      final statusIcon = ctrl.environmentStatusIcon;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        borderColor: isConnected && isAvailable
            ? statusColor.withValues(alpha: 0.35)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.device_thermostat_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sensor Lingkungan DHT11',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Suhu & kelembapan udara sekitar',
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Environment Status Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: AppTypography.captionSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4 Metrics: 2x2 Grid Layout
            Row(
              children: [
                // Metric 1: 🌡 Suhu Lingkungan
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: Icons.thermostat_rounded,
                    iconColor: const Color(0xFFE11D48),
                    label: 'Suhu Lingkungan',
                    value: tempText,
                    unit: isConnected && isAvailable ? '' : '',
                    note: 'Udara sekitar jamaah',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Metric 2: 💧 Kelembapan
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF0284C7),
                    label: 'Kelembapan',
                    value: humText,
                    unit: '',
                    note: 'Relatif udara (%RH)',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                // Metric 3: 🔥 Heat Index
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFEA580C),
                    label: 'Heat Index',
                    value: heatIndexText,
                    unit: '',
                    note: 'Suhu terasa tubuh',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Metric 4: 🌤 Kondisi Lingkungan
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    icon: statusIcon,
                    iconColor: statusColor,
                    label: 'Kondisi Lingkungan',
                    value: statusLabel,
                    unit: '',
                    note: 'Kombinasi T & HI',
                    isDark: isDark,
                    valueColor: isConnected && isAvailable ? statusColor : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required String note,
    required bool isDark,
    Color? valueColor,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerHighest.withValues(alpha: 0.4)
            : const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.captionSmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                color: valueColor ?? headingColor,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: AppTypography.captionSmall.copyWith(
              color: bodyColor.withValues(alpha: 0.6),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── 3. Realtime Indicator (DHT11) ───────────────────────────────────────────
  Widget _buildRealtimeIndicator(
    BuildContext context,
    SmartbandLdrController ctrl,
  ) {
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isConnected = ctrl.isConnected;
      final isAvailable = ctrl.isSensorAvailable.value;
      final timeStr = ctrl.relativeTimeStr.value;

      Color indicatorBg;
      Color indicatorBorder;
      Color statusTextColor;
      String statusMsg;
      bool showDot = false;

      if (!isConnected) {
        indicatorBg = AppColors.canvasCreamSubtle.withValues(alpha: 0.4);
        indicatorBorder = AppColors.outlineVariant.withValues(alpha: 0.3);
        statusTextColor = bodyColor;
        statusMsg = 'HajiCare Watch belum terhubung';
      } else if (isAvailable) {
        indicatorBg = AppColors.statusSafe.withValues(alpha: 0.08);
        indicatorBorder = AppColors.statusSafe.withValues(alpha: 0.25);
        statusTextColor = AppColors.statusSafe;
        statusMsg = 'DHT11 realtime: $timeStr';
        showDot = true;
      } else {
        indicatorBg = const Color(0xFFEA580C).withValues(alpha: 0.08);
        indicatorBorder = const Color(0xFFEA580C).withValues(alpha: 0.25);
        statusTextColor = const Color(0xFFEA580C);
        statusMsg = 'Sensor tidak tersedia (menunggu data)';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: indicatorBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: indicatorBorder),
        ),
        child: Row(
          children: [
            if (showDot)
              const AnimatedPingDot(size: 8, color: AppColors.statusSafe)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? const Color(0xFFEA580C)
                      : AppColors.textCaption,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                statusMsg,
                style: AppTypography.bodySmall.copyWith(
                  color: statusTextColor,
                  fontWeight: showDot ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 4. Raw Data Diagnostic Card ─────────────────────────────────────────────
  Widget _buildRawDataCard(BuildContext context, SmartbandLdrController ctrl) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isConnected = ctrl.isConnected;
      final isAvailable = ctrl.isSensorAvailable.value;
      final rawPayload = ctrl.rawDataString.value;
      final temp = ctrl.temperature.value != null
          ? '${ctrl.temperature.value!.toStringAsFixed(1)} °C'
          : '-';
      final hum = ctrl.humidity.value != null
          ? '${ctrl.humidity.value!.toStringAsFixed(1)} %'
          : '-';
      final hi = ctrl.heatIndex.value != null
          ? '${ctrl.heatIndex.value!.toStringAsFixed(1)} °C'
          : '-';

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
            title: Text(
              'Data Diagnostik Sensor',
              style: AppTypography.titleMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Detail teknis BLE & status sensor DHT11',
              style: AppTypography.caption.copyWith(
                color: bodyColor.withValues(alpha: 0.75),
              ),
            ),
            children: [
              const Divider(height: 16),
              _buildDebugRow(context, 'Device Name', ctrl.deviceName.value),
              _buildDebugRow(
                context,
                'BLE Status',
                isConnected ? 'Connected' : 'Disconnected',
                isSuccess: isConnected,
              ),
              _buildDebugRow(
                context,
                'DHT11 Status',
                isAvailable ? 'Receiving' : 'Not Available',
                isSuccess: isAvailable,
              ),
              _buildDebugRow(context, 'Suhu Lingkungan', temp),
              _buildDebugRow(context, 'Kelembapan', hum),
              _buildDebugRow(context, 'Heat Index', hi),
              _buildDebugRow(context, 'Kondisi', ctrl.environmentStatusLabel),
              _buildDebugRow(context, 'Raw Payload', rawPayload),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDebugRow(
    BuildContext context,
    String label,
    String value, {
    bool? isSuccess,
    String? hint,
  }) {
    final bodyColor = AppColors.textBodyColor(context);
    final headingColor = AppColors.textHeadingColor(context);

    Color valColor = headingColor;
    if (isSuccess == true) valColor = AppColors.statusSafe;
    if (isSuccess == false) valColor = AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: bodyColor.withValues(alpha: 0.8),
                ),
              ),
              Text(
                value,
                style: AppTypography.labelLarge.copyWith(
                  color: valColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (hint != null)
            Text(
              hint,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textCaption.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  // ── 5. Action Button ────────────────────────────────────────────────────────
  Widget _buildActionButton(BuildContext context, SmartbandLdrController ctrl) {
    return Obx(() {
      final isConnected = ctrl.isConnected;
      final isBusy = ctrl.isBusy;

      if (isConnected) {
        return SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : () => ctrl.disconnectSmartband(),
            icon: const Icon(Icons.link_off_rounded, size: 20),
            label: Text(
              'Putuskan Gelang',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: isBusy ? null : () => ctrl.connectSmartband(),
          icon: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surfaceWhite,
                  ),
                )
              : const Icon(Icons.bluetooth_searching_rounded, size: 20),
          label: Text(
            isBusy
                ? (ctrl.isScanning ? 'Mencari Gelang...' : 'Menghubungkan...')
                : 'Hubungkan Gelang',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.surfaceWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.surfaceWhite,
            disabledBackgroundColor: AppColors.primaryContainer.withValues(
              alpha: 0.6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            elevation: 0,
          ),
        ),
      );
    });
  }
}
