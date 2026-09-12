import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    this.separatedMode = false,
    this.sosActive = false,
    this.currentLocation,
  }) : tier = _calcTier(distance);

  factory JamaahData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return JamaahData(
        id: doc.id,
        name: 'Unknown',
        shortLabel: 'Unknown',
        distance: 0.0,
      );
    }
    
    // Fallbacks
    final name = data['name'] as String? ?? 'Jamaah';
    final shortLabel = name.split(' ').first;
    final distance = (data['distance'] as num?)?.toDouble() ?? 0.0;
    
    return JamaahData(
      id: doc.id,
      name: name,
      shortLabel: shortLabel,
      distance: distance,
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
