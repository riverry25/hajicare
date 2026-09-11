import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MapFloatingControls extends StatelessWidget {
  final VoidCallback? onCompassTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onLayersTap;
  final VoidCallback? onBandTap;

  const MapFloatingControls({
    super.key,
    this.onCompassTap,
    this.onLocationTap,
    this.onLayersTap,
    this.onBandTap,
  });

  @override
  Widget build(BuildContext context) {
    final topOffset = MediaQuery.of(context).padding.top + 155;

    return Positioned(
      top: topOffset,
      right: AppSpacing.screenEdgeGutter,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.explore,
            color: AppColors.accentGoldStar,
            onTap: onCompassTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildControlButton(
            icon: Icons.my_location,
            color: AppColors.primary,
            onTap: onLocationTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildControlButton(
            icon: Icons.layers,
            color: AppColors.tanMedium,
            onTap: onLayersTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildControlButton(
            icon: Icons.ring_volume,
            color: AppColors.onSecondaryContainer,
            bgColor: AppColors.secondaryContainer,
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
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
              color: AppColors.espressoDark.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
