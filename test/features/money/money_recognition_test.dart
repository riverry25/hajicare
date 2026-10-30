import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/money/models/currency_code.dart';
import 'package:hajicare/features/money/models/money_detection.dart';
import 'package:hajicare/features/money/services/currency_rate_service.dart';
import 'package:hajicare/features/money/services/money_aggregator.dart';
import 'package:hajicare/features/money/services/money_class_parser.dart';
import 'package:hajicare/features/money/services/smart_multi_pass_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Money Class Parser Tests', () {
    test('Correctly maps SAR banknotes and coins', () {
      final oneRiyal = MoneyClassParser.parse('one riyal');
      expect(oneRiyal, isNotNull);
      expect(oneRiyal!.currency, CurrencyCode.sar);
      expect(oneRiyal.amount, 1.0);
      expect(oneRiyal.isCoin, isFalse);

      final fiftyRiyal = MoneyClassParser.parse('fifty riyal');
      expect(fiftyRiyal, isNotNull);
      expect(fiftyRiyal!.currency, CurrencyCode.sar);
      expect(fiftyRiyal.amount, 50.0);

      final tenHalalas = MoneyClassParser.parse('ten halalas');
      expect(tenHalalas, isNotNull);
      expect(tenHalalas!.currency, CurrencyCode.sar);
      expect(tenHalalas.amount, 0.10);
      expect(tenHalalas.isCoin, isTrue);
    });

    test('Correctly maps IDR and USD denominations', () {
      final seratusRibu = MoneyClassParser.parse('one hundred thousand rupiah');
      expect(seratusRibu, isNotNull);
      expect(seratusRibu!.currency, CurrencyCode.idr);
      expect(seratusRibu.amount, 100000.0);

      final twentyDollar = MoneyClassParser.parse('twenty dollar');
      expect(twentyDollar, isNotNull);
      expect(twentyDollar!.currency, CurrencyCode.usd);
      expect(twentyDollar.amount, 20.0);
    });
  });

  group('Cross-Pass Deduplication & Accuracy Tests', () {
    test('Merges same physical object across passes and boosts confidence', () {
      final pass1 = [
        const MoneyDetection(
          className: 'fifty riyal',
          currency: CurrencyCode.sar,
          displayName: '50 SAR',
          spokenName: 'lima puluh Riyal',
          amount: 50.0,
          confidence: 0.50,
          box: Rect.fromLTWH(100, 100, 300, 150),
          normalizedBox: Rect.fromLTWH(0.2, 0.2, 0.5, 0.3),
        ),
      ];

      final pass2 = [
        const MoneyDetection(
          className: 'fifty riyal',
          currency: CurrencyCode.sar,
          displayName: '50 SAR',
          spokenName: 'lima puluh Riyal',
          amount: 50.0,
          confidence: 0.54,
          box: Rect.fromLTWH(102, 98, 298, 152),
          normalizedBox: Rect.fromLTWH(0.204, 0.196, 0.496, 0.304),
        ),
      ];

      final result = SmartMultiPassDetector.mergeCrossPassDetections(
        [pass1, pass2],
        finalThreshold: 0.58,
        candidateThreshold: 0.42,
        iouThreshold: 0.45,
        conflictIoUThreshold: 0.48,
      );

      // Even though individual passes were 0.50 and 0.54 (< 0.58),
      // cross-pass confirmation boosts confidence by +0.12 (0.54 + 0.12 = 0.66 >= 0.58)
      expect(result.length, 1);
      expect(result.first.displayName, '50 SAR');
      expect(result.first.confidence, greaterThanOrEqualTo(0.58));
    });

    test('Suppresses conflicting denominations on the same physical bill (no double counting)', () {
      // Scenario: YOLO outputs two conflicting detections for the exact same physical bill:
      // "ten riyal" with 0.72 confidence and "fifty riyal" with 0.46 confidence.
      final detections = [
        const MoneyDetection(
          className: 'ten riyal',
          currency: CurrencyCode.sar,
          displayName: '10 SAR',
          spokenName: 'sepuluh Riyal',
          amount: 10.0,
          confidence: 0.72,
          box: Rect.fromLTWH(100, 100, 300, 150),
          normalizedBox: Rect.fromLTWH(0.2, 0.2, 0.5, 0.3),
        ),
        const MoneyDetection(
          className: 'fifty riyal',
          currency: CurrencyCode.sar,
          displayName: '50 SAR',
          spokenName: 'lima puluh Riyal',
          amount: 50.0,
          confidence: 0.46,
          box: Rect.fromLTWH(105, 102, 290, 145),
          normalizedBox: Rect.fromLTWH(0.21, 0.204, 0.48, 0.29),
        ),
      ];

      final result = SmartMultiPassDetector.mergeCrossPassDetections(
        [detections],
        finalThreshold: 0.58,
        candidateThreshold: 0.42,
        iouThreshold: 0.45,
        conflictIoUThreshold: 0.48,
      );

      // Only the higher confidence detection (10 SAR) should be preserved!
      expect(result.length, 1, reason: 'Conflicting denomination must be suppressed to avoid double counting');
      expect(result.first.displayName, '10 SAR');
      expect(result.first.amount, 10.0);
    });

    test('Preserves separate physical bills positioned in different areas of the frame', () {
      const bill1 = MoneyDetection(
        className: 'ten riyal',
        currency: CurrencyCode.sar,
        displayName: '10 SAR',
        spokenName: 'sepuluh Riyal',
        amount: 10.0,
        confidence: 0.85,
        box: Rect.fromLTWH(20, 20, 200, 100),
        normalizedBox: Rect.fromLTWH(0.05, 0.05, 0.4, 0.2),
      );

      const bill2 = MoneyDetection(
        className: 'fifty riyal',
        currency: CurrencyCode.sar,
        displayName: '50 SAR',
        spokenName: 'lima puluh Riyal',
        amount: 50.0,
        confidence: 0.80,
        box: Rect.fromLTWH(20, 300, 200, 100),
        normalizedBox: Rect.fromLTWH(0.05, 0.60, 0.4, 0.2),
      );

      final result = SmartMultiPassDetector.mergeCrossPassDetections(
        [[bill1, bill2]],
        finalThreshold: 0.58,
      );

      expect(result.length, 2);
      final totals = MoneyAggregator.totalsByCurrency(result);
      expect(totals[CurrencyCode.sar], 60.0);
    });

    test('Rejects tiny noise bounding boxes that are not coins', () {
      const tinyArtifact = MoneyDetection(
        className: 'one hundred thousand rupiah',
        currency: CurrencyCode.idr,
        displayName: 'Rp 100.000',
        spokenName: 'seratus ribu rupiah',
        amount: 100000.0,
        confidence: 0.90,
        box: Rect.fromLTWH(50, 50, 10, 8),
        normalizedBox: Rect.fromLTWH(0.05, 0.05, 0.02, 0.02), // Area = 0.0004 (< 0.005)
        isCoin: false,
      );

      final result = SmartMultiPassDetector.mergeCrossPassDetections(
        [[tinyArtifact]],
        finalThreshold: 0.58,
      );

      expect(result.isEmpty, isTrue, reason: 'Tiny noise box should be rejected');
    });
  });

  group('Money Aggregator & Currency Conversion Tests', () {
    test('Calculates multi-currency totals and conversions accurately', () {
      final detections = [
        const MoneyDetection(
          className: 'ten riyal',
          currency: CurrencyCode.sar,
          displayName: '10 SAR',
          spokenName: 'sepuluh Riyal',
          amount: 10.0,
          confidence: 0.90,
          box: Rect.zero,
          normalizedBox: Rect.zero,
        ),
        const MoneyDetection(
          className: 'fifty riyal',
          currency: CurrencyCode.sar,
          displayName: '50 SAR',
          spokenName: 'lima puluh Riyal',
          amount: 50.0,
          confidence: 0.88,
          box: Rect.zero,
          normalizedBox: Rect.zero,
        ),
        const MoneyDetection(
          className: 'fifty thousand rupiah',
          currency: CurrencyCode.idr,
          displayName: 'Rp 50.000',
          spokenName: 'lima puluh ribu rupiah',
          amount: 50000.0,
          confidence: 0.85,
          box: Rect.zero,
          normalizedBox: Rect.zero,
        ),
      ];

      final totals = MoneyAggregator.totalsByCurrency(detections);
      expect(totals[CurrencyCode.sar], 60.0);
      expect(totals[CurrencyCode.idr], 50000.0);

      final grandTotalInIdr = MoneyAggregator.grandTotalIn(
        totals: totals,
        targetCurrency: CurrencyCode.idr,
        conversionService: CurrencyRateService.instance,
      );

      // 60 SAR * 4750 (default rate) = Rp 285.000 + Rp 50.000 = Rp 335.000
      expect(grandTotalInIdr, 335000.0);
    });
  });

  group('MultiPassConfig Performance Settings', () {
    test('Config defaults have lightweight settings and conflict IoU', () {
      const config = MultiPassConfig();
      expect(config.finalConfidenceThreshold, 0.58);
      expect(config.candidateConfidenceThreshold, 0.42);
      expect(config.crossPassIoUThreshold, 0.45);
      expect(config.conflictIoUThreshold, 0.48);
      expect(config.maxInferenceDimension, 1280);
      expect(config.maxAdditionalPasses, 2);
    });
  });
}
