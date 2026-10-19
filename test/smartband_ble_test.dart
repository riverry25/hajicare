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

    test('MAX30102: Membaca Heart Rate (BPM) dan Oksigen Darah (SpO2)', () {
      final jsonMap = {'braceletId': 'HCG-001', 'heartRate': 76, 'spo2': 98};

      final data = SmartbandData.fromJson(jsonMap);
      expect(data.heartRate, equals(76));
      expect(data.spo2, equals(98));
      expect(data.isValidSpo2, isTrue);
      expect(data.hasValidVitals, isTrue);

      // Alias SpO2 key 'oxygen'
      final jsonAlias = {'braceletId': 'HCG-001', 'bpm': 80, 'oxygen': 99};
      final dataAlias = SmartbandData.fromJson(jsonAlias);
      expect(dataAlias.heartRate, equals(80));
      expect(dataAlias.spo2, equals(99));
      expect(dataAlias.isValidSpo2, isTrue);
    });

    test('MCP9808: Membaca Suhu Tubuh Jemaah Presisi (°C)', () {
      final jsonMap = {'braceletId': 'HCG-001', 'temperature': 36.65};

      final data = SmartbandData.fromJson(jsonMap);
      expect(data.temperature, closeTo(36.65, 0.01));
      expect(data.isValidTemperature, isTrue);

      // Alias key 'bodyTemp'
      final jsonAlias = {'braceletId': 'HCG-001', 'bodyTemp': 37.10};
      final dataAlias = SmartbandData.fromJson(jsonAlias);
      expect(dataAlias.temperature, closeTo(37.10, 0.01));
      expect(dataAlias.isValidTemperature, isTrue);
    });

    test('MPU6050: Deteksi Langkah dan Insiden Jatuh (Fall Detection)', () {
      final jsonMap = {
        'braceletId': 'HCG-001',
        'stepCount': 3420,
        'isFallDetected': true,
        'gyroRoll': 68.5,
        'gyroPitch': -45.2,
        'accelG': 2.85,
      };

      final data = SmartbandData.fromJson(jsonMap);
      expect(data.stepCount, equals(3420));
      expect(data.isFallDetected, isTrue);
      expect(data.gyroRoll, closeTo(68.5, 0.1));
      expect(data.gyroPitch, closeTo(-45.2, 0.1));
      expect(data.accelG, closeTo(2.85, 0.01));

      // Alias key 'langkah' dan 'steps'
      final jsonAlias = {'braceletId': 'HCG-001', 'langkah': 5120};
      final dataAlias = SmartbandData.fromJson(jsonAlias);
      expect(dataAlias.stepCount, equals(5120));
    });

    test('GPS NEO-6M: Melacak Titik Satelit Dinamis Latitude & Longitude', () {
      final jsonMap = {
        'braceletId': 'HCG-001',
        'latitude': 21.422510,
        'longitude': 39.826220,
        'satellites': 9,
      };

      final data = SmartbandData.fromJson(jsonMap);
      expect(data.latitude, closeTo(21.422510, 0.000001));
      expect(data.longitude, closeTo(39.826220, 0.000001));
      expect(data.satellites, equals(9));
      expect(data.isValidLocation, isTrue);

      // Kasus tanpa sinyal satelit (GPS searching)
      final noGps = SmartbandData.fromJson({'braceletId': 'HCG-001'});
      expect(noGps.latitude, isNull);
      expect(noGps.longitude, isNull);
      expect(noGps.isValidLocation, isFalse);
    });

    test('LCD 16x2 + I2C: Format 16 Karakter Baris 1 & 2', () {
      final normalData = SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 78,
        spo2: 98,
        temperature: 36.6,
      );

      // Baris 1 harus persis 16 karakter
      expect(normalData.displayLcdLine1.length, equals(16));
      expect(normalData.displayLcdLine1, equals('HR: 78  SpO2:98%'));

      // Baris 2 status normal harus persis 16 karakter
      expect(normalData.displayLcdLine2.length, equals(16));
      expect(normalData.displayLcdLine2, equals('T:36.6C NORMAL  '));

      // Baris 2 ketika jatuh terdeteksi
      final fallData = normalData.copyWith(isFallDetected: true);
      expect(fallData.displayLcdLine2.length, equals(16));
      expect(fallData.displayLcdLine2, equals('!JATUH DETEKSI !'));

      // Baris 2 ketika ada pesan darurat
      final emergencyData = normalData.copyWith(
        emergencyMessage: 'MINUM AIR SEGERA',
      );
      expect(emergencyData.displayLcdLine2.length, equals(16));
      expect(emergencyData.displayLcdLine2, equals('MINUM AIR SEGERA'));

      // Baris 2 ketika pesan melebihi 16 karakter (terpotong aman)
      final longMsgData = normalData.copyWith(
        emergencyMessage: 'PESAN DARURAT SANGAT PANJANG MELEBIHI ENAM BELAS',
      );
      expect(longMsgData.displayLcdLine2.length, equals(16));
      expect(longMsgData.displayLcdLine2, equals('PESAN DARURAT SA'));
    });

    test('ESP32 BLE Full 5-Module Data Packet Parsing', () {
      const fullBlePayload = '''
      {
        "braceletId": "HCG-001",
        "heartRate": 74,
        "spo2": 99,
        "temperature": 36.72,
        "stepCount": 4250,
        "isFallDetected": false,
        "gyroRoll": 2.1,
        "gyroPitch": -1.4,
        "accelG": 1.02,
        "latitude": 21.422530,
        "longitude": 39.826240,
        "satellites": 10,
        "lcdLine1": "HAJICARE ESP32  ",
        "lcdLine2": "STATUS: AMAN OK "
      }
      ''';

      final data = SmartbandData.fromRawJson(fullBlePayload);

      // Module 1: MAX30102
      expect(data.heartRate, equals(74));
      expect(data.spo2, equals(99));

      // Module 2: MCP9808
      expect(data.temperature, closeTo(36.72, 0.01));

      // Module 3: MPU6050
      expect(data.stepCount, equals(4250));
      expect(data.isFallDetected, isFalse);
      expect(data.gyroRoll, closeTo(2.1, 0.1));

      // Module 4: GPS NEO-6M
      expect(data.latitude, closeTo(21.422530, 0.000001));
      expect(data.longitude, closeTo(39.826240, 0.000001));
      expect(data.satellites, equals(10));

      // Module 5: LCD 16x2
      expect(data.displayLcdLine1, equals('HAJICARE ESP32  '));
      expect(data.displayLcdLine2, equals('STATUS: AMAN OK '));
    });

    test('ESP32 WROOM-32 Arduino Firmware Payload Format Parsing', () {
      const arduinoPayload = '''
      {
        "braceletId": "HCG-001",
        "heartRate": 78,
        "spo2": 97,
        "fingerDetected": true,
        "temperatureC": 36.85,
        "batteryLevel": 94,
        "batteryVoltage": 4.10,
        "motionG": 1.15,
        "stepCount": 128,
        "roll": 3.4,
        "pitch": -2.1,
        "gpsFix": true,
        "satellites": 8,
        "latitude": 21.422550,
        "longitude": 39.826260,
        "fallStatus": "FALL_CONFIRMED",
        "sos": true
      }
      ''';

      final data = SmartbandData.fromRawJson(arduinoPayload);

      expect(data.braceletId, equals('HCG-001'));
      expect(data.heartRate, equals(78));
      expect(data.spo2, equals(97));
      expect(data.temperature, closeTo(36.85, 0.01));
      expect(data.batteryLevel, equals(94));
      expect(data.batteryVoltage, closeTo(4.10, 0.01));
      expect(data.accelG, closeTo(1.15, 0.01));
      expect(data.stepCount, equals(128));
      expect(data.roll, closeTo(3.4, 0.1));
      expect(data.pitch, closeTo(-2.1, 0.1));
      expect(data.isFallDetected, isTrue);
      expect(data.isSos, isTrue);
      expect(data.sos, isTrue);
      expect(data.sosButtonPressed, isTrue);
      expect(data.displayLcdLine2, contains('TOMBOL SOS'));
      expect(data.emergencyMessage, equals('TOMBOL SOS AKTIF!'));
      expect(data.latitude, closeTo(21.422550, 0.000001));
      expect(data.longitude, closeTo(39.826260, 0.000001));
      expect(data.satellites, equals(8));
      expect(data.isValidLocation, isTrue);
    });

    test('Tombol SOS: parsing berbagai varian key payload JSON', () {
      final json1 = {'braceletId': 'HCG-001', 'heartRate': 75, 'sos': true};
      final json2 = {'braceletId': 'HCG-001', 'heartRate': 75, 'isSos': 1};
      final json3 = {
        'braceletId': 'HCG-001',
        'heartRate': 75,
        'sosButton': 'true',
      };
      final json4 = {
        'braceletId': 'HCG-001',
        'heartRate': 75,
        'emergencyButton': true,
      };
      final json5 = {'braceletId': 'HCG-001', 'heartRate': 75, 'sos': false};

      expect(SmartbandData.fromJson(json1).isSos, isTrue);
      expect(SmartbandData.fromJson(json2).isSos, isTrue);
      expect(SmartbandData.fromJson(json3).isSos, isTrue);
      expect(SmartbandData.fromJson(json4).isSos, isTrue);
      expect(SmartbandData.fromJson(json5).isSos, isFalse);
    });

    test('Serialisasi toJson menyertakan field sos', () {
      final data = SmartbandData(
        braceletId: 'HCG-001',
        heartRate: 75,
        isSos: true,
      );
      final jsonMap = data.toJson();
      expect(jsonMap['sos'], isTrue);
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
