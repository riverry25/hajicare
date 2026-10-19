import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model Log Pengujian Komponen Aktual Smart Band (Tabel 6.1)
class SmartbandComponentLog {
  final String id;
  final DateTime timestamp;
  final String
  component; // MAX30102, MLX90614, MPU6050, Tombol SOS, Motor getar, OLED
  final String parameter;
  final String referenceStandard;
  final String measuredValue;
  final bool isSuccess;
  final String indicatorResult;
  final String? notes;

  SmartbandComponentLog({
    required this.id,
    required this.timestamp,
    required this.component,
    required this.parameter,
    required this.referenceStandard,
    required this.measuredValue,
    required this.isSuccess,
    required this.indicatorResult,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'component': component,
    'parameter': parameter,
    'referenceStandard': referenceStandard,
    'measuredValue': measuredValue,
    'isSuccess': isSuccess,
    'indicatorResult': indicatorResult,
    'notes': notes,
  };

  factory SmartbandComponentLog.fromJson(Map<String, dynamic> json) =>
      SmartbandComponentLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        component: json['component'] as String,
        parameter: json['parameter'] as String,
        referenceStandard: json['referenceStandard'] as String,
        measuredValue: json['measuredValue'] as String,
        isSuccess: json['isSuccess'] as bool? ?? true,
        indicatorResult: json['indicatorResult'] as String? ?? 'Berhasil',
        notes: json['notes'] as String?,
      );
}

/// Model Log Pengujian Akurasi Fisiologis vs Alat Referensi (Tabel 6.2)
class SmartbandPhysiologicalLog {
  final String id;
  final DateTime timestamp;
  final String measurementType; // 'Heart Rate', 'SpO₂', 'Temperature'
  final double referenceValue;
  final double bandValue;
  final double absoluteError;
  final String unit; // 'BPM', '%', '°C'

  SmartbandPhysiologicalLog({
    required this.id,
    required this.timestamp,
    required this.measurementType,
    required this.referenceValue,
    required this.bandValue,
    required this.absoluteError,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'measurementType': measurementType,
    'referenceValue': referenceValue,
    'bandValue': bandValue,
    'absoluteError': absoluteError,
    'unit': unit,
  };

  factory SmartbandPhysiologicalLog.fromJson(Map<String, dynamic> json) =>
      SmartbandPhysiologicalLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        measurementType: json['measurementType'] as String,
        referenceValue: (json['referenceValue'] as num).toDouble(),
        bandValue: (json['bandValue'] as num).toDouble(),
        absoluteError: (json['absoluteError'] as num).toDouble(),
        unit: json['unit'] as String,
      );
}

/// Model Log Validasi Modul GPS Smart Band (Tabel 7)
class SmartbandGpsLog {
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final int satellites;
  final double durationSeconds;
  final double? errorMeters;
  final bool isValidLocation;

  SmartbandGpsLog({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.satellites,
    required this.durationSeconds,
    this.errorMeters,
    required this.isValidLocation,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'satellites': satellites,
    'durationSeconds': durationSeconds,
    'errorMeters': errorMeters,
    'isValidLocation': isValidLocation,
  };

  factory SmartbandGpsLog.fromJson(Map<String, dynamic> json) =>
      SmartbandGpsLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        satellites: json['satellites'] as int? ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 1.5,
        errorMeters: (json['errorMeters'] as num?)?.toDouble(),
        isValidLocation: json['isValidLocation'] as bool? ?? true,
      );
}

/// Service untuk melacak, mencatat (logging), dan merekapitulasi
/// Hasil Pengujian Sensor dan Fungsi Smart Band ESP32-S3 HajiCare.
class SmartbandValidationTrackerService {
  SmartbandValidationTrackerService._();
  static final SmartbandValidationTrackerService instance =
      SmartbandValidationTrackerService._();

  static const String _keyComponents = 'hajicare_smartband_component_logs';
  static const String _keyPhysio = 'hajicare_smartband_physio_logs';
  static const String _keyGps = 'hajicare_smartband_gps_logs';

  final ValueNotifier<List<SmartbandComponentLog>> componentLogsNotifier =
      ValueNotifier<List<SmartbandComponentLog>>([]);
  final ValueNotifier<List<SmartbandPhysiologicalLog>> physioLogsNotifier =
      ValueNotifier<List<SmartbandPhysiologicalLog>>([]);
  final ValueNotifier<List<SmartbandGpsLog>> gpsLogsNotifier =
      ValueNotifier<List<SmartbandGpsLog>>([]);

