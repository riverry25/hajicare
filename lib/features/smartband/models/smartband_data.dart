import 'dart:convert';

/// Model representasi data telemetri dari ESP32-S3 Smartband
/// Dilengkapi 5 sensor:
/// 1. Detak Jantung (MAX30102) -> heartRate (BPM)
/// 2. Suhu Tubuh (MCP9808) -> temperature (°C)
/// 3. Deteksi Jatuh & Gerak (MPU6050) -> fallDetected, roll, pitch, accelG
/// 4. GPS (NEO-6M) -> latitude, longitude, satellites, isValidLocation
/// 5. Baterai LiPo -> batteryLevel (%), batteryVoltage (V), isCharging
class SmartbandData {
  final String braceletId;
  final double? latitude;
  final double? longitude;
  final int heartRate;
  final double? temperature;
  final bool fallDetected;
  final double? roll;
  final double? pitch;
  final double? accelG;
  final int? batteryLevel;
  final double? batteryVoltage;
  final bool isCharging;
  final int? satellites;
  final DateTime timestamp;
  final String rawJson;
  final bool isValidLocation;

  /// Default koordinat GPS statis Smartband (Pelataran Masjidil Haram, Makkah)
  static const double staticDefaultLatitude = 21.422487;
  static const double staticDefaultLongitude = 39.826206;

  const SmartbandData({
    required this.braceletId,
    this.latitude,
    this.longitude,
    required this.heartRate,
    this.temperature,
    this.fallDetected = false,
    this.roll,
    this.pitch,
    this.accelG,
    this.batteryLevel,
    this.batteryVoltage,
    this.isCharging = false,
    this.satellites,
    required this.timestamp,
    this.rawJson = '',
    this.isValidLocation = false,
  });

  /// Salin objek SmartbandData dengan field yang diperbarui
  SmartbandData copyWith({
    String? braceletId,
    double? latitude,
    double? longitude,
    int? heartRate,
    double? temperature,
    bool? fallDetected,
    double? roll,
    double? pitch,
    double? accelG,
    int? batteryLevel,
    double? batteryVoltage,
    bool? isCharging,
    int? satellites,
    DateTime? timestamp,
    String? rawJson,
    bool? isValidLocation,
  }) {
    return SmartbandData(
      braceletId: braceletId ?? this.braceletId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heartRate: heartRate ?? this.heartRate,
      temperature: temperature ?? this.temperature,
      fallDetected: fallDetected ?? this.fallDetected,
      roll: roll ?? this.roll,
      pitch: pitch ?? this.pitch,
      accelG: accelG ?? this.accelG,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      isCharging: isCharging ?? this.isCharging,
      satellites: satellites ?? this.satellites,
      timestamp: timestamp ?? this.timestamp,
      rawJson: rawJson ?? this.rawJson,
      isValidLocation: isValidLocation ?? this.isValidLocation,
    );
  }

  /// Factory untuk mem-parse JSON payload dari BLE notification
  /// Melempar [FormatException] jika JSON rusak atau field wajib tidak tersedia
  factory SmartbandData.fromJson(Map<String, dynamic> json, {String raw = ''}) {
    final bId = json['braceletId']?.toString().trim();
    if (bId == null || bId.isEmpty) {
      throw const FormatException(
        'Field "braceletId" tidak ditemukan atau kosong',
      );
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      final str = val.toString().toLowerCase();
      return str == 'true' || str == '1';
    }

    final double? lat = parseDouble(json['latitude']);
    final double? lng = parseDouble(json['longitude']);

    int hr = 0;
    if (json['heartRate'] != null) {
      hr = parseInt(json['heartRate']) ?? 0;
    }

    final double? temp = parseDouble(json['temperature'] ?? json['temp']);
    final bool fall = parseBool(json['fallDetected'] ?? json['fall']);
    final double? rollVal = parseDouble(json['roll']);
    final double? pitchVal = parseDouble(json['pitch']);
    final double? gForce = parseDouble(json['accelG'] ?? json['gForce']);
    final int? bat = parseInt(
      json['batteryLevel'] ?? json['battery'] ?? json['bat'],
    );
    final double? batVolt = parseDouble(json['batteryVoltage'] ?? json['volt']);
    final bool charging = parseBool(json['isCharging'] ?? json['charging']);
    final int? sats = parseInt(json['satellites'] ?? json['sats']);

    // Validasi lokasi geografis:
    // Koordinat (0.0, 0.0) atau koordinat di luar batas bumi dianggap belum valid (misal GPS fix belum dapat)
    final bool validLoc =
        lat != null &&
        lng != null &&
        !lat.isNaN &&
        !lng.isNaN &&
        (lat.abs() > 0.000001 || lng.abs() > 0.000001) &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lng >= -180.0 &&
        lng <= 180.0;

    return SmartbandData(
      braceletId: bId,
      latitude: lat,
      longitude: lng,
      heartRate: hr < 0 ? 0 : hr,
      temperature: temp,
      fallDetected: fall,
      roll: rollVal,
      pitch: pitchVal,
      accelG: gForce,
      batteryLevel: bat,
      batteryVoltage: batVolt,
      isCharging: charging,
      satellites: sats,
      timestamp: DateTime.now(),
      rawJson: raw,
      isValidLocation: validLoc,
    );
  }

  /// Parse dari raw UTF-8 string JSON
  factory SmartbandData.fromRawJson(String rawString) {
    final dynamic decoded = jsonDecode(rawString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Payload JSON bukan merupakan objek Map valid',
      );
    }
    return SmartbandData.fromJson(decoded, raw: rawString);
  }

  Map<String, dynamic> toJson() => {
    'braceletId': braceletId,
    'latitude': latitude,
    'longitude': longitude,
    'heartRate': heartRate,
    'temperature': temperature,
    'fallDetected': fallDetected,
    'roll': roll,
    'pitch': pitch,
    'accelG': accelG,
    'batteryLevel': batteryLevel,
    'batteryVoltage': batteryVoltage,
    'isCharging': isCharging,
    'satellites': satellites,
    'timestamp': timestamp.toIso8601String(),
    'isValidLocation': isValidLocation,
  };

  @override
  String toString() {
    return 'SmartbandData(braceletId: $braceletId, lat: $latitude, lng: $longitude, hr: $heartRate, temp: $temperature, fall: $fallDetected, bat: $batteryLevel%, validLoc: $isValidLocation)';
  }
}
