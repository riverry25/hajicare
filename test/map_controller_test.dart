import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/constants/app_constants.dart';
import 'package:hajicare/core/services/geocoding_service.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
import 'package:hajicare/features/map/models/map_search_result.dart';
import 'package:hajicare/features/room/models/room_member_model.dart';
import 'package:hajicare/features/map/services/route_service.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

List<MapPoi> get samplePois => [
  MapPoi(
    id: 'medical-1',
    name: 'Klinik OSM',
    category: PoiCategory.medis,
    coordinate: const LatLng(21.4145, 39.8942),
  ),
  MapPoi(
    id: 'toilet-1',
    name: 'Toilet OSM',
    category: PoiCategory.toilet,
    coordinate: const LatLng(21.4130, 39.8922),
  ),
  MapPoi(
    id: 'hotel-1',
    name: 'Hotel OSM',
    category: PoiCategory.hotel,
    coordinate: const LatLng(21.4150, 39.8950),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MapController controller;
  late MockRouteService mockRouteService;

  setUp(() {
    Get.testMode = true;
    mockRouteService = MockRouteService();
    controller = MapController(routeService: mockRouteService);
    controller.onInit();
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  group('MapController Unit Tests', () {
    test(
      'Initializes with null currentUserLocation until real GPS fix is acquired',
      () {
        expect(controller.currentUserLocation.value, isNull);
        expect(controller.safeRadiusMeters.value, equals(200.0));
        expect(controller.activeTileUrl.value, contains('cartocdn'));
      },
    );

    test('Filters POIs correctly based on selected category chip', () {
      controller.pois.value = samplePois;
      controller.selectFilter(0);
      expect(controller.filteredPois.isNotEmpty, isTrue);

      controller.selectFilter(1);
      expect(controller.filteredPois, isEmpty);

      controller.selectFilter(3);
      expect(
        controller.filteredPois.every((p) => p.category == PoiCategory.medis),
        isTrue,
      );

      controller.selectFilter(4);
      expect(
        controller.filteredPois.every(
          (p) =>
              p.category == PoiCategory.toilet ||
              p.category == PoiCategory.wudhu,
        ),
        isTrue,
      );

      controller.selectFilter(7);
      expect(controller.filteredPois, hasLength(1));
      expect(controller.filteredPois.single.category, PoiCategory.hotel);
      expect(controller.selectedPoi.value, isNull);
    });

    test(
      'camera movement exposes search-this-area only after a useful move',
      () {
        controller.poiQueryCenter.value = const LatLng(-6.2088, 106.8456);

        controller.onMapPositionChanged(
          const LatLng(-6.2090, 106.8458),
          16,
          hasGesture: true,
        );
        expect(controller.showSearchThisArea.value, isFalse);

        controller.onMapPositionChanged(
          const LatLng(-6.2200, 106.8600),
          16,
          hasGesture: true,
        );
        expect(controller.showSearchThisArea.value, isTrue);
      },
    );

    test(
      'Distance calculation between coordinates returns accurate metric distance',
      () {
        const p1 = LatLng(21.4135, 39.8930); // Maktab 48
        const p2 = LatLng(21.4145, 39.8942); // Posko Medis
        final dist = controller.calculateDistanceMeters(p1, p2);

        expect(dist, greaterThan(80.0));
        expect(dist, lessThan(250.0));
      },
    );

    test(
      'Selecting a POI updates selection, clears member, and updates route async',
      () async {
        // Simulate real GPS location acquired
        controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);
        controller.pois.value = samplePois;
        final poi = controller.pois.firstWhere(
          (p) => p.category == PoiCategory.toilet,
        );

        await controller.requestRouteToPoi(poi);

        expect(controller.selectedPoi.value, equals(poi));
        expect(controller.selectedMember.value, isNull);
        expect(controller.activeRoute.isNotEmpty, isTrue);
        // It should match the mock output
        expect(controller.activeRoute.last, equals(const LatLng(2.0, 2.0)));
      },
    );

    test(
      'Selecting a Room Member updates selection, clears POI, and updates route async',
      () async {
        controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);
        const member = RoomMemberModel(
          uid: 'user_pendamping_1',
          name: 'Budi Santoso',
          role: 'pendamping',
          currentLocation: GeoPoint(21.4140, 39.8935),
        );

        await controller.requestRouteToMember(member);

        expect(controller.selectedMember.value, equals(member));
        expect(controller.selectedPoi.value, isNull);
        expect(controller.activeRoute.isNotEmpty, isTrue);
      },
    );

    test('clearSelectionAndRoute resets all selected entities and route', () {
      controller.pois.value = samplePois;
      final poi = controller.pois.first;
      controller.selectPoi(poi);
      expect(controller.selectedPoi.value, isNotNull);

      controller.clearSelectionAndRoute();

      expect(controller.selectedPoi.value, isNull);
      expect(controller.selectedMember.value, isNull);
      expect(controller.activeRoute.isEmpty, isTrue);
    });

    test(
      'closing place details preserves an active navigation route',
      () async {
        controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);
        final poi = samplePois.first;
        await controller.requestRouteToPoi(poi);

        controller.closeBottomSheet();

        expect(controller.selectedPoi.value, isNull);
        expect(controller.activeRoute, isNotEmpty);
      },
    );

    test('Reset compass resets compassRotation to 0.0', () {
      controller.compassRotation.value = 45.0;
      controller.resetCompass();
      expect(controller.compassRotation.value, equals(0.0));
    });

    test(
      'toggleMapTileLayer switches between Voyager and OpenStreetMap tiles',
      () {
        expect(controller.activeTileUrl.value, contains('cartocdn'));
        expect(
          controller.activeTileUrl.value,
          contains('?key=${AppConstants.cartoApiKey}'),
        );

        controller.toggleMapTileLayer();
        expect(controller.activeTileUrl.value, contains('openstreetmap.org'));

        controller.toggleMapTileLayer();
        expect(controller.activeTileUrl.value, contains('cartocdn'));
        expect(
          controller.activeTileUrl.value,
          contains('?key=${AppConstants.cartoApiKey}'),
        );
      },
    );
  });

  group('Room Members & Distance Formatting Requirements', () {
    test(
      'Formats distance correctly: <1000m -> "X m", >=1000m -> "X.X km"',
      () {
        expect(MapController.formatDistance(500.0), equals('500 m'));
        expect(MapController.formatDistance(240.4), equals('240 m'));
        expect(MapController.formatDistance(1200.0), equals('1.2 km'));
        expect(MapController.formatDistance(2560.0), equals('2.6 km'));
      },
    );

    test(
      'RoomMemberModel parses GeoPoint correctly and handles null safely without crash',
      () {
        const memberWithGps = RoomMemberModel(
          uid: 'user_1',
          name: 'Ahmad Dahlan',
          role: 'jamaah',
          currentLocation: GeoPoint(21.4138, 39.8932),
        );
        expect(memberWithGps.hasLocation, isTrue);
        expect(memberWithGps.latitude, closeTo(21.4138, 0.0001));
        expect(memberWithGps.longitude, closeTo(39.8932, 0.0001));

        const memberWithoutGps = RoomMemberModel(
          uid: 'user_2',
          name: 'Siti Aminah',
          role: 'jamaah',
          currentLocation: null,
        );
        expect(memberWithoutGps.hasLocation, isFalse);
        expect(memberWithoutGps.latitude, isNull);
        expect(memberWithoutGps.longitude, isNull);
        expect(
          memberWithoutGps.getLocationStatus(),
          equals('Lokasi belum tersedia'),
        );
      },
    );

    test(
      'RoomMemberModel evaluates location status based on locationUpdatedAt',
      () {
        final now = DateTime.now();

        // Recent <= 30 seconds -> Online
        final onlineMember = RoomMemberModel(
          uid: 'u1',
          name: 'Budi',
          role: 'pendamping',
          currentLocation: const GeoPoint(21.4135, 39.8930),
          locationUpdatedAt: now.subtract(const Duration(seconds: 15)),
        );
        expect(onlineMember.getLocationStatus(now), equals('Online'));

        // Stale between 31 and 120 seconds -> Terakhir terlihat X dtk lalu
        final staleMember = RoomMemberModel(
          uid: 'u2',
          name: 'Fadli',
          role: 'jamaah',
          currentLocation: const GeoPoint(21.4135, 39.8930),
          locationUpdatedAt: now.subtract(const Duration(seconds: 45)),
        );
        expect(
          staleMember.getLocationStatus(now),
          equals('Terakhir terlihat 45 dtk lalu'),
        );

        // Expired > 120 seconds -> Lokasi tidak diperbarui
        final expiredMember = RoomMemberModel(
          uid: 'u3',
          name: 'Hasan',
          role: 'jamaah',
          currentLocation: const GeoPoint(21.4135, 39.8930),
          locationUpdatedAt: now.subtract(const Duration(seconds: 180)),
        );
        expect(
          expiredMember.getLocationStatus(now),
          equals('Lokasi tidak diperbarui'),
        );
      },
    );

    test(
      'Filters room members correctly by role: Semua, Jamaah, Pendamping',
      () {
        controller.roomMembers.value = [
          const RoomMemberModel(uid: 'p1', name: 'Budi', role: 'pendamping'),
          const RoomMemberModel(uid: 'j1', name: 'Ahmad', role: 'jamaah'),
          const RoomMemberModel(uid: 'j2', name: 'Fadli', role: 'jamaah'),
        ];

        expect(controller.memberCount, equals(3));
        expect(controller.jamaahMembers.length, equals(2));
        expect(controller.pendampingMembers.length, equals(1));

        // Filter 0: Semua
        controller.selectRoleFilter(0);
        expect(controller.filteredMembers.length, equals(3));

        // Filter 1: Jamaah
        controller.selectRoleFilter(1);
        expect(controller.filteredMembers.length, equals(2));
        expect(controller.filteredMembers.every((m) => m.isJamaah), isTrue);

        // Filter 2: Pendamping
        controller.selectRoleFilter(2);
        expect(controller.filteredMembers.length, equals(1));
        expect(controller.filteredMembers.first.isPendamping, isTrue);
      },
    );

    test(
      'Nearest member calculation finds closest member with location and excludes current user',
      () {
        controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);

        controller.roomMembers.value = [
          const RoomMemberModel(
            uid: 'j_far',
            name: 'Far Jamaah',
            role: 'jamaah',
            currentLocation: GeoPoint(21.4190, 39.8990), // ~800m away
          ),
          const RoomMemberModel(
            uid: 'p_near',
            name: 'Near Pendamping',
            role: 'pendamping',
            currentLocation: GeoPoint(21.4138, 39.8933), // ~45m away
          ),
          const RoomMemberModel(
            uid: 'j_no_gps',
            name: 'No GPS Jamaah',
            role: 'jamaah',
            currentLocation: null,
          ),
        ];

        expect(controller.membersWithLocation.length, equals(2));
        final nearest = controller.nearestMember;
        expect(nearest, isNotNull);
        expect(nearest!.uid, equals('p_near'));
        expect(
          controller.nearestMemberInfo,
          contains('Pendamping terdekat: Near Pendamping'),
        );
      },
    );
  });

  group('Automatic Routing & Race Condition Tests', () {
    setUp(() {
      controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);
    });

    test(
      'pilih member -> otomatis request route ketika kedua GPS tersedia',
      () async {
        const member = RoomMemberModel(
          uid: 'u_fadli',
          name: 'Fadli',
          role: 'jamaah',
          currentLocation: GeoPoint(21.4140, 39.8935),
        );

        await controller.selectMember(member);

        expect(controller.selectedMember.value, equals(member));
        expect(controller.activeRoute.isNotEmpty, isTrue);
        expect(mockRouteService.callCount, equals(1));
      },
    );

    test(
      'member tanpa GPS -> tidak request route dan error ditampilkan',
      () async {
        final initialCalls = mockRouteService.callCount;
        const memberNoGps = RoomMemberModel(
          uid: 'u_no_gps',
          name: 'Hasan',
          role: 'jamaah',
          currentLocation: null,
        );

        await controller.selectMember(memberNoGps);

        expect(controller.selectedMember.value, equals(memberNoGps));
        expect(controller.activeRoute.isEmpty, isTrue);
        expect(mockRouteService.callCount, equals(initialCalls));
        expect(
          controller.routeError.value,
          contains('Lokasi anggota belum tersedia'),
        );
      },
    );

    test(
      'current user tanpa GPS -> tidak request route dan error ditampilkan',
      () async {
        controller.currentUserLocation.value = null;
        final initialCalls = mockRouteService.callCount;
        const member = RoomMemberModel(
          uid: 'u_fadli',
          name: 'Fadli',
          role: 'jamaah',
          currentLocation: GeoPoint(21.4140, 39.8935),
        );

        await controller.selectMember(member);

        expect(controller.activeRoute.isEmpty, isTrue);
        expect(mockRouteService.callCount, equals(initialCalls));
        expect(
          controller.routeError.value,
          contains('Lokasi Anda belum ditemukan'),
        );
      },
    );

    test(
      'route success -> activeRoute terisi dengan distance dan duration',
      () async {
        const member = RoomMemberModel(
          uid: 'u_fadli',
          name: 'Fadli',
          role: 'jamaah',
          currentLocation: GeoPoint(21.4140, 39.8935),
        );

        await controller.selectMember(member);

        expect(controller.activeRoute.length, equals(3));
        expect(controller.routeDistanceMeters.value, equals(500.0));
        expect(controller.routeDurationSeconds.value, equals(300));
        expect(controller.isRouteLoading.value, isFalse);
      },
    );

    test('route error -> loading false dan activeRoute dikosongkan', () async {
      mockRouteService.shouldFail = true;
      const member = RoomMemberModel(
        uid: 'u_fadli',
        name: 'Fadli',
        role: 'jamaah',
        currentLocation: GeoPoint(21.4140, 39.8935),
      );

      await controller.selectMember(member);

      expect(controller.isRouteLoading.value, isFalse);
      expect(controller.activeRoute.isEmpty, isTrue);
      expect(controller.routeError.value, isNotNull);
    });

    test(
      'race condition: response request lama tidak menimpa route terbaru',
      () async {
        final completerA = Completer<RouteResult>();
        final completerB = Completer<RouteResult>();

        mockRouteService.customHandler = (origin, dest) {
          if (dest.latitude == 21.4140) {
            return completerA.future;
          } else {
            return completerB.future;
          }
        };

        const memberA = RoomMemberModel(
          uid: 'u_a',
          name: 'Ahmad',
          role: 'jamaah',
          currentLocation: GeoPoint(21.4140, 39.8935),
        );
        const memberB = RoomMemberModel(
          uid: 'u_b',
          name: 'Budi',
          role: 'jamaah',
          currentLocation: GeoPoint(21.4150, 39.8945),
        );

        // Trigger selection A, lalu cepat memilih B
        final futureA = controller.selectMember(memberA);
        final futureB = controller.selectMember(memberB);

        // Response B selesai lebih dulu
        completerB.complete(
          const RouteResult(
            points: [LatLng(21.4135, 39.8930), LatLng(21.4150, 39.8945)],
            distanceMeters: 200,
            durationSeconds: 150,
          ),
        );
        await futureB;
        expect(
          controller.activeRoute.last,
          equals(const LatLng(21.4150, 39.8945)),
        );
        expect(controller.routeDistanceMeters.value, equals(200));

        // Response A selesai belakangan (obsolete)
        completerA.complete(
          const RouteResult(
            points: [LatLng(21.4135, 39.8930), LatLng(21.4140, 39.8935)],
            distanceMeters: 100,
            durationSeconds: 80,
          ),
        );
        await futureA;

        // activeRoute TIDAK boleh tertimpa oleh response A
        expect(
          controller.activeRoute.last,
          equals(const LatLng(21.4150, 39.8945)),
        );
        expect(controller.routeDistanceMeters.value, equals(200));
      },
    );

    test('GPS update tidak memanggil ORS secara otomatis', () {
      final callsBefore = mockRouteService.callCount;
      controller.currentUserLocation.value = const LatLng(21.4138, 39.8934);
      expect(mockRouteService.callCount, equals(callsBefore));
    });
  });

  group('MapController Search Location Tests', () {
    late MapController searchController;
    late MockGeocodingService mockGeocoding;

    setUp(() {
      mockGeocoding = MockGeocodingService();
      searchController = MapController(
        routeService: mockRouteService,
        geocodingService: mockGeocoding,
      );
      searchController.onInit();
    });

    tearDown(() {
      searchController.onClose();
    });

    test('Search bar ignores queries with length < 2 and stays idle', () async {
      searchController.onSearchQueryChanged('a');
      expect(searchController.searchState.value, equals(MapSearchState.idle));
      expect(searchController.searchResults.isEmpty, isTrue);

      await Future.delayed(const Duration(milliseconds: 600));
      expect(mockGeocoding.callCount, equals(0));
    });

    test(
      'Search debounce calls searchLocations only after 500ms delay',
      () async {
        searchController.onSearchQueryChanged('jak');
        searchController.onSearchQueryChanged('jaka');
        searchController.onSearchQueryChanged('jakarta');

        // Before debounce delay (200ms), no API call should happen
        await Future.delayed(const Duration(milliseconds: 200));
        expect(mockGeocoding.callCount, equals(0));

        // After debounce delay (600ms), exactly 1 call should be made
        await Future.delayed(const Duration(milliseconds: 400));
        expect(mockGeocoding.callCount, equals(1));
        expect(
          searchController.searchState.value,
          equals(MapSearchState.results),
        );
        expect(searchController.searchResults.length, equals(2));
        expect(
          searchController.searchResults.first.name,
          equals('Monumen Nasional'),
        );
      },
    );

    test(
      'Search passes user current location as proximity bias to searchLocations',
      () async {
        // Allow async onInit() GPS failure to settle before setting test coordinates
        await Future.delayed(const Duration(milliseconds: 50));
        searchController.currentUserLocation.value = const LatLng(
          -6.1754,
          106.8272,
        );

        searchController.onSearchQueryChanged('masjid');
        await Future.delayed(const Duration(milliseconds: 600));

        expect(mockGeocoding.callCount, equals(1));
        expect(mockGeocoding.lastLatitude, equals(-6.1754));
        expect(mockGeocoding.lastLongitude, equals(106.8272));
      },
    );

    test('Search returns empty state when no locations found', () async {
      mockGeocoding.customHandler = (q) async => [];

      searchController.onSearchQueryChanged('lokasitidakada12345');
      await Future.delayed(const Duration(milliseconds: 600));

      expect(searchController.searchState.value, equals(MapSearchState.empty));
      expect(searchController.searchResults.isEmpty, isTrue);
    });

    test('Search handles API error gracefully without crashing', () async {
      mockGeocoding.shouldFail = true;

      searchController.onSearchQueryChanged('error_trigger');
      await Future.delayed(const Duration(milliseconds: 600));

      expect(searchController.searchState.value, equals(MapSearchState.error));
      expect(searchController.searchErrorMessage.value, contains('Gagal'));
      expect(searchController.searchResults.isEmpty, isTrue);
    });

    test('Race condition: stale search response is ignored', () async {
      final completerA = Completer<List<MapSearchResult>>();

      mockGeocoding.customHandler = (query) {
        if (query == 'jakarta') {
          return completerA.future;
        } else {
          return Future.value([
            const MapSearchResult(
              id: 'bdg',
              name: 'Bandung',
              address: 'Jawa Barat',
              latitude: -6.9175,
              longitude: 107.6191,
            ),
          ]);
        }
      };

      // 1. User searches 'jakarta'
      searchController.onSearchQueryChanged('jakarta');
      await Future.delayed(const Duration(milliseconds: 550));

      // 2. User quickly searches 'bandung'
      searchController.onSearchQueryChanged('bandung');
      await Future.delayed(const Duration(milliseconds: 550));

      // 3. Bandung response arrives
      expect(searchController.searchResults.first.name, equals('Bandung'));

      // 4. Jakarta response arrives late
      completerA.complete([
        const MapSearchResult(
          id: 'jkt',
          name: 'Jakarta',
          address: 'DKI Jakarta',
          latitude: -6.2088,
          longitude: 106.8456,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 50));

      // Results must still be Bandung, Jakarta response ignored
      expect(searchController.searchResults.first.name, equals('Bandung'));
    });

    test(
      'Selecting search result sets location and marker without altering current location',
      () {
        const result = MapSearchResult(
          id: '1',
          name: 'Monas',
          address: 'Jakarta',
          latitude: -6.1754,
          longitude: 106.8272,
        );

        final initialUserLoc = searchController.currentUserLocation.value;

        searchController.selectSearchResult(result);

        expect(searchController.selectedSearchResult.value, equals(result));
        expect(searchController.searchState.value, equals(MapSearchState.idle));
        expect(searchController.searchResults.isEmpty, isTrue);
        // Ensure current GPS user location is NOT mutated
        expect(
          searchController.currentUserLocation.value,
          equals(initialUserLoc),
        );
        expect(searchController.selectedPoi.value?.name, 'Monas');
        expect(searchController.selectedPoi.value?.category, PoiCategory.place);
        expect(searchController.isBottomSheetOpen.value, isTrue);
      },
    );

    test('Selecting a second search result updates existing search marker', () {
      const result1 = MapSearchResult(
        id: '1',
        name: 'Monas',
        address: 'Jakarta',
        latitude: -6.1754,
        longitude: 106.8272,
      );
      const result2 = MapSearchResult(
        id: '2',
        name: 'Bandung',
        address: 'Jawa Barat',
        latitude: -6.9175,
        longitude: 107.6191,
      );

      searchController.selectSearchResult(result1);
      expect(
        searchController.selectedSearchResult.value?.name,
        equals('Monas'),
      );

      searchController.selectSearchResult(result2);
      expect(
        searchController.selectedSearchResult.value?.name,
        equals('Bandung'),
      );
    });

    test(
      'clearSearch clears query and dropdown without moving map or clearing other markers',
      () {
        const result = MapSearchResult(
          id: '1',
          name: 'Monas',
          address: 'Jakarta',
          latitude: -6.1754,
          longitude: 106.8272,
        );
        searchController.selectSearchResult(result);

        searchController.clearSearch(clearMarker: false);
        expect(searchController.searchState.value, equals(MapSearchState.idle));
        expect(searchController.searchResults.isEmpty, isTrue);
        expect(searchController.selectedSearchResult.value, isNotNull);

        searchController.clearSearch(clearMarker: true);
        expect(searchController.selectedSearchResult.value, isNull);
      },
    );
  });
}

