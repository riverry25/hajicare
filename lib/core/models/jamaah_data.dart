import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';

enum UserRole { jamaah, pendamping }

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
  double distance;
  DistanceTier tier;
  bool separatedMode;
  bool sosActive;
  GeoPoint? currentLocation;
  DateTime? _dangerStart;

  JamaahData({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.distance,
    this.porsi,
    this.kloter,
    this.maktab,
    this.separatedMode = false,
    this.sosActive = false,
    this.currentLocation,
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
    final shortLabel = (rawShortLabel != null && rawShortLabel.trim().isNotEmpty)
        ? rawShortLabel.trim()
        : name.split(' ').first;

    final distance = (data['distance'] as num?)?.toDouble() ?? 0.0;
    final porsi = data['porsi'] as String?;
    final kloter = data['kloter'] as String?;
    final maktab = data['maktab'] as String?;

    return JamaahData(
      id: doc.id,
      name: name,
      shortLabel: shortLabel,
      distance: distance,
      porsi: porsi,
      kloter: kloter,
      maktab: maktab,
      separatedMode: data['separatedMode'] as bool? ?? false,
      sosActive: data['sosActive'] as bool? ?? false,
      currentLocation: data['currentLocation'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'distance': distance,
      'separatedMode': separatedMode,
      'sosActive': sosActive,
      if (currentLocation != null) 'currentLocation': currentLocation,
    };
  }

  static DistanceTier _calcTier(double d) {
    if (d < 100) return DistanceTier.aman;
    if (d < 200) return DistanceTier.waspada;
    return DistanceTier.terlalujJauh;
  }

  void refresh() {
    final newTier = _calcTier(distance);
    if (newTier != DistanceTier.terlalujJauh) {
      _dangerStart = null;
    } else {
      _dangerStart ??= DateTime.now();
    }
    tier = newTier;

    if (_dangerStart != null &&
        DateTime.now().difference(_dangerStart!).inSeconds >= 15) {
      separatedMode = true;
    }
  }
}
