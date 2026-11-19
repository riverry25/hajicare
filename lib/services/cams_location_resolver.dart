import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/services/location_service.dart';
import 'cams_canonical_frames.dart';

/// Non-blocking GPS to [CamsLocation] mapper using existing [LocationService].
class CamsLocationResolver {
  final LocationService? _locationService;

  const CamsLocationResolver({LocationService? locationService})
    : _locationService = locationService;

  /// Resolves raw latitude/longitude to the nearest of the 8 Hajj locations
  /// within [maxDistanceMeters] (default 3,500 meters). Returns [CamsLocation.unknown]
  /// if outside all Hajj landmarks.
  CamsLocation resolveFromCoordinates(
    double latitude,
    double longitude, {
    double maxDistanceMeters = 3500.0,
  }) {
    CamsLocation nearest = CamsLocation.unknown;
    double bestDistance = maxDistanceMeters;

    for (final loc in CamsLocation.values) {
      final lat = loc.latitude;
      final lng = loc.longitude;
      if (lat == null || lng == null) continue;
      final dist = _haversineMeters(latitude, longitude, lat, lng);
      if (dist <= bestDistance) {
        bestDistance = dist;
        nearest = loc;
      }
    }
    return nearest;
  }

  /// Checks GPS non-blockingly (only if location service is enabled and permission
  /// is already granted) so the camera screen never freezes or triggers an unexpected
  /// OS permission modal.
  Future<CamsLocation> detectCurrentHajjLocation() async {
    try {
      final service = _locationService ?? LocationService();
      final enabled = await service.isLocationServiceEnabled();
      if (!enabled) return CamsLocation.unknown;

      final perm = await service.checkPermission();
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        return CamsLocation.unknown;
      }

      Position? pos = await service.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );

      return resolveFromCoordinates(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('[CamsLocationResolver] non-blocking GPS lookup skipped: $e');
      return CamsLocation.unknown;
    }
  }

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusM = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}
