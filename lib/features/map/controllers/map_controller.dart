import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../room/services/room_service.dart';
import '../models/map_poi.dart';
import '../models/map_search_result.dart';
import '../services/poi_service.dart';
import '../services/route_service.dart';

/// State of the location search workflow.
enum MapSearchState { idle, loading, results, empty, error }

/// Controller managing reactive interactive map state, camera,
/// real geolocation with live streaming, dynamic POIs, and Room Member markers.
class MapController extends GetxController with GetTickerProviderStateMixin {
  final fmap.MapController flutterMapController = fmap.MapController();
  final RoomService? _injectedRoomService;
  RoomService? _lazyRoomService;
  final RouteService _routeService;
  final GeocodingService _geocodingService;
  final PoiService _poiService;

  MapController({
    RoomService? roomService,
    RouteService? routeService,
    GeocodingService? geocodingService,
    PoiService? poiService,
  }) : _injectedRoomService = roomService,
       _routeService = routeService ?? RouteService(),
       _geocodingService = geocodingService ?? GeocodingService(),
       _poiService = poiService ?? PoiService();

  RoomService? get _roomService {
    if (_injectedRoomService != null) return _injectedRoomService;
    if (_lazyRoomService != null) return _lazyRoomService;
    try {
      _lazyRoomService = RoomService();
    } catch (e) {
      debugPrint(
        '[MapController] RoomService initialization deferred or unavailable: $e',
      );
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

  final isRouteLoading = false.obs;
  final routeError = RxnString();
  final routeDistanceMeters = Rxn<double>();
  final routeDurationSeconds = Rxn<int>();

  static const LatLng defaultMinaBase = LatLng(21.4135, 39.8930);
  final currentUserLocation = Rxn<LatLng>();
  final isLocationLoading = false.obs;
  final locationError = RxnString();

  // Active navigation tracking
  LatLng? _activeDestination;
  DateTime? _lastRerouteTime;
  static const double _deviationThresholdMeters = 50.0;
  static const Duration _rerouteCooldown = Duration(seconds: 15);
  LatLng? _lastPoiFetchCoord;

  final isLiveTracking = false.obs;
  final gpsAccuracy = 0.0.obs;
  StreamSubscription<Position>? _nativePositionSub;
  StreamSubscription<Position?>? _statePositionSub;
  StreamSubscription<List<RoomMemberModel>>? _roomMembersSub;
  Worker? _roomWorker;
  Worker? _safeRadiusWorker;
  AnimationController? _moveAnimCtrl;
  int _lifecycleGeneration = 0;

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
  final isPoiLoading = false.obs;
  final poiError = RxnString();
  final showSearchThisArea = false.obs;
  final poiQueryCenter = Rxn<LatLng>();
  final mapCameraCenter = Rxn<LatLng>();
  final mapZoom = 16.5.obs;
  double _mapCameraZoom = 16.5;
  int _poiRequestId = 0;
  final safeRadiusMeters = 200.0.obs;
  final activeTileUrl = AppConstants.cartoVoyagerUrl.obs;
  final isBottomSheetOpen = true.obs;

  // ── SEARCH LOCATION STATE ──────────────────────────────────────────────────
  final searchState = MapSearchState.idle.obs;
  final searchResults = <MapSearchResult>[].obs;
  final selectedSearchResult = Rxn<MapSearchResult>();
  final searchErrorMessage = ''.obs;
  Timer? _searchDebounceTimer;
  int _searchRequestId = 0;

  void closeBottomSheet() {
    isBottomSheetOpen.value = false;
    clearSelection();
  }

  void openBottomSheet() {
    isBottomSheetOpen.value = true;
  }

  void backToMembersList() {
    selectedMember.value = null;
    selectedJamaah.value = null;
    selectedPoi.value = null;
    clearRoute();
    isBottomSheetOpen.value = true;
  }

  bool _initialMoveDone = false;

  @override
  void onInit() {
    super.onInit();
    _initRoomListener();
    _autoStartGps();
  }

  Future<void> refreshNearbyPois(
    LatLng center, {
    bool force = false,
    int? radiusMeters,
  }) async {
    // Spatial buffer: only refresh POIs if user moved >= 500m from last query coordinate
    double? movedDistance;
    if (_lastPoiFetchCoord != null) {
      movedDistance = calculateDistanceMeters(_lastPoiFetchCoord!, center);
    }
    if (!force && movedDistance != null) {
      final movedDist = movedDistance;
      if (movedDist < 500.0 && pois.isNotEmpty) {
        return;
      }
    }

    // Never keep pins from a different area while a new area is loading.
    if (movedDistance != null && movedDistance > 500) {
      pois.clear();
      clearSelection();
    }

    _lastPoiFetchCoord = center;
    poiQueryCenter.value = center;
    showSearchThisArea.value = false;
    poiError.value = null;
    isPoiLoading.value = true;
    final requestId = ++_poiRequestId;
    try {
      final realPois = await _poiService.fetchNearbyPois(
        center: center,
        radiusMeters: radiusMeters ?? _radiusForZoom(_mapCameraZoom),
        forceRefresh: force,
      );
      if (requestId == _poiRequestId) {
        pois.assignAll(realPois);
      }
    } on PoiServiceException catch (error) {
      if (requestId == _poiRequestId) poiError.value = error.message;
    } catch (error) {
      if (requestId == _poiRequestId) {
        poiError.value = 'Tempat di area ini belum dapat dimuat';
      }
      debugPrint('[MapController] POI refresh error: $error');
    } finally {
      if (requestId == _poiRequestId) isPoiLoading.value = false;
    }
  }

  void onMapPositionChanged(
    LatLng center,
    double zoom, {
    required bool hasGesture,
  }) {
    mapCameraCenter.value = center;
    _mapCameraZoom = zoom;
    if ((mapZoom.value - zoom).abs() > 0.05) mapZoom.value = zoom;
    if (!hasGesture || poiQueryCenter.value == null) return;
    final distance = calculateDistanceMeters(poiQueryCenter.value!, center);
    showSearchThisArea.value = distance > _searchAreaThresholdForZoom(zoom);
  }

  void handleMapReady() {
    if (isMapReady.value || !isMapAttached) return;
    isMapReady.value = true;
    final camera = flutterMapController.camera;
    onMapPositionChanged(camera.center, camera.zoom, hasGesture: false);
    if (poiQueryCenter.value == null && !isPoiLoading.value) {
      refreshNearbyPois(camera.center);
    }
  }

  Future<void> searchThisArea() async {
    final center =
        mapCameraCenter.value ??
        poiQueryCenter.value ??
        currentUserLocation.value;
    if (center == null) return;
    await refreshNearbyPois(center, force: true);
  }

  static int _radiusForZoom(double zoom) {
    if (zoom >= 17) return 1000;
    if (zoom >= 15) return 2500;
    if (zoom >= 13) return 5000;
    return 8000;
  }

  static double _searchAreaThresholdForZoom(double zoom) {
    if (zoom >= 17) return 250;
    if (zoom >= 15) return 500;
    if (zoom >= 13) return 1200;
    return 2500;
  }

  // ── ROOM MEMBER LISTENERS ──────────────────────────────────────────────────

  void _initRoomListener() {
    if (Get.isRegistered<HajiCareController>()) {
      final state = Get.find<HajiCareController>();
      safeRadiusMeters.value = state.safeRadiusMeters.value;
      _safeRadiusWorker = ever<double>(state.safeRadiusMeters, (r) {
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
      if (currentUserLocation.value != null) {
        refreshNearbyPois(currentUserLocation.value!);
      }
    }

    isRoomMembersLoading.value = true;
    roomMembersError.value = null;

    final service = _roomService;
    if (service == null) {
      isRoomMembersLoading.value = false;
      return;
    }

    try {
      _roomMembersSub = service
          .watchRoomMembers(roomId)
          .listen(
            (members) {
              roomMembers.value = members;
              isRoomMembersLoading.value = false;
            },
            onError: (e) {
              debugPrint('[MapController] watchRoomMembers error: $e');
              roomMembersError.value = UserFeedbackMessage.from(
                e,
                fallback:
                    'Data rombongan belum dapat dimuat. Silakan coba lagi.',
              );
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

  /// Finds nearest member with location excluding current user in a single O(N) pass.
  RoomMemberModel? get nearestMember => _findNearestMemberData()?.member;

  /// Returns computed (nearestMember, distanceInMeters) in a single O(N) pass without repeated distance calculations.
  ({RoomMemberModel member, double distance})? _findNearestMemberData() {
    final myLoc = currentUserLocation.value;
    if (myLoc == null || roomMembers.isEmpty) return null;

    final myUid = currentUserId;
    RoomMemberModel? bestMember;
    double bestDist = double.infinity;

    for (final m in roomMembers) {
      if (!m.hasLocation || (myUid != null && m.uid == myUid)) continue;
      final dist = Geolocator.distanceBetween(
        myLoc.latitude,
        myLoc.longitude,
        m.latitude!,
        m.longitude!,
      );
      if (dist < bestDist) {
        bestDist = dist;
        bestMember = m;
      }
    }

    if (bestMember == null) return null;
    return (member: bestMember, distance: bestDist);
  }

  String get nearestMemberInfo {
    final data = _findNearestMemberData();
    if (data == null) return '';

    final roleLabel = data.member.isPendamping ? 'Pendamping' : 'Jamaah';
    return '$roleLabel terdekat: ${data.member.name} · ${formatDistance(data.distance)}';
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000.0;
      if (km >= 100) {
        return '${km.round()} km';
      }
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
    final generation = _lifecycleGeneration;
    isLocationLoading.value = true;
    locationError.value = null;

    // Fast-path: Check if HajiCareController is already providing a valid GPS location
    if (Get.isRegistered<HajiCareController>()) {
      final state = Get.find<HajiCareController>();
      if (state.myCurrentPosition.value != null) {
        _applyPosition(state.myCurrentPosition.value!, publishToRoom: false);
        isLocationLoading.value = false;
        _subscribeToStatePosition(state);
        return;
      }
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (isClosed || generation != _lifecycleGeneration) return;
      if (!serviceEnabled) {
        locationError.value = 'Lokasi ponsel belum aktif';
        isLocationLoading.value = false;
        AppAlert.warning(
          Get.context,
          title: 'Lokasi Ponsel Belum Aktif',
          message: 'Aktifkan lokasi ponsel agar posisi Anda terlihat di peta.',
          okText: 'Buka Pengaturan',
          onOk: () => Geolocator.openLocationSettings(),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (isClosed || generation != _lifecycleGeneration) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (isClosed || generation != _lifecycleGeneration) return;
        if (permission == LocationPermission.denied) {
          locationError.value = 'Izin lokasi belum diberikan';
          isLocationLoading.value = false;
          AppAlert.warning(
            Get.context,
            title: 'Izin Lokasi Diperlukan',
            message:
                'Izinkan HajiCare memakai lokasi agar posisi Anda terlihat di peta.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError.value = 'Izin lokasi belum diberikan';
        isLocationLoading.value = false;
        AppAlert.warning(
          Get.context,
          title: 'Buka Pengaturan Lokasi',
          message:
              'Izin lokasi belum diberikan. Buka pengaturan, lalu izinkan akses lokasi untuk HajiCare.',
          okText: 'Buka Pengaturan',
          onOk: () => Geolocator.openAppSettings(),
        );
        return;
      }

      Position? firstPosition;
      if (Get.isRegistered<HajiCareController>()) {
        final state = Get.find<HajiCareController>();
        firstPosition = state.myCurrentPosition.value;
      }

      firstPosition ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (isClosed || generation != _lifecycleGeneration) return;

      if (Get.isRegistered<HajiCareController>()) {
        final state = Get.find<HajiCareController>();
        _applyPosition(firstPosition, publishToRoom: false);
        isLocationLoading.value = false;
        _subscribeToStatePosition(state);
      } else {
        _applyPosition(firstPosition, publishToRoom: true);
        isLocationLoading.value = false;
        _startPositionStream();
      }
    } catch (e) {
      debugPrint('[MapController] GPS init error: $e');
      locationError.value = UserFeedbackMessage.from(
        e,
        fallback:
            'Lokasi belum dapat ditemukan. Periksa pengaturan lokasi ponsel, lalu coba lagi.',
      );
      isLocationLoading.value = false;
      // Do NOT set currentUserLocation to defaultMinaBase on failure:
      // real GPS location must remain null until an actual device fix is acquired.
    }
  }

  void _subscribeToStatePosition(HajiCareController state) {
    _nativePositionSub?.cancel();
    _statePositionSub?.cancel();
    _statePositionSub = state.myCurrentPosition.listen((pos) {
      if (pos != null) {
        _applyPosition(pos, publishToRoom: false);
      }
    });
    isLiveTracking.value = true;
  }

  void _startPositionStream() {
    _statePositionSub?.cancel();
    _nativePositionSub?.cancel();
    _nativePositionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen(
          (pos) => _applyPosition(pos, publishToRoom: true),
          onError: (e) {
            debugPrint('[MapController] Stream error: $e');
            isLiveTracking.value = false;
          },
        );
    isLiveTracking.value = true;
  }

  void _applyPosition(Position position, {bool publishToRoom = true}) {
    final newCoord = LatLng(position.latitude, position.longitude);
    currentUserLocation.value = newCoord;
    gpsAccuracy.value = position.accuracy;
    refreshNearbyPois(newCoord);

    // Live navigation: evaluate route deviation if active route is engaged
    _checkRouteDeviation(newCoord);

    if (publishToRoom) {
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

      if (_lastFirestoreWriteTime == null ||
          (timeDiffSec >= 8.0 && distMoved >= 10.0)) {
        _lastFirestoreWriteTime = now;
        _lastWrittenPosition = position;
        _publishLocationToRoom(position.latitude, position.longitude);
      }
    }

    if (!_initialMoveDone) {
      _initialMoveDone = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (isClosed) return;
        // Defer to post-frame to avoid MapControllerImpl notifications during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isMapAttached) animatedMove(newCoord, 16.5);
        });
      });
    }
  }

  /// Checks if the user has deviated > 50m from the active walking polyline.
  /// If deviated and cooldown (15s) has passed, triggers controlled reroute.
  void _checkRouteDeviation(LatLng userPos) {
    if (activeRoute.isEmpty ||
        _activeDestination == null ||
        isRouteLoading.value) {
      return;
    }

    final now = DateTime.now();
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!) < _rerouteCooldown) {
      return;
    }

    final minDistance = _distanceToPolyline(userPos, activeRoute);
    if (minDistance > _deviationThresholdMeters) {
      debugPrint(
        '[ROUTE] User deviated ${minDistance.toInt()}m from route. Initiating reroute...',
      );
      _lastRerouteTime = now;
      _updateRouteTo(_activeDestination!, isReroute: true);
    }
  }

  /// Computes cross-track distance in meters from point to polyline.
  double _distanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) {
      return double.infinity;
    }
    if (polyline.length == 1) {
      return calculateDistanceMeters(point, polyline.first);
    }

    double minDistance = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final d = _distanceToSegment(point, polyline[i], polyline[i + 1]);
      if (d < minDistance) {
        minDistance = d;
      }
    }
    return minDistance;
  }

  /// Distance from point P to segment [A, B] in meters.
  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final l2 =
        (b.latitude - a.latitude) * (b.latitude - a.latitude) +
        (b.longitude - a.longitude) * (b.longitude - a.longitude);
    if (l2 == 0) return calculateDistanceMeters(p, a);

    // Projection factor t
    final t =
        (((p.latitude - a.latitude) * (b.latitude - a.latitude) +
                    (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
                l2)
            .clamp(0.0, 1.0);

    final proj = LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );
    return calculateDistanceMeters(p, proj);
  }

  void _publishLocationToRoom(double lat, double lng) {
    final service = _roomService;
    if (service == null) return;

    if (Get.isRegistered<HajiCareController>()) {
      final state = Get.find<HajiCareController>();
      final roomId = state.activeRoomId.value;
      final uid = state.currentUid;
      if (roomId != null &&
          roomId.isNotEmpty &&
          uid != null &&
          uid.isNotEmpty) {
        service
            .updateMemberLocation(
              roomId: roomId,
              uid: uid,
              latitude: lat,
              longitude: lng,
            )
            .catchError((e) {
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
      selectedMember.value = null;
      selectedJamaah.value = null;
      selectedPoi.value = null;
      openBottomSheet();
    } else {
      // POI filters only change visibility. They never invent/select a place.
      selectedRoleFilter.value = 0;
      final currentPoi = selectedPoi.value;
      if (currentPoi != null &&
          !filteredPois.any((p) => p.id == currentPoi.id)) {
        clearSelection();
      }
      isBottomSheetOpen.value = false;
    }
  }

  void selectRoleFilter(int index) {
    selectedRoleFilter.value = index;
  }

  void changeTab(int index) => currentIndex.value = index;

  List<MapPoi> get filteredPois {
    switch (selectedFilter.value) {
      case 0:
        return pois;
      case 1:
      case 2:
        return const [];
      case 3:
        return pois.where((p) => p.category == PoiCategory.medis).toList();
      case 4:
        return pois
            .where(
              (p) =>
                  p.category == PoiCategory.toilet ||
                  p.category == PoiCategory.wudhu,
            )
            .toList();
      case 5:
        return pois.where((p) => p.category == PoiCategory.maktab).toList();
      case 6:
        return pois.where((p) => p.category == PoiCategory.posPantau).toList();
      case 7:
        return pois.where((p) => p.category == PoiCategory.hotel).toList();
      default:
        return pois;
    }
  }

  int _routeRequestId = 0;

  void selectPoi(MapPoi poi) {
    debugPrint('[SELECT] poi = ${poi.name}');
    isBottomSheetOpen.value = true;
    if (selectedPoi.value?.id == poi.id) return;
    if (_activeDestination != null &&
        calculateDistanceMeters(_activeDestination!, poi.coordinate) > 2) {
      clearRoute();
    }
    selectedPoi.value = poi;
    selectedJamaah.value = null;
    selectedMember.value = null;
    animatedMove(poi.coordinate, 17.5);
  }

  Future<void> selectMember(RoomMemberModel member) async {
    debugPrint('[SELECT] member = ${member.name}');
    final hasUserLoc = currentUserLocation.value != null;
    final hasDestLoc = member.hasLocation;
    debugPrint('[SELECT] currentLocation available = $hasUserLoc');
    debugPrint('[SELECT] destination available = $hasDestLoc');

    isBottomSheetOpen.value = true;
    selectedMember.value = member;
    selectedPoi.value = null;
    selectedJamaah.value = null;

    if (member.hasLocation) {
      final target = LatLng(member.latitude!, member.longitude!);
      animatedMove(target, 17.0);
    }

    if (hasUserLoc && hasDestLoc) {
      debugPrint('[ROUTE] automatic request started');
      await requestRouteToMember(member);
    } else {
      clearRoute();
      if (!hasUserLoc) {
        routeError.value = 'Lokasi Anda belum ditemukan';
      } else if (!hasDestLoc) {
        routeError.value = 'Lokasi anggota belum tersedia';
      }
    }
  }

  Future<void> selectJamaah(JamaahData jamaah) async {
    debugPrint('[SELECT] member = ${jamaah.name}');
    final hasUserLoc = currentUserLocation.value != null;
    final hasDestLoc = jamaah.currentLocation != null;
    debugPrint('[SELECT] currentLocation available = $hasUserLoc');
    debugPrint('[SELECT] destination available = $hasDestLoc');

    isBottomSheetOpen.value = true;
    selectedJamaah.value = jamaah;
    selectedPoi.value = null;
    selectedMember.value = null;
    final targetCoord = getJamaahCoordinate(jamaah);
    animatedMove(targetCoord, 17.0);

    if (hasUserLoc && hasDestLoc) {
      debugPrint('[ROUTE] automatic request started');
      await requestRouteToJamaah(jamaah);
    } else {
      clearRoute();
      if (!hasUserLoc) {
        routeError.value = 'Lokasi Anda belum ditemukan';
      } else if (!hasDestLoc) {
        routeError.value = 'Lokasi jamaah belum tersedia';
      }
    }
  }

  bool get hasActiveRoute => activeRoute.isNotEmpty;

  void clearSelection() {
    selectedPoi.value = null;
    selectedJamaah.value = null;
    selectedMember.value = null;
    // Note: does NOT clear active route. Route persists until
    // clearRoute() is explicitly called or a new route is requested.
  }

  void clearRoute() {
    activeRoute.clear();
    _activeDestination = null;
    routeError.value = null;
    routeDistanceMeters.value = null;
    routeDurationSeconds.value = null;
  }

  /// Clears both selection and route (used by close button in bottom sheet).
  void clearSelectionAndRoute() {
    clearSelection();
    clearRoute();
  }

  // ── ROUTE & DISTANCE ───────────────────────────────────────────────────────

  Future<void> _updateRouteTo(
    LatLng destination, {
    bool isReroute = false,
  }) async {
    final start = currentUserLocation.value;
    if (start == null) {
      if (!isReroute) clearRoute();
      routeError.value = 'Lokasi Anda belum ditemukan';
      return;
    }

    _activeDestination = destination;
    final requestId = ++_routeRequestId;

    isRouteLoading.value = true;
    routeError.value = null;
    if (!isReroute) {
      routeDistanceMeters.value = null;
      routeDurationSeconds.value = null;
    }

    try {
      final result = await _routeService.getWalkingRoute(
        origin: start,
        destination: destination,
      );

      // Race condition check: ignore obsolete responses
      if (requestId != _routeRequestId) {
        debugPrint(
          '[ROUTE] obsolete response ignored (request $requestId != $_routeRequestId)',
        );
        return;
      }

      debugPrint('[ROUTE] activeRoute = ${result.points.length}');

      activeRoute.assignAll(result.points);
      routeDistanceMeters.value = result.distanceMeters;
      routeDurationSeconds.value = result.durationSeconds;
      if (!isReroute) {
        _fitCameraToRoute(start, destination, result.points);
      }
    } on RouteException catch (e) {
      if (requestId != _routeRequestId) return;
      debugPrint('[ROUTE] ERROR RouteException: ${e.message}');
      if (!isReroute) activeRoute.clear();
      routeError.value = e.message;
    } catch (e) {
      if (requestId != _routeRequestId) return;
      debugPrint('[ROUTE] ERROR unknown: $e');
      if (!isReroute) activeRoute.clear();
      routeError.value = 'Terjadi kesalahan saat mencari rute';
    } finally {
      if (requestId == _routeRequestId) {
        isRouteLoading.value = false;
      }
    }
  }

  void _fitCameraToRoute(LatLng origin, LatLng dest, List<LatLng> routePoints) {
    if (!isMapAttached) return;

    final allPoints = [origin, dest, ...routePoints];
    if (allPoints.isEmpty) return;

    try {
      final bounds = fmap.LatLngBounds.fromPoints(allPoints);
      flutterMapController.fitCamera(
        fmap.CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(48, 140, 48, 300),
        ),
      );
    } catch (e) {
      debugPrint('[MapController] fitCamera route error: $e');
    }
  }

  Future<void> requestRouteToMember(RoomMemberModel member) async {
    if (selectedMember.value?.uid != member.uid) {
      selectedMember.value = member;
      selectedPoi.value = null;
      selectedJamaah.value = null;
    }
    if (member.hasLocation && currentUserLocation.value != null) {
      await _updateRouteTo(LatLng(member.latitude!, member.longitude!));
    } else {
      clearRoute();
      if (currentUserLocation.value == null) {
        routeError.value = 'Lokasi Anda belum ditemukan';
      } else if (!member.hasLocation) {
        routeError.value = 'Lokasi anggota belum tersedia';
      }
    }
  }

  Future<void> requestRouteToPoi(MapPoi poi) async {
    if (selectedPoi.value?.id != poi.id) {
      selectedPoi.value = poi;
      selectedMember.value = null;
      selectedJamaah.value = null;
    }
    if (currentUserLocation.value != null) {
      await _updateRouteTo(poi.coordinate);
    } else {
      clearRoute();
      routeError.value = 'Aktifkan lokasi GPS untuk membuat rute';
    }
  }

  Future<void> requestRouteToJamaah(JamaahData jamaah) async {
    if (selectedJamaah.value?.id != jamaah.id) {
      selectedJamaah.value = jamaah;
      selectedMember.value = null;
      selectedPoi.value = null;
    }
    if (jamaah.currentLocation != null && currentUserLocation.value != null) {
      await _updateRouteTo(getJamaahCoordinate(jamaah));
    } else {
      clearRoute();
      if (currentUserLocation.value == null) {
        routeError.value = 'Lokasi Anda belum ditemukan';
      } else if (jamaah.currentLocation == null) {
        routeError.value = 'Lokasi jamaah belum tersedia';
      }
    }
  }

  void retryRoute() {
    if (selectedMember.value != null && selectedMember.value!.hasLocation) {
      _updateRouteTo(
        LatLng(
          selectedMember.value!.latitude!,
          selectedMember.value!.longitude!,
        ),
      );
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
    openBottomSheet();
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
      // Defer to post-frame to prevent MapControllerImpl notifications during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isMapAttached) {
          flutterMapController.fitCamera(
            fmap.CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
            ),
          );
        }
      });
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

    _moveAnimCtrl?.dispose();
    _moveAnimCtrl = null;

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
    _moveAnimCtrl = animCtrl;
    final animation = CurvedAnimation(
      parent: animCtrl,
      curve: Curves.easeInOutCubic,
    );

    animCtrl.addListener(() {
      if (isMapAttached) {
        // Defer map moves to post-frame to prevent MapControllerImpl notifications during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isMapAttached) {
            flutterMapController.move(
              LatLng(
                latTween.evaluate(animation),
                lngTween.evaluate(animation),
              ),
              zoomTween.evaluate(animation),
            );
          }
        });
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (_moveAnimCtrl == animCtrl) {
          _moveAnimCtrl = null;
        }
        animCtrl.dispose();
      }
    });

    animCtrl.forward();
  }

  void resetCompass() {
    compassRotation.value = 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isMapAttached) flutterMapController.rotate(0.0);
    });
  }

  void zoomIn() {
    if (!isMapAttached) return;
    animatedMove(
      flutterMapController.camera.center,
      (flutterMapController.camera.zoom + 1.0).clamp(3.0, 19.0),
    );
  }

  void zoomOut() {
    if (!isMapAttached) return;
    animatedMove(
      flutterMapController.camera.center,
      (flutterMapController.camera.zoom - 1.0).clamp(3.0, 19.0),
    );
  }

  void toggleMapTileLayer() {
    if (activeTileUrl.value.contains('cartocdn')) {
      activeTileUrl.value = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      if (Get.context != null) {
        AppAlert.info(
          Get.context,
          title: 'Tampilan Peta Diubah',
          message: 'Peta sederhana sedang digunakan.',
        );
      }
    } else {
      activeTileUrl.value = AppConstants.cartoVoyagerUrl;
      if (Get.context != null) {
        AppAlert.info(
          Get.context,
          title: 'Tampilan Peta Diubah',
          message: 'Peta berwarna sedang digunakan.',
        );
      }
    }
  }

  // ── SEARCH ACTIONS ─────────────────────────────────────────────────────────

  /// Handles user input in search bar with 500ms debounce and race-condition safety.
  void onSearchQueryChanged(String query) {
    _searchDebounceTimer?.cancel();

    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      clearSearch();
      return;
    }

    if (cleanQuery.length < 2) {
      searchState.value = MapSearchState.idle;
      searchResults.clear();
      searchErrorMessage.value = '';
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final currentId = ++_searchRequestId;
      searchState.value = MapSearchState.loading;
      searchErrorMessage.value = '';

      // Dynamic current user location for proximity bias (ranking boost, not hard filter)
      final userLoc = currentUserLocation.value;

      try {
        final results = await _geocodingService.searchLocations(
          cleanQuery,
          latitude: userLoc?.latitude,
          longitude: userLoc?.longitude,
          limit: 10,
        );

        // Race condition check: discard stale response
        if (currentId != _searchRequestId) {
          debugPrint(
            '[SEARCH] stale response ignored (request $currentId != $_searchRequestId)',
          );
          return;
        }

        if (results.isEmpty) {
          searchResults.clear();
          searchState.value = MapSearchState.empty;
        } else {
          searchResults.assignAll(results);
          searchState.value = MapSearchState.results;
        }
      } catch (e) {
        if (currentId != _searchRequestId) return;
        debugPrint('[SEARCH] error: $e');
        searchResults.clear();
        searchState.value = MapSearchState.error;
        searchErrorMessage.value = 'Gagal mencari lokasi. Coba lagi.';
      }
    });
  }

  /// Selects a location result, dismisses dropdown, updates search marker,
  /// and animates camera to the target coordinates.
  void selectSearchResult(MapSearchResult result) {
    if (_activeDestination != null &&
        calculateDistanceMeters(_activeDestination!, result.coordinate) > 2) {
      clearRoute();
    }
    selectedSearchResult.value = result;
    selectedPoi.value = MapPoi(
      id: 'search_${result.id}',
      name: result.name,
      category: PoiCategory.place,
      coordinate: result.coordinate,
      statusLabel: 'Hasil pencarian',
      subtitle: result.address,
    );
    selectedMember.value = null;
    selectedJamaah.value = null;
    searchState.value = MapSearchState.idle;
    searchResults.clear();

    isBottomSheetOpen.value = true;

    // Smoothly animate camera to search result coordinate
    animatedMove(result.coordinate, 16.5);
  }

  /// Clears the active search query and dropdown results.
  /// Preserves the selected search marker on the map unless explicitly instructed.
  void clearSearch({bool clearMarker = false}) {
    _searchDebounceTimer?.cancel();
    _searchRequestId++;
    searchResults.clear();
    searchState.value = MapSearchState.idle;
    searchErrorMessage.value = '';
    if (clearMarker) {
      selectedSearchResult.value = null;
    }
  }

  /// Explicitly removes the search marker from the map.
  void clearSearchMarker() {
    selectedSearchResult.value = null;
  }

  @override
  void onClose() {
    _lifecycleGeneration++;
    _searchDebounceTimer?.cancel();
    _moveAnimCtrl?.dispose();
    _nativePositionSub?.cancel();
    _statePositionSub?.cancel();
    _roomMembersSub?.cancel();
    _roomWorker?.dispose();
    _safeRadiusWorker?.dispose();
    _poiRequestId++;
    _poiService.dispose();
    flutterMapController.dispose();
    super.onClose();
  }
}
