import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../features/map/models/map_search_result.dart';

class GeocodingResult {
  final String cityName;
  final String countryName;
  final String countryCode;
  final String displayName;
  final bool isSuccess;

  const GeocodingResult({
    required this.cityName,
    required this.countryName,
    required this.countryCode,
    required this.displayName,
    this.isSuccess = true,
  });

  factory GeocodingResult.coordinateFallback(double lat, double lng) {
    final coordLabel =
        'Koordinat (${lat.toStringAsFixed(3)}°, ${lng.toStringAsFixed(3)}°)';
    return GeocodingResult(
      cityName: coordLabel,
      countryName: '',
      countryCode: '',
      displayName: coordLabel,
      isSuccess: false,
    );
  }
}

class GeocodingService {
  final Geocoding? _geocoding;

  GeocodingService({Geocoding? geocoding}) : _geocoding = geocoding;

  /// Reverse geocode coordinates to obtain city, country, and countryCode.
  /// If reverse geocoding fails (e.g. offline/no network), it returns a clean
  /// coordinate-based label without invalidating the GPS coordinates.
  Future<GeocodingResult> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    // If coordinates are empty/zero, return invalid
    if (latitude == 0.0 && longitude == 0.0) {
      return const GeocodingResult(
        cityName: 'Lokasi tidak tersedia',
        countryName: '',
        countryCode: '',
        displayName: 'Lokasi tidak tersedia',
        isSuccess: false,
      );
    }

    try {
      final client = _geocoding ?? Geocoding();
      final placemarks = await client.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return GeocodingResult.coordinateFallback(latitude, longitude);
      }

      final placemark = placemarks.first;

      // Extract City following user's defined priority:
      // city (locality) -> town (subLocality) -> municipality/district (subAdministrativeArea) -> state (administrativeArea) -> country
      String city = '';
      if (_isValidName(placemark.locality)) {
        city = placemark.locality!;
      } else if (_isValidName(placemark.subLocality)) {
        city = placemark.subLocality!;
      } else if (_isValidName(placemark.subAdministrativeArea)) {
        city = _cleanAdminName(placemark.subAdministrativeArea!);
      } else if (_isValidName(placemark.administrativeArea)) {
        city = placemark.administrativeArea!;
      }

      final country = placemark.country ?? '';
      final countryCode = (placemark.isoCountryCode ?? '').toUpperCase();

      String displayName = '';
      if (city.isNotEmpty && country.isNotEmpty) {
        displayName = '$city, $country';
      } else if (city.isNotEmpty) {
        displayName = city;
      } else if (country.isNotEmpty) {
        displayName = country;
      } else {
        displayName =
            'Koordinat (${latitude.toStringAsFixed(3)}°, ${longitude.toStringAsFixed(3)}°)';
      }

