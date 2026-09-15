import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/models/jamaah_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';

class JamaahDistanceCard extends StatelessWidget {
  final JamaahData jamaah;
  final VoidCallback? onViewMap;
  final VoidCallback? onRefreshGps;

  const JamaahDistanceCard({
    super.key,
    required this.jamaah,
    this.onViewMap,
    this.onRefreshGps,
  });

  AppStatusType _mapStatusType(DistanceTier tier) {
    switch (tier) {
      case DistanceTier.aman:
        return AppStatusType.safe;
      case DistanceTier.waspada:
        return AppStatusType.warning;
      case DistanceTier.terlalujJauh:
        return AppStatusType.danger;
    }
  }

  String _localizedTierLabel(BuildContext context, DistanceTier tier) {
    switch (tier) {
      case DistanceTier.aman:
        return context.tr('statusSafe');
      case DistanceTier.waspada:
        return context.tr('statusWarning');
      case DistanceTier.terlalujJauh:
        return context.tr('statusDanger');
    }
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'Menunggu sinyal...';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 30) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDistanceValue(double distanceMeters) {
    if (distanceMeters >= 100000) {
      return (distanceMeters / 1000).toStringAsFixed(0);
    } else if (distanceMeters >= 1000) {
      final km = distanceMeters / 1000;
      return km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    } else {
      return distanceMeters.toInt().toString();
    }
  }

  String _formatDistanceUnit(BuildContext context, double distanceMeters) {
    return distanceMeters >= 1000 ? 'km' : context.tr('meterUnit');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    // 1. STATE: GPS is completely inactive on this device
    if (!jamaah.isGpsActive) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderColor: AppColors.error.withValues(alpha: isDark ? 0.6 : 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Anda Tidak Aktif',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pendamping tidak dapat melacak jarak & posisi Anda saat GPS mati.',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  onRefreshGps?.call();
                },
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Aktifkan GPS Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. STATE: GPS active, but waiting for companion's location signal
    final hasDistance = jamaah.distance > 0.0 || jamaah.locationUpdatedAt != null;
    if (!hasDistance) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.canvasCream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menunggu Lokasi Pendamping',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'GPS Anda aktif. Menunggu sinyal koordinat dari pendamping.',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const AppStatusBadge(
                  label: 'Menunggu',
                  statusType: AppStatusType.warning,
                  icon: Icons.hourglass_top_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainerHighest
                  : AppColors.surfaceVariant,
              color: AppColors.accentGoldStar,
              minHeight: 6,
            ),
          ],
        ),
      );
    }

    // 3. STATE: Normal real distance available
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.radar,
                  color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('distanceToCompanion'),
                      style: AppTypography.caption.copyWith(
                        color: bodyColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatDistanceValue(jamaah.distance),
                            style: AppTypography.displayMedium.copyWith(
                              color: jamaah.tier.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDistanceUnit(context, jamaah.distance),
                            style: AppTypography.bodySmall.copyWith(
                              color: bodyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusBadge(
                label: _localizedTierLabel(context, jamaah.tier),
                statusType: _mapStatusType(jamaah.tier),
                icon: jamaah.tier.icon,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (jamaah.distance / 200).clamp(0.0, 1.0),
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainerHighest
                  : AppColors.surfaceVariant,
              color: jamaah.tier.color,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terakhir sinkron: ${_formatTimestamp(jamaah.locationUpdatedAt)}',
                style: AppTypography.captionSmall.copyWith(
                  color: bodyColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.statusSafe,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'GPS Akurat',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.statusSafe,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm2),
          Divider(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.canvasCreamSubtle,
          ),
          InkWell(
            onTap: onViewMap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pin_drop,
                          color: AppColors.tanMedium,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            context.tr('viewCompanionOnMap'),
                            style: AppTypography.labelLarge.copyWith(
                              color: headingColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: headingColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

