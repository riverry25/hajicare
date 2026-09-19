import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
import 'package:hajicare/features/map/services/poi_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('PoiService dynamic OpenStreetMap discovery', () {
    test(
      'queries Overpass in Holy Land instead of returning static places',
      () async {
        var callCount = 0;
        final service = PoiService(
          client: MockClient((request) async {
            callCount++;
            expect(request.body, contains('21.4135'));
            expect(request.body, contains('nwr'));
            return http.Response(jsonEncode({'elements': <Object>[]}), 200);
          }),
        );

        final result = await service.fetchNearbyPois(
          center: const LatLng(21.4135, 39.8930),
        );

        expect(callCount, 1);
        expect(result, isEmpty);
      },
    );

    test(
      'parses nodes, ways, and relations into truthful POI metadata',
      () async {
        final response = {
          'elements': [
            {
              'type': 'node',
              'id': 101,
              'lat': -6.2080,
              'lon': 106.8450,
              'tags': {
                'amenity': 'restaurant',
                'name': 'Warung Nusantara',
                'cuisine': 'indonesian;seafood',
                'opening_hours': 'Mo-Su 08:00-22:00',
                'addr:street': 'Jalan Merdeka',
                'addr:housenumber': '10',
              },
            },
            {
              'type': 'way',
              'id': 102,
              'center': {'lat': -6.2095, 'lon': 106.8460},
              'tags': {
                'tourism': 'hotel',
                'name': 'Hotel Nyata',
                'stars': '4',
                'wheelchair': 'yes',
              },
            },
            {
              'type': 'relation',
              'id': 103,
              'center': {'lat': -6.2070, 'lon': 106.8440},
              'tags': {'amenity': 'atm', 'operator': 'Bank Contoh'},
            },
          ],
        };
        final service = PoiService(
          client: MockClient(
            (_) async => http.Response(jsonEncode(response), 200),
          ),
        );

        final pois = await service.fetchNearbyPois(
          center: const LatLng(-6.2088, 106.8456),
        );

        expect(pois, hasLength(3));
        final restaurant = pois.firstWhere(
          (poi) => poi.category == PoiCategory.restaurant,
        );
        expect(restaurant.address, 'Jalan Merdeka 10');
        expect(restaurant.openingHours, 'Mo-Su 08:00-22:00');
        expect(restaurant.tags, containsAll(['Indonesian', 'Seafood']));

        final hotel = pois.firstWhere(
          (poi) => poi.category == PoiCategory.hotel,
        );
        expect(hotel.id, 'osm_way_102');
        expect(hotel.isAccessible, isTrue);
        expect(hotel.tags, containsAll(['Bintang 4', 'Akses kursi roda']));

        final atm = pois.firstWhere((poi) => poi.category == PoiCategory.atm);
        expect(atm.name, 'Bank Contoh');
        expect(atm.openStreetMapUri.toString(), contains('/relation/103'));
      },
    );

    test('deduplicates provider elements and reuses same-area cache', () async {
      var calls = 0;
      final payload = {
        'elements': [
          {
            'type': 'node',
            'id': 1,
            'lat': -6.2,
            'lon': 106.8,
            'tags': {'amenity': 'cafe', 'name': 'Kafe A'},
          },
          {
            'type': 'node',
            'id': 1,
            'lat': -6.2,
            'lon': 106.8,
            'tags': {'amenity': 'cafe', 'name': 'Duplikat'},
          },
        ],
      };
      final service = PoiService(
        client: MockClient((_) async {
          calls++;
          return http.Response(jsonEncode(payload), 200);
        }),
      );

      final first = await service.fetchNearbyPois(
        center: const LatLng(-6.2001, 106.8001),
      );
      final second = await service.fetchNearbyPois(
        center: const LatLng(-6.2002, 106.8002),
      );

      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(calls, 1);
    });

    test(
      'throws a controlled error when every Overpass endpoint fails',
      () async {
        final service = PoiService(
          client: MockClient((_) async => http.Response('unavailable', 503)),
        );

        expect(
          () => service.fetchNearbyPois(center: const LatLng(-7.5, 110.5)),
          throwsA(isA<PoiServiceException>()),
        );
      },
    );
  });
}
