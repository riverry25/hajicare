import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
import 'package:hajicare/features/map/services/poi_service.dart';

void main() {
  group('PoiService Tests', () {
    test('Nominatim fallback successfully fetches and maps Masjid, Hotel, and Restaurant', () async {
      final mockClient = MockClient((request) async {
        final uriStr = request.url.toString();

        // Simulate Overpass failure/timeout
        if (uriStr.contains('interpreter')) {
          return http.Response('Error', 500);
        }

        // Simulate Nominatim responses
        if (uriStr.contains('nominatim.openstreetmap.org')) {
          if (uriStr.contains('masjid')) {
            return http.Response(
              jsonEncode([
                {
                  'place_id': 1001,
                  'osm_type': 'node',
                  'osm_id': 55501,
                  'lat': '-7.77123',
                  'lon': '110.40123',
                  'class': 'amenity',
                  'type': 'place_of_worship',
                  'name': 'Masjid Al-Ikhlas',
                  'display_name': 'Masjid Al-Ikhlas, Sleman, Yogyakarta',
                  'address': {
                    'road': 'Jl. Kaliurang',
                    'city': 'Sleman',
                  },
                }
              ]),
              200,
            );
          } else if (uriStr.contains('hotel')) {
            return http.Response(
              jsonEncode([
                {
                  'place_id': 1002,
                  'osm_type': 'way',
                  'osm_id': 55502,
                  'lat': '-7.77200',
                  'lon': '110.40200',
                  'class': 'tourism',
                  'type': 'hotel',
                  'name': 'Grand Hajj Hotel',
                  'display_name': 'Grand Hajj Hotel, Sleman',
                }
              ]),
              200,
            );
          } else if (uriStr.contains('rumah')) {
            return http.Response(
              jsonEncode([
                {
                  'place_id': 1003,
                  'osm_type': 'node',
                  'osm_id': 55503,
                  'lat': '-7.77300',
                  'lon': '110.40300',
                  'class': 'amenity',
                  'type': 'restaurant',
                  'name': 'Rumah Makan Padang Minang',
                  'display_name': 'Rumah Makan Padang Minang, Sleman',
                }
              ]),
              200,
            );
          }
          return http.Response('[]', 200);
        }

        return http.Response('Not Found', 404);
      });

      final poiService = PoiService(client: mockClient);
      const center = LatLng(-7.77336, 110.4019);

      final pois = await poiService.fetchNearbyPois(
        center: center,
        radiusMeters: 3000,
      );

      expect(pois.isNotEmpty, isTrue);

      final mosque = pois.firstWhere((p) => p.name == 'Masjid Al-Ikhlas');
      expect(mosque.category, equals(PoiCategory.ibadah));

      // Otomatis membuat Wudhu dan Toilet untuk Masjid
      final hasWudhu = pois.any((p) => p.name.contains('Tempat Wudhu • Masjid Al-Ikhlas'));
      final hasToilet = pois.any((p) => p.name.contains('Toilet Umum • Masjid Al-Ikhlas'));
      expect(hasWudhu, isTrue);
      expect(hasToilet, isTrue);

      final hotel = pois.firstWhere((p) => p.name.contains('Grand Hajj Hotel'));
      expect(hotel.category, equals(PoiCategory.hotel));

      final resto = pois.firstWhere((p) => p.name.contains('Rumah Makan Padang Minang'));
      expect(resto.category, equals(PoiCategory.restaurant));

      poiService.dispose();
    });

    test('Returns regional hub seed POIs instantly even when offline', () async {
      final failingClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final poiService = PoiService(client: failingClient);
      const center = LatLng(-7.77336, 110.4019);

      final pois = await poiService.fetchNearbyPois(
        center: center,
        radiusMeters: 3000,
        forceRefresh: false,
      );

      expect(pois.isNotEmpty, isTrue);
      final hasMosque = pois.any((p) => p.category == PoiCategory.ibadah);
      final hasHotel = pois.any((p) => p.category == PoiCategory.hotel);
      final hasMedical = pois.any((p) => p.category == PoiCategory.medis || p.category == PoiCategory.pharmacy);
      expect(hasMosque, isTrue);
      expect(hasHotel, isTrue);
      expect(hasMedical, isTrue);
      poiService.dispose();
    });

    test('Gracefully returns empty list without crashing when offline outside hub areas (forceRefresh: false)', () async {
      final failingClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final poiService = PoiService(client: failingClient);
      const center = LatLng(0.0, 0.0); // Neutral coordinate outside seed hubs

      final pois = await poiService.fetchNearbyPois(
        center: center,
        radiusMeters: 3000,
        forceRefresh: false,
      );

      expect(pois, isEmpty);
      poiService.dispose();
    });
  });
}
