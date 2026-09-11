import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/jamaah_data.dart';
export '../models/jamaah_data.dart';

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