      return GeocodingResult(
        cityName: city,
        countryName: country,
        countryCode: countryCode,
        displayName: displayName,
        isSuccess: true,
      );
    } catch (e) {
      debugPrint(
        '[GeocodingService] Reverse geocode failed for ($latitude, $longitude): $e',
      );
      return GeocodingResult.coordinateFallback(latitude, longitude);
    }
  }

  bool _isValidName(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _cleanAdminName(String name) {
    return name.trim();
  }

  /// Searches places, venues, and addresses using:
  /// 1. Photon (by Komoot / OSM Elasticsearch) — PRIMARY (supports rich POI/brand/venue search & proximity bias)
  /// 2. Nominatim (OpenStreetMap) — FALLBACK 1 (robust address geocoding)
  /// 3. Native Device Geocoder (package:geocoding) — FALLBACK 2
  Future<List<MapSearchResult>> searchLocations(
    String query, {
    double? latitude,
    double? longitude,
    int limit = 10,
    http.Client? client,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || cleanQuery.length < 2) {
      return const [];
    }

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      // 1. PRIMARY: Photon Search API (OSM Elasticsearch POI Search)
      try {
        final photonResults = await _searchPhoton(
          cleanQuery,
          latitude: latitude,
          longitude: longitude,
          limit: limit,
          httpClient: httpClient,
        );
        if (photonResults.isNotEmpty) {
          return photonResults;
        }
      } catch (e) {
        debugPrint(
          '[GeocodingService] Photon search failed or empty: $e, falling back to Nominatim',
        );
      }

      // 2. FALLBACK 1: OpenStreetMap Nominatim
      try {
        final nominatimResults = await _searchNominatim(
          cleanQuery,
          limit: limit,
          httpClient: httpClient,
        );
        if (nominatimResults.isNotEmpty) {
          return nominatimResults;
        }
      } catch (e) {
        debugPrint(
          '[GeocodingService] Nominatim search failed or empty: $e, falling back to Native geocoder',
        );
      }
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }

    // 3. FALLBACK 2: Native Device Geocoder (Android/iOS geocoding)
    try {
      final nativeResults = await _searchNative(cleanQuery, limit: limit);
      if (nativeResults.isNotEmpty) {
        return nativeResults;
      }
    } catch (e) {
      debugPrint('[GeocodingService] Native geocoding fallback failed: $e');
    }

    return const [];
  }

  /// Photon Search API implementation (GeoJSON FeatureCollection).
  Future<List<MapSearchResult>> _searchPhoton(
    String query, {
    double? latitude,
    double? longitude,
    required int limit,
    required http.Client httpClient,
  }) async {
    final buffer = StringBuffer(
      'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=$limit',
    );
    if (latitude != null && longitude != null) {
      buffer.write('&lat=$latitude&lon=$longitude');
    }

    final uri = Uri.parse(buffer.toString());
    final response = await httpClient
        .get(
          uri,
          headers: {
            'User-Agent': 'HajiCareApp/1.0 (contact: support@hajicare.app)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Photon returned status ${response.statusCode}: ${response.body}',
        uri,
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const [];

    final features = decoded['features'];
    if (features is! List || features.isEmpty) return const [];

    final results = <MapSearchResult>[];
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;

      final geometry = feature['geometry'];
      if (geometry is! Map<String, dynamic>) continue;
      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.length < 2) continue;

      final lon = (coordinates[0] as num?)?.toDouble();
      final lat = (coordinates[1] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      final props = feature['properties'];
      final properties = props is Map<String, dynamic>
          ? props
          : <String, dynamic>{};

      final rawName = properties['name']?.toString().trim();
      final street = properties['street']?.toString().trim();
      final housenumber = properties['housenumber']?.toString().trim();
      final district = properties['district']?.toString().trim();
      final city = properties['city']?.toString().trim();
      final state = properties['state']?.toString().trim();
      final country = properties['country']?.toString().trim();
      final osmKey = properties['osm_key']?.toString();
      final osmValue = properties['osm_value']?.toString();
      final type = properties['type']?.toString();

      // Assemble human-readable place name
      String name = '';
      if (rawName != null && rawName.isNotEmpty) {
        name = rawName;
      } else if (street != null && street.isNotEmpty) {
        name = housenumber != null && housenumber.isNotEmpty
            ? '$street No. $housenumber'
            : street;
      } else if (district != null && district.isNotEmpty) {
        name = district;
      } else if (city != null && city.isNotEmpty) {
        name = city;
      } else {
        name = query;
      }

      // Assemble structured address components
      final addressParts = <String>[];
      if (street != null && street.isNotEmpty) {
        if (housenumber != null && housenumber.isNotEmpty) {
          addressParts.add('$street No. $housenumber');
        } else {
          addressParts.add(street);
        }
      }
      if (district != null && district.isNotEmpty) addressParts.add(district);
      if (city != null && city.isNotEmpty) addressParts.add(city);
      if (state != null && state.isNotEmpty) addressParts.add(state);
      if (country != null && country.isNotEmpty) addressParts.add(country);

      String address = addressParts.join(', ');
      if (address.isEmpty) {
        address = name;
      }

      final osmId =
          properties['osm_id']?.toString() ??
          '${lat.toStringAsFixed(5)}_${lon.toStringAsFixed(5)}';

      results.add(
        MapSearchResult(
          id: 'photon_$osmId',
          name: name,
          address: address,
          latitude: lat,
          longitude: lon,
          type: type,
          category: osmValue ?? osmKey,
        ),
      );
    }

    return results;
  }

  /// OpenStreetMap Nominatim Search API implementation.
  Future<List<MapSearchResult>> _searchNominatim(
    String query, {
    required int limit,
    required http.Client httpClient,
  }) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=$limit',
    );

    final response = await httpClient
        .get(
          uri,
          headers: {
            'User-Agent': 'HajiCareApp/1.0 (contact: support@hajicare.app)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Nominatim returned status ${response.statusCode}: ${response.body}',
        uri,
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return const [];

    final results = <MapSearchResult>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;

      final latStr = item['lat']?.toString();
      final lonStr = item['lon']?.toString();
      if (latStr == null || lonStr == null) continue;

      final lat = double.tryParse(latStr);
      final lon = double.tryParse(lonStr);
      if (lat == null || lon == null) continue;

      final displayName = item['display_name']?.toString() ?? '';
      final rawName = item['name']?.toString();

      String name = (rawName != null && rawName.trim().isNotEmpty)
          ? rawName.trim()
          : (displayName.contains(',')
                ? displayName.split(',').first.trim()
                : displayName);
      if (name.isEmpty) name = query;

      final placeId =
          item['place_id']?.toString() ??
          '${lat.toStringAsFixed(5)}_${lon.toStringAsFixed(5)}';

      results.add(
        MapSearchResult(
          id: 'nominatim_$placeId',
          name: name,
          address: displayName,
          latitude: lat,
          longitude: lon,
          type: item['type']?.toString(),
          category: item['class']?.toString(),
        ),
      );
    }

    return results;
  }

  /// Native device geocoder fallback (package:geocoding).
  Future<List<MapSearchResult>> _searchNative(
    String query, {
    required int limit,
  }) async {
    final client = _geocoding ?? Geocoding();
    final locations = await client.locationFromAddress(query);
    if (locations.isEmpty) return const [];

    final results = <MapSearchResult>[];
    final takeCount = locations.length < limit ? locations.length : limit;
    for (var i = 0; i < takeCount; i++) {
      final loc = locations[i];
      String name = query;
      String address =
          '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';

      try {
        final placemarks = await client.placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          name = p.name?.isNotEmpty == true
              ? p.name!
              : (p.locality?.isNotEmpty == true ? p.locality! : query);
          final parts = [
            p.street,
            p.subLocality,
            p.locality,
            p.country,
          ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {}

      results.add(
        MapSearchResult(
          id: 'native_${loc.latitude}_${loc.longitude}',
          name: name,
          address: address,
          latitude: loc.latitude,
          longitude: loc.longitude,
        ),
      );
    }
    return results;
  }
}
