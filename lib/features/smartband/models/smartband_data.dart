import 'dart:convert';

/// Model representasi data telemetri dari ESP32-S3 Smartband
/// Dilengkapi 5 modul/sensor spesifik:
/// 1. MAX30102: Detak Jantung (BPM) & Saturasi Oksigen Darah (SpO2 %)
/// 2. MCP9808: Suhu Tubuh Presisi Tinggi (°C)
/// 3. MPU6050: Akselerometer & Giroskop -> Deteksi Aktivitas Langkah (stepCount), Keseimbangan (roll, pitch, accelG), & Deteksi Jatuh (fallDetected)
/// 4. GPS NEO-6M: Lokasi Koordinat Satelit (latitude, longitude, satellites, isValidLocation)
/// 5. LCD 16x2 + I2C Backpack: Tampilan Status Kesehatan (BPM, Suhu) & Pesan Darurat di Pergelangan Tangan (lcdLine1, lcdLine2, emergencyMessage)
class SmartbandData {
  final String braceletId;
  final double? latitude;
  final double? longitude;
  final int heartRate;
  final int? spo2;
  final double? temperature;
  final bool fallDetected;
  final int? stepCount;
  final double? roll;
  final double? pitch;
  final double? accelG;
  final int? batteryLevel;
  final double? batteryVoltage;
  final bool isCharging;
  final bool isSos;
  final int? satellites;
  final String? lcdLine1;
  final String? lcdLine2;
  final String? emergencyMessage;
  final DateTime timestamp;
  final String rawJson;
  final bool isValidLocation;

  /// Default koordinat GPS referensi Smartband (Pelataran Masjidil Haram, Makkah)
  static const double staticDefaultLatitude = 21.422487;
  static const double staticDefaultLongitude = 39.826206;

  SmartbandData({
    required this.braceletId,
    this.latitude,
    this.longitude,
    required this.heartRate,
    this.spo2,
    this.temperature,
    bool fallDetected = false,
    bool? isFallDetected,
    bool isSos = false,
    bool? sosButtonPressed,
    this.stepCount,
    double? roll,
    double? gyroRoll,
    double? pitch,
    double? gyroPitch,
    this.accelG,
    this.batteryLevel,
    this.batteryVoltage,
    this.isCharging = false,
    this.satellites,
    this.lcdLine1,
    this.lcdLine2,
    this.emergencyMessage,
    DateTime? timestamp,
    this.rawJson = '',
    bool? isValidLocation,
  }) : isValidLocation =
           isValidLocation ??
           (latitude != null &&
               longitude != null &&
               (latitude.abs() > 0.0001 || longitude.abs() > 0.0001)),
       fallDetected = isFallDetected ?? fallDetected,
       isSos = sosButtonPressed ?? isSos,
       roll = gyroRoll ?? roll,
       pitch = gyroPitch ?? pitch,
       timestamp = timestamp ?? DateTime.now();

  /// Alias untuk tombol SOS
  bool get sos => isSos;
  bool get sosButtonPressed => isSos;

  /// Alias untuk deteksi jatuh
  bool get isFallDetected => fallDetected;

  /// Alias orientasi sudut giroskop
  double? get gyroRoll => roll;
  double? get gyroPitch => pitch;

  /// Validasi rentang fisiologis SpO2 (70% - 100%)
  bool get isValidSpo2 => spo2 != null && spo2! >= 70 && spo2! <= 100;

  /// Validasi rentang fisiologis suhu tubuh jemaah (30°C - 45°C)
  bool get isValidTemperature =>
      temperature != null && temperature! >= 30.0 && temperature! <= 45.0;

  /// Indikator apakah data tanda-tanda vital valid
  bool get hasValidVitals => heartRate > 0 && isValidSpo2;

