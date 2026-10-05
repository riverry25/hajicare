import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/smartband/models/smartband_data.dart';
import 'package:hajicare/features/smartband/services/smartband_ble_service.dart';

void main() {
  group('SmartbandData Model Tests', () {
    test('Parse JSON valid dari ESP32 dengan koordinat dan BPM', () {
      const jsonString = '''
      {
        "braceletId": "HCG-001",
        "latitude": -6.140214,
        "longitude": 106.232288,
        "heartRate": 82
      }
      ''';

      final data = SmartbandData.fromRawJson(jsonString);

      expect(data.braceletId, equals('HCG-001'));
      expect(data.latitude, equals(-6.140214));
      expect(data.longitude, equals(106.232288));
      expect(data.heartRate, equals(82));
      expect(data.isValidLocation, isTrue);
    });

    test(
      'Parse JSON dengan BPM = 0 (sensor belum memperoleh detak jantung)',
      () {
        const jsonString = '''
      {
        "braceletId": "HCG-001",
        "latitude": -6.140310,
        "longitude": 106.232410,
        "heartRate": 0
      }
      ''';

        final data = SmartbandData.fromRawJson(jsonString);

        expect(data.braceletId, equals('HCG-001'));
        expect(data.latitude, closeTo(-6.140310, 0.000001));
        expect(data.longitude, closeTo(106.232410, 0.000001));
        expect(data.heartRate, equals(0));
        expect(data.isValidLocation, isTrue);
      },
    );

    test('Koordinat 0.0, 0.0 tidak dianggap sebagai lokasi valid', () {
      final jsonMap = {
        'braceletId': 'HCG-001',
        'latitude': 0.0,
        'longitude': 0.0,
        'heartRate': 75,
      };

      final data = SmartbandData.fromJson(jsonMap);

      expect(data.braceletId, equals('HCG-001'));
      expect(data.isValidLocation, isFalse);
    });

    test('Throw FormatException jika braceletId kosong atau null', () {
      final jsonMap = {
        'latitude': -6.140214,
        'longitude': 106.232288,
        'heartRate': 80,
      };

      expect(() => SmartbandData.fromJson(jsonMap), throwsFormatException);
    });

    test('Toleransi jika nilai latitude/longitude bertipe string angka', () {
      final jsonMap = {
        'braceletId': 'HCG-001',
        'latitude': '-6.140214',
        'longitude': '106.232288',
        'heartRate': '85',
      };

      final data = SmartbandData.fromJson(jsonMap);

      expect(data.braceletId, equals('HCG-001'));
      expect(data.latitude, equals(-6.140214));
      expect(data.longitude, equals(106.232288));
      expect(data.heartRate, equals(85));
      expect(data.isValidLocation, isTrue);
    });
  });

  group('SmartbandBleService Constants Tests', () {
    test('Target Device Name dan UUID sesuai spesifikasi ESP32-S3', () {
      expect(
        SmartbandBleService.targetDeviceName,
        equals('HajiCare-Gelang-001'),
      );
      expect(SmartbandBleService.targetBraceletId, equals('HCG-001'));
      expect(
        SmartbandBleService.serviceUuid,
        equals('6e400001-b5a3-f393-e0a9-e50e24dcca9e'),
      );
      expect(
        SmartbandBleService.dataCharacteristicUuid,
        equals('6e400003-b5a3-f393-e0a9-e50e24dcca9e'),
      );
    });
  });
}
