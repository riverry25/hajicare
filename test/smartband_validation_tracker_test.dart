import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hajicare/features/smartband/services/smartband_validation_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SmartbandValidationTrackerService.instance.init();
    await SmartbandValidationTrackerService.instance.clearAllLogs();
  });

  group('SmartbandValidationTrackerService Unit Tests', () {
    test(
      '1. Mencatat Uji Fungsional Komponen Aktual (MAX30102, Suhu, MPU, SOS, Motor, OLED)',
      () async {
        final tracker = SmartbandValidationTrackerService.instance;

        // Log MAX30102
        await tracker.logComponentTest(
          component: 'MAX30102',
          parameter: 'Denyut jantung & SpO₂',
          referenceStandard: 'Pulse Oximeter medis',
          measuredValue: 'HR: 76 BPM, SpO₂: 98%',
          isSuccess: true,
          indicatorResult: 'Berhasil membaca denyut kontinu',
        );

        final summary = tracker.getComponentSummary('MAX30102');
        expect(summary['total'], equals(1));
        expect(summary['successCount'], equals(1));
        expect(summary['successRate'], equals(100.0));
        expect(summary['lastMeasured'], equals('HR: 76 BPM, SpO₂: 98%'));
      },
    );

    test(
      '2. Mencatat Uji Akurasi Fisiologis dan Menghitung Absolute Error',
      () async {
        final tracker = SmartbandValidationTrackerService.instance;

        // Heart Rate: Ref 75.0, Band 76.0 -> Absolute Error 1.0
        await tracker.logPhysiologicalTest(
          measurementType: 'Heart Rate',
          referenceValue: 75.0,
          bandValue: 76.0,
          unit: 'BPM',
        );

        // Temperature: Ref 36.5, Band 36.6 -> Absolute Error 0.1
        await tracker.logPhysiologicalTest(
          measurementType: 'Temperature',
          referenceValue: 36.5,
          bandValue: 36.6,
          unit: '°C',
        );

        final hrSummary = tracker.getPhysiologicalSummary('Heart Rate');
        expect(hrSummary['total'], equals(1));
        expect(hrSummary['avgReference'], equals(75.0));
        expect(hrSummary['avgBand'], equals(76.0));
        expect(hrSummary['avgAbsoluteError'], closeTo(1.0, 0.01));

        final tempSummary = tracker.getPhysiologicalSummary('Temperature');
        expect(tempSummary['total'], equals(1));
        expect(tempSummary['avgReference'], equals(36.5));
        expect(tempSummary['avgBand'], equals(36.6));
        expect(tempSummary['avgAbsoluteError'], closeTo(0.1, 0.01));
      },
    );

    test('3. Mencatat dan Menghitung Ringkasan GPS Smart Band', () async {
      final tracker = SmartbandValidationTrackerService.instance;

      await tracker.logGpsTest(
        latitude: 21.422487,
        longitude: 39.826206,
        satellites: 8,
        durationSeconds: 2.5,
        errorMeters: 3.2,
        isValidLocation: true,
      );

      final gpsSummary = tracker.getGpsSummary();
      expect(gpsSummary['total'], equals(1));
      expect(gpsSummary['validRate'], equals(100.0));
      expect(gpsSummary['medianError'], equals(3.2));
      expect(gpsSummary['medianTime'], equals(2.5));
    });
  });
}
