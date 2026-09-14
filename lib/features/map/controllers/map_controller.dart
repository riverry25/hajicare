import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../room/services/room_service.dart';
import '../models/map_poi.dart';

/// Controller managing reactive interactive map state, camera,
/// real geolocation with live streaming, dynamic POIs, and Room Member markers.
class MapController extends GetxController with GetTickerProviderStateMixin {
  final fmap.MapController flutterMapController = fmap.MapController();
  final RoomService? _injectedRoomService;
  RoomService? _lazyRoomService;

  MapController({RoomService? roomService}) : _injectedRoomService = roomService;

  RoomService? get _roomService {
    if (_injectedRoomService != null) return _injectedRoomService;
    if (_lazyRoomService != null) return _lazyRoomService;
    try {
      _lazyRoomService = RoomService();
    } catch (e) {
      debugPrint('[MapController] RoomService initialization deferred or unavailable: $e');
    }
    return _lazyRoomService;
  }

  final isMapReady = false.obs;
  final selectedFilter = 0.obs;
  final currentIndex = 1.obs;
  final compassRotation = 0.0.obs;

  final selectedPoi = Rxn<MapPoi>();
  final selectedJamaah = Rxn<JamaahData>();
  final selectedMember = Rxn<RoomMemberModel>();
  final activeRoute = <LatLng>[].obs;

  static const LatLng defaultMinaBase = LatLng(21.4135, 39.8930);
  final currentUserLocation = Rxn<LatLng>(defaultMinaBase);
  final isLocationLoading = false.obs;
  final locationError = RxnString();

  final isLiveTracking = false.obs;
  final gpsAccuracy = 0.0.obs;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<List<RoomMemberModel>>? _roomMembersSub;
  Worker? _roomWorker;

  // Realtime location throttle trackers (Foreground-only, dual-gate)
  DateTime? _lastFirestoreWriteTime;
  Position? _lastWrittenPosition;

  // Room Member State
  final roomMembers = <RoomMemberModel>[].obs;
  final isRoomMembersLoading = false.obs;
  final roomMembersError = RxnString();
  final activeRoomName = ''.obs;
  final selectedRoleFilter = 0.obs; // 0: Semua, 1: Jamaah, 2: Pendamping

  final pois = <MapPoi>[].obs;
  final safeRadiusMeters = 200.0.obs;
  final activeTileUrl = AppConstants.cartoVoyagerUrl.obs;

  bool _initialMoveDone = false;

  @override
  void onInit() {
    super.onInit();
    pois.value = List.from(MapPoi.defaultMinaPois);
    _initRoomListener();
    _autoStartGps();
  }

  // ── ROOM MEMBER LISTENERS ──────────────────────────────────────────────────

  void _initRoomListener() {
    if (Get.isRegistered<HajiCareController>()) {
      final state = Get.find<HajiCareController>();
      safeRadiusMeters.value = state.safeRadiusMeters.value;
      ever<double>(state.safeRadiusMeters, (r) {
        safeRadiusMeters.value = r;
      });
      _roomWorker = ever<String?>(state.activeRoomId, (roomId) {
        _onActiveRoomChanged(roomId);
      });
      _onActiveRoomChanged(state.activeRoomId.value);
    }
  }

  void _onActiveRoomChanged(String? roomId) {
    _roomMembersSub?.cancel();
    if (roomId == null || roomId.trim().isEmpty) {
      roomMembers.clear();
      activeRoomName.value = '';
      isRoomMembersLoading.value = false;
      return;
    }

    if (Get.isRegistered<HajiCareController>()) {
      final state = Get.find<HajiCareController>();
      activeRoomName.value = state.activeRoom.value?.name ?? 'Room $roomId';
    }

    isRoomMembersLoading.value = true;
    roomMembersError.value = null;

    final service = _roomService;
    if (service == null) {
      isRoomMembersLoading.value = false;
      return;
    }

    try {
      _roomMembersSub = service.watchRoomMembers(roomId).listen(
        (members) {
          roomMembers.value = members;
          isRoomMembersLoading.value = false;
        },
        onError: (e) {
          debugPrint('[MapController] watchRoomMembers error: $e');
          roomMembersError.value = e.toString();
          isRoomMembersLoading.value = false;
        },
      );
    } catch (e) {
      debugPrint('[MapController] watchRoomMembers exception: $e');
      isRoomMembersLoading.value = false;
    }
  }