class MockRouteService extends RouteService {
  int callCount = 0;
  bool shouldFail = false;
  Future<RouteResult> Function(LatLng origin, LatLng destination)?
  customHandler;

  MockRouteService() : super(apiKey: 'dummy');

  @override
  Future<RouteResult> getWalkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    callCount++;
    if (shouldFail) {
      throw const RouteException('Simulated route error');
    }
    if (customHandler != null) {
      return customHandler!(origin, destination);
    }
    return RouteResult(
      points: [origin, destination, const LatLng(2.0, 2.0)],
      distanceMeters: 500.0,
      durationSeconds: 300,
    );
  }
}

class MockGeocodingService extends GeocodingService {
  int callCount = 0;
  bool shouldFail = false;
  double? lastLatitude;
  double? lastLongitude;
  Future<List<MapSearchResult>> Function(String query)? customHandler;

  @override
  Future<List<MapSearchResult>> searchLocations(
    String query, {
    double? latitude,
    double? longitude,
    int limit = 10,
    http.Client? client,
  }) async {
    callCount++;
    lastLatitude = latitude;
    lastLongitude = longitude;
    if (shouldFail) {
      throw Exception('Simulated geocoding search failure');
    }
    if (customHandler != null) {
      return customHandler!(query);
    }
    return [
      const MapSearchResult(
        id: '1',
        name: 'Monumen Nasional',
        address: 'Gambir, Jakarta Pusat, DKI Jakarta',
        latitude: -6.1754,
        longitude: 106.8272,
      ),
      const MapSearchResult(
        id: '2',
        name: 'Masjid Istiqlal',
        address: 'Sawah Besar, Jakarta Pusat, DKI Jakarta',
        latitude: -6.1702,
        longitude: 106.8314,
      ),
    ];
  }
}
