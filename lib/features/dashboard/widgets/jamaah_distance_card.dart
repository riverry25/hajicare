import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/hajicare_controller.dart';
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
    if (dt == null) return 'Menunggu lokasi...';
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

    // Check if user has active room
    final controller = Get.isRegistered<HajiCareController>() ? Get.find<HajiCareController>() : null;
    final hasActiveRoom = controller?.activeRoomId.value != null && controller!.activeRoomId.value!.isNotEmpty;

    if (!hasActiveRoom) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        borderColor: isDark ? AppColors.darkCardBorder : AppColors.goldLight.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimaryContainer : AppColors.canvasCream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radar & Jarak Rombongan',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Fitur pemantauan jarak real-time dengan pendamping memerlukan koneksi room aktif.',
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.joinRoom),
                icon: const Icon(Icons.meeting_room_outlined, size: 20),
                label: const Text(
                  'Gabung Room untuk Mengaktifkan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 1. STATE: GPS is completely inactive on this device
    if (!jamaah.isGpsActive) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        borderColor: AppColors.error.withValues(alpha: isDark ? 0.6 : 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    color: AppColors.error,
                    size: 26,
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
                      const SizedBox(height: 3),
                      Text(
                        'Pendamping tidak dapat melacak posisi Anda saat sensor GPS nonaktif.',
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  onRefreshGps?.call();
                },
                icon: const Icon(Icons.settings_rounded, size: 20),
                label: Text(
                  'Aktifkan GPS Sekarang',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.surfaceWhite,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. STATE: GPS active, but waiting for companion's location signal
    final hasDistance =
        jamaah.distance > 0.0 || jamaah.locationUpdatedAt != null;
    if (!hasDistance) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.canvasCream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    color: isDark
                        ? AppColors.goldLight
                        : AppColors.espressoDark,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menghubungkan ke Pendamping',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'GPS Anda aktif. Menunggu pembaruan lokasi dari pendamping rombongan.',
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const AppStatusBadge(
                  label: 'Menunggu',
                  statusType: AppStatusType.warning,
                  icon: Icons.hourglass_top_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                backgroundColor: isDark
                    ? AppColors.darkSurfaceContainerHighest
                    : AppColors.canvasCreamSubtle,
                color: AppColors.goldPrimary,
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }

    // 3. STATE: Normal real distance available - Modernized clean card
    final tierColor = jamaah.tier.color;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      context.tr('distanceToCompanion'),
                      style: AppTypography.caption.copyWith(
                        color: bodyColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
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

          const SizedBox(height: AppSpacing.lg),

          // Big Distance Hero Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.canvasCream.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              jamaah.distance >= 1000
                                  ? (jamaah.distance / 1000).toStringAsFixed(
                                      jamaah.distance >= 100000 ? 0 : 1,
                                    )
                                  : '${jamaah.distance.toInt()}',
                              style: AppTypography.heroNumberLarge.copyWith(
                                color: tierColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              jamaah.distance >= 1000
                                  ? 'km'
                                  : context.tr('meterUnit'),
                              style: AppTypography.titleMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Batas aman rombongan: ${controller.safeRadiusMeters.value.toInt()} meter',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: bodyColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(jamaah.tier.icon, color: tierColor, size: 28),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Visual Safe Radius Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (jamaah.distance / controller.safeRadiusMeters.value).clamp(0.0, 1.0),
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainerHighest
                  : AppColors.canvasCreamSubtle,
              color: tierColor,
              minHeight: 8,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Sync metadata row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Terakhir sinkron: ${_formatTimestamp(jamaah.locationUpdatedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: bodyColor),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
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
                  const SizedBox(width: 5),
                  Text(
                    'GPS Presisi',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.statusSafe,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // View on Map Action
          InkWell(
            onTap: onViewMap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimaryContainer
                              : AppColors.canvasCream,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: AppColors.tanMedium,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        context.tr('viewCompanionOnMap'),
                        style: AppTypography.labelLarge.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
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
