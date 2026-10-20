import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/smartband_data.dart';

/// Service untuk menyimpan dan memuat data telemetri Smartband ke/dari
/// SharedPs (local storage perangkat).
/// Data yang dipersisten
/// Detak jantung (BPM) terakhir
/// SpO2 terakhir
/// Suhu tubuh terakhir
/// Total langkah (step count
/// Data GPS (lat/lng terakhir yang valid
/// Baterai
/// Waktu data terakhir diterima
/// LCD baris 1 & 2
/// Status deteksi jatuh (reset ke false saat load
class SmartbandStorageService {
  static const String _keyPrefix = 'hajicare_smartband_';
  static const String _keyHeartRate = '${_keyPrefix}heart_rate';
  static const String _keySpo2 = '${_keyPrefix}spo2';
  static const String _keyTemperature = '${_keyPrefix}temperature';
  static const String _keyStepCount = '${_keyPrefix}step_count';
  static const String _keyLastLat = '${_keyPrefix}last_lat';
  static const String _keyLastLng = '${_keyPrefix}last_lng';
  static const String _keyIsGpsFix = '${_keyPrefix}is_gps_fix';
  static const String _keyBatteryPercent = '${_keyPrefix}battery_percent';
  static const String _keyBatteryVoltage = '${_keyPrefix}battery_voltage';
  static const String _keyLcdLine1 = '${_keyPrefix}lcd_line1';
  static const String _keyLcdLine2 = '${_keyPrefix}lcd_line2';
  static const String _keyBraceletId = '${_keyPrefix}bracelet_id';
  static const String _keyLastDataAt = '${_keyPrefix}last_data_at';
  static const String _keyGpsSatellites = '${_keyPrefix}gps_satellites';
  static const String _keyGyroRoll = '${_keyPrefix}gyro_roll';
  static const String _keyGyroPitch = '${_keyPrefix}gyro_pitch';
  static const String _keyAccelG = '${_keyPrefix}accel_g';
  static const String _keyStabilityScore = '${_keyPrefix}stability_score';
  static const String _keyLastRawJson = '${_keyPrefix}last_raw_json';

  SharedPreferences? _prefs;

  /// Singleton instance
  static final SmartbandStorageService _instance =
      SmartbandStorageService._internal();

  SmartbandStorageService._internal();

  static SmartbandStorageService get instance => _instance;

