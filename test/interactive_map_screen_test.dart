import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/core/widgets/bottom_nav_bar.dart';
import 'package:hajicare/features/dashboard/controllers/dashboard_controller.dart';
import 'package:hajicare/features/dashboard/models/assistance_request_model.dart';
import 'package:hajicare/features/dashboard/services/assistance_request_service.dart';
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

    testWidgets(
      'InteractiveMapScreen bottom navigation bar switches dashboard tabs',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        Get.put(AppSettingsController(), permanent: true);
        Get.put(HajiCareController(), permanent: true);
        final dashCtrl = Get.put(DashboardController(), permanent: true);
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
            home: const InteractiveMapScreen(showBottomNav: true),
          ),
        );

        await tester.pump();

        // Bottom nav bar is rendered
        expect(find.byType(HajiCareBottomNavBar), findsOneWidget);

        // Tap Jadwal Salat (tab 2)
        await tester.tap(
          find.descendant(
            of: find.byType(HajiCareBottomNavBar),
            matching: find.byIcon(Icons.schedule_rounded),
          ),
        );
        await tester.pump();
        expect(dashCtrl.currentIndex.value, equals(2));

        // Tap Profil (tab 3)
        await tester.tap(
          find.descendant(
            of: find.byType(HajiCareBottomNavBar),
            matching: find.byIcon(Icons.person_rounded),
          ),
        );
        await tester.pump();
        expect(dashCtrl.currentIndex.value, equals(3));

        // Tap Beranda (tab 0)
        await tester.tap(
          find.descendant(
            of: find.byType(HajiCareBottomNavBar),
            matching: find.byIcon(Icons.home_rounded),
          ),
        );
        await tester.pump();
        expect(dashCtrl.currentIndex.value, equals(0));
      },
    );

    testWidgets(
      'Renders assistance marker on map when active assistance exists',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        Get.put(AppSettingsController(), permanent: true);
        Get.put(HajiCareController(), permanent: true);
        final assistanceService = Get.put(
          AssistanceRequestService(),
          permanent: true,
        );
        MapBinding().dependencies();

        final req = AssistanceRequestModel(
          id: 'req-map-001',
          roomId: 'room-1',
          jamaahId: 'j-01',
          jamaahName: 'Jihad Ardiansyah',
          type: AssistanceType.lostWay,
          status: AssistanceStatus.sent,
          message: 'Saya terpisah dari rombongan',
          latitude: 21.4225,
          longitude: 39.8262,
          humanReadableLocation: '3.5 km dari Maktab 20',
          targetHotel: 'Maktab 20',
          createdAt: DateTime.now(),
        );
        assistanceService.activeRequest.value = req;
        final mapCtrl = Get.find<MapController>();
        mapCtrl.focusOnAssistanceRequest(req);

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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        // Memastikan Marker Bantuan untuk Jihad Ardiansyah dirender pada layer peta
        // dan MapBottomSheet menampilkan detail jamaah
        expect(find.text('Jihad Ardiansyah'), findsNWidgets(2));
        expect(find.byIcon(Icons.directions_run_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Deduplicates SOS markers and renders single emergency pin for jamaah',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        Get.put(AppSettingsController(), permanent: true);
        final hajiCtrl = Get.put(HajiCareController(), permanent: true);
        MapBinding().dependencies();
        final mapCtrl = Get.find<MapController>();

        // Add member "Humai" to room members with SOS active at default camera center
        final humai = RoomMemberModel(
          uid: 'j-humai-1',
          name: 'Humai',
          role: 'jamaah',
          currentLocation: const GeoPoint(21.4133, 39.8933),
          locationUpdatedAt: DateTime.now(),
          sosActive: true,
        );
        mapCtrl.roomMembers.assignAll([humai]);

        // Add 2 active SOS events for Humai in HajiCareController (simulating duplicate events)
        hajiCtrl.activeSosEvents.assignAll([
          {
            'id': 'sos-event-1',
            'userId': 'j-humai-1',
            'userName': 'Humai',
            'location': const GeoPoint(21.4133, 39.8933),
          },
          {
            'id': 'sos-event-2',
            'userId': 'j-humai-1',
            'userName': 'Humai',
            'location': const GeoPoint(21.4133, 39.8933),
          },
        ]);

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
        await tester.pump(const Duration(milliseconds: 500));

        // Exactly one emergency marker banner on the map for Humai (deduplicated from 2 active events)
        expect(find.text('SOS • Humai'), findsOneWidget);
        expect(find.byIcon(Icons.sos_rounded), findsOneWidget);
      },
    );
  });
}

