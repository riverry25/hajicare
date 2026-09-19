import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
import 'package:hajicare/features/map/widgets/location_detail_sheet.dart';
import 'package:latlong2/latlong.dart';

void main() {
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
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LocationDetailSheet(
              poi: poi,
              distanceMeters: 350,
              onRoute: () => routeTaps++,
              onShare: () => shareTaps++,
            ),
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

    await tester.tap(find.text('Rute Jalan Kaki'));
    await tester.tap(find.text('Bagikan'));
    expect(routeTaps, 1);
    expect(shareTaps, 1);
  });

  testWidgets('shows routing progress and disables duplicate route request', (
    tester,
  ) async {
    var routeTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LocationDetailSheet(
              poi: poi,
              isRouteLoading: true,
              onRoute: () => routeTaps++,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Mencari Rute…'), findsOneWidget);
    await tester.tap(find.text('Mencari Rute…'));
    expect(routeTaps, 0);
  });
}
