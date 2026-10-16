import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';

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
  final bool isVisible;

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
    this.isVisible = true,
  });

  @override
  State<MapFloatingControls> createState() => _MapFloatingControlsState();
}

class _MapFloatingControlsState extends State<MapFloatingControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(milliseconds: 320),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(MapFloatingControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible && !widget.isVisible && _isExpanded) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
    }
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
    final hc = context.hc;

    return Positioned(
      top: topOffset,
      right: AppSpacing.screenEdgeGutter,
      child: RepaintBoundary(
        child: AnimatedOpacity(
          opacity: widget.isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !widget.isVisible,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ── Hamburger Toggle Button ───────────────────────────────────────
                Tooltip(
                  message: _isExpanded
                      ? context.tr('maps.closeMapControls')
                      : context.tr('maps.openMapControls'),
                  child: Semantics(
                    button: true,
                    label: _isExpanded
                        ? context.tr('maps.closeMapControls')
                        : context.tr('maps.openMapControls'),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleMenu,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _isExpanded
                                ? hc.primary
                                : hc.surface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isExpanded ? hc.accent : hc.border,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: hc.shadow,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedIcon(
                                icon: AnimatedIcons.menu_close,
                                progress: _expandAnimation,
                                size: 22,
                                color: _isExpanded
                                    ? hc.onPrimary
                                    : hc.textPrimary,
                              ),
                              if (widget.isLiveTracking && !_isExpanded)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: hc.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Collapsible Floating Controls Group ───────────────────────────
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  alignment: Alignment.topCenter,
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
                            color: hc.accent,
                            tooltip: context.tr('maps.compassDirection'),
                            onTap: widget.onCompassTap,
                            child: Transform.rotate(
                              angle: -widget.compassRotation * (math.pi / 180),
                              child: Icon(
                                Icons.explore_rounded,
                                size: 24,
                                color: hc.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // 2. Re-center Current User Location
                          _buildControlButton(
                            context: context,
                            icon: Icons.my_location_rounded,
                            color: widget.isLiveTracking
                                ? hc.onPrimary
                                : hc.textPrimary,
                            bgColor: widget.isLiveTracking
                                ? hc.primary
                                : hc.surface.withValues(alpha: 0.95),
                            borderColor: widget.isLiveTracking
                                ? hc.accent
                                : null,
                            tooltip: context.tr('maps.centerMyLocation'),
                            onTap: widget.onLocationTap,
                            child: widget.isLocationLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: widget.isLiveTracking
                                          ? hc.accent
                                          : hc.primary,
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
                                            ? hc.onPrimary
                                            : hc.textPrimary,
                                      ),
                                      if (widget.isLiveTracking)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: hc.success,
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
                                color: hc.surface.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hc.border,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: hc.shadow,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
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
                                      tooltip: context.tr('maps.zoomIn'),
                                      onTap: widget.onZoomInTap,
                                      isTop: true,
                                    ),
                                  if (widget.onZoomInTap != null &&
                                      widget.onZoomOutTap != null)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: hc.border,
                                    ),
                                  if (widget.onZoomOutTap != null)
                                    _buildMicroButton(
                                      context: context,
                                      icon: Icons.remove_rounded,
                                      tooltip: context.tr('maps.zoomOut'),
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
                            color: hc.textPrimary,
                            bgColor: hc.surface.withValues(alpha: 0.95),
                            tooltip: context.tr('maps.focusAllMembers'),
                            onTap: widget.onFitAllTap,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // 5. Map Tile Layer Switch (Voyager / OSM)
                          _buildControlButton(
                            context: context,
                            icon: Icons.layers_rounded,
                            color: hc.accent,
                            bgColor: hc.surface.withValues(alpha: 0.95),
                            tooltip: context.tr('maps.switchMapLayer'),
                            onTap: widget.onLayersTap,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // 6. Smart Band Paging
                          _buildControlButton(
                            context: context,
                            icon: Icons.ring_volume_rounded,
                            color: hc.primary,
                            bgColor: hc.primaryContainer.withValues(alpha: 0.9),
                            borderColor: hc.accent.withValues(alpha: 0.5),
                            tooltip: context.tr('maps.ringSmartBand'),
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
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    Color? bgColor,
    Color? borderColor,
    String? tooltip,
    VoidCallback? onTap,
    Widget? child,
  }) {
    final hc = context.hc;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor ?? hc.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor ?? hc.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: hc.shadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: child ?? Icon(icon, size: 22, color: color)),
        ),
      ),
    );

    if (tooltip != null) {
      return Semantics(
        button: true,
        label: tooltip,
        child: Tooltip(message: tooltip, child: button),
      );
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
    final hc = context.hc;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: isTop ? const Radius.circular(16) : Radius.zero,
              bottom: isBottom ? const Radius.circular(16) : Radius.zero,
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: Icon(icon, size: 20, color: hc.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}
