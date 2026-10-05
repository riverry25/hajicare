import 'dart:convert';

/// Model representasi data telemetri dari ESP32-S3 Smartband
/// Format JSON yang diterima:
/// {
///   "braceletId": "HCG-001",
///   "latitude": -6.140214,
///   "longitude": 106.232288,
///   "heartRate": 82
/// }
class SmartbandData {
  final String braceletId;
  final double? latitude;
  final double? longitude;
  final int heartRate;
  final DateTime timestamp;
  final String rawJson;
  final bool isValidLocation;

  const SmartbandData({
    required this.braceletId,
    this.latitude,
    this.longitude,
    required this.heartRate,
    required this.timestamp,
    this.rawJson = '',
    this.isValidLocation = false,
  });

  /// Factory untuk mem-parse JSON payload dari BLE notification
  /// Melempar [FormatException] jika JSON rusak atau field wajib tidak tersedia
  factory SmartbandData.fromJson(Map<String, dynamic> json, {String raw = ''}) {
    final bId = json['braceletId']?.toString().trim();
    if (bId == null || bId.isEmpty) {
      throw const FormatException(
        'Field "braceletId" tidak ditemukan atau kosong',
      );
    }

    double? lat;
    if (json['latitude'] != null) {
      if (json['latitude'] is num) {
        lat = (json['latitude'] as num).toDouble();
      } else {
        lat = double.tryParse(json['latitude'].toString());
      }
    }

    double? lng;
    if (json['longitude'] != null) {
      if (json['longitude'] is num) {
        lng = (json['longitude'] as num).toDouble();
      } else {
        lng = double.tryParse(json['longitude'].toString());
      }
    }

    int hr = 0;
    if (json['heartRate'] != null) {
      if (json['heartRate'] is num) {
        hr = (json['heartRate'] as num).toInt();
      } else {
        hr = int.tryParse(json['heartRate'].toString()) ?? 0;
      }
    }

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
    'timestamp': timestamp.toIso8601String(),
    'isValidLocation': isValidLocation,
  };

  @override
  String toString() {
    return 'SmartbandData(braceletId: $braceletId, lat: $latitude, lng: $longitude, hr: $heartRate, validLoc: $isValidLocation)';
  }
}
