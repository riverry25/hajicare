import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single logged test trial for Map & Geolocation (TC-06).
class MapTestLog {
  final String id;
  final DateTime timestamp;
  final String targetName;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double durationSeconds;
  final bool isSuccess;
  final String? errorMessage;

  MapTestLog({
    required this.id,
    required this.timestamp,
    this.targetName = 'Lokasi Saya (Mandiri)',
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.durationSeconds,
    required this.isSuccess,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'targetName': targetName,
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'durationSeconds': durationSeconds,
        'isSuccess': isSuccess,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  factory MapTestLog.fromJson(Map<String, dynamic> json) => MapTestLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        targetName: json['targetName'] as String? ?? 'Lokasi Saya (Mandiri)',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble() ?? 0.0,
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
        isSuccess: json['isSuccess'] as bool? ?? false,
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Service to track and persist validation test trials for Map/Location (TC-06).
class MapValidationTrackerService {
  MapValidationTrackerService._();
  static final MapValidationTrackerService instance =
      MapValidationTrackerService._();

  static const String _storageKey = 'hajicare_map_validation_logs';
  final ValueNotifier<List<MapTestLog>> logsNotifier =
      ValueNotifier<List<MapTestLog>>([]);

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        logsNotifier.value = decoded
            .map((item) => MapTestLog.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[MapValidationTracker] Failed to load logs: $e');
    }
    _isInitialized = true;
  }

  Future<void> logTrial({
    String targetName = 'Lokasi Saya (Mandiri)',
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required double durationSeconds,
    required bool isSuccess,
    String? errorMessage,
  }) async {
    await init();
    final entry = MapTestLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      targetName: targetName,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      durationSeconds: durationSeconds,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );

    final updated = List<MapTestLog>.from(logsNotifier.value)..add(entry);
    logsNotifier.value = updated;
    await _save(updated);

    debugPrint('\n======================================================');
    debugPrint('📍 LOG VALIDASI PETA / LOKASI (TC-06) BARU TERCATAT:');
    debugPrint(
      'Percobaan #${updated.length} | Target: $targetName | Koordinat: ($latitude, $longitude) | Akurasi: ${accuracyMeters.toStringAsFixed(1)}m | Waktu Respon: ${durationSeconds.toStringAsFixed(2)}s | Status: ${isSuccess ? "BERHASIL ✅" : "GAGAL ❌"}',
    );
    debugPrint('======================================================\n');
  }

  Future<void> clearAll() async {
    logsNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<MapTestLog> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('[MapValidationTracker] Failed to save logs: $e');
    }
  }
}
