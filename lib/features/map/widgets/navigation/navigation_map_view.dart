import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/map_controller.dart';

/// Helper to determine if native MapLibre GL is supported on the current platform.
bool get isMapLibreSupported {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS;
}

/// Perspective 3D Navigation Map View.
/// Uses MapLibre GL for true native camera tilt/pitch (55°) and heading-up bearing rotation
/// on mobile, with a fallback to flutter_map on desktop/unsupported environments.
class NavigationMapView extends StatefulWidget {
  final MapController mapCtrl;

  const NavigationMapView({super.key, required this.mapCtrl});

  @override
  State<NavigationMapView> createState() => _NavigationMapViewState();
}

class _NavigationMapViewState extends State<NavigationMapView> {
  ml.MapLibreMapController? _maplibreController;
  bool _isStyleLoaded = false;
  Timer? _cameraFollowDebounce;
  Worker? _locationWorker;
  Worker? _bearingWorker;
  Worker? _routeWorker;
  ml.Symbol? _puckSymbol;

  // Touch drag tracking to prevent taps or programmatic anims from disabling follow mode
  Offset? _touchStartPos;
  double _accumulatedDrag = 0.0;

  @override
  void initState() {
    super.initState();

    // Listen for recenter callback from controller
    widget.mapCtrl.onRecenterTriggered = _handleRecenter;

    // Reactively update camera and native puck symbol when location changes
    _locationWorker = ever(widget.mapCtrl.currentUserLocation, (
      ll.LatLng? pos,
    ) {
      if (pos != null) {
        if (widget.mapCtrl.isFollowingUser.value) {
          _scheduleCameraFollow();
        }
        _updatePuckNativeSymbol();
      }
    });

    _bearingWorker = ever(widget.mapCtrl.navigationBearing, (double bearing) {
      if (widget.mapCtrl.isFollowingUser.value) {
        _scheduleCameraFollow();
      }
      _updatePuckNativeSymbol();
    });

    _routeWorker = ever(widget.mapCtrl.activeRoute, (List<ll.LatLng> points) {
      _drawRouteAndMarkers();
    });
  }

  @override
  void dispose() {
    _cameraFollowDebounce?.cancel();
    _locationWorker?.dispose();
    _bearingWorker?.dispose();
    _routeWorker?.dispose();
    if (widget.mapCtrl.onRecenterTriggered == _handleRecenter) {
      widget.mapCtrl.onRecenterTriggered = null;
    }
    super.dispose();
  }

  void _handleRecenter() {
    if (isMapLibreSupported && _maplibreController != null && _isStyleLoaded) {
      _animateCameraToFollow(force: true, durationMs: 800);
    } else if (!isMapLibreSupported && widget.mapCtrl.isMapAttached) {
      final userLoc = widget.mapCtrl.currentUserLocation.value;
      if (userLoc != null) {
        widget.mapCtrl.flutterMapController.move(userLoc, 18.0);
        widget.mapCtrl.flutterMapController.rotate(
          widget.mapCtrl.navigationBearing.value,
        );
      }
    }
  }

