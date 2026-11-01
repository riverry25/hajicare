import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/models/jamaah_data.dart';
import 'package:hajicare/features/room/models/room_member_model.dart';

void main() {
  group('Smartband Telemetry & Critical Anomaly Detection Tests', () {
    test('JamaahData parses smartband map from Firestore correctly', () {
      final jamaah = JamaahData(
        id: 'user_123',
        name: 'Ahmad Fauzi',
        shortLabel: 'Ahmad',
        distance: 15.0,
        heartRate: 78,
        temperature: 36.6,
        spo2: 98,
        fallDetected: false,
        fallStatus: 'NORMAL',
        batteryLevel: 92,
        braceletId: 'HCG-007',
        isSmartbandConnected: true,
      );

      expect(jamaah.hasSmartbandData, isTrue);
      expect(jamaah.braceletId, 'HCG-007');
      expect(jamaah.heartRate, 78);
      expect(jamaah.temperature, 36.6);
      expect(jamaah.spo2, 98);
      expect(jamaah.fallDetected, isFalse);
      expect(jamaah.batteryLevel, 92);
      expect(jamaah.isHeartRateCritical, isFalse);
      expect(jamaah.isTemperatureCritical, isFalse);
      expect(jamaah.isSpo2Critical, isFalse);
      expect(jamaah.isFallen, isFalse);
      expect(jamaah.hasCriticalAnomaly, isFalse);
    });

    test('Critical anomaly flags trigger correctly on high/low vitals and fall', () {
      // 1. Tachycardia (HR > 120)
      final tachyJamaah = JamaahData(
        id: 'j1',
        name: 'Jamaah HR',
        shortLabel: 'HR',
        distance: 10.0,
        heartRate: 135,
      );
      expect(tachyJamaah.isHeartRateCritical, isTrue);
      expect(tachyJamaah.hasCriticalAnomaly, isTrue);

      // 2. Bradycardia (HR < 45)
      final bradyJamaah = JamaahData(
        id: 'j2',
        name: 'Jamaah Brady',
        shortLabel: 'Brady',
        distance: 10.0,
        heartRate: 40,
      );
      expect(bradyJamaah.isHeartRateCritical, isTrue);
      expect(bradyJamaah.hasCriticalAnomaly, isTrue);

      // 3. Heatstroke (Temp > 38.5)
      final heatstrokeJamaah = JamaahData(
        id: 'j3',
        name: 'Jamaah Heat',
        shortLabel: 'Heat',
        distance: 10.0,
        temperature: 39.4,
      );
      expect(heatstrokeJamaah.isTemperatureCritical, isTrue);
      expect(heatstrokeJamaah.hasCriticalAnomaly, isTrue);

      // 4. Hypothermia (Temp < 35.0)
      final hypoJamaah = JamaahData(
        id: 'j4',
        name: 'Jamaah Hypo',
        shortLabel: 'Hypo',
        distance: 10.0,
        temperature: 34.2,
      );
      expect(hypoJamaah.isTemperatureCritical, isTrue);
      expect(hypoJamaah.hasCriticalAnomaly, isTrue);

      // 5. Hypoxia (SpO2 < 90)
      final hypoxiaJamaah = JamaahData(
        id: 'j5',
        name: 'Jamaah O2',
        shortLabel: 'O2',
        distance: 10.0,
        spo2: 87,
      );
      expect(hypoxiaJamaah.isSpo2Critical, isTrue);
      expect(hypoxiaJamaah.hasCriticalAnomaly, isTrue);

      // 6. Fall Detected (MPU6050)
      final fallenJamaah = JamaahData(
        id: 'j6',
        name: 'Jamaah Fall',
        shortLabel: 'Fall',
        distance: 10.0,
        fallDetected: true,
        fallStatus: 'FALLEN',
      );
      expect(fallenJamaah.isFallen, isTrue);
      expect(fallenJamaah.hasCriticalAnomaly, isTrue);

      // 7. Safe Radius Breach (>50m)
      final outRadiusJamaah = JamaahData(
        id: 'j7',
        name: 'Jamaah Far',
        shortLabel: 'Far',
        distance: 120.0,
      );
      expect(outRadiusJamaah.isOutOfSafeRadius, isTrue);
      expect(outRadiusJamaah.hasAnyWarningOrAnomaly, isTrue);
    });

    test('RoomMemberModel correctly retains smartband telemetry data', () {
      const member = RoomMemberModel(
        uid: 'mem_001',
        name: 'Hj. Siti',
        role: 'jamaah',
        braceletId: 'HCG-088',
        heartRate: 82,
        temperature: 37.1,
        spo2: 97,
        fallDetected: false,
        fallStatus: 'NORMAL',
        batteryLevel: 85,
      );

      expect(member.name, 'Hj. Siti');
      expect(member.braceletId, 'HCG-088');
      expect(member.heartRate, 82);
      expect(member.temperature, 37.1);
      expect(member.spo2, 97);
      expect(member.fallDetected, isFalse);
      expect(member.fallStatus, 'NORMAL');
      expect(member.batteryLevel, 85);
    });
  });
}
