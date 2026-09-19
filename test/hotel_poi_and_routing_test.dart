import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
import 'package:hajicare/features/map/services/poi_service.dart';
import 'package:hajicare/features/map/services/route_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Real OSM Hotel POI Discovery & Parsing Tests', () {
    test('mapOsmElementToHotel correctly parses node coordinates', () {
      final service = PoiService();
      final nodeData = {
        "type": "node",
        "id": 12345678,
        "lat": 21.4230,
        "lon": 39.8255,
        "tags": {
          "tourism": "hotel",
          "name": "Makkah Clock Royal Tower",
          "stars": "5",
          "wheelchair": "yes",
        },
      };

      final poi = service.mapOsmElementToHotel(nodeData);

      expect(poi, isNotNull);
      expect(poi!.id, equals('osm_node_12345678'));
      expect(poi.name, equals('Makkah Clock Royal Tower'));
      expect(poi.category, equals(PoiCategory.hotel));
      expect(poi.coordinate.latitude, equals(21.4230));
      expect(poi.coordinate.longitude, equals(39.8255));
      expect(poi.isAccessible, isTrue);
      expect(poi.tags, contains('Bintang 5'));
      expect(poi.statusLabel, equals('Data OpenStreetMap'));
    });

    test(
      'mapOsmElementToHotel correctly parses way and relation with center coordinates',
      () {
        final service = PoiService();
        final wayData = {
          "type": "way",
          "id": 9876543,
          "center": {"lat": 21.4200, "lon": 39.8300},
          "tags": {
            "tourism": "hotel",
            "name": "Swissôtel Al Maqam",
            "rooms": "1624",
          },
        };

        final poi = service.mapOsmElementToHotel(wayData);

        expect(poi, isNotNull);
        expect(poi!.id, equals('osm_way_9876543'));
        expect(poi.name, equals('Swissôtel Al Maqam'));
        expect(poi.coordinate.latitude, equals(21.4200));
        expect(poi.coordinate.longitude, equals(39.8300));
        expect(poi.tags, contains('1624 kamar'));
      },
    );

    test(
      'mapOsmElementToHotel returns null for invalid or missing coordinates',
      () {
        final service = PoiService();
        // Missing lat/lon
        expect(
          service.mapOsmElementToHotel({
            "type": "node",
            "id": 1,
            "tags": {"tourism": "hotel"},
          }),
          isNull,
        );
        // Way missing center
        expect(
          service.mapOsmElementToHotel({
            "type": "way",
            "id": 2,
            "tags": {"tourism": "hotel"},
          }),
          isNull,
        );
        // Out of bounds coordinates
        expect(
          service.mapOsmElementToHotel({
            "type": "node",
            "id": 3,
            "lat": 100.0,
            "lon": 50.0,
          }),
          isNull,
        );
      },
    );

    test(
      'mapOsmElementToHotel provides fallback name when tags["name"] is missing',
      () {
        final service = PoiService();
        final anonymousHotel = {
          "type": "node",
          "id": 555,
          "lat": 21.4150,
          "lon": 39.8950,
          "tags": {"tourism": "hotel"},
        };

        final poi = service.mapOsmElementToHotel(anonymousHotel);
        expect(poi, isNotNull);
        expect(poi!.name, equals('Hotel / Penginapan'));
      },
    );

    test(
      'fetchNearbyHotels deduplicates elements and caches responses spatially',
      () async {
        int apiCallCount = 0;
        final mockOverpassResponse = {
          "elements": [
            {
              "type": "node",
              "id": 1001,
              "lat": 21.4201,
              "lon": 39.8251,
              "tags": {"tourism": "hotel", "name": "Hotel A"},
            },
            // Duplicate element with same ID
            {
              "type": "node",
              "id": 1001,
              "lat": 21.4201,
              "lon": 39.8251,
              "tags": {"tourism": "hotel", "name": "Hotel A Duplicate"},
            },
            {
              "type": "way",
              "id": 2002,
              "center": {"lat": 21.4205, "lon": 39.8258},
              "tags": {"tourism": "hotel", "name": "Hotel B"},
            },
          ],
        };

        final mockClient = MockClient((request) async {
          apiCallCount++;
          return http.Response(jsonEncode(mockOverpassResponse), 200);
        });

        final service = PoiService(client: mockClient);
        const userCenter = LatLng(21.4200, 39.8250);

        // First fetch: triggers API call
        final hotels1 = await service.fetchNearbyHotels(center: userCenter);
        expect(hotels1.length, equals(2));
        expect(apiCallCount, equals(1));
        expect(hotels1.map((h) => h.id).toSet().length, equals(2));

        // Second fetch within 500m (e.g. moved 50 meters)
        const slightlyMovedCenter = LatLng(21.4203, 39.8252);
        final hotels2 = await service.fetchNearbyHotels(
          center: slightlyMovedCenter,
        );
        expect(hotels2.length, equals(2));
        // API call count MUST still be 1 (spatial cache hit)
        expect(apiCallCount, equals(1));
      },
    );

    test(
      'fetchNearbyHotels does not reuse hotels from a different area on failure',
      () async {
        int callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            return http.Response(
              jsonEncode({
                "elements": [
                  {
                    "type": "node",
                    "id": 777,
                    "lat": 21.421,
                    "lon": 39.826,
                    "tags": {"tourism": "hotel", "name": "Solid Hotel"},
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('Server Error', 500);
        });

        final service = PoiService(client: mockClient);
        const center1 = LatLng(21.421, 39.826);
        const center2FarAway = LatLng(21.435, 39.840); // > 1km away

        // 1. First fetch succeeds
        final res1 = await service.fetchNearbyHotels(center: center1);
        expect(res1.isNotEmpty, isTrue);

        // A different area must never receive stale pins from center1.
        await expectLater(
          service.fetchNearbyHotels(center: center2FarAway),
          throwsA(isA<PoiServiceException>()),
        );
      },
    );
  });

  group('Route Service & GeoJSON Geometry Tests', () {
    test('no-key fallback uses the pedestrian OpenStreetMap backend', () async {
      late Uri requestedUri;
      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 92.0,
                'duration': 73.5,
                'geometry': {
                  'type': 'LineString',
                  'coordinates': [
                    [106.8456, -6.2088],
                    [106.8460, -6.2095],
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      final service = RouteService(client: mockClient, apiKey: '');

      final result = await service.getWalkingRoute(
        origin: const LatLng(-6.2088, 106.8456),
        destination: const LatLng(-6.2095, 106.8460),
      );

      expect(requestedUri.host, 'routing.openstreetmap.de');
      expect(requestedUri.path, contains('/routed-foot/'));
      expect(result.distanceMeters, 92.0);
      expect(result.points, hasLength(2));
    });

    test(
      'HeiGIT GeoJSON line string coordinates converted correctly to LatLng',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              "type": "FeatureCollection",
              "features": [
                {
                  "type": "Feature",
                  "geometry": {
                    "type": "LineString",
                    "coordinates": [
                      [39.8262, 21.4225], // GeoJSON lon, lat
                      [39.8270, 21.4230],
                    ],
                  },
                  "properties": {
                    "summary": {"distance": 115.0, "duration": 85.0},
                  },
                },
              ],
            }),
            200,
          );
        });

        final routeService = RouteService(
          client: mockClient,
          apiKey: 'test_key',
        );
        final result = await routeService.getWalkingRoute(
          origin: const LatLng(21.4225, 39.8262),
          destination: const LatLng(21.4230, 39.8270),
        );

        expect(result.points.length, equals(2));
        // First coordinate: latitude must be 21.4225, longitude must be 39.8262
        expect(result.points.first.latitude, equals(21.4225));
        expect(result.points.first.longitude, equals(39.8262));
        expect(result.distanceMeters, equals(115.0));
        expect(result.durationSeconds, equals(85));
      },
    );
  });
}
