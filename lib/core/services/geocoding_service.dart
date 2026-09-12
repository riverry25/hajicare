import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

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
}
