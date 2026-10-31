import 'package:flutter/foundation.dart';

/// Asal data sensor yang dipakai sebagai konteks AI.
enum SensorDataSource {
  /// Data real-time dari gelang yang sedang terhubung via BLE.
  live,

  /// Data dari Mode Simulasi Sensor (saklar di UI / halaman smartband).
  simulation,

  /// Data terakhir yang tersimpan dari gelang (BLE terputus, data masih segar).
  lastKnown,

  /// Nilai demo realistis karena gelang belum terhubung sama sekali.
  demo,
}

extension SensorDataSourceX on SensorDataSource {
  String get label => switch (this) {
    SensorDataSource.live => 'Live dari Gelang',
    SensorDataSource.simulation => 'Mode Simulasi',
    SensorDataSource.lastKnown => 'Data Terakhir',
    SensorDataSource.demo => 'Data Demo',
  };

  bool get isReal =>
      this == SensorDataSource.live || this == SensorDataSource.lastKnown;
}

/// Status koneksi BLE gelang yang relevan bagi fitur AI.
enum SmartbandLinkStatus { disconnected, scanning, connecting, connected }

/// Snapshot immutable kondisi sensor gelang jamaah untuk konteks AI.
@immutable
class SensorContext {
  const SensorContext({
    required this.heartRateBpm,
    required this.temperatureC,
    required this.isFallDetected,
    required this.source,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.distanceToCompanionMeters,
    this.safeRadiusMeters,
  });

  final int heartRateBpm;
  final double temperatureC;
  final bool isFallDetected;
  final double? latitude;
  final double? longitude;

  /// Jarak ke pendamping (meter). `null` jika belum tersedia.
  final double? distanceToCompanionMeters;

  /// Batas radius aman (meter). `null` jika belum tersedia.
  final double? safeRadiusMeters;

  final SensorDataSource source;
  final DateTime capturedAt;

  bool get hasLocation => latitude != null && longitude != null;

  bool get isOutsideSafeRadius {
    final d = distanceToCompanionMeters;
    final r = safeRadiusMeters;
    return d != null && r != null && d > r;
  }

  String get fallStatusLabel =>
      isFallDetected ? 'TERDETEKSI JATUH' : 'Aman (tidak jatuh)';

  String get temperatureLabel => temperatureC.toStringAsFixed(1);

  String? get distanceLabel => distanceToCompanionMeters?.round().toString();

  /// Penilaian sederhana untuk pewarnaan UI (bukan diagnosis medis).
  bool get isHeartRateAbnormal => heartRateBpm > 0 &&
      (heartRateBpm < 50 || heartRateBpm > 110);
  bool get isTemperatureAbnormal => temperatureC >= 37.8 || temperatureC < 35.0;

  SensorContext copyWith({
    int? heartRateBpm,
    double? temperatureC,
    bool? isFallDetected,
    double? latitude,
    double? longitude,
    double? distanceToCompanionMeters,
    double? safeRadiusMeters,
    SensorDataSource? source,
    DateTime? capturedAt,
  }) {
    return SensorContext(
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      temperatureC: temperatureC ?? this.temperatureC,
      isFallDetected: isFallDetected ?? this.isFallDetected,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceToCompanionMeters:
          distanceToCompanionMeters ?? this.distanceToCompanionMeters,
      safeRadiusMeters: safeRadiusMeters ?? this.safeRadiusMeters,
      source: source ?? this.source,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  /// Kesetaraan nilai sengaja mengabaikan [capturedAt] agar stream
  /// `distinct()` tidak memicu rebuild bila nilainya tidak berubah.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorContext &&
          other.heartRateBpm == heartRateBpm &&
          other.temperatureC == temperatureC &&
          other.isFallDetected == isFallDetected &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.distanceToCompanionMeters == distanceToCompanionMeters &&
          other.safeRadiusMeters == safeRadiusMeters &&
          other.source == source;

  @override
  int get hashCode => Object.hash(
    heartRateBpm,
    temperatureC,
    isFallDetected,
    latitude,
    longitude,
    distanceToCompanionMeters,
    safeRadiusMeters,
    source,
  );

  @override
  String toString() =>
      'SensorContext(bpm: $heartRateBpm, temp: $temperatureLabel, '
      'fall: $isFallDetected, dist: $distanceLabel, source: ${source.name})';
}

