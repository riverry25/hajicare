import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/map/models/map_poi.dart';
import 'package:hajicare/features/map/services/poi_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('PoiService Real-World POI Discovery Tests', () {
    test('isInHolyLand correctly identifies Makkah, Mina, and Madinah coordinates', () {
      // Mina Tent City
      expect(PoiService.isInHolyLand(const LatLng(21.4135, 39.8930)), isTrue);
      // Ka'bah / Masjidil Haram
      expect(PoiService.isInHolyLand(const LatLng(21.4225, 39.8262)), isTrue);
      // Masjid Nabawi Madinah
      expect(PoiService.isInHolyLand(const LatLng(24.4672, 39.6111)), isTrue);
      // Jakarta, Indonesia (NOT holy land)
      expect(PoiService.isInHolyLand(const LatLng(-6.2088, 106.8456)), isFalse);
      // Mountain View, USA (NOT holy land)
      expect(PoiService.isInHolyLand(const LatLng(37.4220, -122.0841)), isFalse);
    });

    test('fetchRealNearbyPois returns verified authentic Holy Land POIs when in Masyair/Makkah', () async {
      final service = PoiService();
      const minaCoord = LatLng(21.4135, 39.8930);

      final pois = await service.fetchRealNearbyPois(center: minaCoord);

      expect(pois.isNotEmpty, isTrue);
      expect(pois.any((p) => p.name.contains('Maktab 48')), isTrue);
      expect(pois.any((p) => p.name.contains('Posko Medis PPIH')), isTrue);
      expect(pois.any((p) => p.name.contains('Toilet')), isTrue);
    });

    test('fetchRealNearbyPois queries Overpass API and parses genuine real-world amenities outside Holy Land', () async {
      final mockOverpassResponse = {
        "elements": [
          {
            "type": "node",
            "id": 101,
            "lat": -6.2080,
            "lon": 106.8450,
            "tags": {
              "amenity": "toilets",
              "name": "Toilet Publik Stasiun",
              "wheelchair": "yes"
            }
          },
          {
            "type": "node",
            "id": 102,
            "lat": -6.2095,
            "lon": 106.8460,
            "tags": {
              "amenity": "hospital",
              "name": "RSUD Tebet",
              "opening_hours": "24/7",
              "emergency": "yes"
            }
          },
          {
            "type": "node",
            "id": 103,
            "lat": -6.2070,
            "lon": 106.8440,
            "tags": {
              "amenity": "place_of_worship",
              "religion": "muslim",
              "name": "Masjid Al-Barkah"
            }
          }
        ]
      };

      final mockClient = MockClient((request) async {
        if (request.url.host.contains('overpass-api.de')) {
          return http.Response(jsonEncode(mockOverpassResponse), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = PoiService(client: mockClient);
      const jakartaCoord = LatLng(-6.2088, 106.8456);

      final pois = await service.fetchRealNearbyPois(center: jakartaCoord);

      expect(pois.length, equals(3));

      // 1. Check Toilet
      final toilet = pois.firstWhere((p) => p.category == PoiCategory.toilet);
      expect(toilet.name, equals('Toilet Publik Stasiun'));
      expect(toilet.isAccessible, isTrue);
      expect(toilet.coordinate.latitude, equals(-6.2080));

      // 2. Check Hospital
      final hospital = pois.firstWhere((p) => p.category == PoiCategory.medis);
      expect(hospital.name, equals('RSUD Tebet'));
      expect(hospital.statusLabel, equals('Siaga 24 Jam'));
      expect(hospital.coordinate.latitude, equals(-6.2095));

      // 3. Check Mosque
      final mosque = pois.firstWhere((p) => p.category == PoiCategory.ibadah);
      expect(mosque.name, equals('Masjid Al-Barkah'));
      expect(mosque.coordinate.latitude, equals(-6.2070));
    });

    test('fetchRealNearbyPois returns empty list when no real amenities exist in area (no fake offset pins)', () async {
      final mockEmptyResponse = {"elements": []};

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockEmptyResponse), 200);
      });

      final service = PoiService(client: mockClient);
      const emptyLocation = LatLng(-7.5000, 110.5000);

      final pois = await service.fetchRealNearbyPois(center: emptyLocation);

      expect(pois, isEmpty);
    });
  });
}
