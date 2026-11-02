import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../smartband/widgets/battery_optimization_sheet.dart';
import '../models/sensor_context.dart';

/// Kartu **Konteks Sensor Gelang & Data Aplikasi Real-Time (Tanpa Simulasi)**.
///
/// Menampilkan:
/// 1. Status perangkat fisik **HajiCare Smartband BLE** (jika belum terhubung,
///    ditampilkan jujur `-- BPM`, `-- °C` beserta tombol **Sambungkan Gelang Bluetooth**).
/// 2. Data nyata dari **Aplikasi & HP** (Koordinat GPS HP & Kota, Jarak Real-Time
///    ke Pendamping, Status Room/Kloter/Maktab, serta Jadwal Salat & Arah Kiblat).
class SensorContextLiveCard extends StatelessWidget {
  const SensorContextLiveCard({
    super.key,
    required this.sensor,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onRefreshTap,
    this.onConnectSmartbandTap,
  });

  final SensorContext sensor;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onRefreshTap;
  final VoidCallback? onConnectSmartbandTap;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final bleConnected = sensor.isSmartbandConnected;
    final hasAlert =
        (bleConnected && sensor.isFallDetected) || sensor.isOutsideSafeRadius;

    return Container(
      decoration: BoxDecoration(
        color: hc.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: hasAlert ? hc.danger.withValues(alpha: 0.65) : hc.border,
          width: hasAlert ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Ringkas (Selalu Terlihat)
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () {
              HapticFeedback.selectionClick();
              onToggleExpand();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (bleConnected ? hc.success : hc.warning)
                          .withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      bleConnected
                          ? Icons.bluetooth_connected_rounded
                          : Icons.bluetooth_disabled_rounded,
                      size: 18,
                      color: bleConnected ? hc.success : hc.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                context.tr('ai.sensorCardTitle'),
                                style: context.text.labelLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: hc.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _SourceBadge(isConnected: bleConnected),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bleConnected
                              ? '${sensor.heartRateDisplay} • ${sensor.temperatureLabel}°C • ${sensor.fallStatusLabel}'
                              : context.tr('ai.bandNotConnectedSub'),
                          style: context.text.labelSmall.copyWith(
                            color: hasAlert ? hc.danger : hc.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Mode Latar Belakang 24/7 (Baterai)',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      BatteryOptimizationSheet.show(context);
                    },
                    icon: Icon(
                      Icons.battery_saver_rounded,
                      size: 18,
                      color: hc.textSecondary,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: context.tr('ai.refreshRealtimeTooltip'),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onRefreshTap();
                    },
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: hc.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            Divider(height: 1, color: hc.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. BAGIAN SENSOR GELANG BLE
                  if (!bleConnected)
                    _DisconnectedSmartbandBanner(
                      onConnectTap: onConnectSmartbandTap,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 420;
                        final itemWidth = isWide
                            ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                            : (constraints.maxWidth - AppSpacing.sm) / 2;

                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _MetricTile(
                                icon: Icons.favorite_rounded,
                                label: context.tr('ai.metricHeartRate'),
                                value: sensor.heartRateBpm > 0
                                    ? '${sensor.heartRateBpm} BPM'
                                    : context.tr('ai.metricReading'),
                                isWarning: sensor.isHeartRateAbnormal,
                                accentColor: const Color(0xFFE11D48),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _MetricTile(
                                icon: Icons.thermostat_rounded,
                                label: context.tr('ai.metricBodyTemp'),
                                value: sensor.temperatureC > 0
                                    ? '${sensor.temperatureLabel} °C'
                                    : context.tr('ai.metricReading'),
                                isWarning: sensor.isTemperatureAbnormal,
                                accentColor: const Color(0xFFEA580C),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _MetricTile(
                                icon: Icons.health_and_safety_rounded,
                                label: context.tr('ai.metricFallStatus'),
                                value: sensor.isFallDetected
                                    ? context.tr('ai.metricFallDetected')
                                    : context.tr('ai.metricSafe'),
                                isWarning: sensor.isFallDetected,
                                accentColor: sensor.isFallDetected
                                    ? hc.danger
                                    : hc.success,
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _MetricTile(
                                icon: Icons.directions_walk_rounded,
                                label: 'Langkah Kaki',
                                value: '${sensor.stepCount ?? 0} lkh',
                                isWarning: false,
                                accentColor: hc.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: AppSpacing.md),

                  // 2. BAGIAN KONTEKS NYATA APLIKASI & HP
                  Text(
                    context.tr('ai.realAppSectionTitle'),
                    style: context.text.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: hc.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  _RealAppInfoRow(
                    icon: Icons.my_location_rounded,
                    title: context.tr('ai.infoPhoneGpsTitle'),
                    value: sensor.hasPhoneLocation
                        ? '${sensor.locationCityName != null ? "${sensor.locationCityName} • " : ""}'
                              '${sensor.phoneLatitude!.toStringAsFixed(5)}, ${sensor.phoneLongitude!.toStringAsFixed(5)}'
                        : context.tr('ai.infoPhoneGpsWaiting'),
                    isWarning: !sensor.hasPhoneLocation,
                  ),
                  const SizedBox(height: 6),
                  _RealAppInfoRow(
                    icon: Icons.social_distance_rounded,
                    title: context.tr('ai.infoCompanionDistTitle'),
                    value: sensor.distanceStatusSummary,
                    isWarning: sensor.isOutsideSafeRadius,
                  ),
                  const SizedBox(height: 6),
                  _RealAppInfoRow(
                    icon: Icons.groups_rounded,
                    title: context.tr('ai.infoRoomMembersTitle'),
                    value: sensor.hasActiveRoom
                        ? '${sensor.roomName ?? "Room Aktif"} '
                              '${sensor.kloter != null ? "• Kloter ${sensor.kloter} " : ""}'
                              '${sensor.maktab != null ? "• Maktab ${sensor.maktab}" : ""}'
                              '${sensor.closestJamaahSummary != null ? "\n${sensor.closestJamaahSummary}" : ""}'
                        : context.tr('ai.infoRoomNotJoined'),
                    isWarning: false,
                  ),
                  const SizedBox(height: 6),
                  _RealAppInfoRow(
                    icon: Icons.mosque_rounded,
                    title: context.tr('ai.infoPrayerQiblaTitle'),
                    value: (sensor.nextPrayerName != null &&
                            sensor.nextPrayerTime != null)
                        ? '${sensor.nextPrayerName} ${sensor.nextPrayerTime} '
                              '${sensor.nextPrayerCountdown != null ? "(${sensor.nextPrayerCountdown}) " : ""}'
                              '• Kiblat ${sensor.qiblaBearingDegrees?.round() ?? "--"}°'
                        : context.tr('ai.infoPrayerSyncHint'),
                    isWarning: false,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DisconnectedSmartbandBanner extends StatelessWidget {
  const _DisconnectedSmartbandBanner({this.onConnectTap});

  final VoidCallback? onConnectTap;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: hc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.watch_off_rounded,
                size: 18,
                color: hc.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('ai.bandDisconnectedBannerTitle'),
                  style: context.text.titleSmall.copyWith(
                    color: hc.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('ai.bandDisconnectedBannerDesc'),
            style: context.text.bodySmall.copyWith(
              color: hc.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (onConnectTap != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onConnectTap,
                icon: Icon(
                  Icons.bluetooth_searching_rounded,
                  size: 17,
                  color: hc.primary,
                ),
                label: Text(
                  context.tr('ai.connectBleButton'),
                  style: context.text.labelMedium.copyWith(
                    color: hc.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: hc.borderStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RealAppInfoRow extends StatelessWidget {
  const _RealAppInfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isWarning,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isWarning
            ? hc.danger.withValues(alpha: 0.08)
            : hc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isWarning ? hc.danger.withValues(alpha: 0.4) : hc.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 16,
              color: isWarning ? hc.danger : hc.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.labelSmall.copyWith(
                    color: isWarning ? hc.danger : hc.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: context.text.bodySmall.copyWith(
                    color: isWarning ? hc.danger : hc.textPrimary,
                    fontWeight: FontWeight.w500,
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
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final color = isConnected ? hc.success : hc.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        isConnected
            ? context.tr('ai.badgeBleConnected')
            : context.tr('ai.badgeBleDisconnected'),
        style: context.text.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isWarning,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isWarning
            ? hc.danger.withValues(alpha: 0.08)
            : hc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isWarning ? hc.danger.withValues(alpha: 0.45) : hc.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: accentColor),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.labelSmall.copyWith(
                    color: hc.textSecondary,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: context.text.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isWarning ? hc.danger : hc.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
