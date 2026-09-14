import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../models/map_poi.dart';

/// Controller managing reactive interactive map state, camera,
/// real geolocation with live streaming, dynamic POIs, and Jamaah markers.
class MapController extends GetxController with GetTickerProviderStateMixin {
  final fmap.MapController flutterMapController = fmap.MapController();

  final isMapReady = false.obs;
  final selectedFilter = 0.obs;
  final currentIndex = 1.obs;
  final compassRotation = 0.0.obs;

  final selectedPoi = Rxn<MapPoi>();
  final selectedJamaah = Rxn<JamaahData>();
  final activeRoute = <LatLng>[].obs;

  static const LatLng defaultMinaBase = LatLng(21.4135, 39.8930);
  final currentUserLocation = Rxn<LatLng>();
  final isLocationLoading = false.obs;
  final locationError = RxnString();

  final isLiveTracking = false.obs;
  final gpsAccuracy = 0.0.obs;
  StreamSubscription<Position>? _positionStreamSub;

  final pois = <MapPoi>[].obs;
  final safeRadiusMeters = 200.0.obs;
  final activeTileUrl = AppConstants.cartoVoyagerUrl.obs;

  bool _initialMoveDone = false;

  @override
  void onInit() {
    super.onInit();
    pois.value = List.from(MapPoi.defaultMinaPois);
    _autoStartGps();
  }

  // GPS AUTO-START & STREAMING

  Future<void> _autoStartGps() async {
    isLocationLoading.value = true;
    locationError.value = null;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError.value = 'GPS dinonaktifkan';
        isLocationLoading.value = false;
        AppAlert.warning(
          Get.context,
          title: 'GPS Nonaktif',
          message: 'Aktifkan GPS perangkat untuk melihat posisi Anda di peta.',
          okText: 'Aktifkan GPS',
          onOk: () => Geolocator.openLocationSettings(),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationError.value = 'Izin ditolak';
          isLocationLoading.value = false;
          AppAlert.warning(
            Get.context,
            title: 'Izin Lokasi Diperlukan',
            message: 'Izin akses lokasi diperlukan agar peta dapat menampilkan posisi Anda.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError.value = 'Izin ditolak permanen';
        isLocationLoading.value = false;
        AppAlert.warning(
          Get.context,
          title: 'Izin Ditolak Permanen',
          message: 'Harap izinkan akses lokasi melalui Pengaturan Aplikasi.',
          okText: 'Pengaturan',
          onOk: () => Geolocator.openAppSettings(),
        );
        return;
      }

      final firstPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _applyPosition(firstPosition);
      isLocationLoading.value = false;
      _startPositionStream();
    } catch (e) {
      debugPrint('[MapController] GPS init error: $e');
      locationError.value = e.toString();
      isLocationLoading.value = false;
      currentUserLocation.value = defaultMinaBase;
      _initJamaahAndRoute();
    }
  }

  void _startPositionStream() {
    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      _applyPosition,
      onError: (e) {
        debugPrint('[MapController] Stream error: $e');
        isLiveTracking.value = false;
      },
    );
    isLiveTracking.value = true;
  }

  void _applyPosition(Position position) {
    final newCoord = LatLng(position.latitude, position.longitude);
    currentUserLocation.value = newCoord;
    gpsAccuracy.value = position.accuracy;
    _updateRouteToSelected();

    if (!_initialMoveDone) {
      _initialMoveDone = true;
      _initJamaahAndRoute();
      Future.delayed(const Duration(milliseconds: 300), () {
        animatedMove(newCoord, 16.5);
      });
    }
  }

  void _initJamaahAndRoute() {
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

  // FILTERING & SELECTION

  void selectFilter(int index) => selectedFilter.value = index;
  void changeTab(int index) => currentIndex.value = index;

  List<MapPoi> get filteredPois {
    switch (selectedFilter.value) {
      case 0:
        return [];
      case 1:
        return pois;
      case 2:
        return pois.where((p) => p.category == PoiCategory.toilet).toList();
      case 3:
        return pois.where((p) => p.category == PoiCategory.medis).toList();
      case 4:
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

  // ROUTE & DISTANCE

  void _updateRouteTo(LatLng destination) {
    final start = currentUserLocation.value ?? defaultMinaBase;
    activeRoute.value = generateWalkingWaypoints(start, destination);
  }

  void _updateRouteToSelected() {
    if (selectedJamaah.value != null) {
      _updateRouteTo(getJamaahCoordinate(selectedJamaah.value!));
    } else if (selectedPoi.value != null) {
      _updateRouteTo(selectedPoi.value!.coordinate);
    }
  }

  LatLng getJamaahCoordinate(JamaahData jamaah) {
    if (jamaah.currentLocation != null) {
      return LatLng(
        jamaah.currentLocation!.latitude,
        jamaah.currentLocation!.longitude,
      );
    }
    final base = currentUserLocation.value ?? defaultMinaBase;
    final distKm = (jamaah.distance > 0 ? jamaah.distance : 120.0) / 1000.0;
    const earthRadiusKm = 6371.0;
    const bearingRad = 45.0 * math.pi / 180.0;

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

  double calculateDistanceMeters(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude, from.longitude,
      to.latitude, to.longitude,
    );
  }

  List<LatLng> generateWalkingWaypoints(LatLng start, LatLng end) {
    final midLng = (start.longitude + end.longitude) / 2;
    final midLat = (start.latitude + end.latitude) / 2;
    return [
      start,
      LatLng(start.latitude, midLng),
      LatLng(midLat, midLng),
      LatLng(end.latitude, midLng),
      end,
    ];
  }

  // MANUAL REFRESH

  Future<void> moveToCurrentLocation() async {
    if (isLiveTracking.value && currentUserLocation.value != null) {
      animatedMove(currentUserLocation.value!, 17.0);
      return;
    }
    await _autoStartGps();
  }

  // CAMERA & COMPASS

  bool get isMapAttached {
    try {
      flutterMapController.camera;
      return true;
    } catch (_) {
      return false;
    }
  }

  void animatedMove(LatLng destLocation, double destZoom) {
    if (!isMapAttached) return;

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

    final animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final animation = CurvedAnimation(
      parent: animCtrl,
      curve: Curves.easeInOutCubic,
    );

    animCtrl.addListener(() {
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
        animCtrl.dispose();
      }
    });

    animCtrl.forward();
  }

  void resetCompass() {
    if (isMapAttached) flutterMapController.rotate(0.0);
    compassRotation.value = 0.0;
  }

  void zoomIn() {
    if (!isMapAttached) return;
    animatedMove(flutterMapController.camera.center, flutterMapController.camera.zoom + 1.0);
  }

  void zoomOut() {
    if (!isMapAttached) return;
    animatedMove(flutterMapController.camera.center, flutterMapController.camera.zoom - 1.0);
  }

  void toggleMapTileLayer() {
    if (activeTileUrl.value.contains('cartocdn')) {
      activeTileUrl.value = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      AppAlert.info(Get.context, title: 'Mode Peta: OpenStreetMap', message: 'Menampilkan peta standar OpenStreetMap.');
    } else {
      activeTileUrl.value = AppConstants.cartoVoyagerUrl;
      AppAlert.info(Get.context, title: 'Mode Peta: Voyager', message: 'Menampilkan peta bertema hangat & bersih.');
    }
  }

  @override
  void onClose() {
    _positionStreamSub?.cancel();
    flutterMapController.dispose();
    super.onClose();
  }
}