  /// Inisialisasi SharedPs. Harus dipanggil sebelum operasi lainnya.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[SmartbandStorage] Gagal inisialisasi SharedPreferences: $e');
    }
  }

  // Simpan Data

  /// Simpan seluruh data telemetri dari [SmartbandData] ke local storage.
  Future<void> saveSmartbandData(SmartbandData data) async {
    final p = _prefs;
    if (p == null) return;
    try {
      final futures = <Future<bool>>[
        if (data.heartRate > 0) p.setInt(_keyHeartRate, data.heartRate),
        if (data.spo2 != null && data.spo2! > 0) p.setInt(_keySpo2, data.spo2!),
        if (data.temperature != null && data.temperature! > 0)
          p.setDouble(_keyTemperature, data.temperature!),
        if (data.stepCount != null) p.setInt(_keyStepCount, data.stepCount!),
        if (data.isValidLocation && data.latitude != null)
          p.setDouble(_keyLastLat, data.latitude!),
        if (data.isValidLocation && data.longitude != null)
          p.setDouble(_keyLastLng, data.longitude!),
        p.setBool(_keyIsGpsFix, data.isValidLocation),
        if (data.batteryLevel != null)
          p.setInt(_keyBatteryPercent, data.batteryLevel!),
        if (data.batteryVoltage != null)
          p.setDouble(_keyBatteryVoltage, data.batteryVoltage!),
        p.setString(_keyLcdLine1, data.displayLcdLine1),
        p.setString(_keyLcdLine2, data.displayLcdLine2),
        p.setString(_keyBraceletId, data.braceletId),
        p.setString(_keyLastDataAt, data.timestamp.toIso8601String()),
        if (data.satellites != null)
          p.setInt(_keyGpsSatellites, data.satellites!),
        if (data.roll != null) p.setDouble(_keyGyroRoll, data.roll!),
        if (data.pitch != null) p.setDouble(_keyGyroPitch, data.pitch!),
        if (data.accelG != null) p.setDouble(_keyAccelG, data.accelG!),
        if (data.rawJson.isNotEmpty) p.setString(_keyLastRawJson, data.rawJson),
      ];
      await Future.wait(futures);
    } catch (e) {
      debugPrint('[SmartbandStorage] Gagal menyimpan data smartband: $e');
    }
  }

  /// Simpan step count secara terpisah (dipakai saat simulation update per-tick
  Future<void> saveStepCount(int steps) async {
    try {
      await _prefs?.setInt(_keyStepCount, steps);
    } catch (e) {
      debugPrint('[SmartbandStorage] Gagal simpan step count: $e');
    }
  }

  /// Simpan stability score
  Future<void> saveStabilityScore(int score) async {
    try {
      await _prefs?.setInt(_keyStabilityScore, score);
    } catch (e) {
      debugPrint('[SmartbandStorage] Gagal simpan stability score: $e');
    }
  }

  // Muat Data

  /// Muat semua data tersimpan dari local storage.
  /// Mengembalikan [SmartbandStoredSnapshot] berisi semua field yang berhasil dimuat.
  SmartbandStoredSnapshot loadStoredData() {
    final p = _prefs;
    if (p == null) return const SmartbandStoredSnapshot();

    try {
      final lastDataAtStr = p.getString(_keyLastDataAt);
      final lastDataAt = lastDataAtStr != null
          ? DateTime.tryParse(lastDataAtStr)
          : null;

      return SmartbandStoredSnapshot(
        heartRate: p.getInt(_keyHeartRate),
        spo2: p.getInt(_keySpo2),
        temperature: p.getDouble(_keyTemperature),
        stepCount: p.getInt(_keyStepCount),
        lastKnownLatitude: p.getDouble(_keyLastLat),
        lastKnownLongitude: p.getDouble(_keyLastLng),
        wasGpsFix: p.getBool(_keyIsGpsFix) ?? false,
        batteryPercent: p.getInt(_keyBatteryPercent),
        batteryVoltage: p.getDouble(_keyBatteryVoltage),
        lcdLine1: p.getString(_keyLcdLine1),
        lcdLine2: p.getString(_keyLcdLine2),
        braceletId: p.getString(_keyBraceletId),
        lastDataReceivedAt: lastDataAt,
        gpsSatellites: p.getInt(_keyGpsSatellites),
        gyroRoll: p.getDouble(_keyGyroRoll),
        gyroPitch: p.getDouble(_keyGyroPitch),
        accelG: p.getDouble(_keyAccelG),
        stabilityScore: p.getInt(_keyStabilityScore),
        lastRawJson: p.getString(_keyLastRawJson),
      );
    } catch (e) {
      debugPrint('[SmartbandStorage] Gagal memuat data tersimpan: $e');
      return const SmartbandStoredSnapshot();
    }
  }

  /// Hapus semua data tersimpan (untuk logout atau reset
  Future<void> clearAll() async {
    try {
      final p = _prefs;
      if (p == null) return;
      final keysToRemove = p
          .getKeys()
          .where((k) => k.startsWith(_keyPrefix))
          .toList();
      for (final key in keysToRemove) {
        await p.remove(key);
      }
    } catch (e) {
      debugPrint('[SmartbandStorage] Gagal menghapus data: $e');
    }
  }

  /// Cek apakah ada data tersimpan yang valid
  bool get hasStoredData {
    final p = _prefs;
    if (p == null) return false;
    final hr = p.getInt(_keyHeartRate);
    return hr != null && hr > 0;
  }
}

/// Snapshot data Smartband yang dimuat dari local storage.
/// Semua field nullable karena mungkin belum pernah disimpan sebelumnya.
class SmartbandStoredSnapshot {
  final int? heartRate;
  final int? spo2;
  final double? temperature;
  final int? stepCount;
  final double? lastKnownLatitude;
  final double? lastKnownLongitude;
  final bool wasGpsFix;
  final int? batteryPercent;
  final double? batteryVoltage;
  final String? lcdLine1;
  final String? lcdLine2;
  final String? braceletId;
  final DateTime? lastDataReceivedAt;
  final int? gpsSatellites;
  final double? gyroRoll;
  final double? gyroPitch;
  final double? accelG;
  final int? stabilityScore;
  final String? lastRawJson;

  const SmartbandStoredSnapshot({
    this.heartRate,
    this.spo2,
    this.temperature,
    this.stepCount,
    this.lastKnownLatitude,
    this.lastKnownLongitude,
    this.wasGpsFix = false,
    this.batteryPercent,
    this.batteryVoltage,
    this.lcdLine1,
    this.lcdLine2,
    this.braceletId,
    this.lastDataReceivedAt,
    this.gpsSatellites,
    this.gyroRoll,
    this.gyroPitch,
    this.accelG,
    this.stabilityScore,
    this.lastRawJson,
  });

  bool get hasAnyData =>
      heartRate != null ||
      spo2 != null ||
      temperature != null ||
      stepCount != null;
}
