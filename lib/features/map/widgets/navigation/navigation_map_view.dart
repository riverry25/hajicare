import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_context.dart';
import '../../controllers/map_controller.dart';
import '../gps_user_puck.dart';

/// High-performance, butter-smooth Navigation Map View.
/// Preserves FlutterMap and CARTO basemap architecture per hajicare-map rules.
/// Zero platform-view overhead, seamless 60/120 FPS gesture handling
/// hardware-accelerated polyline rendering, and dynamic rotating GPS user puck.
class NavigationMapView extends StatefulWidget {
  final MapController mapCtrl;

  const NavigationMapView({super.key, required this.mapCtrl});

  @override
  State<NavigationMapView> createState() => _NavigationMapViewState();
}

class _NavigationMapViewState extends State<NavigationMapView> {
  Worker? _locationWorker;
  DateTime? _lastCameraMoveTime;

  @override
  void initState() {
    super.initState();

    // Listen for recenter callback from controller
    widget.mapCtrl.onRecenterTriggered = _handleRecenter;

    // Reactively follow camera when user location changes
    _locationWorker = ever(widget.mapCtrl.currentUserLocation, (
      ll.LatLng? pos,
    ) {
      if (pos != null && widget.mapCtrl.isFollowingUser.value) {
        _smoothFollowUser(pos);
      }
    });

    // Ensure map starts centered on user position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRecenter();
    });
  }

  @override
  void dispose() {
    _locationWorker?.dispose();
    if (widget.mapCtrl.onRecenterTriggered == _handleRecenter) {
      widget.mapCtrl.onRecenterTriggered = null;
    }
    super.dispose();
  }

  void _handleRecenter() {
    final userLoc = widget.mapCtrl.currentUserLocation.value;
    if (userLoc != null && widget.mapCtrl.isMapAttached) {
      widget.mapCtrl.animatedMove(userLoc, 18.0);
    }
  }

  void _smoothFollowUser(ll.LatLng pos) {
    if (!widget.mapCtrl.isMapAttached) return;
    final now = DateTime.now();
    // Throttle camera moves to 450ms intervals to prevent animation thrashing while maintaining smooth follow
    if (_lastCameraMoveTime != null &&
        now.difference(_lastCameraMoveTime!).inMilliseconds < 450) {
      return;
    }
    _lastCameraMoveTime = now;
    widget.mapCtrl.animatedMove(pos, 18.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.hc.isDark;
    final userLoc =
        widget.mapCtrl.currentUserLocation.value ??
        MapController.defaultMinaBase;
    final effectiveTile = isDark
        ? AppConstants.cartoDarkMatterUrl
        : AppConstants.cartoVoyagerUrl;

    return RepaintBoundary(
      child: fmap.FlutterMap(
        mapController: widget.mapCtrl.ensureFreshMapController(),
        options: fmap.MapOptions(
          initialCenter: userLoc,
          initialZoom: 18.0,
          minZoom: 11.0,
          maxZoom: 19.5,
          onPositionChanged: (camera, hasGesture) {
            // Immediate, lag-free user interaction detection
            if (hasGesture && widget.mapCtrl.isFollowingUser.value) {
              widget.mapCtrl.onNavigationUserPan();
            }
          },
        ),
        children: [
          // 1. CARTO Basemap Layer
          fmap.TileLayer(
            urlTemplate: effectiveTile,
            userAgentPackageName: 'com.example.hajicare',
            panBuffer: 1,
          ),

          // 2. High-contrast Route Polyline Layer
          Obx(() {
            final route = widget.mapCtrl.activeRoute;
            if (route.length < 2) return const SizedBox.shrink();

            return fmap.PolylineLayer(
              polylines: [
                // Outer casing for high contrast on both dark and light tiles
                fmap.Polyline(
                  points: route.toList(),
                  strokeWidth: 10.0,
                  color: isDark
                      ? const Color(0xFF0F3D1F)
                      : const Color(0xFF14532D),
                  borderStrokeWidth: 0.0,
                ),
                // Inner vibrant emerald route
                fmap.Polyline(
                  points: route.toList(),
                  strokeWidth: 6.5,
                  color: const Color(0xFF22C55E),
                  borderStrokeWidth: 0.0,
                ),
              ],
            );
          }),

          // 3. Destination Pin Marker Layer
          Obx(() {
            final dest = widget.mapCtrl.currentDestinationCoord;
            if (dest == null) return const SizedBox.shrink();

            return fmap.MarkerLayer(
              markers: [
                fmap.Marker(
                  point: dest,
                  width: 48,
                  height: 48,
                  child: RepaintBoundary(child: _buildDestinationPin(context)),
                ),
              ],
            );
          }),

          // 4. Dynamic GPS User Puck with Directional Beam & Compass Rotation
          Obx(() {
            final user = widget.mapCtrl.currentUserLocation.value;
            if (user == null) return const SizedBox.shrink();

            return fmap.MarkerLayer(
              markers: [
                fmap.Marker(
                  point: user,
                  width: 88,
                  height: 88,
                  child: RepaintBoundary(
                    child: GpsUserPuck(
                      mapCtrl: widget.mapCtrl,
                      isNavigating: true,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDestinationPin(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE11D48).withValues(alpha: 0.20),
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE11D48),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 16),
        ),
      ],
    );
  }
}
