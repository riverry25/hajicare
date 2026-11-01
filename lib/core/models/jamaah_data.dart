import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/haji_colors.dart';
import '../utils/distance_formatter.dart';

enum UserRole { admin, pendamping, jamaah }

enum DistanceTier { aman, waspada, terlalujJauh }

extension DistanceTierColor on DistanceTier {
  StatusTone get tone {
    switch (this) {
      case DistanceTier.aman:
        return StatusTone.success;
      case DistanceTier.waspada:
        return StatusTone.warning;
      case DistanceTier.terlalujJauh:
        return StatusTone.danger;
    }
  }

  /// Dynamic color resolution based on active theme
  Color resolveColor(HajiColors colors) => colors.tone(tone);

  /// Default light palette color for contexts without BuildContext
  Color get color => HajiColors.light.tone(tone);

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
  bool isSmartbandConnected;
  DateTime? locationUpdatedAt;
  bool onlineStatus;
  DateTime? _dangerStart;

  final String? bloodType;
  final String? allergies;
  final String? conditions;
  final String? emergencyContact;
  final String? passportNumber;
  final String? nik;
  final String? email;
  final String? role;

  int? heartRate;
  double? temperature;
  int? spo2;
  bool fallDetected;
  String? fallStatus;
  int? batteryLevel;
  String? braceletId;
  DateTime? smartbandUpdatedAt;
  int? steps;
  double? stepDistanceM;

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
    this.isSmartbandConnected = false,
    this.locationUpdatedAt,
    this.onlineStatus = true,
    this.bloodType,
    this.allergies,
    this.conditions,
    this.emergencyContact,
    this.passportNumber,
    this.nik,
    this.email,
    this.role,
    this.heartRate,
    this.temperature,
    this.spo2,
    this.fallDetected = false,
    this.fallStatus,
    this.batteryLevel,
    this.braceletId,
    this.smartbandUpdatedAt,
    this.steps,
    this.stepDistanceM,
  }) : tier = _calcTier(distance);

  bool get hasMedicalData =>
      (bloodType != null && bloodType!.trim().isNotEmpty) ||
      (allergies != null && allergies!.trim().isNotEmpty) ||
      (conditions != null && conditions!.trim().isNotEmpty) ||
      (emergencyContact != null && emergencyContact!.trim().isNotEmpty);

  bool get hasHajjDocs =>
      (porsi != null && porsi!.trim().isNotEmpty) ||
      (passportNumber != null && passportNumber!.trim().isNotEmpty) ||
      (nik != null && nik!.trim().isNotEmpty);

  bool get hasSmartbandData =>
      isSmartbandConnected || heartRate != null || temperature != null || spo2 != null;

  /// Kritis jika detak jantung < 45 BPM atau > 120 BPM
  bool get isHeartRateCritical =>
      heartRate != null && heartRate! > 0 && (heartRate! < 45 || heartRate! > 120);

  /// Waspada jika detak jantung 45-49 BPM atau 101-120 BPM
  bool get isHeartRateWarning =>
      heartRate != null &&
      heartRate! > 0 &&
      ((heartRate! >= 45 && heartRate! < 50) ||
          (heartRate! > 100 && heartRate! <= 120));

  /// Kritis jika suhu > 38.5°C (Heatstroke) atau < 35.0°C (Hipotermia)
  bool get isTemperatureCritical =>
      temperature != null && (temperature! > 38.5 || temperature! < 35.0);

  /// Waspada jika suhu demam ringan 37.6 - 38.5°C
  bool get isTemperatureWarning =>
      temperature != null && (temperature! >= 37.6 && temperature! <= 38.5);

  /// Kritis jika SpO2 < 90%
  bool get isSpo2Critical => spo2 != null && spo2! > 0 && spo2! < 90;

  /// Waspada jika SpO2 90% - 94%
  bool get isSpo2Warning => spo2 != null && spo2! >= 90 && spo2! < 95;

  /// Terjatuh jika fallDetected true atau fallStatus == 'FALLEN'
  bool get isFallen =>
      fallDetected ||
      (fallStatus != null && fallStatus!.toUpperCase() == 'FALLEN');

  /// Di luar radius aman rombongan
  bool get isOutOfSafeRadius =>
      (distance > 0 && distance > 50.0) ||
      tier == DistanceTier.terlalujJauh ||
      separatedMode;

  /// Memiliki anomali kritis (Darurat / Danger)
  bool get hasCriticalAnomaly =>
      sosActive ||
      isFallen ||
      isHeartRateCritical ||
      isTemperatureCritical ||
      isSpo2Critical;

  /// Memiliki peringatan atau anomali
  bool get hasAnyWarningOrAnomaly =>
      hasCriticalAnomaly ||
      isOutOfSafeRadius ||
      isHeartRateWarning ||
      isTemperatureWarning ||
      isSpo2Warning;

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
    final nik = (data['nik'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim();
    final role = (data['role'] as String?)?.trim();

    DateTime? locationTime;
    if (data['locationUpdatedAt'] is Timestamp) {
      locationTime = (data['locationUpdatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is Timestamp) {
      locationTime = (data['updatedAt'] as Timestamp).toDate();
    }

    final isGps = (data['isGpsActive'] as bool?) ?? (loc != null);
    final isOnline = (data['onlineStatus'] as bool?) ?? true;

    int? hr;
    double? temp;
    int? oxygen;
    bool fall = false;
    String? fStatus;
    int? battery;
    String? bId;
    DateTime? bandTime;
    int? stepsCount;
    double? stepDist;

    final smartbandMap = data['smartband'] as Map<String, dynamic>?;
    if (smartbandMap != null) {
      hr = (smartbandMap['heartRate'] as num?)?.toInt() ??
          (smartbandMap['bpm'] as num?)?.toInt();
      temp = (smartbandMap['temperature'] as num?)?.toDouble();
      oxygen = (smartbandMap['spo2'] as num?)?.toInt();
      fall = (smartbandMap['fallDetected'] as bool?) ?? false;
      fStatus = smartbandMap['fallStatus'] as String?;
      battery = (smartbandMap['batteryLevel'] as num?)?.toInt();
      bId = smartbandMap['braceletId'] as String?;
      stepsCount = (smartbandMap['steps'] as num?)?.toInt();
      stepDist = (smartbandMap['stepDistanceM'] as num?)?.toDouble();
      if (smartbandMap['updatedAt'] is Timestamp) {
        bandTime = (smartbandMap['updatedAt'] as Timestamp).toDate();
      }
    } else {
      hr = (data['heartRate'] as num?)?.toInt() ?? (data['bpm'] as num?)?.toInt();
      temp = (data['temperature'] as num?)?.toDouble();
      oxygen = (data['spo2'] as num?)?.toInt();
      fall = (data['fallDetected'] as bool?) ?? false;
      fStatus = data['fallStatus'] as String?;
      battery = (data['batteryLevel'] as num?)?.toInt();
      bId = data['braceletId'] as String?;
      stepsCount = (data['steps'] as num?)?.toInt();
      stepDist = (data['stepDistanceM'] as num?)?.toDouble();
      if (data['smartbandUpdatedAt'] is Timestamp) {
        bandTime = (data['smartbandUpdatedAt'] as Timestamp).toDate();
      }
    }

    final isSmartband = (data['isSmartbandConnected'] as bool?) ??
        (data['smartbandConnected'] as bool?) ??
        (data['isSmartbandActive'] as bool?) ??
        (smartbandMap?['connected'] as bool?) ??
        (hr != null || temp != null);

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
      isSmartbandConnected: isSmartband,
      locationUpdatedAt: locationTime,
      onlineStatus: isOnline,
      bloodType: bloodType,
      allergies: allergies,
      conditions: conditions,
      emergencyContact: emergencyContact,
      passportNumber: passportNumber,
      nik: nik,
      email: email,
      role: role,
      heartRate: hr,
      temperature: temp,
      spo2: oxygen,
      fallDetected: fall,
      fallStatus: fStatus,
      batteryLevel: battery,
      braceletId: bId,
      smartbandUpdatedAt: bandTime,
      steps: stepsCount,
      stepDistanceM: stepDist,
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
      'isSmartbandConnected': isSmartbandConnected,
      if (locationUpdatedAt != null)
        'locationUpdatedAt': Timestamp.fromDate(locationUpdatedAt!),
      'onlineStatus': onlineStatus,
      if (heartRate != null) 'heartRate': heartRate,
      if (temperature != null) 'temperature': temperature,
      if (spo2 != null) 'spo2': spo2,
      'fallDetected': fallDetected,
      if (fallStatus != null) 'fallStatus': fallStatus,
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
      if (braceletId != null) 'braceletId': braceletId,
      if (smartbandUpdatedAt != null)
        'smartbandUpdatedAt': Timestamp.fromDate(smartbandUpdatedAt!),
      if (steps != null) 'steps': steps,
      if (stepDistanceM != null) 'stepDistanceM': stepDistanceM,
      if (nik != null && nik!.isNotEmpty) 'nik': nik,
      if (porsi != null && porsi!.isNotEmpty) 'porsi': porsi,
      if (porsi != null && porsi!.isNotEmpty) 'nomorPorsi': porsi,
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

  /// Formatted distance string (e.g. "120 m", "1.5 km", "14040 km"
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

  /// Unit string ('meter' or 'km'
  String get distanceUnit => distance >= 1000 ? 'km' : 'meter';
}
