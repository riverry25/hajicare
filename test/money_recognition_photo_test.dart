import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/money/models/money_detection.dart';
import 'package:hajicare/features/money/services/riyal_currency_helper.dart';
import 'package:hajicare/features/money/services/smart_multi_pass_detector.dart';

void main() {
  group('Smart Multi-Pass Money Detection — Acceptance Tests', () {
    // Helper to create MoneyDetection instances
    MoneyDetection createDetection({
      required String className,
      required double confidence,
      required Rect normalizedBox,
    }) {
      final info = RiyalCurrencyHelper.getInfo(className)!;
      return MoneyDetection(
        className: className,
        displayName: info.displayName,
        spokenName: info.spokenName,
        amount: info.amount,
        confidence: confidence,
        box: Rect.fromLTWH(
          normalizedBox.left * 1000,
          normalizedBox.top * 1000,
          normalizedBox.width * 1000,
          normalizedBox.height * 1000,
        ),
        normalizedBox: normalizedBox,
        isCoin: info.isCoin,
      );
    }

    double calculateTotal(List<MoneyDetection> detections) {
      return detections.fold(0.0, (sum, item) => sum + item.amount);
    }

    test('IoU calculation verifies exact overlap and non-overlap', () {
      const boxA = Rect.fromLTWH(0.1, 0.1, 0.2, 0.2); // area = 0.04
      const boxB = Rect.fromLTWH(0.1, 0.1, 0.2, 0.2); // identical -> IoU = 1.0
      expect(
        SmartMultiPassDetector.calculateIoU(boxA, boxB),
        closeTo(1.0, 0.001),
      );

      const boxDisjoint = Rect.fromLTWH(
        0.5,
        0.5,
        0.2,
        0.2,
      ); // disjoint -> IoU = 0.0
      expect(
        SmartMultiPassDetector.calculateIoU(boxA, boxDisjoint),
        equals(0.0),
      );

      const boxPartial = Rect.fromLTWH(0.2, 0.1, 0.2, 0.2); // half overlap
      final iou = SmartMultiPassDetector.calculateIoU(boxA, boxPartial);
      expect(iou, greaterThan(0.2));
      expect(iou, lessThan(0.5));
    });

    test('Test 1: 5 + 10 + 5 + 100 + 5 => 5 detections, Total = 125 Riyal', () {
      final pass1 = [
        createDetection(
          className: 'five riyal',
          confidence: 0.92,
          normalizedBox: const Rect.fromLTWH(0.05, 0.10, 0.20, 0.25),
        ),
        createDetection(
          className: 'ten riyal',
          confidence: 0.88,
          normalizedBox: const Rect.fromLTWH(0.30, 0.10, 0.20, 0.25),
        ),
        createDetection(
          className: 'five riyal',
          confidence: 0.90,
          normalizedBox: const Rect.fromLTWH(0.55, 0.10, 0.20, 0.25),
        ),
        createDetection(
          className: 'one hundred riyal',
          confidence: 0.95,
          normalizedBox: const Rect.fromLTWH(0.10, 0.50, 0.25, 0.30),
        ),
        createDetection(
          className: 'five riyal',
          confidence: 0.85,
          normalizedBox: const Rect.fromLTWH(0.45, 0.50, 0.25, 0.30),
        ),
      ];

      final merged = SmartMultiPassDetector.mergeCrossPassDetections([pass1]);
      final total = calculateTotal(merged);

      expect(merged.length, equals(5));
      expect(total, equals(125.0));
      expect(RiyalCurrencyHelper.formatAmount(total), equals('125 Riyal'));
      expect(
        RiyalCurrencyHelper.totalToSpokenIndonesian(total),
        equals('seratus dua puluh lima Riyal'),
      );
    });

    test('Test 2: 5 + 5 + 5 => 3 detections, Total = 15 Riyal', () {
      final pass1 = [
        createDetection(
          className: 'five riyal',
          confidence: 0.91,
          normalizedBox: const Rect.fromLTWH(0.10, 0.20, 0.20, 0.25),
        ),
        createDetection(
          className: 'five riyal',
          confidence: 0.89,
          normalizedBox: const Rect.fromLTWH(0.40, 0.20, 0.20, 0.25),
        ),
        createDetection(
          className: 'five riyal',
          confidence: 0.94,
          normalizedBox: const Rect.fromLTWH(0.70, 0.20, 0.20, 0.25),
        ),
      ];

      final merged = SmartMultiPassDetector.mergeCrossPassDetections([pass1]);
      final total = calculateTotal(merged);

      expect(merged.length, equals(3));
      expect(total, equals(15.0));
      expect(RiyalCurrencyHelper.formatAmount(total), equals('15 Riyal'));
      expect(
        RiyalCurrencyHelper.totalToSpokenIndonesian(total),
        equals('lima belas Riyal'),
      );
    });

    test('Test 3: 100 => 1 detection, Total = 100 Riyal', () {
      final pass1 = [
        createDetection(
          className: 'one hundred riyal',
          confidence: 0.96,
          normalizedBox: const Rect.fromLTWH(0.25, 0.30, 0.50, 0.40),
        ),
      ];

      final merged = SmartMultiPassDetector.mergeCrossPassDetections([pass1]);
      final total = calculateTotal(merged);

      expect(merged.length, equals(1));
      expect(total, equals(100.0));
      expect(RiyalCurrencyHelper.formatAmount(total), equals('100 Riyal'));
      expect(
        RiyalCurrencyHelper.totalToSpokenIndonesian(total),
        equals('seratus Riyal'),
      );
    });

    test('Test 4: Foto tanpa uang => 0 detections, Total = 0 Riyal', () {
      final List<MoneyDetection> pass1 = [];
      final List<MoneyDetection> pass2 = [];

      final merged = SmartMultiPassDetector.mergeCrossPassDetections([
        pass1,
        pass2,
      ]);
      final total = calculateTotal(merged);

      expect(merged.length, equals(0));
      expect(total, equals(0.0));
      expect(RiyalCurrencyHelper.formatAmount(total), equals('0 Riyal'));
      expect(
        RiyalCurrencyHelper.totalToSpokenIndonesian(total),
        equals('nol Riyal'),
      );
    });

    test(
      'Test 5: Same physical object detected by multiple passes merged into 1 with best confidence',
      () {
        // Physical Object A: detected in Pass 1 (0.84), Pass 2 (0.93), Pass 3 (0.87) at nearly the same bounding box
        const boxA1 = Rect.fromLTWH(0.20, 0.30, 0.30, 0.25);
        const boxA2 = Rect.fromLTWH(
          0.21,
          0.30,
          0.29,
          0.25,
        ); // IoU > 0.85 with boxA1
        const boxA3 = Rect.fromLTWH(
          0.20,
          0.31,
          0.30,
          0.24,
        ); // IoU > 0.85 with boxA1

        final pass1 = [
          createDetection(
            className: 'five riyal',
            confidence: 0.84,
            normalizedBox: boxA1,
          ),
        ];
        final pass2 = [
          createDetection(
            className: 'five riyal',
            confidence: 0.93, // best confidence
            normalizedBox: boxA2,
          ),
        ];
        final pass3 = [
          createDetection(
            className: 'five riyal',
            confidence: 0.87,
            normalizedBox: boxA3,
          ),
        ];

        final merged = SmartMultiPassDetector.mergeCrossPassDetections([
          pass1,
          pass2,
          pass3,
        ]);

        // MUST be exactly 1 object, not 3 duplicate rows
        expect(merged.length, equals(1));
        expect(merged.first.amount, equals(5.0));
        expect(
          merged.first.confidence,
          equals(0.93),
        ); // Preserved highest confidence
      },
    );

    test(
      'Test 6: Two physically separate 5 Riyal objects => 2 detections, 10 Riyal (Do NOT merge)',
      () {
        // Physical Object A (Left side of table)
        const boxA = Rect.fromLTWH(0.10, 0.30, 0.30, 0.25);
        // Physical Object B (Right side of table, completely distinct)
        const boxB = Rect.fromLTWH(0.60, 0.30, 0.30, 0.25);

        final pass1 = [
          createDetection(
            className: 'five riyal',
            confidence: 0.88,
            normalizedBox: boxA,
          ),
          createDetection(
            className: 'five riyal',
            confidence: 0.91,
            normalizedBox: boxB,
          ),
        ];

        final merged = SmartMultiPassDetector.mergeCrossPassDetections([pass1]);

        expect(merged.length, equals(2));
        expect(calculateTotal(merged), equals(10.0));
      },
    );

    test(
      'Test 7: Many money: 5 + 10 + 20 + 5 + 100 + 5 + 10 + 50 => 8 physical objects, TOTAL = 205 Riyal',
      () {
        final pass1 = [
          createDetection(
            className: 'five riyal',
            confidence: 0.89,
            normalizedBox: const Rect.fromLTWH(0.05, 0.05, 0.18, 0.20),
          ),
          createDetection(
            className: 'ten riyal',
            confidence: 0.92,
            normalizedBox: const Rect.fromLTWH(0.28, 0.05, 0.18, 0.20),
          ),
          createDetection(
            className: 'twenty riyal',
            confidence: 0.87,
            normalizedBox: const Rect.fromLTWH(0.51, 0.05, 0.18, 0.20),
          ),
          createDetection(
            className: 'five riyal',
            confidence: 0.90,
            normalizedBox: const Rect.fromLTWH(0.74, 0.05, 0.18, 0.20),
          ),
          createDetection(
            className: 'one hundred riyal',
            confidence: 0.95,
            normalizedBox: const Rect.fromLTWH(0.05, 0.50, 0.18, 0.20),
          ),
          createDetection(
            className: 'five riyal',
            confidence: 0.88,
            normalizedBox: const Rect.fromLTWH(0.28, 0.50, 0.18, 0.20),
          ),
          createDetection(
            className: 'ten riyal',
            confidence: 0.91,
            normalizedBox: const Rect.fromLTWH(0.51, 0.50, 0.18, 0.20),
          ),
          createDetection(
            className: 'fifty riyal',
            confidence: 0.94,
            normalizedBox: const Rect.fromLTWH(0.74, 0.50, 0.18, 0.20),
          ),
        ];

        final merged = SmartMultiPassDetector.mergeCrossPassDetections([pass1]);
        final total = calculateTotal(merged);

        // Expected: 8 physical objects
        expect(merged.length, equals(8));
        // Expected total: 5 + 10 + 20 + 5 + 100 + 5 + 10 + 50 = 205
        expect(total, equals(205.0));
        expect(RiyalCurrencyHelper.formatAmount(total), equals('205 Riyal'));
      },
    );

    test(
      'Multi-pass candidate confirmation: weak candidate (<0.65) confirmed across 2 passes is boosted and kept',
      () {
        const box = Rect.fromLTWH(0.25, 0.25, 0.30, 0.30);

        // Pass 1 found it at 0.58 (below 0.65 threshold)
        final pass1 = [
          createDetection(
            className: 'twenty riyal',
            confidence: 0.58,
            normalizedBox: box,
          ),
        ];

        // Pass 2 also confirmed the same object at 0.60
        final pass2 = [
          createDetection(
            className: 'twenty riyal',
            confidence: 0.60,
            normalizedBox: box,
          ),
        ];

        final merged = SmartMultiPassDetector.mergeCrossPassDetections([
          pass1,
          pass2,
        ]);

        // Confirmed by 2 passes -> boosted to >= 0.65 -> included in final result!
        expect(merged.length, equals(1));
        expect(merged.first.amount, equals(20.0));
        expect(merged.first.confidence, greaterThanOrEqualTo(0.65));
      },
    );

    test(
      'Single unconfirmed weak candidate (<0.65) in only one pass is dropped',
      () {
        const box = Rect.fromLTWH(0.25, 0.25, 0.30, 0.30);

        // Only Pass 1 found a weak candidate at 0.52
        final pass1 = [
          createDetection(
            className: 'twenty riyal',
            confidence: 0.52,
            normalizedBox: box,
          ),
        ];

        final merged = SmartMultiPassDetector.mergeCrossPassDetections([pass1]);

        // Unconfirmed and < 0.65 -> dropped to prevent false positives!
        expect(merged.length, equals(0));
      },
    );
  });
}
