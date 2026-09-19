import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/services/geocoding_service.dart';
import 'package:hajicare/features/map/models/map_search_result.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GeocodingService Search Locations Tests', () {
    test(
      'Query < 2 characters returns empty list without making HTTP request',
      () async {
        int requestCount = 0;
        final client = MockClient((request) async {
          requestCount++;
          return http.Response(
            '{"type":"FeatureCollection","features":[]}',
            200,
          );
        });

        final service = GeocodingService();
        final resultsEmpty = await service.searchLocations('', client: client);
        final resultsSingle = await service.searchLocations(
          'j',
          client: client,
        );

        expect(resultsEmpty.isEmpty, isTrue);
        expect(resultsSingle.isEmpty, isTrue);
        expect(requestCount, equals(0));
      },
    );

    test(
      'Photon primary: parses GeoJSON features, coordinates, and structured address',
      () async {
        final client = MockClient((request) async {
          expect(request.url.host, equals('photon.komoot.io'));
          expect(request.url.path, equals('/api/'));
          expect(request.url.queryParameters['q'], equals("McDonald's"));
          expect(request.url.queryParameters['limit'], equals('10'));
          expect(request.headers['User-Agent'], contains('HajiCareApp'));

          final responseData = {
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "properties": {
                  "osm_id": 6183150285,
                  "osm_key": "amenity",
                  "osm_value": "fast_food",
                  "type": "house",
                  "name": "McDonald's",
                  "street": "Jalan Cideng Barat",
                  "housenumber": "12",
                  "district": "Gambir",
                  "city": "Jakarta",
                  "state": "Jawa",
                  "country": "Indonesia",
                  "postcode": "10150",
                },
                "geometry": {
                  "type": "Point",
                  "coordinates": [106.8110895, -6.173406],
                },
              },
            ],
          };
          return http.Response(jsonEncode(responseData), 200);
        });

        final service = GeocodingService();
        final results = await service.searchLocations(
          "McDonald's",
          client: client,
        );

        expect(results.length, equals(1));
        final item = results.first;
        expect(item.id, equals('photon_6183150285'));
        expect(item.name, equals("McDonald's"));
        // In GeoJSON, coordinates are [lon, lat]
        expect(item.longitude, closeTo(106.811, 0.001));
        expect(item.latitude, closeTo(-6.1734, 0.001));
        expect(item.coordinate.latitude, closeTo(-6.1734, 0.001));
        expect(item.address, contains('Jalan Cideng Barat No. 12'));
        expect(item.address, contains('Gambir'));
        expect(item.address, contains('Jakarta'));
        expect(item.category, equals('fast_food'));
        expect(item.type, equals('house'));
      },
    );

    test(
      'Photon primary: applies proximity bias when latitude and longitude provided',
      () async {
        Uri? capturedUri;
        final client = MockClient((request) async {
          capturedUri = request.url;
          final responseData = {
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "properties": {
                  "osm_id": 12345,
                  "name": "Masjid Istiqlal",
                  "city": "Jakarta Pusat",
                  "country": "Indonesia",
                },
                "geometry": {
                  "type": "Point",
                  "coordinates": [106.831, -6.170],
                },
              },
            ],
          };
          return http.Response(jsonEncode(responseData), 200);
        });

        final service = GeocodingService();
        await service.searchLocations(
          'masjid',
          latitude: -6.1754,
          longitude: 106.8272,
          client: client,
        );

        expect(capturedUri, isNotNull);
        expect(capturedUri!.queryParameters['lat'], equals('-6.1754'));
        expect(capturedUri!.queryParameters['lon'], equals('106.8272'));
      },
    );

    test(
      'Photon primary: runs global search without lat/lon when coordinates are null',
      () async {
        Uri? capturedUri;
        final client = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(
            '{"type":"FeatureCollection","features":[]}',
            200,
          );
        });

        final service = GeocodingService();
        await service.searchLocations('Monas', client: client);

        expect(capturedUri, isNotNull);
        expect(capturedUri!.queryParameters.containsKey('lat'), isFalse);
        expect(capturedUri!.queryParameters.containsKey('lon'), isFalse);
      },
    );

    test('Fallback to Nominatim when Photon returns empty features', () async {
      int requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        if (request.url.host == 'photon.komoot.io') {
          // Photon returns empty
          return http.Response(
            '{"type":"FeatureCollection","features":[]}',
            200,
          );
        } else if (request.url.host == 'nominatim.openstreetmap.org') {
          // Nominatim returns result
          final nominatimData = [
            {
              "place_id": 9999,
              "lat": "-6.1753924",
              "lon": "106.8271528",
              "name": "Monumen Nasional",
              "display_name":
                  "Monumen Nasional, Gambir, Jakarta Pusat, Indonesia",
            },
          ];
          return http.Response(jsonEncode(nominatimData), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = GeocodingService();
      final results = await service.searchLocations('Monas', client: client);

      // Both Photon and Nominatim were called
      expect(requestCount, equals(2));
      expect(results.length, equals(1));
      expect(results.first.id, equals('nominatim_9999'));
      expect(results.first.name, equals('Monumen Nasional'));
    });

    test('Fallback to Nominatim when Photon throws HTTP 500 error', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'photon.komoot.io') {
          return http.Response('Server Error', 500);
        } else if (request.url.host == 'nominatim.openstreetmap.org') {
          final nominatimData = [
            {
              "place_id": 8888,
              "lat": "-6.9175",
              "lon": "107.6191",
              "name": "Bandung",
              "display_name": "Bandung, Jawa Barat, Indonesia",
            },
          ];
          return http.Response(jsonEncode(nominatimData), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = GeocodingService();
      final results = await service.searchLocations('Bandung', client: client);

      expect(results.length, equals(1));
      expect(results.first.id, equals('nominatim_8888'));
      expect(results.first.name, equals('Bandung'));
    });

    test('Handles all providers failure gracefully without throwing', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = GeocodingService();
      final results = await service.searchLocations('Jakarta', client: client);
      expect(results, isA<List<MapSearchResult>>());
    });
  });
}
