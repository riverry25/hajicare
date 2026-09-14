import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../models/map_poi.dart';

/// Controller managing reactive interactive map state, camera,
/// real geolocation, dynamic POIs, and Jamaah markers.
class MapController extends GetxController with GetTickerProviderStateMixin {
  // Map Engine Controller from flutter_map
  final fmap.MapController flutterMapController = fmap.MapController();

  // Map Readiness & State
  final isMapReady = false.obs;
  final selectedFilter = 0.obs; // 0: Jamaah, 1: Semua, 2: Toilet, 3: Medis, 4: Maktab
  final currentIndex = 1.obs; // Bottom nav index
  final compassRotation = 0.0.obs;

  // Selected Entities
  final selectedPoi = Rxn<MapPoi>();
  final selectedJamaah = Rxn<JamaahData>();
  final activeRoute = <LatLng>[].obs;

  // User & Companion Location
  // Default base: Mina Tent City Sector 48
  static const LatLng defaultMinaBase = LatLng(21.4135, 39.8930);
  final currentUserLocation = Rxn<LatLng>();
  final isLocationLoading = false.obs;
  final locationError = RxnString();

  // POIs and Safe Radius (200m)
  final pois = <MapPoi>[].obs;
  final safeRadiusMeters = 200.0.obs;

  // Tile Provider URL (CartoDB Voyager with official CARTO API Key)
  final activeTileUrl = AppConstants.cartoVoyagerUrl.obs;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  void _initData() {
    pois.value = List.from(MapPoi.defaultMinaPois);

    // Initial default user position in Mina
    currentUserLocation.value = defaultMinaBase;

    // Auto-select first Jamaah if available in HajiCareController
    if (Get.isRegistered<HajiCareController>()) {
      final state = Get.find<HajiCareController>();
      if (state.jamaahList.isNotEmpty) {
        selectedJamaah.value = state.jamaahList.first;
      } else {
        selectedJamaah.value = state.self;
      }
      _updateRouteToSelected();
    }
  }

  // ---------------------------------------------------------------------------
  // FILTERING & SELECTION
  // ---------------------------------------------------------------------------

  void selectFilter(int index) {
    selectedFilter.value = index;
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  /// Returns list of POIs matching the currently selected filter chip.
  List<MapPoi> get filteredPois {
    switch (selectedFilter.value) {
      case 0: // Jamaah (Ayah) - hide other POIs or show minimal
        return [];
      case 1: // Semua
        return pois;
      case 2: // Toilet & Wudhu
        return pois.where((p) => p.category == PoiCategory.toilet).toList();
      case 3: // Posko Medis PPIH
        return pois.where((p) => p.category == PoiCategory.medis).toList();
      case 4: // Tenda Maktab 48
        return pois.where((p) => p.category == PoiCategory.maktab).toList();
      default:
        return pois;
    }
  }

  void selectPoi(MapPoi poi) {
    selectedPoi.value = poi;
    selectedJamaah.value = null;
    _updateRouteTo(poi.coordinate);
    animatedMove(poi.coordinate, 17.5);
  }

  void selectJamaah(JamaahData jamaah) {
    selectedJamaah.value = jamaah;
    selectedPoi.value = null;
    final targetCoord = getJamaahCoordinate(jamaah);
    _updateRouteTo(targetCoord);
    animatedMove(targetCoord, 17.0);
  }

  void clearSelection() {
    selectedPoi.value = null;
    selectedJamaah.value = null;
    activeRoute.clear();
  }

  // ---------------------------------------------------------------------------
  // ROUTE & DISTANCE CALCULATIONS
  // ---------------------------------------------------------------------------

  /// Computes simulated street walking waypoints from user to destination.
  void _updateRouteTo(LatLng destination) {
    final start = currentUserLocation.value ?? defaultMinaBase;
    activeRoute.value = generateWalkingWaypoints(start, destination);
  }

  void _updateRouteToSelected() {
    if (selectedJamaah.value != null) {
      final dest = getJamaahCoordinate(selectedJamaah.value!);
      _updateRouteTo(dest);
    } else if (selectedPoi.value != null) {
      _updateRouteTo(selectedPoi.value!.coordinate);
    }
  }

  /// Converts a [JamaahData] into a [LatLng] coordinate.
  LatLng getJamaahCoordinate(JamaahData jamaah) {
    if (jamaah.currentLocation != null) {
      return LatLng(
        jamaah.currentLocation!.latitude,
        jamaah.currentLocation!.longitude,
      );
    }
    // Realistic Mina sector offset based on distance
    final base = currentUserLocation.value ?? defaultMinaBase;
    final distKm = (jamaah.distance > 0 ? jamaah.distance : 120.0) / 1000.0;
    const earthRadiusKm = 6371.0;
    const bearingRad = 45.0 * math.pi / 180.0; // North-East

    final lat1 = base.latitude * math.pi / 180.0;
    final lon1 = base.longitude * math.pi / 180.0;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(distKm / earthRadiusKm) +
          math.cos(lat1) * math.sin(distKm / earthRadiusKm) * math.cos(bearingRad),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearingRad) * math.sin(distKm / earthRadiusKm) * math.cos(lat1),
          math.cos(distKm / earthRadiusKm) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(lat2 * 180.0 / math.pi, lon2 * 180.0 / math.pi);
  }

