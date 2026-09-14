import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/constants/app_constants.dart';
import 'package:hajicare/core/models/jamaah_data.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
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
      // 0: Jamaah -> no POIs shown
      controller.selectFilter(0);
      expect(controller.filteredPois.isEmpty, isTrue);

      // 1: Semua -> all POIs
      controller.selectFilter(1);
      expect(controller.filteredPois.length, equals(controller.pois.length));

      // 2: Toilet & Wudhu
      controller.selectFilter(2);
      expect(controller.filteredPois.every((p) => p.category == PoiCategory.toilet), isTrue);
      expect(controller.filteredPois.isNotEmpty, isTrue);

      // 3: Posko Medis PPIH
      controller.selectFilter(3);
      expect(controller.filteredPois.every((p) => p.category == PoiCategory.medis), isTrue);
      expect(controller.filteredPois.isNotEmpty, isTrue);

      // 4: Tenda Maktab 48
      controller.selectFilter(4);
      expect(controller.filteredPois.every((p) => p.category == PoiCategory.maktab), isTrue);
      expect(controller.filteredPois.isNotEmpty, isTrue);
    });

    test('Distance calculation between coordinates returns accurate metric distance', () {
      const p1 = LatLng(21.4135, 39.8930); // Maktab 48
      const p2 = LatLng(21.4145, 39.8942); // Posko Medis
      final dist = controller.calculateDistanceMeters(p1, p2);

      // Distance should be approximately 100-200 meters in Mina
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

    test('Selecting a POI updates selection, clears Jamaah, and updates route', () {
      final poi = controller.pois.firstWhere((p) => p.category == PoiCategory.toilet);

      controller.selectPoi(poi);

      expect(controller.selectedPoi.value, equals(poi));
      expect(controller.selectedJamaah.value, isNull);
      expect(controller.activeRoute.isNotEmpty, isTrue);
      expect(controller.activeRoute.last, equals(poi.coordinate));
    });

    test('Selecting a Jamaah updates selection, clears POI, and updates route', () {
      final jamaah = JamaahData(
        id: 'user_123',
        name: 'H. Ahmad Dahlan',
        shortLabel: 'Ayah',
        distance: 120.0,
      );

      controller.selectJamaah(jamaah);

      expect(controller.selectedJamaah.value, equals(jamaah));
      expect(controller.selectedPoi.value, isNull);
      expect(controller.activeRoute.isNotEmpty, isTrue);
    });

    test('clearSelection resets all selected entities and route', () {
      final poi = controller.pois.first;
      controller.selectPoi(poi);
      expect(controller.selectedPoi.value, isNotNull);

      controller.clearSelection();

      expect(controller.selectedPoi.value, isNull);
      expect(controller.selectedJamaah.value, isNull);
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
}