  /// Teks LCD 16x2 Baris 1 (Format 16 Karakter Pas)
  String get displayLcdLine1 {
    if (lcdLine1 != null && lcdLine1!.trim().isNotEmpty) {
      final s = lcdLine1!.trim();
      return s.length > 16 ? s.substring(0, 16) : s.padRight(16);
    }
    // Format otomatis status kesehatan: HR: 76  SpO2:98%
    final hrStr = heartRate > 0 ? heartRate.toString().padLeft(3) : ' --';
    final oxStr = spo2 != null ? '$spo2%' : '--%';
    final line = 'HR:$hrStr  SpO2:$oxStr';
    return line.length > 16 ? line.substring(0, 16) : line.padRight(16);
  }

  /// Teks LCD 16x2 Baris 2 (Format 16 Karakter Pas)
  String get displayLcdLine2 {
    if (lcdLine2 != null && lcdLine2!.trim().isNotEmpty) {
      final s = lcdLine2!.trim();
      return s.length > 16 ? s.substring(0, 16) : s.padRight(16);
    }
    if (isSos) {
      return '!TOMBOL SOS!    ';
    }
    if (fallDetected) {
      return '!JATUH DETEKSI !';
    }
    if (emergencyMessage != null && emergencyMessage!.trim().isNotEmpty) {
      final s = emergencyMessage!.trim();
      return s.length > 16 ? s.substring(0, 16) : s.padRight(16);
    }
    final tempStr = temperature != null
        ? '${temperature!.toStringAsFixed(1)}C'
        : '--.-C';
    final line = 'T:$tempStr NORMAL';
    return line.length > 16 ? line.substring(0, 16) : line.padRight(16);
  }

