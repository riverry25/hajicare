import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pill_button.dart';
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
      padding: const EdgeInsets.all(AppConstants.spaceLg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppConstants.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
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
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: poi.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(poi.icon, color: poi.color, size: 30),
              ),
              const SizedBox(width: AppConstants.spaceMd),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.espressoDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Jarak: $formattedDistance • ${poi.isAccessible ? "Akses Kursi Roda Tersedia" : "Jalan Tangga"}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                    if (poi.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        poi.subtitle!,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.tanMedium,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusPositive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      ),
                      child: Text(
                        poi.statusLabel,
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.statusPositive,
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
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textBody,
                  onPressed: onClose,
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceLg),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'Rute Berjalan',
                  icon: Icons.directions_walk,
                  onPressed: onRoute ?? () {},
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: PillButton(
                  label: 'Bagikan',
                  icon: Icons.share_outlined,
                  onPressed: onShare ?? () {},
                  isOutline: true,
                  color: AppColors.goldLight,
                  textColor: AppColors.espressoDark,
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