  bool _isInitialized = false;

  /// Inisialisasi dan load dari local cache SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Component logs
      final compRaw = prefs.getString(_keyComponents);
      if (compRaw != null && compRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(compRaw) as List<dynamic>;
        componentLogsNotifier.value = decoded
            .map(
              (e) => SmartbandComponentLog.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }

      // 2. Physio logs
      final physioRaw = prefs.getString(_keyPhysio);
      if (physioRaw != null && physioRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(physioRaw) as List<dynamic>;
        physioLogsNotifier.value = decoded
            .map(
              (e) =>
                  SmartbandPhysiologicalLog.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }

      // 3. GPS logs
      final gpsRaw = prefs.getString(_keyGps);
      if (gpsRaw != null && gpsRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(gpsRaw) as List<dynamic>;
        gpsLogsNotifier.value = decoded
            .map((e) => SmartbandGpsLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[SmartbandValidationTracker] Error loading logs: $e');
    }
    _isInitialized = true;
  }

  // ── Logging Methods ────────────────────────────────────────────────────────

  /// Catat pengujian komponen sensor (Tabel 6.1)
  Future<void> logComponentTest({
    required String component,
    required String parameter,
    required String referenceStandard,
    required String measuredValue,
    required bool isSuccess,
    required String indicatorResult,
    String? notes,
  }) async {
    await init();
    final log = SmartbandComponentLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      component: component,
      parameter: parameter,
      referenceStandard: referenceStandard,
      measuredValue: measuredValue,
      isSuccess: isSuccess,
      indicatorResult: indicatorResult,
      notes: notes,
    );

    final updated = List<SmartbandComponentLog>.from(
      componentLogsNotifier.value,
    )..insert(0, log);
    componentLogsNotifier.value = updated;
    await _persistComponents();
  }

  /// Catat perbandingan akurasi fisiologis (Tabel 6.2)
  Future<void> logPhysiologicalTest({
    required String measurementType,
    required double referenceValue,
    required double bandValue,
    required String unit,
  }) async {
    await init();
    final absoluteError = (bandValue - referenceValue).abs();
    final log = SmartbandPhysiologicalLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      measurementType: measurementType,
      referenceValue: referenceValue,
      bandValue: bandValue,
      absoluteError: absoluteError,
      unit: unit,
    );

    final updated = List<SmartbandPhysiologicalLog>.from(
      physioLogsNotifier.value,
    )..insert(0, log);
    physioLogsNotifier.value = updated;
    await _persistPhysio();
  }

  /// Catat pengujian modul GPS Smart Band (Tabel 7)
  Future<void> logGpsTest({
    required double latitude,
    required double longitude,
    required int satellites,
    required double durationSeconds,
    double? errorMeters,
    required bool isValidLocation,
  }) async {
    await init();
    final log = SmartbandGpsLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      satellites: satellites,
      durationSeconds: durationSeconds,
      errorMeters: errorMeters,
      isValidLocation: isValidLocation,
    );