  /// Salin objek SmartbandData dengan field yang diperbarui
  SmartbandData copyWith({
    String? braceletId,
    double? latitude,
    double? longitude,
    int? heartRate,
    int? spo2,
    double? temperature,
    bool? fallDetected,
    bool? isFallDetected,
    bool? isSos,
    bool? sosButtonPressed,
    int? stepCount,
    double? roll,
    double? gyroRoll,
    double? pitch,
    double? gyroPitch,
    double? accelG,
    int? batteryLevel,
    double? batteryVoltage,
    bool? isCharging,
    int? satellites,
    String? lcdLine1,
    String? lcdLine2,
    String? emergencyMessage,
    DateTime? timestamp,
    String? rawJson,
    bool? isValidLocation,
  }) {
    return SmartbandData(
      braceletId: braceletId ?? this.braceletId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      temperature: temperature ?? this.temperature,
      fallDetected: isFallDetected ?? fallDetected ?? this.fallDetected,
      isSos: sosButtonPressed ?? isSos ?? this.isSos,
      stepCount: stepCount ?? this.stepCount,
      roll: gyroRoll ?? roll ?? this.roll,
      pitch: gyroPitch ?? pitch ?? this.pitch,
      accelG: accelG ?? this.accelG,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      isCharging: isCharging ?? this.isCharging,
      satellites: satellites ?? this.satellites,
      lcdLine1: lcdLine1 ?? this.lcdLine1,
      lcdLine2: lcdLine2 ?? this.lcdLine2,
      emergencyMessage: emergencyMessage ?? this.emergencyMessage,
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

    // 1. MAX30102: BPM & SpO2
    int hr = 0;
    if (json['heartRate'] != null ||
        json['bpm'] != null ||
        json['hr'] != null) {
      hr = parseInt(json['heartRate'] ?? json['bpm'] ?? json['hr']) ?? 0;
    }
    final int? oxygen = parseInt(
      json['spo2'] ?? json['oxygen'] ?? json['ox'] ?? json['o2'],
    );

    // 2. MCP9808: Suhu Tubuh (°C)
    final double? temp = parseDouble(
      json['temperature'] ??
          json['temperatureC'] ??
          json['temp'] ??
          json['tempC'] ??
          json['mcpTemp'] ??
          json['bodyTemp'],
    );

    // 3. MPU6050: Deteksi Jatuh, Langkah, Keseimbangan
    final dynamic rawFallStatus = json['fallStatus'];
    final bool fallConfirmed =
        rawFallStatus != null &&
        rawFallStatus.toString().toUpperCase().contains('CONFIRMED');
    final bool fall =
        fallConfirmed ||
        parseBool(
          json['fallDetected'] ??
              json['isFallDetected'] ??
              json['fall'] ??
              json['jatuh'],
        );
    final int? steps = parseInt(
      json['stepCount'] ?? json['steps'] ?? json['step'] ?? json['langkah'],
    );
    final double? rollVal = parseDouble(json['roll'] ?? json['gyroRoll']);
    final double? pitchVal = parseDouble(json['pitch'] ?? json['gyroPitch']);
    final double? gForce = parseDouble(
      json['accelG'] ?? json['motionG'] ?? json['gForce'] ?? json['accel'],
    );

    // 4. GPS NEO-6M: Koordinat & Satelit
    final double? lat = parseDouble(json['latitude'] ?? json['lat']);
    final double? lng = parseDouble(
      json['longitude'] ?? json['lng'] ?? json['lon'],
    );
    final int? sats = parseInt(json['satellites'] ?? json['sats']);

    // 5. Baterai LiPo
    final int? bat = parseInt(
      json['batteryLevel'] ?? json['battery'] ?? json['bat'],
    );
    final double? batVolt = parseDouble(json['batteryVoltage'] ?? json['volt']);
    final bool charging = parseBool(json['isCharging'] ?? json['charging']);

    // 6. LCD 16x2 + I2C Backpack & Tombol SOS
    final bool isSos = parseBool(
      json['sos'] ??
          json['isSos'] ??
          json['sosButton'] ??
          json['buttonSos'] ??
          json['btnSos'] ??
          json['emergencyButton'] ??
          json['emergencyBtn'],
    );
    final String? l1 =
        json['lcdLine1']?.toString() ??
        json['lcd1']?.toString() ??
        json['line1']?.toString();
    final String? l2 =
        json['lcdLine2']?.toString() ??
        json['lcd2']?.toString() ??
        json['line2']?.toString();
    final String? emerg =
        json['emergencyMessage']?.toString() ??
        json['emergency']?.toString() ??
        json['sosMsg']?.toString() ??
        json['msg']?.toString() ??
        (isSos ? 'TOMBOL SOS AKTIF!' : null);

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
      spo2: oxygen?.clamp(0, 100),
      temperature: temp,
      fallDetected: fall,
      isSos: isSos,
      stepCount: steps,
      roll: rollVal,
      pitch: pitchVal,
      accelG: gForce,
      batteryLevel: bat,
      batteryVoltage: batVolt,
      isCharging: charging,
      satellites: sats,
      lcdLine1: l1,
      lcdLine2: l2,
      emergencyMessage: emerg,
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
    'spo2': spo2,
    'temperature': temperature,
    'fallDetected': fallDetected,
    'sos': isSos,
    'stepCount': stepCount,
    'roll': roll,
    'pitch': pitch,
    'accelG': accelG,
    'batteryLevel': batteryLevel,
    'batteryVoltage': batteryVoltage,
    'isCharging': isCharging,
    'satellites': satellites,
    'lcdLine1': lcdLine1,
    'lcdLine2': lcdLine2,
    'emergencyMessage': emergencyMessage,
    'timestamp': timestamp.toIso8601String(),
    'isValidLocation': isValidLocation,
  };

  @override
  String toString() {
    return 'SmartbandData(braceletId: $braceletId, lat: $latitude, lng: $longitude, hr: $heartRate, spo2: $spo2, temp: $temperature, steps: $stepCount, fall: $fallDetected, sos: $isSos, bat: $batteryLevel%, validLoc: $isValidLocation, lcd: [$displayLcdLine1 | $displayLcdLine2])';
  }
}
