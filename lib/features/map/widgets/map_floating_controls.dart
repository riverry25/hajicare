import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MapFloatingControls extends StatefulWidget {
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
  State<MapFloatingControls> createState() => _MapFloatingControlsState();
}

class _MapFloatingControlsState extends State<MapFloatingControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topOffset = MediaQuery.of(context).padding.top + 155;
    final isDark = AppColors.isDark(context);

    return Positioned(
      top: topOffset,
      right: AppSpacing.screenEdgeGutter,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Hamburger Toggle Button ───────────────────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleMenu,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isExpanded
                        ? AppColors.espressoDark
                        : (isDark
                              ? AppColors.darkSurface
                              : AppColors.surfaceWhite),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isExpanded
                          ? AppColors.goldPrimary
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : AppColors.goldLight.withValues(alpha: 0.35)),
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedIcon(
                        icon: AnimatedIcons.menu_close,
                        progress: _expandAnimation,
                        size: 22,
                        color: _isExpanded
                            ? AppColors.goldPrimary
                            : (isDark ? Colors.white : AppColors.espressoDark),
                      ),
                      if (widget.isLiveTracking && !_isExpanded)
                        Positioned(
                          right: 8,
                          top: 8,
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
              ),
            ),

            // ── Collapsible Floating Controls Group ───────────────────────────
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: _expandAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Compass / Kiblat Direction
                      _buildControlButton(
                        context: context,
                        icon: Icons.explore_rounded,
                        color: AppColors.goldPrimary,
                        tooltip: 'Arah Kompas / Kiblat',
                        onTap: widget.onCompassTap,
                        child: Transform.rotate(
                          angle: -widget.compassRotation * (math.pi / 180),
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
                        color: widget.isLiveTracking
                            ? AppColors.canvasCream
                            : AppColors.espressoDark,
                        bgColor: widget.isLiveTracking
                            ? AppColors.espressoDark
                            : (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.surfaceWhite),
                        borderColor: widget.isLiveTracking
                            ? AppColors.goldPrimary
                            : null,
                        tooltip: 'Pusatkan ke Lokasi Saya',
                        onTap: widget.onLocationTap,
                        child: widget.isLocationLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: widget.isLiveTracking
                                      ? AppColors.goldPrimary
                                      : AppColors.espressoDark,
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    widget.isLiveTracking
                                        ? Icons.my_location_rounded
                                        : Icons.location_searching_rounded,
                                    size: 22,
                                    color: widget.isLiveTracking
                                        ? AppColors.canvasCream
                                        : (isDark
                                              ? Colors.white
                                              : AppColors.espressoDark),
                                  ),
                                  if (widget.isLiveTracking)
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
                      if (widget.onZoomInTap != null ||
                          widget.onZoomOutTap != null) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : AppColors.goldLight.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.espressoDark.withValues(
                                  alpha: 0.10,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.onZoomInTap != null)
                                _buildMicroButton(
                                  context: context,
                                  icon: Icons.add_rounded,
                                  tooltip: 'Perbesar Peta',
                                  onTap: widget.onZoomInTap,
                                  isTop: true,
                                ),
                              if (widget.onZoomInTap != null &&
                                  widget.onZoomOutTap != null)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : AppColors.goldLight.withValues(
                                          alpha: 0.25,
                                        ),
                                ),
                              if (widget.onZoomOutTap != null)
                                _buildMicroButton(
                                  context: context,
                                  icon: Icons.remove_rounded,
                                  tooltip: 'Perkecil Peta',
                                  onTap: widget.onZoomOutTap,
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
                        color: isDark ? Colors.white : AppColors.espressoDark,
                        bgColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.surfaceWhite,
                        tooltip: 'Fokus ke Semua Anggota',
                        onTap: widget.onFitAllTap,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // 5. Map Tile Layer Switch (Voyager / OSM)
                      _buildControlButton(
                        context: context,
                        icon: Icons.layers_rounded,
                        color: AppColors.tanMedium,
                        bgColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.surfaceWhite,
                        tooltip: 'Ganti Tampilan Peta',
                        onTap: widget.onLayersTap,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // 6. Smart Band Paging
                      _buildControlButton(
                        context: context,
                        icon: Icons.ring_volume_rounded,
                        color: AppColors.espressoDark,
                        bgColor: AppColors.secondaryContainer.withValues(
                          alpha: 0.85,
                        ),
                        borderColor: AppColors.goldPrimary.withValues(
                          alpha: 0.5,
                        ),
                        tooltip: 'Panggil Gelang Jamaah',
                        onTap: widget.onBandTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final isDark = AppColors.isDark(context);
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
              color:
                  borderColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.goldLight.withValues(alpha: 0.35)),
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
          child: Center(child: child ?? Icon(icon, size: 22, color: color)),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Widget _buildMicroButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    bool isTop = false,
    bool isBottom = false,
  }) {
    final isDark = AppColors.isDark(context);
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
              color: isDark ? Colors.white : AppColors.espressoDark,
            ),
          ),
        ),
      ),
    );
  }
}
