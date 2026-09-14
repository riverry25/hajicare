import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/constants/app_constants.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
import 'package:hajicare/features/room/models/room_member_model.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MapController controller;

  setUp(() {
    Get.testMode = true;
    controller = MapController();
    controller.onInit();
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  group('MapController Unit Tests', () {
    test('Initializes with default Mina POIs and base location', () {
      expect(controller.pois.isNotEmpty, isTrue);
      expect(controller.pois.any((p) => p.name.contains('Maktab 48')), isTrue);
      expect(controller.pois.any((p) => p.name.contains('Posko Medis')), isTrue);
      expect(controller.pois.any((p) => p.name.contains('Toilet')), isTrue);
      expect(controller.currentUserLocation.value, equals(MapController.defaultMinaBase));
      expect(controller.safeRadiusMeters.value, equals(200.0));
      expect(controller.activeTileUrl.value, contains('cartocdn'));
    });

    test('Filters POIs correctly based on selected category chip', () {
      controller.selectFilter(0);
      expect(controller.filteredPois.isNotEmpty, isTrue);

      controller.selectFilter(1);
      expect(controller.filteredPois.length, equals(controller.pois.length));

      controller.selectFilter(3);
      expect(controller.filteredPois.every((p) => p.category == PoiCategory.medis), isTrue);

      controller.selectFilter(4);
      expect(controller.filteredPois.every((p) => p.category == PoiCategory.toilet), isTrue);
    });

    test('Distance calculation between coordinates returns accurate metric distance', () {
      const p1 = LatLng(21.4135, 39.8930); // Maktab 48
      const p2 = LatLng(21.4145, 39.8942); // Posko Medis
      final dist = controller.calculateDistanceMeters(p1, p2);

      expect(dist, greaterThan(80.0));
      expect(dist, lessThan(250.0));
    });

    test('Route generator creates valid walking waypoints', () {
      const start = LatLng(21.4135, 39.8930);
      const dest = LatLng(21.4145, 39.8942);

      final route = controller.generateWalkingWaypoints(start, dest);
      expect(route.isNotEmpty, isTrue);
      expect(route.first, equals(start));
      expect(route.last, equals(dest));
      expect(route.length, greaterThanOrEqualTo(3));
    });

    test('Selecting a POI updates selection, clears member, and updates route', () {
      final poi = controller.pois.firstWhere((p) => p.category == PoiCategory.toilet);

      controller.selectPoi(poi);

      expect(controller.selectedPoi.value, equals(poi));
      expect(controller.selectedMember.value, isNull);
      expect(controller.activeRoute.isNotEmpty, isTrue);
      expect(controller.activeRoute.last, equals(poi.coordinate));
    });

    test('Selecting a Room Member updates selection, clears POI, and updates route', () {
      const member = RoomMemberModel(
        uid: 'user_pendamping_1',
        name: 'Budi Santoso',
        role: 'pendamping',
        currentLocation: GeoPoint(21.4140, 39.8935),
      );

      controller.selectMember(member);

      expect(controller.selectedMember.value, equals(member));
      expect(controller.selectedPoi.value, isNull);
      expect(controller.activeRoute.isNotEmpty, isTrue);
    });

    test('clearSelection resets all selected entities and route', () {
      final poi = controller.pois.first;
      controller.selectPoi(poi);
      expect(controller.selectedPoi.value, isNotNull);

      controller.clearSelection();

      expect(controller.selectedPoi.value, isNull);
      expect(controller.selectedMember.value, isNull);
      expect(controller.activeRoute.isEmpty, isTrue);
    });

    test('Reset compass resets compassRotation to 0.0', () {
      controller.compassRotation.value = 45.0;
      controller.resetCompass();
      expect(controller.compassRotation.value, equals(0.0));
    });

    test('toggleMapTileLayer switches between Voyager and OpenStreetMap tiles', () {
      expect(controller.activeTileUrl.value, contains('cartocdn'));
      expect(controller.activeTileUrl.value, contains(AppConstants.cartoApiKey));

      controller.toggleMapTileLayer();
      expect(controller.activeTileUrl.value, contains('openstreetmap.org'));

      controller.toggleMapTileLayer();
      expect(controller.activeTileUrl.value, contains('cartocdn'));
      expect(controller.activeTileUrl.value, contains(AppConstants.cartoApiKey));
    });
  });

  group('Room Members & Distance Formatting Requirements', () {
    test('Formats distance correctly: <1000m -> "X m", >=1000m -> "X.X km"', () {
      expect(MapController.formatDistance(500.0), equals('500 m'));
      expect(MapController.formatDistance(240.4), equals('240 m'));
      expect(MapController.formatDistance(1200.0), equals('1.2 km'));
      expect(MapController.formatDistance(2560.0), equals('2.6 km'));
    });

    test('RoomMemberModel parses GeoPoint correctly and handles null safely without crash', () {
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
      expect(memberWithoutGps.getLocationStatus(), equals('Lokasi belum tersedia'));
    });

    test('RoomMemberModel evaluates location status based on locationUpdatedAt', () {
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
      expect(staleMember.getLocationStatus(now), equals('Terakhir terlihat 45 dtk lalu'));

      // Expired > 120 seconds -> Lokasi tidak diperbarui
      final expiredMember = RoomMemberModel(
        uid: 'u3',
        name: 'Hasan',
        role: 'jamaah',
        currentLocation: const GeoPoint(21.4135, 39.8930),
        locationUpdatedAt: now.subtract(const Duration(seconds: 180)),
      );
      expect(expiredMember.getLocationStatus(now), equals('Lokasi tidak diperbarui'));
    });

    test('Filters room members correctly by role: Semua, Jamaah, Pendamping', () {
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
    });

    test('Nearest member calculation finds closest member with location and excludes current user', () {
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
      expect(controller.nearestMemberInfo, contains('Pendamping terdekat: Near Pendamping'));
    });
  });
}
