import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MapFloatingControls extends StatelessWidget {
  final VoidCallback? onCompassTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onLayersTap;
  final VoidCallback? onBandTap;
  final double compassRotation;
  final bool isLocationLoading;

  const MapFloatingControls({
    super.key,
    this.onCompassTap,
    this.onLocationTap,
    this.onLayersTap,
    this.onBandTap,
    this.compassRotation = 0.0,
    this.isLocationLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final topOffset = MediaQuery.of(context).padding.top + 155;

    return Positioned(
      top: topOffset,
      right: AppSpacing.screenEdgeGutter,
      child: Column(
        children: [
          // Compass (Rotates with map and resets to North when tapped)
          _buildControlButton(
            icon: Icons.explore,
            color: AppColors.accentGoldStar,
            tooltip: 'Reset Arah Utara',
            onTap: onCompassTap,
            child: Transform.rotate(
              angle: -compassRotation * (math.pi / 180),
              child: const Icon(
                Icons.explore,
                size: 24,
                color: AppColors.accentGoldStar,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Current User Location
          _buildControlButton(
            icon: Icons.my_location,
            color: AppColors.primary,
            tooltip: 'Lokasi Saya',
            onTap: onLocationTap,
            child: isLocationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.my_location,
                    size: 22,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Map Tile Layer Style (Voyager / OSM)
          _buildControlButton(
            icon: Icons.layers,
            color: AppColors.tanMedium,
            tooltip: 'Ganti Tampilan Peta',
            onTap: onLayersTap,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Smart Band Paging
          _buildControlButton(
            icon: Icons.ring_volume,
            color: AppColors.onSecondaryContainer,
            bgColor: AppColors.secondaryContainer,
            tooltip: 'Panggil Gelang Jamaah',
            onTap: onBandTap,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color bgColor = AppColors.surfaceWhite,
    String? tooltip,
    VoidCallback? onTap,
    Widget? child,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.espressoDark.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: child ?? Icon(icon, size: 22, color: color),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}
