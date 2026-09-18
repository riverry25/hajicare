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
import '../services/ble_service.dart';

class SmartbandLdrPage extends GetView<SmartbandLdrController> {
  const SmartbandLdrPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered if not passed via GetPage binding
    final ctrl = Get.put(SmartbandLdrController());
    final scaffoldBg = AppColors.scaffoldColor(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: const HajiCareHeader(
        title: 'Gelang Pintar Haji',
        subtitle: 'Prototype BLE • Sensor LDR',
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
              _buildLdrMainCard(context, ctrl),
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
  Widget _buildConnectionCard(BuildContext context, SmartbandLdrController ctrl) {
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
          noteText = 'Membuka koneksi & membaca service...';
          showSpinner = true;
          break;

        case SmartbandConnectionState.connected:
          badgeBg = AppColors.statusSafe.withValues(alpha: 0.15);
          badgeBorder = AppColors.statusSafe.withValues(alpha: 0.35);
          iconColor = AppColors.statusSafe;
          iconData = Icons.watch_rounded;
          titleText = 'Gelang Pintar Haji';
          subtitleText = 'Terhubung';
          noteText = 'BLE Sync Aktif';
          break;

        case SmartbandConnectionState.disconnected:
          final isExplicitDisconnected = ctrl.statusMessage.value == 'Terputus';
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
          titleText = 'Gelang Pintar Haji';
          subtitleText = isExplicitDisconnected ? 'Terputus' : 'Belum terhubung';
          noteText = isExplicitDisconnected
              ? 'BLE Sync Tidak Aktif'
              : 'Menunggu koneksi BLE';
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

  // ── 2. LDR Main Card ────────────────────────────────────────────────────────
  Widget _buildLdrMainCard(BuildContext context, SmartbandLdrController ctrl) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isConnected = ctrl.isConnected;
      final displayPercent = ctrl.formattedBrightnessPercentage;
      final rawAdc = ctrl.formattedLdrValue;
      final lightStatus = ctrl.lightStatus;
      final statusColor = ctrl.lightStatusColor;
      final statusIcon = ctrl.lightStatusIcon;

      // Dynamic icon based on status/brightness
      final iconBgColor = isConnected
          ? statusColor.withValues(alpha: isDark ? 0.25 : 0.15)
          : AppColors.primaryGold.withValues(alpha: 0.12);
      final iconColor = isConnected ? statusColor : AppColors.accentGoldStar;

      return AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.xl,
        ),
        borderColor: isConnected
            ? AppColors.goldLight.withValues(alpha: 0.4)
            : null,
        child: Column(
          children: [
            // Dynamic Light Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Section Title
            Text(
              'Intensitas Cahaya',
              style: AppTypography.titleMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Main Large Brightness Percentage Number (e.g. 88%)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayPercent,
                style: AppTypography.heroNumberLarge.copyWith(
                  color: isConnected ? headingColor : bodyColor.withValues(alpha: 0.4),
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Status Badge (Gelap / Redup / Terang)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    lightStatus,
                    style: AppTypography.labelLarge.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Raw ADC Information: "ADC Sensor: 500"
            Text(
              'ADC Sensor: $rawAdc',
              style: AppTypography.caption.copyWith(
                color: bodyColor.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 3. Realtime Indicator ───────────────────────────────────────────────────
  Widget _buildRealtimeIndicator(BuildContext context, SmartbandLdrController ctrl) {
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final isReceiving = ctrl.receivingData.value;
      final timeStr = ctrl.relativeTimeStr.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isReceiving
              ? AppColors.statusSafe.withValues(alpha: 0.08)
              : AppColors.canvasCreamSubtle.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isReceiving
                ? AppColors.statusSafe.withValues(alpha: 0.25)
                : AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            if (isReceiving)
              const AnimatedPingDot(size: 8, color: AppColors.statusSafe)
            else
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textCaption,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isReceiving ? '● Data realtime: $timeStr' : 'Menunggu data sensor...',
                style: AppTypography.bodySmall.copyWith(
                  color: isReceiving ? AppColors.statusSafe : bodyColor,
                  fontWeight: isReceiving ? FontWeight.w600 : FontWeight.normal,
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
      final adcValue = ctrl.rawDataString.value;
      final serviceStatus = ctrl.serviceDiscovered.value ? 'Connected' : 'Waiting';
      final charStatus = ctrl.characteristicDiscovered.value ? 'Connected' : 'Waiting';

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
              'Detail teknis BLE & status peripheral',
              style: AppTypography.caption.copyWith(
                color: bodyColor.withValues(alpha: 0.75),
              ),
            ),
            children: [
              const Divider(height: 16),
              _buildDebugRow(context, 'Device Name', ctrl.deviceName.value),
              _buildDebugRow(context, 'LDR ADC (Raw)', adcValue),
              _buildDebugRow(
                context,
                'BLE Status',
                isConnected ? 'Connected' : 'Disconnected',
                isSuccess: isConnected,
              ),
              _buildDebugRow(
                context,
                'Service UUID',
                serviceStatus,
                isSuccess: ctrl.serviceDiscovered.value,
                hint: BleService.serviceUuid,
              ),
              _buildDebugRow(
                context,
                'Characteristic UUID',
                charStatus,
                isSuccess: ctrl.characteristicDiscovered.value,
                hint: BleService.ldrCharacteristicUuid,
              ),
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
    if (isSuccess == true) {
      valColor = AppColors.statusSafe;
    } else if (isSuccess == false) {
      valColor = AppColors.textCaption;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
            disabledBackgroundColor: AppColors.primaryContainer.withValues(alpha: 0.6),
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
