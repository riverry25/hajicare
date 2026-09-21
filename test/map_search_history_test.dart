import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:hajicare/features/map/models/map_search_result.dart';
import 'package:hajicare/features/map/services/route_service.dart';
import 'package:hajicare/features/map/widgets/map_search_dropdown.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRouteService extends RouteService {
  bool shouldThrow = false;
  RouteResult? fixedResult;

  @override
  Future<RouteResult> getWalkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (shouldThrow) {
      throw const RouteException('Network failure or impossible route');
    }
    return fixedResult ??
        RouteResult(
          points: [origin, destination],
          distanceMeters: 500,
          durationSeconds: 300,
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  group('MapSearchResult Serialization', () {
    test('toJson and fromJson preserve all fields correctly', () {
      const original = MapSearchResult(
        id: 'place_123',
        name: 'Masjidil Haram',
        address: 'Al Haram, Makkah 24231',
        latitude: 21.4225,
        longitude: 39.8262,
        type: 'place_of_worship',
        category: 'amenity',
      );

      final json = original.toJson();
      expect(json['id'], equals('place_123'));
      expect(json['name'], equals('Masjidil Haram'));
      expect(json['latitude'], equals(21.4225));
      expect(json['longitude'], equals(39.8262));

      final restored = MapSearchResult.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.address, equals(original.address));
      expect(restored.latitude, equals(original.latitude));
      expect(restored.longitude, equals(original.longitude));
      expect(restored.type, equals(original.type));
      expect(restored.category, equals(original.category));
      expect(restored, equals(original));
    });
  });

  group('MapController Search History Management', () {
    late MapController controller;
    late _FakeRouteService fakeRouteService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeRouteService = _FakeRouteService();
      controller = MapController(routeService: fakeRouteService);
    });

    tearDown(() {
      controller.onClose();
    });

    test('addSearchHistory prepends and removes duplicates by id', () async {
      const place1 = MapSearchResult(
        id: 'loc_1',
        name: 'Hotel Al-Safwah',
        address: 'Abraj Al Bait',
        latitude: 21.42,
        longitude: 39.82,
      );
      const place2 = MapSearchResult(
        id: 'loc_2',
        name: 'Zamzam Tower',
        address: 'Ajyad',
        latitude: 21.419,
        longitude: 39.825,
      );

      await controller.addSearchHistory(place1);
      await controller.addSearchHistory(place2);
      expect(controller.searchHistory.length, equals(2));
      expect(controller.searchHistory.first.id, equals('loc_2'));

      // Re-adding place1 moves it to the top without duplicating
      await controller.addSearchHistory(place1);
      expect(controller.searchHistory.length, equals(2));
      expect(controller.searchHistory.first.id, equals('loc_1'));
      expect(controller.searchHistory[1].id, equals('loc_2'));
    });

    test(
      'Search history persists in SharedPreferences across reload',
      () async {
        const place = MapSearchResult(
          id: 'loc_persistent',
          name: 'Jabal Rahmah',
          address: 'Arafat',
          latitude: 21.3547,
          longitude: 39.9841,
        );

        await controller.addSearchHistory(place);

        // Create a second controller instance and load history
        final controller2 = MapController(routeService: fakeRouteService);
        await controller2.loadSearchHistory();
        expect(controller2.searchHistory.length, equals(1));
        expect(controller2.searchHistory.first.name, equals('Jabal Rahmah'));
        controller2.onClose();
      },
    );

    test(
      'removeSearchHistoryItem and clearSearchHistory work properly',
      () async {
        const place1 = MapSearchResult(
          id: 'p1',
          name: 'Mina Camp',
          address: 'Mina',
          latitude: 21.413,
          longitude: 39.893,
        );
        const place2 = MapSearchResult(
          id: 'p2',
          name: 'Muzdalifah',
          address: 'Makkah',
          latitude: 21.38,
          longitude: 39.93,
        );

        await controller.addSearchHistory(place1);
        await controller.addSearchHistory(place2);
        expect(controller.searchHistory.length, equals(2));

        await controller.removeSearchHistoryItem('p1');
        expect(controller.searchHistory.length, equals(1));
        expect(controller.searchHistory.first.id, equals('p2'));

        await controller.clearSearchHistory();
        expect(controller.searchHistory.isEmpty, isTrue);
      },
    );

    test(
      'selectSearchResult adds to history, opens sheet, and sets destination',
      () {
        const place = MapSearchResult(
          id: 'sel_target',
          name: 'Pintu King Abdulaziz',
          address: 'Masjidil Haram',
          latitude: 21.419,
          longitude: 39.825,
        );

        controller.selectSearchResult(place);

        expect(
          controller.searchHistory.any((e) => e.id == 'sel_target'),
          isTrue,
        );
        expect(controller.selectedSearchResult.value, equals(place));
        expect(
          controller.selectedPoi.value?.name,
          equals('Pintu King Abdulaziz'),
        );
        expect(controller.isBottomSheetOpen.value, isTrue);
        expect(controller.searchState.value, equals(MapSearchState.idle));
      },
    );
  });

  group('MapController Route & Far Destination Handling', () {
    late MapController controller;
    late _FakeRouteService fakeRouteService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeRouteService = _FakeRouteService();
      controller = MapController(routeService: fakeRouteService);
    });

    tearDown(() {
      controller.onClose();
    });

    test(
      'requestRouteToPoi handles distance > 100km gracefully without crash',
      () async {
        // User in Jakarta (-6.2, 106.8), Target in Makkah (21.42, 39.82) -> distance ~ 8000km
        controller.currentUserLocation.value = const LatLng(-6.2, 106.8);

        const farResult = MapSearchResult(
          id: 'far_dest',
          name: 'Masjidil Haram',
          address: 'Makkah',
          latitude: 21.4225,
          longitude: 39.8262,
        );
        controller.selectSearchResult(farResult);

        await controller.requestRouteToPoi(controller.selectedPoi.value!);

        expect(controller.isRouteLoading.value, isFalse);
        expect(controller.activeRoute.isEmpty, isTrue);
        expect(
          controller.routeError.value,
          equals('Rute langsung tidak tersedia untuk tujuan ini'),
        );
      },
    );

    test(
      'requestRouteToPoi handles RouteException gracefully without crashing',
      () async {
        // User nearby (~500m) but routing API throws
        controller.currentUserLocation.value = const LatLng(21.4200, 39.8200);
        fakeRouteService.shouldThrow = true;

        const target = MapSearchResult(
          id: 'near_dest',
          name: 'Hotel Dekat',
          address: 'Makkah',
          latitude: 21.4225,
          longitude: 39.8225,
        );
        controller.selectSearchResult(target);

        await controller.requestRouteToPoi(controller.selectedPoi.value!);

        expect(controller.isRouteLoading.value, isFalse);
        expect(controller.activeRoute.isEmpty, isTrue);
        expect(
          controller.routeError.value,
          equals('Rute langsung tidak tersedia untuk tujuan ini'),
        );
      },
    );
  });

  group('MapSearchDropdown Recent Searches UI', () {
    testWidgets('renders search history and allows tapping an item', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final controller = MapController();
      controller.searchHistory.assignAll([
        const MapSearchResult(
          id: 'hist_1',
          name: 'Stasiun Kereta Cepat Haramain',
          address: 'Rusaifah, Makkah',
          latitude: 21.415,
          longitude: 39.790,
        ),
      ]);
      controller.searchState.value = MapSearchState.history;

      MapSearchResult? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSearchDropdown(
              mapCtrl: controller,
              onSelect: (item) => selectedItem = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pencarian Terakhir'), findsOneWidget);
      expect(find.text('Stasiun Kereta Cepat Haramain'), findsOneWidget);
      expect(find.text('Hapus Semua'), findsOneWidget);

      await tester.tap(find.text('Stasiun Kereta Cepat Haramain'));
      expect(selectedItem?.id, equals('hist_1'));

      controller.onClose();
    });
  });
}
