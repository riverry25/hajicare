import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../models/sensor_context.dart';

/// **Kartu Konteks Sensor Live (Collapsible/Compact Card)** untuk menampilkan
/// metrik real-time gelang (BPM, Suhu °C, Jarak Radius, Status Aman/Jatuh, GPS)
/// beserta saklar **"Mode Simulasi Sensor"**.
class SensorContextLiveCard extends StatelessWidget {
  const SensorContextLiveCard({
    super.key,
    required this.sensor,
    required this.isExpanded,
    required this.isSimulationMode,
    required this.onToggleExpand,
    required this.onToggleSimulation,
    required this.onToggleFallSimulation,
    required this.onRefreshTap,
  });

  final SensorContext sensor;
  final bool isExpanded;
  final bool isSimulationMode;
  final VoidCallback onToggleExpand;
  final ValueChanged<bool> onToggleSimulation;
  final ValueChanged<bool> onToggleFallSimulation;
  final VoidCallback onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final bpm = sensor.heartRateBpm > 0 ? sensor.heartRateBpm : 78;
    final dist = (sensor.distanceToCompanionMeters ?? 12).round();
    final radius = (sensor.safeRadiusMeters ?? 200).round();

    return Container(
      decoration: BoxDecoration(
        color: hc.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: sensor.isFallDetected
              ? hc.danger.withValues(alpha: 0.6)
              : hc.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Collapsible
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (sensor.isFallDetected ? hc.danger : hc.primary)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      sensor.isFallDetected
                          ? Icons.warning_amber_rounded
                          : Icons.monitor_heart_rounded,
                      size: 18,
                      color: sensor.isFallDetected ? hc.danger : hc.primary,
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
                                'Konteks Sensor Gelang',
                                style: context.text.labelLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: hc.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: hc.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                sensor.source.label,
                                style: context.text.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: hc.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$bpm BPM • ${sensor.temperatureLabel}°C • '
                          '${sensor.isFallDetected ? "JATUH!" : "Aman"} • '
                          'Jarak ${dist}m',
                          style: context.text.labelSmall.copyWith(
                            color: sensor.isFallDetected
                                ? hc.danger
                                : hc.textSecondary,
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
                    onPressed: onRefreshTap,
                    tooltip: 'Segarkan Sensor',
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: hc.textSecondary,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: hc.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            Divider(height: 1, color: hc.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  // 4 Metrik Utama dalam Grid Responsif 2x2
                  Row(
                    children: [
                      Expanded(
                        child: _SensorMetricTile(
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFE11D48),
                          label: 'Detak Jantung',
                          value: '$bpm BPM',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SensorMetricTile(
                          icon: Icons.thermostat_rounded,
                          iconColor: const Color(0xFFEA580C),
                          label: 'Suhu Tubuh',
                          value: '${sensor.temperatureLabel} °C',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorMetricTile(
                          icon: Icons.social_distance_rounded,
                          iconColor: sensor.isOutsideSafeRadius
                              ? hc.danger
                              : hc.success,
                          label: 'Jarak Radius',
                          value: '${dist}m / ${radius}m',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SensorMetricTile(
                          icon: sensor.isFallDetected
                              ? Icons.personal_injury_rounded
                              : Icons.verified_user_rounded,
                          iconColor: sensor.isFallDetected
                              ? hc.danger
                              : hc.success,
                          label: 'Status Jatuh',
                          value: sensor.isFallDetected ? 'JATUH!' : 'Aman',
                        ),
                      ),
                    ],
                  ),
                  if (sensor.hasLocation) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: hc.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'GPS Gelang: ${sensor.latitude!.toStringAsFixed(5)}, '
                            '${sensor.longitude!.toStringAsFixed(5)}',
                            style: context.text.labelSmall.copyWith(
                              color: hc.textSecondary,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),

                  // Saklar Mode Simulasi Sensor + Uji Jatuh
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hc.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: hc.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.science_rounded,
                          size: 17,
                          color: hc.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Mode Simulasi Sensor',
                            style: context.text.labelMedium.copyWith(
                              color: hc.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSimulationMode)
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: () =>
                                onToggleFallSimulation(!sensor.isFallDetected),
                            child: Text(
                              sensor.isFallDetected
                                  ? 'Reset Jatuh'
                                  : 'Uji Jatuh',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: sensor.isFallDetected
                                    ? hc.success
                                    : hc.danger,
                              ),
                            ),
                          ),
                        Switch.adaptive(
                          value: isSimulationMode,
                          activeTrackColor: hc.primary,
                          onChanged: onToggleSimulation,
                        ),
                      ],
                    ),
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

class _SensorMetricTile extends StatelessWidget {
  const _SensorMetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: hc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: hc.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.labelSmall.copyWith(
                    fontSize: 10.5,
                    color: hc.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: context.text.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: hc.textPrimary,
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

