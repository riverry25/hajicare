import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
import 'package:hajicare/features/map/services/navigation_voice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Map Navigation Mode Tests', () {
    late MapController controller;

    setUp(() {
      controller = MapController();
    });

    test('Initial map mode is normal and follow user is true', () {
      expect(controller.mapMode.value, equals(MapMode.normal));
      expect(controller.isNavigating, isFalse);
      expect(controller.isFollowingUser.value, isTrue);
    });

    test(
      'startNavigation transitions to navigationStarting and navigating',
      () async {
        controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);
        final poi = MapPoi(
          id: 'hotel_1',
          name: 'Hotel Pullman Zamzam',
          category: PoiCategory.hotel,
          coordinate: const LatLng(21.4190, 39.8260),
        );
        controller.selectedPoi.value = poi;
        controller.activeRoute.assignAll([
          const LatLng(21.4135, 39.8930),
          const LatLng(21.4150, 39.8900),
          const LatLng(21.4190, 39.8260),
        ]);
        controller.routeDistanceMeters.value = 850.0;
        controller.routeDurationSeconds.value = 720;

        final startFuture = controller.startNavigation();
        expect(controller.mapMode.value, equals(MapMode.navigationStarting));
        expect(controller.isNavigating, isTrue);
        expect(controller.isBottomSheetOpen.value, isFalse);
        expect(
          controller.destinationTitle.value,
          equals('Hotel Pullman Zamzam'),
        );
        expect(controller.remainingNavDistance.value, equals(850.0));

        await startFuture;
        expect(controller.mapMode.value, equals(MapMode.navigating));
      },
    );

    test('Manual map interaction sets isFollowingUser to false', () async {
      controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);
      controller.selectedPoi.value = MapPoi(
        id: 'hotel_1',
        name: 'Hotel Pullman',
        category: PoiCategory.hotel,
        coordinate: const LatLng(21.4190, 39.8260),
      );
      controller.activeRoute.assignAll([
        const LatLng(21.4135, 39.8930),
        const LatLng(21.4190, 39.8260),
      ]);
      await controller.startNavigation();

      expect(controller.isFollowingUser.value, isTrue);
      controller.onNavigationUserPan();
      expect(controller.isFollowingUser.value, isFalse);
    });

    test('recenterNavigation re-engages follow mode', () async {
      controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);
      controller.selectedPoi.value = MapPoi(
        id: 'hotel_1',
        name: 'Hotel Pullman',
        category: PoiCategory.hotel,
        coordinate: const LatLng(21.4190, 39.8260),
      );
      controller.activeRoute.assignAll([
        const LatLng(21.4135, 39.8930),
        const LatLng(21.4190, 39.8260),
      ]);
      await controller.startNavigation();

      controller.onNavigationUserPan();
      expect(controller.isFollowingUser.value, isFalse);

      bool recenterTriggered = false;
      controller.onRecenterTriggered = () => recenterTriggered = true;

      controller.recenterNavigation();
      expect(controller.isFollowingUser.value, isTrue);
      expect(recenterTriggered, isTrue);
    });

    test(
      'exitNavigation restores normal mode and re-opens bottom sheet',
      () async {
        controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);
        controller.selectedPoi.value = MapPoi(
          id: 'hotel_1',
          name: 'Hotel Pullman',
          category: PoiCategory.hotel,
          coordinate: const LatLng(21.4190, 39.8260),
        );
        controller.activeRoute.assignAll([
          const LatLng(21.4135, 39.8930),
          const LatLng(21.4190, 39.8260),
        ]);
        await controller.startNavigation();

        expect(controller.isNavigating, isTrue);

        controller.exitNavigation();
        expect(controller.mapMode.value, equals(MapMode.normal));
        expect(controller.isNavigating, isFalse);
        expect(controller.isBottomSheetOpen.value, isTrue);
        expect(controller.selectedPoi.value?.name, equals('Hotel Pullman'));
      },
    );

    test('Arriving within 20 meters transitions mapMode to arrived', () async {
      const destCoord = LatLng(21.419000, 39.826000);
      controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);
      controller.selectedPoi.value = MapPoi(
        id: 'hotel_1',
        name: 'Hotel Pullman',
        category: PoiCategory.hotel,
        coordinate: destCoord,
      );
      controller.activeRoute.assignAll([
        const LatLng(21.4135, 39.8930),
        destCoord,
      ]);
      await controller.startNavigation();

      // Simulate GPS position within 10 meters of destination
      final arrivedPos = Position(
        longitude: destCoord.longitude,
        latitude: destCoord.latitude + 0.00005, // ~5.5 meters away
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 1.0,
        speedAccuracy: 0.0,
      );

      final arrivedCoord = LatLng(arrivedPos.latitude, arrivedPos.longitude);
      controller.currentUserLocation.value = arrivedCoord;
      controller.mapMode.value = MapMode.arrived;

      expect(controller.mapMode.value, equals(MapMode.arrived));
    });

    test('isVoiceGuidanceEnabled toggles voiceService muted state', () {
      expect(controller.isVoiceGuidanceEnabled.value, isTrue);
      expect(controller.voiceService.isMuted, isFalse);

      controller.isVoiceGuidanceEnabled.value = false;
      expect(controller.voiceService.isMuted, isTrue);

      controller.isVoiceGuidanceEnabled.value = true;
      expect(controller.voiceService.isMuted, isFalse);
    });

    test(
      'NavigationVoiceService handles announcement and reset without throwing',
      () async {
        final voice = NavigationVoiceService();
        voice.setMuted(false);
        expect(voice.isMuted, isFalse);

        // Verify announceManeuver does not crash
        await voice.announceManeuver(
          instruction: 'Belok kiri',
          distanceMeters: 50.0,
          durationSeconds: 120,
        );

        // Verify arrival call
        await voice.speak('Anda telah sampai di tujuan.', force: true);

        // Verify reset
        voice.reset();
        expect(voice.isMuted, isFalse);
      },
    );
  });
}
