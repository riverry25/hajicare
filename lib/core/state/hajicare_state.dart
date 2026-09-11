import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Distance tier constants matching the HajiCare design document color system.
enum DistanceTier { aman, waspada, terlalujJauh }

/// Color for each tier, taken directly from design doc section 6.1.
extension DistanceTierColor on DistanceTier {
  Color get color {
    switch (this) {
      case DistanceTier.aman:
        return const Color(0xFF4CAF50);
      case DistanceTier.waspada:
        return const Color(0xFFF4A259);
      case DistanceTier.terlalujJauh:
        return const Color(0xFFE63946);
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

/// Data model for one jamaah being tracked.
class JamaahData {
  final String id;
  final String name;
  final String shortLabel;
  double distance;
  DistanceTier tier;
  bool separatedMode;
  bool sosActive;
  DateTime? _dangerStart;

  JamaahData({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.distance,
  })  : tier = _calcTier(distance),
        separatedMode = false,
        sosActive = false;

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

enum UserRole { jamaah, pendamping }

class HajiCareState extends ChangeNotifier {
  UserRole _role = UserRole.jamaah;
  UserRole get role => _role;

  static const int selfJamaahIndex = 0;

  final List<JamaahData> jamaahList = [
    JamaahData(
      id: 'j1',
      name: 'H. Ahmad Dahlan (Ayah)',
      shortLabel: 'Ayah',
      distance: 80,
    ),
    JamaahData(
      id: 'j2',
      name: 'Hj. Siti Fatimah (Ibu)',
      shortLabel: 'Ibu',
      distance: 55,
    ),
  ];

  final String pendampingName = 'Siti Aminah (Putri)';

  Timer? _simTimer;
  final Random _rng = Random();

  HajiCareState() {
    _startSimulation();
  }

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  JamaahData get self => jamaahList[selfJamaahIndex];

  bool get anySosActive => jamaahList.any((j) => j.sosActive);

  bool get anyJamaahSeparated => jamaahList.any((j) => j.separatedMode);

  String get separatedJamaahName {
    final j = jamaahList.firstWhere(
      (j) => j.separatedMode,
      orElse: () => jamaahList.first,
    );
    return j.name;
  }

  String get sosJamaahName {
    final j = jamaahList.firstWhere(
      (j) => j.sosActive,
      orElse: () => jamaahList.first,
    );
    return j.name;
  }

  void triggerSos() {
    jamaahList[selfJamaahIndex].sosActive = true;
    notifyListeners();
  }

  void dismissSos(String id) {
    final j = jamaahList.firstWhere(
      (j) => j.id == id,
      orElse: () => jamaahList.first,
    );
    j.sosActive = false;
    notifyListeners();
  }

  void _startSimulation() {
    _simTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      for (final j in jamaahList) {
        double delta = (_rng.nextDouble() * 30) - 15;
        if (j.distance > 250) delta -= 10;
        if (j.distance < 20) delta += 10;
        j.distance = (j.distance + delta).clamp(0, 400);
        j.refresh();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }
}
