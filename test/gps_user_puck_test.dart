import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:hajicare/features/map/widgets/gps_user_puck.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GpsUserPuck Widget Tests', () {
    late MapController controller;

    setUp(() {
      Get.testMode = true;
      controller = MapController();
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    testWidgets('Renders stationary puck with forward beam when not moving', (
      tester,
    ) async {
      controller.userHeading.value = 45.0;
      controller.isUserMoving.value = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GpsUserPuck(mapCtrl: controller, isNavigating: false),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Verifies puck widget is present in tree
      expect(find.byType(GpsUserPuck), findsOneWidget);
      // Stationary state uses custom painter rather than navigation arrow icon
      expect(find.byIcon(Icons.navigation_rounded), findsNothing);
    });

    testWidgets('Renders navigation arrow icon when user is moving/walking', (
      tester,
    ) async {
      controller.userHeading.value = 90.0;
      controller.isUserMoving.value = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GpsUserPuck(mapCtrl: controller, isNavigating: false),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Moving state renders sharp navigation icon
      expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);
    });

    testWidgets('Renders in navigation mode with emerald theme', (
      tester,
    ) async {
      controller.userHeading.value = 180.0;
      controller.isUserMoving.value = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GpsUserPuck(mapCtrl: controller, isNavigating: true),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(GpsUserPuck), findsOneWidget);
      expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);
    });
  });

  group('MapController Compass & Dynamic Heading Tests', () {
    late MapController controller;
    late StreamController<CompassEvent> compassStreamCtrl;

    setUp(() {
      Get.testMode = true;
      compassStreamCtrl = StreamController<CompassEvent>.broadcast();
      controller = MapController(compassStream: compassStreamCtrl.stream);
      controller.onInit();
    });

    tearDown(() {
      compassStreamCtrl.close();
      controller.onClose();
      Get.reset();
    });

    test('Initializes with default heading 0.0 and stationary state', () {
      expect(controller.userHeading.value, equals(0.0));
      expect(controller.isUserMoving.value, isFalse);
    });

    test('Updates userHeading from compass events when stationary', () async {
      // In flutter_compass, CompassEvent.fromList expects [heading, accuracy, headingForCameraMode, accuracyForCameraMode]
      final event = CompassEvent.fromList([125.0, 15.0, 125.0, 15.0]);
      compassStreamCtrl.add(event);
      await pumpEventQueue();

      expect(controller.userHeading.value, closeTo(125.0, 0.1));
    });

    test('Filters micro-jitter noise below 0.6 degrees threshold', () async {
      compassStreamCtrl.add(CompassEvent.fromList([100.0, 15.0, 100.0, 15.0]));
      await pumpEventQueue();
      expect(controller.userHeading.value, closeTo(100.0, 0.1));

      // Minor jitter +0.3 degrees should be ignored by deadband filter
      compassStreamCtrl.add(CompassEvent.fromList([100.3, 15.0, 100.3, 15.0]));
      await pumpEventQueue();
      expect(controller.userHeading.value, closeTo(100.0, 0.1));

      // Significant movement +2.5 degrees should be accepted
      compassStreamCtrl.add(CompassEvent.fromList([102.5, 15.0, 102.5, 15.0]));
      await pumpEventQueue();
      expect(controller.userHeading.value, closeTo(102.5, 0.1));
    });

    test('Disengages isFollowingUser when map has user gesture', () {
      controller.isFollowingUser.value = true;

      controller.onMapPositionChanged(
        const LatLng(21.4135, 39.8930),
        16.5,
        hasGesture: true,
      );

      expect(controller.isFollowingUser.value, isFalse);
    });

    test('Re-engages isFollowingUser when focusToMe is called', () {
      controller.isFollowingUser.value = false;
      controller.currentUserLocation.value = const LatLng(21.4135, 39.8930);

      controller.focusToMe();

      expect(controller.isFollowingUser.value, isTrue);
    });
  });
}