  void _scheduleCameraFollow() {
    _cameraFollowDebounce?.cancel();
    _cameraFollowDebounce = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animateCameraToFollow();
      }
    });
  }

  /// Style JSON embedding official Carto API key to prevent "API KEY REQUIRED" watermark
  String _getCartoStyleJson(bool isDark) {
    final tileUrl = isDark
        ? AppConstants.cartoDarkMatterUrl
        : AppConstants.cartoVoyagerUrl;

    return jsonEncode({
      'version': 8,
      'name': isDark ? 'Carto Dark Matter' : 'Carto Voyager',
      'sources': {
        'carto-tiles': {
          'type': 'raster',
          'tiles': [tileUrl],
          'tileSize': 256,
          'attribution': '© CARTO, © OpenStreetMap contributors',
        },
      },
      'layers': [
        {
          'id': 'carto-tiles-layer',
          'type': 'raster',
          'source': 'carto-tiles',
          'minzoom': 0,
          'maxzoom': 22,
        },
      ],
    });
  }

  void _onMapCreated(ml.MapLibreMapController controller) {
    _maplibreController = controller;
  }

  Future<Uint8List> _generatePuckIconBytes() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 96, 96));

    // 1. Subtle, serene ambient halo
    final haloPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(48, 48), 44, haloPaint);

    // 2. High-contrast crisp white boundary ring
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(48, 48), 34, borderPaint);

    // 3. Inner vibrant emerald core
    final corePaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(48, 18),
        const Offset(48, 78),
        [const Color(0xFF22C55E), const Color(0xFF15803D)],
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(48, 48), 28, corePaint);

    // 4. Directional chevron/arrow pointing forward (UP)
    final path = Path();
    path.moveTo(48, 28); // Tip
    path.lineTo(60, 58); // Bottom right
    path.lineTo(48, 52); // Inner notch
    path.lineTo(36, 58); // Bottom left
    path.close();

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, arrowPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(96, 96);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _onStyleLoaded() async {
    _isStyleLoaded = true;
    try {
      final puckBytes = await _generatePuckIconBytes();
      await _maplibreController!.addImage('hajicare_nav_puck', puckBytes);
    } catch (e) {
      debugPrint('[NavigationMapView] Error registering puck image: $e');
    }
    await _drawRouteAndMarkers();
  }

  Future<void> _updatePuckNativeSymbol() async {
    if (_maplibreController == null || !_isStyleLoaded) return;
    final userLoc = widget.mapCtrl.currentUserLocation.value;
    if (userLoc == null) return;
    final bearing = widget.mapCtrl.navigationBearing.value;
    try {
      if (_puckSymbol != null) {
        await _maplibreController!.updateSymbol(
          _puckSymbol!,
          ml.SymbolOptions(
            geometry: ml.LatLng(userLoc.latitude, userLoc.longitude),
            iconRotate: bearing,
          ),
        );
      } else {
        _puckSymbol = await _maplibreController!.addSymbol(
          ml.SymbolOptions(
            geometry: ml.LatLng(userLoc.latitude, userLoc.longitude),
            iconImage: 'hajicare_nav_puck',
            iconRotate: bearing,
            iconSize: 0.65,
            iconAnchor: 'center',
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _drawRouteAndMarkers() async {
    if (_maplibreController == null || !_isStyleLoaded) return;
    try {
      await _maplibreController!.clearLines();
      await _maplibreController!.clearCircles();
      await _maplibreController!.clearSymbols();
      _puckSymbol = null;

      final route = widget.mapCtrl.activeRoute;
      if (route.isNotEmpty) {
        final points = route
            .map((p) => ml.LatLng(p.latitude, p.longitude))
            .toList();

        // 1. Route casing / outline for maximum contrast
        await _maplibreController!.addLine(
          ml.LineOptions(
            geometry: points,
            lineColor: '#14532D',
            lineWidth: 12.0,
            lineOpacity: 0.85,
            lineJoin: 'round',
          ),
        );

        // 2. High visibility emerald route line
        await _maplibreController!.addLine(
          ml.LineOptions(
            geometry: points,
            lineColor: '#22C55E',
            lineWidth: 8.5,
            lineOpacity: 0.98,
            lineJoin: 'round',
          ),
        );
      }

      // Red destination marker
      final dest = widget.mapCtrl.currentDestinationCoord;
      if (dest != null) {
        await _maplibreController!.addCircle(
          ml.CircleOptions(
            geometry: ml.LatLng(dest.latitude, dest.longitude),
            circleRadius: 10.0,
            circleColor: '#E11D48',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 3.5,
          ),
        );
      }

      // Native Directional Navigation Puck pinned to userLoc inside GL surface
      final userLoc = widget.mapCtrl.currentUserLocation.value;
      final bearing = widget.mapCtrl.navigationBearing.value;
      if (userLoc != null) {
        _puckSymbol = await _maplibreController!.addSymbol(
          ml.SymbolOptions(
            geometry: ml.LatLng(userLoc.latitude, userLoc.longitude),
            iconImage: 'hajicare_nav_puck',
            iconRotate: bearing,
            iconSize: 0.65,
            iconAnchor: 'center',
          ),
        );
      }
    } catch (e) {
      debugPrint('[NavigationMapView] Error rendering route lines: $e');
    }
  }

  /// Calculates a point offset in meters along the given bearing from [from].
  /// Projecting 65 meters forward along the travel bearing places the user cleanly in the
  /// lower 30% of the screen with a perspective look ahead into the upcoming route.
  ll.LatLng _computeOffsetPoint(
    ll.LatLng from,
    double distanceMeters,
    double bearingDegrees,
  ) {
    const double earthRadius = 6371000.0;
    final double radDist = distanceMeters / earthRadius;
    final double radBearing = bearingDegrees * (math.pi / 180.0);
    final double lat1 = from.latitude * (math.pi / 180.0);
    final double lon1 = from.longitude * (math.pi / 180.0);

    final double lat2 = math.asin(
      math.sin(lat1) * math.cos(radDist) +
          math.cos(lat1) * math.sin(radDist) * math.cos(radBearing),
    );
    final double lon2 =
        lon1 +
        math.atan2(
          math.sin(radBearing) * math.sin(radDist) * math.cos(lat1),
          math.cos(radDist) - math.sin(lat1) * math.sin(lat2),
        );

    return ll.LatLng(lat2 * (180.0 / math.pi), lon2 * (180.0 / math.pi));
  }

  void _animateCameraToFollow({bool force = false, int durationMs = 600}) {
    if (_maplibreController == null || !_isStyleLoaded) return;
    if (!widget.mapCtrl.isFollowingUser.value && !force) return;

    final userLoc = widget.mapCtrl.currentUserLocation.value;
    if (userLoc == null) return;

    final bearing = widget.mapCtrl.navigationBearing.value;
    // 65 meters forward projection places user cleanly in the lower 30% of viewport
    final target = _computeOffsetPoint(userLoc, 65.0, bearing);

    final update = ml.CameraUpdate.newCameraPosition(
      ml.CameraPosition(
        target: ml.LatLng(target.latitude, target.longitude),
        zoom: 18.0,
        tilt: 55.0, // 55 degrees authentic 3D perspective pitch
        bearing: bearing, // Heading-up orientation looking forward
      ),
    );

    _maplibreController!.animateCamera(
      update,
      duration: Duration(milliseconds: durationMs),
    );

    _updatePuckNativeSymbol();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    if (isMapLibreSupported) {
      return _buildMapLibreView(isDark);
    } else {
      return _buildDesktopFallbackView(isDark);
    }
  }

  Widget _buildMapLibreView(bool isDark) {
    final userLoc =
        widget.mapCtrl.currentUserLocation.value ??
        MapController.defaultMinaBase;
    final bearing = widget.mapCtrl.navigationBearing.value;
    final target = _computeOffsetPoint(userLoc, 65.0, bearing);

    return Listener(
      onPointerDown: (e) {
        _touchStartPos = e.position;
        _accumulatedDrag = 0.0;
      },
      onPointerMove: (e) {
        if (_touchStartPos != null) {
          _accumulatedDrag += (e.position - _touchStartPos!).distance;
          _touchStartPos = e.position;
          // Only disable follow mode on an intentional user pan (> 25px)
          if (_accumulatedDrag > 25.0) {
            widget.mapCtrl.onNavigationUserPan();
          }
        }
      },
      onPointerUp: (_) {
        _touchStartPos = null;
        _accumulatedDrag = 0.0;
      },
      onPointerCancel: (_) {
        _touchStartPos = null;
        _accumulatedDrag = 0.0;
      },
      child: ml.MapLibreMap(
        initialCameraPosition: ml.CameraPosition(
          target: ml.LatLng(target.latitude, target.longitude),
          zoom: 18.0,
          tilt: 55.0,
          bearing: bearing,
        ),
        styleString: _getCartoStyleJson(isDark),
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        trackCameraPosition: true,
        compassEnabled: false,
        attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
        attributionButtonMargins: const math.Point(12, 280),
      ),
    );
  }

  Widget _buildDesktopFallbackView(bool isDark) {
    final userLoc =
        widget.mapCtrl.currentUserLocation.value ??
        MapController.defaultMinaBase;
    final effectiveTile = isDark
        ? AppConstants.cartoDarkMatterUrl
        : AppConstants.cartoVoyagerUrl;

    return Stack(
      children: [
        fmap.FlutterMap(
          mapController: widget.mapCtrl.flutterMapController,
          options: fmap.MapOptions(
            initialCenter: userLoc,
            initialZoom: 18.0,
            initialRotation: widget.mapCtrl.navigationBearing.value,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                widget.mapCtrl.onNavigationUserPan();
              }
            },
          ),
          children: [
            fmap.TileLayer(
              urlTemplate: effectiveTile,
              userAgentPackageName: 'com.example.hajicare',
            ),
            Obx(() {
              final route = widget.mapCtrl.activeRoute;
              if (route.length < 2) return const SizedBox.shrink();
              return fmap.PolylineLayer(
                polylines: [
                  fmap.Polyline(
                    points: route.toList(),
                    strokeWidth: 8.0,
                    color: const Color(0xFF22C55E),
                    borderStrokeWidth: 2.0,
                    borderColor: const Color(0xFF166534),
                  ),
                ],
              );
            }),
            Obx(() {
              final user = widget.mapCtrl.currentUserLocation.value;
              if (user == null) return const SizedBox.shrink();
              return fmap.MarkerLayer(
                markers: [
                  fmap.Marker(
                    point: user,
                    width: 56,
                    height: 56,
                    child: _buildNavigationPuck(),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Directional navigation chevron puck.
  /// Points forward (UP) along the line of sight in heading-up navigation mode.
  /// Steady and calm when user is stationary (no fidgeting/pulsing ripples).
  Widget _buildNavigationPuck() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Subtle, serene ambient aura (fixed, zero jitter)
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF22C55E).withValues(alpha: 0.20),
          ),
        ),
        // 2. High-contrast white border ring with subtle shadow
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        // 3. Inner vibrant emerald core with white navigation heading chevron
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF22C55E), Color(0xFF15803D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Icon(Icons.navigation, size: 20, color: Colors.white),
        ),
      ],
    );
  }
}
