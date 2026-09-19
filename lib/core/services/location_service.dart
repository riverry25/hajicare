import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/prayer/models/prayer_location_data.dart';

enum LocationPermissionState { granted, denied, deniedForever, serviceDisabled }

class LocationResult {
  final Position? position;
  final LocationSource source;
  final LocationPermissionState state;
  final String? errorMessage;

  const LocationResult({
    this.position,
    required this.source,
    required this.state,
    this.errorMessage,
  });

  bool get isSuccess => position != null;
}

class LocationService {
  /// Check if device location service (GPS) is turned on
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request permission from user
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Open device app settings (e.g. if permission was denied permanently)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open device system location settings (e.g. if GPS is disabled)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Obtain device's last known cached position quickly from OS
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('[LocationService] getLastKnownPosition failed: $e');
      return null;
    }
  }

  /// Safely obtain location:
  /// 1. Verifies service and permissions
  /// 2. Attempts fresh high-accuracy GPS (timeout 12s)
  /// 3. If fresh GPS fails/times out, smoothly falls back to OS last-known position
  Future<LocationResult> getCurrentPosition({
    Duration timeout = const Duration(seconds: 12),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Attempt last known even if service is now off
        final lastKnown = await getLastKnownPosition();
        if (lastKnown != null) {
          return LocationResult(
            position: lastKnown,
            source: LocationSource.lastKnown,
            state: LocationPermissionState.serviceDisabled,
            errorMessage:
                'Lokasi ponsel belum aktif. Lokasi terakhir akan digunakan.',
          );
        }
        return const LocationResult(
          source: LocationSource.unavailable,
          state: LocationPermissionState.serviceDisabled,
          errorMessage: 'Lokasi ponsel belum aktif.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            source: LocationSource.unavailable,
            state: LocationPermissionState.denied,
            errorMessage:
                'Izin lokasi belum diberikan. Izinkan lokasi, lalu coba lagi.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          source: LocationSource.unavailable,
          state: LocationPermissionState.deniedForever,
          errorMessage:
              'Izin lokasi belum diberikan. Buka pengaturan, lalu izinkan lokasi untuk HajiCare.',
        );
      }

      // Try fresh GPS with timeout
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: accuracy,
            timeLimit: timeout,
          ),
        );

        return LocationResult(
          position: position,
          source: LocationSource.gps,
          state: LocationPermissionState.granted,
        );
      } on TimeoutException {
        debugPrint(
          '[LocationService] Fresh GPS timed out, trying lastKnown position...',
        );
        final lastKnown = await getLastKnownPosition();
        if (lastKnown != null) {
          return LocationResult(
            position: lastKnown,
            source: LocationSource.lastKnown,
            state: LocationPermissionState.granted,
            errorMessage:
                'Lokasi terbaru belum ditemukan. Lokasi terakhir akan digunakan.',
          );
        }
        return const LocationResult(
          source: LocationSource.unavailable,
          state: LocationPermissionState.granted,
          errorMessage:
              'Lokasi belum ditemukan. Pastikan lokasi ponsel aktif, lalu coba lagi.',
        );
      } catch (gpsError) {
        debugPrint('[LocationService] getCurrentPosition error: $gpsError');
        final lastKnown = await getLastKnownPosition();
        if (lastKnown != null) {
          return LocationResult(
            position: lastKnown,
            source: LocationSource.lastKnown,
            state: LocationPermissionState.granted,
          );
        }
        return LocationResult(
          source: LocationSource.unavailable,
          state: LocationPermissionState.denied,
          errorMessage:
              'Lokasi belum ditemukan. Pastikan lokasi ponsel aktif, lalu coba lagi.',
        );
      }
    } catch (e) {
      debugPrint('[LocationService] Location retrieval failed: $e');
      return LocationResult(
        source: LocationSource.unavailable,
        state: LocationPermissionState.denied,
        errorMessage:
            'Lokasi belum dapat ditemukan. Periksa pengaturan lokasi ponsel, lalu coba lagi.',
      );
    }
  }

  /// Calculate distance in meters between two coordinate pairs
  double calculateDistanceMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Stream of location updates with distance filter (e.g. 500 meters)
  Stream<Position> getPositionStream({
    int distanceFilter = 500,
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
