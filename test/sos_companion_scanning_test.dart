import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/routes/app_routes.dart';
import 'package:hajicare/features/sos/models/candidate_companion.dart';
import 'package:hajicare/features/sos/screens/sos_companion_scanning_screen.dart';

void main() {
  group('SOS Companion Scanning & Radar Tests', () {
    test('AppRoutes registers sosScanning route correctly', () {
      expect(AppRoutes.sosScanning, '/sos_scanning');
      final page = AppRoutes.pages.firstWhere(
        (p) => p.name == AppRoutes.sosScanning,
        orElse: () => throw StateError('sosScanning page not found'),
      );
      expect(page.name, '/sos_scanning');
    });

    test('CandidateCompanion calculates formattedDistance accurately', () {
      const near = CandidateCompanion(
        uid: 'p1',
        name: 'Ust. Abdullah',
        distanceMeters: 250.4,
      );
      expect(near.formattedDistance, '± 250 meter');

      const far = CandidateCompanion(
        uid: 'p2',
        name: 'Ust. Salman',
        distanceMeters: 1500.0,
      );
      expect(far.formattedDistance, '± 1.5 km');

      const unknown = CandidateCompanion(
        uid: 'p3',
        name: 'Ust. Zaki',
        distanceMeters: null,
      );
      expect(unknown.formattedDistance, 'Jarak tidak diketahui');
    });

    test('CandidateCompanion radar radius ratio stays within [0.2, 0.85]', () {
      const zeroDist = CandidateCompanion(
        uid: 'p0',
        name: 'Test',
        distanceMeters: 0,
      );
      expect(zeroDist.getRadarRadiusRatio(), 0.25);

      const closeDist = CandidateCompanion(
        uid: 'p1',
        name: 'Test',
        distanceMeters: 30,
      );
      final r1 = closeDist.getRadarRadiusRatio(2000);
      expect(r1, greaterThanOrEqualTo(0.2));
      expect(r1, lessThanOrEqualTo(0.85));

      const farDist = CandidateCompanion(
        uid: 'p2',
        name: 'Test',
        distanceMeters: 5000,
      );
      final r2 = farDist.getRadarRadiusRatio(2000);
      expect(r2, 0.85); // Clamped to 0.85
    });

    test('CandidateCompanion bearing to radar angle conversion', () {
      const north = CandidateCompanion(
        uid: 'p1',
        name: 'North',
        bearingDegrees: 0,
      );
      expect(north.getRadarAngleRadians(), 0.0);

      const east = CandidateCompanion(
        uid: 'p2',
        name: 'East',
        bearingDegrees: 90,
      );
      expect(east.getRadarAngleRadians(), closeTo(math.pi / 2, 0.001));

      const south = CandidateCompanion(
        uid: 'p3',
        name: 'South',
        bearingDegrees: 180,
      );
      expect(south.getRadarAngleRadians(), closeTo(math.pi, 0.001));
    });

    test('Candidate list sorts closest candidates first', () {
      final candidates = [
        const CandidateCompanion(uid: 'c1', name: 'Far', distanceMeters: 800),
        const CandidateCompanion(
          uid: 'c2',
          name: 'NoLocation',
          distanceMeters: null,
        ),
        const CandidateCompanion(
          uid: 'c3',
          name: 'Closest',
          distanceMeters: 120,
        ),
        const CandidateCompanion(
          uid: 'c4',
          name: 'Medium',
          distanceMeters: 450,
        ),
      ];

      candidates.sort((a, b) {
        if (a.distanceMeters == null && b.distanceMeters == null) return 0;
        if (a.distanceMeters == null) return 1;
        if (b.distanceMeters == null) return -1;
        return a.distanceMeters!.compareTo(b.distanceMeters!);
      });

      expect(candidates.first.name, 'Closest');
      expect(candidates[1].name, 'Medium');
      expect(candidates[2].name, 'Far');
      expect(candidates.last.name, 'NoLocation');
    });

    test('Radar state enum has all required detection phases', () {
      expect(SosScanningState.values, contains(SosScanningState.detectingGps));
      expect(
        SosScanningState.values,
        contains(SosScanningState.scanningCompanions),
      );
      expect(
        SosScanningState.values,
        contains(SosScanningState.searchingClosest),
      );
      expect(
        SosScanningState.values,
        contains(SosScanningState.companionFound),
      );
      expect(
        SosScanningState.values,
        contains(SosScanningState.noCompanionAvailable),
      );
    });
  });
}