  /// Calculates straight-line distance in meters between two coordinates.
  double calculateDistanceMeters(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Generates a realistic walking route with turns between start and end.
  List<LatLng> generateWalkingWaypoints(LatLng start, LatLng end) {
    // Generate an L-shaped / stepped pedestrian path
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;

    final p1 = LatLng(start.latitude, midLng);
    final p2 = LatLng(midLat, midLng);
    final p3 = LatLng(end.latitude, midLng);

    return [start, p1, p2, p3, end];
  }

  // ---------------------------------------------------------------------------
  // REAL GEOLOCATION FLOW
  // ---------------------------------------------------------------------------

  /// Fetches real user device position using Geolocator with robust permission checks.
  Future<void> moveToCurrentLocation() async {
    isLocationLoading.value = true;
    locationError.value = null;

    try {
      // 1. Check if location services are enabled on device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'GPS Nonaktif',
          'Layanan lokasi dinonaktifkan. Silakan aktifkan GPS perangkat Anda.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryContainer,
          colorText: Colors.white,
          mainButton: TextButton(
            onPressed: () => Geolocator.openLocationSettings(),
            child: const Text('Aktifkan', style: TextStyle(color: AppColors.goldLight)),
          ),
        );
        isLocationLoading.value = false;
        return;
      }

      // 2. Check and request location permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Izin Lokasi Diperlukan',
            'Izin akses lokasi diperlukan untuk melihat posisi Anda pada peta.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primaryContainer,
            colorText: Colors.white,
          );
          isLocationLoading.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Izin Lokasi Ditolak Permanen',
          'Harap izinkan akses lokasi melalui Pengaturan Aplikasi.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryContainer,
          colorText: Colors.white,
          mainButton: TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: const Text('Pengaturan', style: TextStyle(color: AppColors.goldLight)),
          ),
        );
        isLocationLoading.value = false;
        return;
      }

      // 3. Acquire actual position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final newCoord = LatLng(position.latitude, position.longitude);
      currentUserLocation.value = newCoord;

      // 4. Update route and camera
      _updateRouteToSelected();
      animatedMove(newCoord, 17.5);

      Get.snackbar(
        'Lokasi Terkini Ditemukan',
        'Akurasi: ±${position.accuracy.toStringAsFixed(1)} meter',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.statusSafe.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('[MapController] Get position error: $e');
      locationError.value = e.toString();
      // Graceful fallback to Mina Base if device has no GPS fix
      animatedMove(defaultMinaBase, 17.0);
      Get.snackbar(
        'Peta Berpusat di Mina',
        'Menggunakan lokasi basis Tenda Maktab 48 Mina.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryContainer,
        colorText: Colors.white,
      );
    } finally {
      isLocationLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // CAMERA & COMPASS CONTROLS
  // ---------------------------------------------------------------------------

  /// Returns true if flutterMapController is attached to a rendered FlutterMap.
  bool get isMapAttached {
    try {
      flutterMapController.camera;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Smoothly animates camera to [destLocation] with [destZoom].
  void animatedMove(LatLng destLocation, double destZoom) {
    if (!isMapAttached) return;

    // Create an animation tween from current center to destLocation
    final latTween = Tween<double>(
      begin: flutterMapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: flutterMapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: flutterMapController.camera.zoom,
      end: destZoom,
    );

    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final Animation<double> animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    );

    animationController.addListener(() {
      if (isMapAttached) {
        flutterMapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }

  /// Resets map rotation bearing smoothly back to North (0°).
  void resetCompass() {
    if (isMapAttached) {
      flutterMapController.rotate(0.0);
    }
    compassRotation.value = 0.0;
  }

  /// Zoom in by 1.0 level.
  void zoomIn() {
    if (!isMapAttached) return;
    final currentZoom = flutterMapController.camera.zoom;
    animatedMove(flutterMapController.camera.center, currentZoom + 1.0);
  }

  /// Zoom out by 1.0 level.
  void zoomOut() {
    if (!isMapAttached) return;
    final currentZoom = flutterMapController.camera.zoom;
    animatedMove(flutterMapController.camera.center, currentZoom - 1.0);
  }

  /// Toggles map visual tile style between CartoDB Voyager and OpenStreetMap.
  void toggleMapTileLayer() {
    if (activeTileUrl.value.contains('cartocdn')) {
      activeTileUrl.value = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      if (Get.context != null) {
        Get.snackbar(
          'Mode Peta: OpenStreetMap',
          'Menampilkan peta standar OpenStreetMap.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      activeTileUrl.value = AppConstants.cartoVoyagerUrl;
      if (Get.context != null) {
        Get.snackbar(
          'Mode Peta: Voyager',
          'Menampilkan peta bertema hangat & bersih.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  void onClose() {
    flutterMapController.dispose();
    super.onClose();
  }
}
