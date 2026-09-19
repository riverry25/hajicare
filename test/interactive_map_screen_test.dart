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
import 'package:hajicare/features/map/screens/interactive_map_screen.dart';
import 'package:latlong2/latlong.dart';
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

  group('InteractiveMapScreen Widget Rendering Tests', () {
    testWidgets('Renders InteractiveMapScreen in Light Mode without error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      MapBinding().dependencies();

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: const InteractiveMapScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(InteractiveMapScreen), findsOneWidget);
      expect(find.text('GPS Aktif'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
    });

    testWidgets('Renders InteractiveMapScreen in Dark Mode without error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      MapBinding().dependencies();

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: const InteractiveMapScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(InteractiveMapScreen), findsOneWidget);
      expect(find.text('GPS Aktif'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
    });

    testWidgets(
      'Renders PolylineLayer with activeRoute on InteractiveMapScreen',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        Get.put(AppSettingsController(), permanent: true);
        Get.put(HajiCareController(), permanent: true);
        MapBinding().dependencies();

        await tester.pumpWidget(
          GetMaterialApp(
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
          ),
        );

        await tester.pump();

        final mapCtrl = Get.find<MapController>();
        expect(mapCtrl.activeRoute.isEmpty, isTrue);

        // Simulate activeRoute assigned with walking coordinates
        mapCtrl.activeRoute.assignAll([
          const LatLng(21.4135, 39.8930),
          const LatLng(21.4140, 39.8935),
          const LatLng(21.4145, 39.8942),
        ]);

        await tester.pump();

        final polylineLayerFinder = find.byType(fmap.PolylineLayer);
        expect(polylineLayerFinder, findsOneWidget);
        final polylineLayer = tester.widget<fmap.PolylineLayer>(
          polylineLayerFinder,
        );
        expect(polylineLayer.polylines.isNotEmpty, isTrue);
        expect(polylineLayer.polylines.first.points.length, equals(3));
        expect(polylineLayer.polylines.first.strokeWidth, equals(8.0));
        expect(
          polylineLayer.polylines.first.color,
          equals(const Color(0xFF1E60CC)),
        );
      },
    );
  });
}
