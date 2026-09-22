import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/map/bindings/map_binding.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:hajicare/features/map/models/map_search_result.dart';
import 'package:hajicare/features/map/screens/interactive_map_screen.dart';
import 'package:hajicare/features/map/widgets/map_bottom_sheet.dart';
import 'package:hajicare/features/map/widgets/map_floating_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestMapScreen() {
    Get.put(AppSettingsController(), permanent: true);
    Get.put(HajiCareController(), permanent: true);
    MapBinding().dependencies();

    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: const InteractiveMapScreen(),
    );
  }

  group('InteractiveMapScreen UX Coordination Tests', () {
    testWidgets('Verify correct Stack layering order', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestMapScreen());
      await tester.pump();

      final stackFinder = find.byType(Stack).first;
      expect(stackFinder, findsOneWidget);

      final stackWidget = tester.widget<Stack>(stackFinder);
      final children = stackWidget.children;

      // Ensure that there are at least 6 children and the top-most is Positioned (MapSearchDropdown)
      expect(children.length, greaterThanOrEqualTo(6));
      expect(children.last, isA<Positioned>());
    });

    testWidgets(
      'Scenario A & E: Search active hides Hamburger so it never overlaps',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestMapScreen());
        await tester.pump();

        final mapCtrl = Get.find<MapController>();

        final floatingControlsFinder = find.byType(MapFloatingControls);
        expect(floatingControlsFinder, findsOneWidget);
        var controlsWidget = tester.widget<MapFloatingControls>(
          floatingControlsFinder,
        );
        expect(controlsWidget.isVisible, isTrue);

        // Simulate search results active
        mapCtrl.searchState.value = MapSearchState.results;
        mapCtrl.searchResults.assignAll([
          const MapSearchResult(
            id: 'test_1',
            name: 'Masjidil Haram',
            address: 'Makkah, Saudi Arabia',
            latitude: 21.4225,
            longitude: 39.8262,
          ),
        ]);

        await tester.pump(const Duration(milliseconds: 300));

        // Hamburger is now hidden so it cannot overlap search dropdown results!
        controlsWidget = tester.widget<MapFloatingControls>(
          floatingControlsFinder,
        );
        expect(controlsWidget.isVisible, isFalse);

        // Dismiss search
        mapCtrl.searchState.value = MapSearchState.idle;
        await tester.pump(const Duration(milliseconds: 300));

        controlsWidget = tester.widget<MapFloatingControls>(
          floatingControlsFinder,
        );
        expect(controlsWidget.isVisible, isTrue);
      },
    );

    testWidgets(
      'Scenario B & C: Map gesture hides Hamburger; 1.5s idle re-shows Hamburger',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestMapScreen());
        await tester.pump();

        final floatingControlsFinder = find.byType(MapFloatingControls);
        expect(floatingControlsFinder, findsOneWidget);
        var controlsWidget = tester.widget<MapFloatingControls>(
          floatingControlsFinder,
        );
        expect(controlsWidget.isVisible, isTrue);

        final mapFinder = find.byType(fmap.FlutterMap);
        expect(mapFinder, findsOneWidget);

        // Drag down on map to trigger gesture
        await tester.drag(mapFinder, const Offset(0, 80));
        await tester.pump();

        controlsWidget = tester.widget<MapFloatingControls>(
          floatingControlsFinder,
        );
        expect(controlsWidget.isVisible, isFalse);

        // Advance 1000ms (still less than 1.5s)
        await tester.pump(const Duration(milliseconds: 1000));
        controlsWidget = tester.widget<MapFloatingControls>(
          floatingControlsFinder,
        );
        expect(controlsWidget.isVisible, isFalse);

        // Advance 600ms (totals 1600ms > 1500ms)
        await tester.pump(const Duration(milliseconds: 600));

        controlsWidget = tester.widget<MapFloatingControls>(
          floatingControlsFinder,
        );
        expect(controlsWidget.isVisible, isTrue);
      },
    );

    testWidgets(
      'Scenario D: Compact Member Pill is tappable and opens MapBottomSheet',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestMapScreen());
        await tester.pump();

        final mapCtrl = Get.find<MapController>();

        // Close bottom sheet to put it in collapsed compact mode
        mapCtrl.closeBottomSheet();
        await tester.pump(const Duration(milliseconds: 300));
        expect(mapCtrl.isBottomSheetOpen.value, isFalse);

        // Find the compact pill expand text 'Buka'
        final openButtonFinder = find.text('Buka');
        expect(openButtonFinder, findsOneWidget);

        // Tap on the compact pill
        await tester.tap(openButtonFinder);
        await tester.pump(const Duration(milliseconds: 300));

        // Bottom sheet is now open
        expect(mapCtrl.isBottomSheetOpen.value, isTrue);
        expect(find.byType(MapBottomSheet), findsOneWidget);

        // Close bottom sheet
        mapCtrl.closeBottomSheet();
        await tester.pump(const Duration(milliseconds: 300));

        expect(mapCtrl.isBottomSheetOpen.value, isFalse);
        expect(find.text('Buka'), findsOneWidget);
      },
    );
  });
}
