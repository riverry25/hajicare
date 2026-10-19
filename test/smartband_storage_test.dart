import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/smartband/models/smartband_data.dart';
import 'package:hajicare/features/smartband/services/smartband_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SmartbandStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = SmartbandStorageService.instance;
    await storage.init();
  });

  tearDown(() async {
    await storage.clearAll();
  });

  group('SmartbandStorageService Unit Tests', () {
    test('Initial state has no stored data', () {
      final snapshot = storage.loadStoredData();
      expect(snapshot.hasAnyData, isFalse);
      expect(snapshot.heartRate, isNull);
      expect(snapshot.stepCount, isNull);
      expect(storage.hasStoredData, isFalse);
    });

    test(
      'saveSmartbandData persisten data telemetri ke local storage',
      () async {
        final data = SmartbandData(
          braceletId: 'HCG-TEST-001',
          heartRate: 78,
          spo2: 98,
          temperature: 36.6,
          stepCount: 2540,
          latitude: 21.4225,
          longitude: 39.8262,
          batteryLevel: 85,
          batteryVoltage: 3.95,
          satellites: 8,
          roll: 1.5,
          pitch: -2.0,
          accelG: 1.01,
          timestamp: DateTime(2026, 10, 18, 0, 0, 0),
          rawJson: '{"test":true}',
        );

        await storage.saveSmartbandData(data);

        expect(storage.hasStoredData, isTrue);

        final snapshot = storage.loadStoredData();
        expect(snapshot.hasAnyData, isTrue);
        expect(snapshot.braceletId, equals('HCG-TEST-001'));
        expect(snapshot.heartRate, equals(78));
        expect(snapshot.spo2, equals(98));
        expect(snapshot.temperature, equals(36.6));
        expect(snapshot.stepCount, equals(2540));
        expect(snapshot.lastKnownLatitude, equals(21.4225));
        expect(snapshot.lastKnownLongitude, equals(39.8262));
        expect(snapshot.wasGpsFix, isTrue);
        expect(snapshot.batteryPercent, equals(85));
        expect(snapshot.batteryVoltage, equals(3.95));
        expect(snapshot.gpsSatellites, equals(8));
        expect(snapshot.gyroRoll, equals(1.5));
        expect(snapshot.gyroPitch, equals(-2.0));
        expect(snapshot.accelG, equals(1.01));
        expect(snapshot.lastRawJson, equals('{"test":true}'));
      },
    );

    test('saveStepCount mengupdate step count secara independen', () async {
      await storage.saveStepCount(1234);

      final snapshot = storage.loadStoredData();
      expect(snapshot.stepCount, equals(1234));
      expect(snapshot.hasAnyData, isTrue);
    });

    test('saveStabilityScore mengupdate stability score', () async {
      await storage.saveStabilityScore(95);

      final snapshot = storage.loadStoredData();
      expect(snapshot.stabilityScore, equals(95));
    });

    test('clearAll membersihkan semua data telemetri smartband', () async {
      final data = SmartbandData(
        braceletId: 'HCG-TEST-002',
        heartRate: 80,
        spo2: 99,
        temperature: 36.7,
        stepCount: 4000,
      );

      await storage.saveSmartbandData(data);
      expect(storage.hasStoredData, isTrue);

      await storage.clearAll();

      final snapshot = storage.loadStoredData();
      expect(snapshot.hasAnyData, isFalse);
      expect(snapshot.heartRate, isNull);
      expect(snapshot.stepCount, isNull);
      expect(storage.hasStoredData, isFalse);
    });
  });
}
