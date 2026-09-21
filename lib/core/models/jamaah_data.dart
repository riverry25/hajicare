import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../utils/distance_formatter.dart';

enum UserRole { admin, pendamping, jamaah }

enum DistanceTier { aman, waspada, terlalujJauh }

extension DistanceTierColor on DistanceTier {
  Color get color {
    switch (this) {
      case DistanceTier.aman:
        return AppColors.statusSafe;
      case DistanceTier.waspada:
        return AppColors.statusWarning;
      case DistanceTier.terlalujJauh:
        return AppColors.statusDanger;
    }
  }

  String get label {
    switch (this) {
      case DistanceTier.aman:
        return 'Aman';
      case DistanceTier.waspada:
        return 'Waspada';
      case DistanceTier.terlalujJauh:
        return 'Terlalu jauh';
    }
  }

  IconData get icon {
    switch (this) {
      case DistanceTier.aman:
        return Icons.check_circle;
      case DistanceTier.waspada:
        return Icons.warning_amber;
      case DistanceTier.terlalujJauh:
        return Icons.dangerous;
    }
  }
}

class JamaahData {
  final String id;
  final String name;
  final String shortLabel;
  final String? porsi;
  final String? kloter;
  final String? maktab;
  final String? activeRoomId;
  double distance;
  DistanceTier tier;
  bool separatedMode;
  bool sosActive;
  GeoPoint? currentLocation;
  bool isGpsActive;
  DateTime? locationUpdatedAt;
  bool onlineStatus;
  DateTime? _dangerStart;

  final String? bloodType;
  final String? allergies;
  final String? conditions;
  final String? emergencyContact;
  final String? passportNumber;

  JamaahData({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.distance,
    this.porsi,
    this.kloter,
    this.maktab,
    this.activeRoomId,
    this.separatedMode = false,
    this.sosActive = false,
    this.currentLocation,
    this.isGpsActive = false,
    this.locationUpdatedAt,
    this.onlineStatus = true,
    this.bloodType,
    this.allergies,
    this.conditions,
    this.emergencyContact,
    this.passportNumber,
  }) : tier = _calcTier(distance);

  factory JamaahData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      currentUser = null;
    }
    if (data == null) {
      final fallbackName = currentUser?.displayName?.trim().isNotEmpty == true
          ? currentUser!.displayName!.trim()
          : (currentUser?.email?.trim().isNotEmpty == true
                ? currentUser!.email!.split('@').first
                : 'Jamaah');
      return JamaahData(
        id: doc.id,
        name: fallbackName,
        shortLabel: fallbackName.split(' ').first,
        distance: 0.0,
      );
    }

    // Dynamic name resolution with graceful fallbacks
    final rawName = data['name'] as String? ?? data['displayName'] as String?;
    final name = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : (currentUser?.displayName?.trim().isNotEmpty == true
              ? currentUser!.displayName!.trim()
              : (currentUser?.email?.trim().isNotEmpty == true
                    ? currentUser!.email!.split('@').first
                    : 'Jamaah'));

    final rawShortLabel = data['shortLabel'] as String?;
    final shortLabel =
        (rawShortLabel != null && rawShortLabel.trim().isNotEmpty)
        ? rawShortLabel.trim()
        : name.split(' ').first;

    final distance = (data['distance'] as num?)?.toDouble() ?? 0.0;
    final porsi = (data['porsi'] as String?) ?? (data['nomorPorsi'] as String?);
    final kloter = data['kloter'] as String?;
    final maktab = data['maktab'] as String?;
    final activeRoomId = data['activeRoomId'] as String?;
    final loc = data['currentLocation'] as GeoPoint?;

    final bloodType = data['bloodType'] as String?;
    final allergies = data['allergies'] as String?;
    final conditions = data['conditions'] as String?;
    final emergencyContact = data['emergencyContact'] as String?;
    final passportNumber =
        (data['passportNumber'] as String?) ?? (data['passport'] as String?);

    DateTime? locationTime;
    if (data['locationUpdatedAt'] is Timestamp) {
      locationTime = (data['locationUpdatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is Timestamp) {
      locationTime = (data['updatedAt'] as Timestamp).toDate();
    }

    final isGps = (data['isGpsActive'] as bool?) ?? (loc != null);
    final isOnline = (data['onlineStatus'] as bool?) ?? true;

    return JamaahData(
      id: doc.id,
      name: name,
      shortLabel: shortLabel,
      distance: distance,
      porsi: porsi,
      kloter: kloter,
      maktab: maktab,
      activeRoomId: activeRoomId,
      separatedMode: data['separatedMode'] as bool? ?? false,
      sosActive: data['sosActive'] as bool? ?? false,
      currentLocation: loc,
      isGpsActive: isGps,
      locationUpdatedAt: locationTime,
      onlineStatus: isOnline,
      bloodType: bloodType,
      allergies: allergies,
      conditions: conditions,
      emergencyContact: emergencyContact,
      passportNumber: passportNumber,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'distance': distance,
      'separatedMode': separatedMode,
      'sosActive': sosActive,
      if (activeRoomId != null) 'activeRoomId': activeRoomId,
      if (currentLocation != null) 'currentLocation': currentLocation,
      'isGpsActive': isGpsActive,
      if (locationUpdatedAt != null)
        'locationUpdatedAt': Timestamp.fromDate(locationUpdatedAt!),
      'onlineStatus': onlineStatus,
    };
  }

  static DistanceTier _calcTier(double d, [double safeRadius = 200.0]) {
    if (d <= safeRadius * 0.5) return DistanceTier.aman;
    if (d <= safeRadius) return DistanceTier.waspada;
    return DistanceTier.terlalujJauh;
  }

  void refresh({double safeRadius = 200.0}) {
    final newTier = _calcTier(distance, safeRadius);
    if (newTier != DistanceTier.terlalujJauh) {
      _dangerStart = null;
      separatedMode = false;
    } else {
      _dangerStart ??= DateTime.now();
      if (DateTime.now().difference(_dangerStart!).inSeconds >= 5) {
        separatedMode = true;
      }
    }
    tier = newTier;
  }

  /// Formatted distance string (e.g. "120 m", "1.5 km", "14040 km")
  String get formattedDistance => DistanceFormatter.format(distance);

  /// Numeric string value for distance display
  String get distanceValue {
    if (distance.isNaN || distance.isInfinite) return '0';
    if (distance >= 100000) {
      return (distance / 1000).round().toString();
    } else if (distance >= 1000) {
      final km = distance / 1000;
      return km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    } else {
      return distance.round().toString();
    }
  }

  /// Unit string ('meter' or 'km')
  String get distanceUnit => distance >= 1000 ? 'km' : 'meter';
}
