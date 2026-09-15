import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/config/app_config.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class RouteException implements Exception {
  final String message;
  const RouteException(this.message);

  @override
  String toString() => message;
}

class RouteService {
  static const String _orsBaseUrl =
      'https://api.heigit.org/openrouteservice/v2/directions/foot-walking/geojson';
  static const String _osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/foot';

  final http.Client _httpClient;
  final String _apiKey;

  RouteService({http.Client? client, String? apiKey}) 
      : _httpClient = client ?? http.Client(),
        _apiKey = apiKey ?? AppConfig.orsApiKey;

  Future<RouteResult> getWalkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // 1. If ORS API key is configured, use OpenRouteService
    if (_apiKey.isNotEmpty) {
      return _getOrsWalkingRoute(origin: origin, destination: destination);
    }

    // 2. If no ORS API key, fallback to OpenStreetMap OSRM foot routing
    // (Free public router, follows real road network geometry, requires no API key)
    return _getOsrmWalkingRoute(origin: origin, destination: destination);
  }

  Future<RouteResult> _getOrsWalkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final headers = {
      'Authorization': _apiKey,
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    // ORS expects [longitude, latitude]
    final body = jsonEncode({
      'coordinates': [
        [origin.longitude, origin.latitude],
        [destination.longitude, destination.latitude],
      ],
      'alternative_routes': {
        'target_count': 3,
        'share_factor': 0.8,
        'weight_factor': 2.0,
      },
      'instructions': false,
    });

    try {
      final response = await _httpClient.post(
        Uri.parse(_orsBaseUrl),
        headers: headers,
        body: body,
      );
      debugPrint('[ROUTE] ORS status = ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('[ROUTE] ORS ERROR BODY: ${response.body}');
        throw RouteException('Routing gagal: HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final features = data['features'] as List<dynamic>?;

      if (features == null || features.isEmpty) {
        throw const RouteException('Rute berjalan tidak ditemukan untuk koordinat ini');
      }

      debugPrint('[ROUTE] route alternatives = ${features.length}');

      // Find the fastest route by duration
      Map<String, dynamic>? fastestFeature;
      double minDuration = double.infinity;

      for (final feature in features) {
        final props = feature['properties'] as Map<String, dynamic>?;
        if (props != null) {
          final summary = props['summary'] as Map<String, dynamic>?;
          if (summary != null) {
            final duration = (summary['duration'] as num?)?.toDouble() ?? double.infinity;
            if (duration < minDuration) {
              minDuration = duration;
              fastestFeature = feature as Map<String, dynamic>;
            }
          }
        }
      }

      debugPrint('[ROUTE] selected duration = $minDuration');

      if (fastestFeature == null) {
        throw const RouteException('Rute berjalan tidak memiliki durasi yang valid');
      }

      final geometry = fastestFeature['geometry'] as Map<String, dynamic>?;
      if (geometry == null || geometry['type'] != 'LineString') {
        throw const RouteException('Format rute tidak didukung');
      }

      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) {
        throw const RouteException('Koordinat rute kosong');
      }

      final points = _decodeGeoJsonCoords(coordinates);
      debugPrint('[ROUTE] route points = ${points.length}');
      
      if (points.isEmpty) {
        throw const RouteException('Koordinat rute kosong setelah parsing');
      }
      
      final summary = fastestFeature['properties']['summary'] as Map<String, dynamic>;
      final distance = (summary['distance'] as num).toDouble();
      final duration = (summary['duration'] as num).toInt();

      return RouteResult(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } on RouteException {
      rethrow;
    } catch (e) {
      throw const RouteException('Gagal terhubung ke layanan routing');
    }
  }

  Future<RouteResult> _getOsrmWalkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
      '$_osrmBaseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    try {
      debugPrint('[ROUTE] Fetching real walking route from OSM: $url');
      final response = await _httpClient.get(url);
      debugPrint('[ROUTE] OSM status = ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('[ROUTE] OSM ERROR BODY: ${response.body}');
        throw RouteException('Routing gagal: HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;

      if (routes == null || routes.isEmpty) {
        throw const RouteException('Rute berjalan tidak ditemukan');
      }

      final primaryRoute = routes.first as Map<String, dynamic>;
      final geometry = primaryRoute['geometry'] as Map<String, dynamic>?;
      if (geometry == null || geometry['type'] != 'LineString') {
        throw const RouteException('Format rute tidak didukung');
      }

      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) {
        throw const RouteException('Koordinat rute kosong');
      }

      final points = _decodeGeoJsonCoords(coordinates);
      debugPrint('[ROUTE] route points = ${points.length}');

      final distance = (primaryRoute['distance'] as num).toDouble();
      final duration = (primaryRoute['duration'] as num).toInt();

      return RouteResult(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } on RouteException {
      rethrow;
    } catch (e) {
      debugPrint('[ROUTE] OSM error: $e');
      throw const RouteException('Gagal terhubung ke layanan routing jalan kaki');
    }
  }

  List<LatLng> _decodeGeoJsonCoords(List<dynamic> coords) {
    return coords.map((c) {
      final lon = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      return LatLng(lat, lon); // Convert back to LatLng format
    }).toList();
  }
}
