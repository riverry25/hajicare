import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a candidate companion evaluated during the SOS scanning process.
class CandidateCompanion {
  final String uid;
  final String name;
  final String? phone;
  final GeoPoint? location;
  final double? distanceMeters;
  final double? bearingDegrees;
  final DateTime? locationUpdatedAt;
  final bool isFromRoom;

  const CandidateCompanion({
    required this.uid,
    required this.name,
    this.phone,
    this.location,
    this.distanceMeters,
    this.bearingDegrees,
    this.locationUpdatedAt,
    this.isFromRoom = false,
  });

  /// Computes the normalized polar radius (0.2 to 0.85) for positioning on radar canvas.
  /// [maxRangeMeters] defaults to 2000m.
  double getRadarRadiusRatio([double maxRangeMeters = 2000]) {
    if (distanceMeters == null || distanceMeters! <= 0) {
      return 0.25; // Default close-in circle
    }
    final clamped = distanceMeters!.clamp(20.0, maxRangeMeters);
    // Non-linear log scale for natural radar grouping
    final ratio =
        0.2 +
        (0.65 *
            (math.log(clamped) - math.log(20)) /
            (math.log(maxRangeMeters) - math.log(20)));
    return ratio.clamp(0.2, 0.85);
  }

  /// Returns angle in radians where 0 is North (-Y axis on Flutter Canvas).
  double getRadarAngleRadians() {
    if (bearingDegrees == null) {
      // Deterministic spread based on UID hash if bearing is unknown
      final hash = uid.hashCode.abs() % 360;
      return (hash * math.pi) / 180.0;
    }
    return (bearingDegrees! * math.pi) / 180.0;
  }

  CandidateCompanion copyWith({
    String? uid,
    String? name,
    String? phone,
    GeoPoint? location,
    double? distanceMeters,
    double? bearingDegrees,
    DateTime? locationUpdatedAt,
    bool? isFromRoom,
  }) {
    return CandidateCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      bearingDegrees: bearingDegrees ?? this.bearingDegrees,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      isFromRoom: isFromRoom ?? this.isFromRoom,
    );
  }

  String get formattedDistance {
    if (distanceMeters == null) return 'Jarak tidak diketahui';
    if (distanceMeters! < 1000) {
      return '± ${distanceMeters!.round()} meter';
    }
    final km = distanceMeters! / 1000;
    return '± ${km.toStringAsFixed(1)} km';
  }
}
