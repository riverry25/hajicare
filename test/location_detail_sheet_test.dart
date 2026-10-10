import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
import 'package:hajicare/features/map/widgets/location_detail_sheet.dart';
import 'package:latlong2/latlong.dart';

void main() {
  Widget buildTestApp({
    required Widget child,
    Locale locale = const Locale('id'),
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
      ],
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: textScaler,
          size: const Size(360, 640),
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  final poi = MapPoi(
    id: 'osm_node_42',
    name: 'Hotel Dinamis',
    category: PoiCategory.hotel,
    coordinate: const LatLng(-6.2, 106.8),
    openingHours: '24/7',
    statusLabel: 'Buka 24 jam',
    address: 'Jalan Contoh 1',
    subtitle: 'Jalan Contoh 1',
    phone: '+62 21 1234',
    website: 'https://example.test',
    tags: const ['Bintang 4', 'Akses kursi roda'],
    osmType: 'node',
    osmId: 42,
  );

  testWidgets('shows sourced metadata and exposes working actions', (
    tester,
  ) async {
    var routeTaps = 0;
    var shareTaps = 0;
    await tester.pumpWidget(
      buildTestApp(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LocationDetailSheet(
            poi: poi,
            distanceMeters: 350,
            onRoute: () => routeTaps++,
            onShare: () => shareTaps++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hotel Dinamis'), findsOneWidget);
    expect(find.text('Buka 24 jam'), findsOneWidget);
    expect(find.text('+62 21 1234'), findsOneWidget);
    expect(find.text('Situs tersedia'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Rute'));
    await tester.tap(find.text('Bagikan'));
    expect(routeTaps, 1);
    expect(shareTaps, 1);
  });

  testWidgets('shows routing progress and disables duplicate route request', (
    tester,
  ) async {
    var routeTaps = 0;
    await tester.pumpWidget(
      buildTestApp(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LocationDetailSheet(
            poi: poi,
            isRouteLoading: true,
            onRoute: () => routeTaps++,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Mencari Rute…'), findsOneWidget);
    await tester.tap(find.text('Mencari Rute…'));
    expect(routeTaps, 0);
  });

  testWidgets(
    'shows clear error message and working fallback buttons when route unavailable',
    (tester) async {
      var centerMapTaps = 0;
      Uri? launchedUri;

      await tester.pumpWidget(
        buildTestApp(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: LocationDetailSheet(
              poi: poi,
              routeError: 'Rute langsung tidak tersedia untuk tujuan ini',
              userCoordinate: const LatLng(-6.175, 106.827),
              onCenterOnDestination: () => centerMapTaps++,
              uriLauncher: (uri) async {
                launchedUri = uri;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Rute langsung tidak tersedia untuk tujuan ini'),
        findsOneWidget,
      );
      expect(find.text('Lihat di Peta'), findsOneWidget);
      expect(find.text('Buka di Google Maps'), findsOneWidget);

      await tester.tap(find.text('Lihat di Peta'));
      expect(centerMapTaps, equals(1));

      await tester.tap(find.text('Buka di Google Maps'));
      expect(launchedUri, isNotNull);
      expect(launchedUri.toString(), contains('google.com/maps/dir/'));
      expect(launchedUri.toString(), contains('-6.2'));
      expect(launchedUri.toString(), contains('106.8'));
    },
  );

  testWidgets(
    'displays fully localized category, status, and tags in English',
    (tester) async {
      final wudhuPoi = MapPoi(
        id: 'osm_node_99',
        name: 'Air & Wudhu',
        category: PoiCategory.wudhu,
        coordinate: const LatLng(-6.2, 106.8),
        openingHours: '24/7',
        statusLabel: 'Buka 24 jam',
        tags: const ['Gratis', 'Akses kursi roda'],
      );

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: LocationDetailSheet(
              poi: wudhuPoi,
              distanceMeters: 250,
              onRoute: () {},
              onShare: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check category badge translates
      expect(find.text('Water & Wudhu'), findsAtLeastNWidgets(1));
      // Check status translates
      expect(find.text('Open 24 hours'), findsOneWidget);
      // Check tags translate
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Wheelchair accessible'), findsOneWidget);
      // Check buttons translate
      expect(find.text('Route'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders cleanly without overflow under high accessibility font scaling (2.0x)',
    (tester) async {
      final hotelPoi = MapPoi(
        id: 'osm_node_42',
        name: 'Hotel Mewah Grand Makkah Super Bintang Lima',
        category: PoiCategory.hotel,
        coordinate: const LatLng(-6.2, 106.8),
        openingHours: '24/7',
        statusLabel: 'Buka 24 jam',
        tags: const ['Bintang 5', 'Akses kursi roda', 'Gratis'],
      );

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('id'),
          textScaler: const TextScaler.linear(2.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: LocationDetailSheet(
              poi: hotelPoi,
              distanceMeters: 1200,
              onRoute: () {},
              onShare: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('displays localized category in Javanese and Sundanese', (
    tester,
  ) async {
    final wudhuPoi = MapPoi(
      id: 'osm_node_99',
      name: 'Air & Wudhu',
      category: PoiCategory.wudhu,
      coordinate: const LatLng(-6.2, 106.8),
      openingHours: '24/7',
      statusLabel: 'Buka 24 jam',
    );

    // Test Javanese
    await tester.pumpWidget(
      buildTestApp(
        locale: const Locale('jv'),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LocationDetailSheet(poi: wudhuPoi),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Toya & Wudhu'), findsAtLeastNWidgets(1));

    // Test Sundanese
    await tester.pumpWidget(
      buildTestApp(
        locale: const Locale('su'),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LocationDetailSheet(poi: wudhuPoi),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cai & Wudhu'), findsAtLeastNWidgets(1));
  });
}