    final updated = List<SmartbandGpsLog>.from(gpsLogsNotifier.value)
      ..insert(0, log);
    gpsLogsNotifier.value = updated;
    await _persistGps();
  }

  // ── Persistence Helpers ────────────────────────────────────────────────────

  Future<void> _persistComponents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = componentLogsNotifier.value.map((e) => e.toJson()).toList();
      await prefs.setString(_keyComponents, jsonEncode(list));
    } catch (e) {
      debugPrint(
        '[SmartbandValidationTracker] Error persisting components: $e',
      );
    }
  }

  Future<void> _persistPhysio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = physioLogsNotifier.value.map((e) => e.toJson()).toList();
      await prefs.setString(_keyPhysio, jsonEncode(list));
    } catch (e) {
      debugPrint('[SmartbandValidationTracker] Error persisting physio: $e');
    }
  }

  Future<void> _persistGps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = gpsLogsNotifier.value.map((e) => e.toJson()).toList();
      await prefs.setString(_keyGps, jsonEncode(list));
    } catch (e) {
      debugPrint('[SmartbandValidationTracker] Error persisting GPS: $e');
    }
  }

  // ── Aggregation & Summaries ────────────────────────────────────────────────

  /// Ringkasan untuk setiap komponen (Tabel 6.1)
  Map<String, dynamic> getComponentSummary(String componentName) {
    final matching = componentLogsNotifier.value
        .where((l) => l.component.toLowerCase() == componentName.toLowerCase())
        .toList();

    final total = matching.length;
    if (total == 0) {
      return {
        'total': 0,
        'successCount': 0,
        'failCount': 0,
        'successRate': 0.0,
        'lastMeasured': '—',
        'indicator': '—',
      };
    }

    final successCount = matching.where((l) => l.isSuccess).length;
    final rate = (successCount / total) * 100.0;
    final last = matching.first;

    return {
      'total': total,
      'successCount': successCount,
      'failCount': total - successCount,
      'successRate': rate,
      'lastMeasured': last.measuredValue,
      'indicator': last.indicatorResult,
    };
  }

  /// Ringkasan untuk pengukuran fisiologis (Tabel 6.2)
  Map<String, dynamic> getPhysiologicalSummary(String measurementType) {
    final matching = physioLogsNotifier.value
        .where(
          (l) =>
              l.measurementType.toLowerCase() == measurementType.toLowerCase(),
        )
        .toList();

    final total = matching.length;
    if (total == 0) {
      return {
        'total': 0,
        'avgReference': null,
        'avgBand': null,
        'avgAbsoluteError': null,
        'unit': measurementType == 'Temperature'
            ? '°C'
            : (measurementType == 'Heart Rate' ? 'BPM' : '%'),
      };
    }

    final sumRef = matching.fold<double>(
      0.0,
      (acc, l) => acc + l.referenceValue,
    );
    final sumBand = matching.fold<double>(0.0, (acc, l) => acc + l.bandValue);
    final sumErr = matching.fold<double>(
      0.0,
      (acc, l) => acc + l.absoluteError,
    );

    final avgRef = sumRef / total;
    final avgBand = sumBand / total;
    final avgErr = sumErr / total;

    return {
      'total': total,
      'avgReference': avgRef,
      'avgBand': avgBand,
      'avgAbsoluteError': avgErr,
      'unit': matching.first.unit,
    };
  }

  /// Ringkasan untuk modul GPS Smartband (Tabel 7)
  Map<String, dynamic> getGpsSummary() {
    final logs = gpsLogsNotifier.value;
    final total = logs.length;
    if (total == 0) {
      return {
        'total': 0,
        'validRate': 0.0,
        'medianError': null,
        'p95Error': null,
        'medianTime': null,
      };
    }

    final validCount = logs.where((l) => l.isValidLocation).length;
    final validRate = (validCount / total) * 100.0;

    final times = logs.map((l) => l.durationSeconds).toList()..sort();
    final medianTime = times[times.length ~/ 2];

    final errors =
        logs
            .where((l) => l.errorMeters != null)
            .map((l) => l.errorMeters!)
            .toList()
          ..sort();

    double? medianErr;
    double? p95Err;
    if (errors.isNotEmpty) {
      medianErr = errors[errors.length ~/ 2];
      final p95Idx = ((errors.length - 1) * 0.95).round();
      p95Err = errors[p95Idx];
    }

    return {
      'total': total,
      'validRate': validRate,
      'medianError': medianErr,
      'p95Error': p95Err,
      'medianTime': medianTime,
    };
  }

  /// Hapus satu log komponen
  Future<void> deleteComponentLog(String id) async {
    componentLogsNotifier.value = componentLogsNotifier.value
        .where((l) => l.id != id)
        .toList();
    await _persistComponents();
  }

  /// Hapus satu log fisiologis
  Future<void> deletePhysiologicalLog(String id) async {
    physioLogsNotifier.value = physioLogsNotifier.value
        .where((l) => l.id != id)
        .toList();
    await _persistPhysio();
  }

  /// Hapus satu log GPS
  Future<void> deleteGpsLog(String id) async {
    gpsLogsNotifier.value = gpsLogsNotifier.value
        .where((l) => l.id != id)
        .toList();
    await _persistGps();
  }

  /// Bersihkan seluruh log pengujian smartband
  Future<void> clearAllLogs() async {
    componentLogsNotifier.value = [];
    physioLogsNotifier.value = [];
    gpsLogsNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyComponents);
    await prefs.remove(_keyPhysio);
    await prefs.remove(_keyGps);
  }
}
