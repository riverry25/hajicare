import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:hajicare/features/map/services/route_service.dart';

void main() {
  group('RouteService Unit Tests', () {
    test('successful walking route response', () async {
      final client = MockClient((request) async {
        if (request.url.toString() !=
            'https://api.heigit.org/openrouteservice/v2/directions/foot-walking/geojson') {
          return http.Response('Not Found', 404);
        }

        final responsePayload = {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "LineString",
                "coordinates": [
                  [39.8930, 21.4135],
                  [39.8942, 21.4145]
                ]
              },
              "properties": {
                "summary": {
                  "distance": 150.5,
                  "duration": 120.0
                }
              }
            }
          ]
        };
        return http.Response(jsonEncode(responsePayload), 200);
      });

      final service = RouteService(client: client, apiKey: 'test_key');
      final result = await service.getWalkingRoute(
        origin: const LatLng(21.4135, 39.8930),
        destination: const LatLng(21.4145, 39.8942),
      );

      expect(result.points.length, 2);
      expect(result.points.first.latitude, 21.4135);
      expect(result.points.first.longitude, 39.8930);
      expect(result.distanceMeters, 150.5);
      expect(result.durationSeconds, 120);
    });

    test('multiple routes -> pilih duration terkecil', () async {
      final client = MockClient((request) async {
        final responsePayload = {
          "type": "FeatureCollection",
          "features": [
            {
              "geometry": {
                "type": "LineString",
                "coordinates": [[1.0, 1.0], [2.0, 2.0]]
              },
              "properties": {
                "summary": {"distance": 500.0, "duration": 500.0} // Slower
              }
            },
            {
              "geometry": {
                "type": "LineString",
                "coordinates": [[1.0, 1.0], [3.0, 3.0]]
              },
              "properties": {
                "summary": {"distance": 450.0, "duration": 300.0} // Fastest
              }
            },
            {
              "geometry": {
                "type": "LineString",
                "coordinates": [[1.0, 1.0], [4.0, 4.0]]
              },
              "properties": {
                "summary": {"distance": 480.0, "duration": 400.0} // Mid
              }
            }
          ]
        };
        return http.Response(jsonEncode(responsePayload), 200);
      });

      final service = RouteService(client: client, apiKey: 'test_key');
      final result = await service.getWalkingRoute(
        origin: const LatLng(1.0, 1.0),
        destination: const LatLng(2.0, 2.0),
      );

      // Should pick the one with duration 300.0
      expect(result.durationSeconds, 300);
      expect(result.distanceMeters, 450.0);
      expect(result.points.last.latitude, 3.0);
    });

    test('routing API failure throws RouteException', () async {
      final client = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = RouteService(client: client, apiKey: 'test_key');
      expect(
        () => service.getWalkingRoute(
          origin: const LatLng(1.0, 1.0),
          destination: const LatLng(2.0, 2.0),
        ),
        throwsA(isA<RouteException>().having((e) => e.message, 'message', contains('HTTP 500'))),
      );
    });

    test('empty routes throws RouteException', () async {
      final client = MockClient((request) async {
        final responsePayload = {
          "type": "FeatureCollection",
          "features": []
        };
        return http.Response(jsonEncode(responsePayload), 200);
      });

      final service = RouteService(client: client, apiKey: 'test_key');
      expect(
        () => service.getWalkingRoute(
          origin: const LatLng(1.0, 1.0),
          destination: const LatLng(2.0, 2.0),
        ),
        throwsA(isA<RouteException>().having((e) => e.message, 'message', contains('tidak ditemukan'))),
      );
    });

    test('falls back to OSM foot routing when apiKey is empty', () async {
      final client = MockClient((request) async {
        if (!request.url.toString().contains('project-osrm.org')) {
          return http.Response('Not Found', 404);
        }

        final responsePayload = {
          "code": "Ok",
          "routes": [
            {
              "geometry": {
                "type": "LineString",
                "coordinates": [
                  [39.8930, 21.4135],
                  [39.8942, 21.4145]
                ]
              },
              "distance": 200.0,
              "duration": 150
            }
          ]
        };
        return http.Response(jsonEncode(responsePayload), 200);
      });

      final service = RouteService(client: client, apiKey: '');
      final result = await service.getWalkingRoute(
        origin: const LatLng(21.4135, 39.8930),
        destination: const LatLng(21.4145, 39.8942),
      );

      expect(result.points.length, 2);
      expect(result.distanceMeters, 200.0);
      expect(result.durationSeconds, 150);
    });
  });
}