  // ── COMPUTED ROOM GETTERS ──────────────────────────────────────────────────

  String? get currentUserId {
    if (Get.isRegistered<HajiCareController>()) {
      return Get.find<HajiCareController>().currentUid;
    }
    return null;
  }

  List<RoomMemberModel> get jamaahMembers =>
      roomMembers.where((m) => m.isJamaah).toList();

  List<RoomMemberModel> get pendampingMembers =>
      roomMembers.where((m) => m.isPendamping).toList();

  List<RoomMemberModel> get membersWithLocation =>
      roomMembers.where((m) => m.hasLocation).toList();

  int get memberCount => roomMembers.length;

  List<RoomMemberModel> get filteredMembers {
    switch (selectedRoleFilter.value) {
      case 1:
        return jamaahMembers;
      case 2:
        return pendampingMembers;
      case 0:
      default:
        return roomMembers;
    }
  }

  /// Finds nearest member with location excluding current user
  RoomMemberModel? get nearestMember {
    final myLoc = currentUserLocation.value;
    if (myLoc == null || roomMembers.isEmpty) return null;

    final myUid = currentUserId;
    final candidates = roomMembers
        .where((m) => m.hasLocation && (myUid == null || m.uid != myUid))
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final distA = Geolocator.distanceBetween(
        myLoc.latitude,
        myLoc.longitude,
        a.latitude!,
        a.longitude!,
      );
      final distB = Geolocator.distanceBetween(
        myLoc.latitude,
        myLoc.longitude,
        b.latitude!,
        b.longitude!,
      );
      return distA.compareTo(distB);
    });

    return candidates.first;
  }

  String get nearestMemberInfo {
    final nearest = nearestMember;
    final myLoc = currentUserLocation.value;
    if (nearest == null || myLoc == null) return '';

    final dist = Geolocator.distanceBetween(
      myLoc.latitude,
      myLoc.longitude,
      nearest.latitude!,
      nearest.longitude!,
    );
    final roleLabel = nearest.isPendamping ? 'Pendamping' : 'Jamaah';
    return '$roleLabel terdekat: ${nearest.name} · ${formatDistance(dist)}';
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  double? getDistanceToMember(RoomMemberModel member) {
    final myLoc = currentUserLocation.value;
    if (myLoc == null || !member.hasLocation) return null;
    return calculateDistanceMeters(
      myLoc,
      LatLng(member.latitude!, member.longitude!),
    );
  }

  String getMemberDistanceText(RoomMemberModel member) {
    final dist = getDistanceToMember(member);
    if (dist == null) return 'Lokasi belum tersedia';
    return formatDistance(dist);
  }

  // ── GPS AUTO-START & FOREGROUND STREAMING ──────────────────────────────────

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
    }
  }

  void _startPositionStream() {
    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
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

    // Dual-gate throttling: minimum 8 seconds AND 10 meters distance
    final now = DateTime.now();
    final timeDiffSec = _lastFirestoreWriteTime == null
        ? double.infinity
        : now.difference(_lastFirestoreWriteTime!).inMilliseconds / 1000.0;

    double distMoved = double.infinity;
    if (_lastWrittenPosition != null) {
      distMoved = Geolocator.distanceBetween(
        _lastWrittenPosition!.latitude,
        _lastWrittenPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    if (_lastFirestoreWriteTime == null || (timeDiffSec >= 8.0 && distMoved >= 10.0)) {
      _lastFirestoreWriteTime = now;
      _lastWrittenPosition = position;
      _publishLocationToRoom(position.latitude, position.longitude);
    }

    if (!_initialMoveDone) {
      _initialMoveDone = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        animatedMove(newCoord, 16.5);
      });
    }
  }

  void _publishLocationToRoom(double lat, double lng) {
    final service = _roomService;
    if (service == null) return;

    if (Get.isRegistered<HajiCareController>()) {
      final state = Get.find<HajiCareController>();
      final roomId = state.activeRoomId.value;
      final uid = state.currentUid;
      if (roomId != null && roomId.isNotEmpty && uid != null && uid.isNotEmpty) {
        service.updateMemberLocation(
          roomId: roomId,
          uid: uid,
          latitude: lat,
          longitude: lng,
        ).catchError((e) {
          debugPrint('[MapController] Failed to publish location: $e');
        });
      }
    }
  }

  // ── FILTERING & SELECTION ──────────────────────────────────────────────────

  void selectFilter(int index) {
    selectedFilter.value = index;
    // Map chip index to role filter: 0: Semua, 1: Jamaah, 2: Pendamping
    if (index >= 0 && index <= 2) {
      selectedRoleFilter.value = index;
    }
  }

  void selectRoleFilter(int index) {
    selectedRoleFilter.value = index;
  }

  void changeTab(int index) => currentIndex.value = index;

  List<MapPoi> get filteredPois {
    switch (selectedFilter.value) {
      case 0:
      case 1:
      case 2:
        return pois;
      case 3:
        return pois.where((p) => p.category == PoiCategory.medis).toList();
      case 4:
        return pois.where((p) => p.category == PoiCategory.toilet).toList();
      default:
        return pois;
    }
  }

  void selectPoi(MapPoi poi) {
    selectedPoi.value = poi;
    selectedJamaah.value = null;
    selectedMember.value = null;
    _updateRouteTo(poi.coordinate);
    animatedMove(poi.coordinate, 17.5);
  }

  void selectMember(RoomMemberModel member) {
    selectedMember.value = member;
    selectedPoi.value = null;
    selectedJamaah.value = null;
    if (member.hasLocation) {
      final target = LatLng(member.latitude!, member.longitude!);
      _updateRouteTo(target);
      animatedMove(target, 17.0);
    }
  }

  void selectJamaah(JamaahData jamaah) {
    selectedJamaah.value = jamaah;
    selectedPoi.value = null;
    selectedMember.value = null;
    final targetCoord = getJamaahCoordinate(jamaah);
    _updateRouteTo(targetCoord);
    animatedMove(targetCoord, 17.0);
  }

  void clearSelection() {
    selectedPoi.value = null;
    selectedJamaah.value = null;
    selectedMember.value = null;
    activeRoute.clear();
  }

  // ── ROUTE & DISTANCE ───────────────────────────────────────────────────────

  void _updateRouteTo(LatLng destination) {
    final start = currentUserLocation.value ?? defaultMinaBase;
    activeRoute.value = generateWalkingWaypoints(start, destination);
  }

  void _updateRouteToSelected() {
    if (selectedMember.value != null && selectedMember.value!.hasLocation) {
      _updateRouteTo(LatLng(
        selectedMember.value!.latitude!,
        selectedMember.value!.longitude!,
      ));
    } else if (selectedJamaah.value != null) {
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
    return currentUserLocation.value ?? defaultMinaBase;
  }

  double calculateDistanceMeters(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
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

  // ── CAMERA ACTIONS & FOCUS ─────────────────────────────────────────────────

  Future<void> moveToCurrentLocation() async {
    if (isLiveTracking.value && currentUserLocation.value != null) {
      animatedMove(currentUserLocation.value!, 17.0);
      return;
    }
    await _autoStartGps();
  }

  void focusToMe() {
    if (currentUserLocation.value != null) {
      animatedMove(currentUserLocation.value!, 17.0);
    } else {
      moveToCurrentLocation();
    }
  }

  void focusToAllMembers() {
    final points = <LatLng>[];
    if (currentUserLocation.value != null) {
      points.add(currentUserLocation.value!);
    }
    for (final m in membersWithLocation) {
      points.add(LatLng(m.latitude!, m.longitude!));
    }

    if (points.isEmpty) {
      if (currentUserLocation.value != null) {
        animatedMove(currentUserLocation.value!, 16.5);
      }
      return;
    }

    if (points.length == 1) {
      animatedMove(points.first, 17.0);
      return;
    }

    try {
      final bounds = fmap.LatLngBounds.fromPoints(points);
      flutterMapController.fitCamera(
        fmap.CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
        ),
      );
    } catch (e) {
      debugPrint('[MapController] fitCamera error: $e');
    }
  }

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
    _roomMembersSub?.cancel();
    _roomWorker?.dispose();
    flutterMapController.dispose();
    super.onClose();
  }
}
