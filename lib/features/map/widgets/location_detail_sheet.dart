import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/map_poi.dart';

/// Bottom sheet displaying dynamic information and action controls for a selected Point of Interest.
class LocationDetailSheet extends StatelessWidget {
  final MapPoi poi;
  final double? distanceMeters;
  final VoidCallback? onRoute;
  final VoidCallback? onShare;
  final VoidCallback? onClose;

  const LocationDetailSheet({
    super.key,
    required this.poi,
    this.distanceMeters,
    this.onRoute,
    this.onShare,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDistance = distanceMeters != null
        ? (distanceMeters! >= 1000
            ? '${(distanceMeters! / 1000).toStringAsFixed(1)} km'
            : '${distanceMeters!.round()} m')
        : 'Dekat';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        14,
        AppSpacing.cardPadding,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorderColor(context),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBorderColor(context),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Box
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: poi.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: poi.color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(poi.icon, color: poi.color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 13,
                          color: AppColors.tanMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$formattedDistance dari posisi Anda',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.textBodyColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          poi.isAccessible
                              ? Icons.accessible_rounded
                              : Icons.stairs_rounded,
                          size: 13,
                          color: poi.isAccessible
                              ? AppColors.statusPositive
                              : AppColors.tanMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          poi.isAccessible
                              ? 'Akses Kursi Roda Tersedia'
                              : 'Jalur Bertangga',
                          style: AppTypography.captionSmall.copyWith(
                            color: poi.isAccessible
                                ? AppColors.statusPositive
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (poi.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        poi.subtitle!,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: poi.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: poi.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        poi.statusLabel,
                        style: AppTypography.captionSmall.copyWith(
                          color: poi.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Close button
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.tanMedium,
                  splashRadius: 20,
                  onPressed: onClose,
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Actions Row: Rute Berjalan (Primary 52px) & Bagikan (Secondary)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRoute ?? () {},
                    icon: const Icon(
                      Icons.directions_walk_rounded,
                      size: 20,
                      color: AppColors.goldPrimary,
                    ),
                    label: Text(
                      'Rute Jalan Kaki',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.espressoDark,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.espressoDark.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        side: BorderSide(
                          color: AppColors.goldPrimary.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: onShare ?? () {},
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: AppColors.espressoDark,
                    ),
                    label: Text(
                      'Bagikan',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.espressoDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.canvasCream.withValues(
                        alpha: 0.35,
                      ),
                      side: BorderSide(
                        color: AppColors.cardBorderColor(context),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required MapPoi poi,
    double? distanceMeters,
    VoidCallback? onRoute,
    VoidCallback? onShare,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationDetailSheet(
        poi: poi,
        distanceMeters: distanceMeters,
        onRoute: onRoute,
        onShare: onShare,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
