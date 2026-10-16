import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:hajicare/features/map/widgets/navigation/navigation_recenter_button.dart';
import 'package:latlong2/latlong.dart';

/// Regression tests for the navigation-mode red screen:
/// "[Get] the improper use of a GetX has been detected" and
/// "Incorrect use of ParentDataWidget".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MapController controller;

  setUp(() {
    Get.testMode = true;
    controller = MapController();
  });

  tearDown(Get.reset);

  testWidgets('Obx reading currentDestinationCoord is reactive when an active '
      'destination is set', (tester) async {
    const dest = LatLng(21.4190, 39.8260);
    controller.debugActiveDestination = dest;

    await tester.pumpWidget(
      MaterialApp(
        home: Obx(() {
          final coord = controller.currentDestinationCoord;
          return Text(coord == null ? 'none' : 'dest');
        }),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('dest'), findsOneWidget);

    controller.clearRoute();
    await tester.pump();
    expect(find.text('none'), findsOneWidget);
  });

  testWidgets('NavigationRecenterButton is a valid Stack child and fades with '
      'follow state', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Stack(
            children: [NavigationRecenterButton(mapCtrl: controller)],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    AnimatedOpacity opacity() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));

    // Following → hidden.
    expect(opacity().opacity, 0.0);

    controller.isFollowingUser.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(opacity().opacity, 1.0);
  });
}
