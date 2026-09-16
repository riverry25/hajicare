import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MapFloatingControls extends StatelessWidget {
  final VoidCallback? onCompassTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onFitAllTap;
  final VoidCallback? onLayersTap;
  final VoidCallback? onBandTap;
  final VoidCallback? onZoomInTap;
  final VoidCallback? onZoomOutTap;
  final double compassRotation;
  final bool isLocationLoading;
  final bool isLiveTracking;

  const MapFloatingControls({
    super.key,
    this.onCompassTap,
    this.onLocationTap,
    this.onFitAllTap,
    this.onLayersTap,
    this.onBandTap,
    this.onZoomInTap,
    this.onZoomOutTap,
    this.compassRotation = 0.0,
    this.isLocationLoading = false,
    this.isLiveTracking = false,
  });

  @override
  Widget build(BuildContext context) {
    final topOffset = MediaQuery.of(context).padding.top + 160;

    return Positioned(
      top: topOffset,
      right: AppSpacing.screenEdgeGutter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Compass / Kiblat Direction
          _buildControlButton(
            context: context,
            icon: Icons.explore_rounded,
            color: AppColors.goldPrimary,
            tooltip: 'Arah Kompas / Kiblat',
            onTap: onCompassTap,
            child: Transform.rotate(
              angle: -compassRotation * (math.pi / 180),
              child: const Icon(
                Icons.explore_rounded,
                size: 24,
                color: AppColors.goldPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. Re-center Current User Location
          _buildControlButton(
            context: context,
            icon: Icons.my_location_rounded,
            color: isLiveTracking ? AppColors.canvasCream : AppColors.espressoDark,
            bgColor: isLiveTracking ? AppColors.espressoDark : AppColors.surfaceWhite,
            borderColor: isLiveTracking ? AppColors.goldPrimary : null,
            tooltip: 'Pusatkan ke Lokasi Saya',
            onTap: onLocationTap,
            child: isLocationLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: isLiveTracking
                          ? AppColors.goldPrimary
                          : AppColors.espressoDark,
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        isLiveTracking
                            ? Icons.my_location_rounded
                            : Icons.location_searching_rounded,
                        size: 22,
                        color: isLiveTracking
                            ? AppColors.canvasCream
                            : AppColors.espressoDark,
                      ),
                      if (isLiveTracking)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.statusSafe,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 3. Zoom Controls Group (In / Out)
          if (onZoomInTap != null || onZoomOutTap != null) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.goldLight.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onZoomInTap != null)
                    _buildMicroButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Perbesar Peta',
                      onTap: onZoomInTap,
                      isTop: true,
                    ),
                  if (onZoomInTap != null && onZoomOutTap != null)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.goldLight.withValues(alpha: 0.25),
                    ),
                  if (onZoomOutTap != null)
                    _buildMicroButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Perkecil Peta',
                      onTap: onZoomOutTap,
                      isBottom: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // 4. Focus All Room Members
          _buildControlButton(
            context: context,
            icon: Icons.groups_rounded,
            color: AppColors.espressoDark,
            tooltip: 'Fokus ke Semua Anggota',
            onTap: onFitAllTap,
          ),
          const SizedBox(height: AppSpacing.sm),

          // 5. Map Tile Layer Switch (Voyager / OSM)
          _buildControlButton(
            context: context,
            icon: Icons.layers_rounded,
            color: AppColors.tanMedium,
            tooltip: 'Ganti Tampilan Peta',
            onTap: onLayersTap,
          ),
          const SizedBox(height: AppSpacing.sm),

          // 6. Smart Band Paging
          _buildControlButton(
            context: context,
            icon: Icons.ring_volume_rounded,
            color: AppColors.espressoDark,
            bgColor: AppColors.secondaryContainer.withValues(alpha: 0.85),
            borderColor: AppColors.goldPrimary.withValues(alpha: 0.5),
            tooltip: 'Panggil Gelang Jamaah',
            onTap: onBandTap,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    Color bgColor = AppColors.surfaceWhite,
    Color? borderColor,
    String? tooltip,
    VoidCallback? onTap,
    Widget? child,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? AppColors.goldLight.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.espressoDark.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: child ?? Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Widget _buildMicroButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    bool isTop = false,
    bool isBottom = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(16) : Radius.zero,
          bottom: isBottom ? const Radius.circular(16) : Radius.zero,
        ),
        child: SizedBox(
          width: 46,
          height: 38,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: AppColors.espressoDark,
            ),
          ),
        ),
      ),
    );
  }
}
