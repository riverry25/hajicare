import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/money/models/currency_code.dart';
import 'package:hajicare/features/money/models/money_detection.dart';
import 'package:hajicare/features/money/services/currency_rate_service.dart';
import 'package:hajicare/features/money/services/money_aggregator.dart';
import 'package:hajicare/features/money/services/money_class_parser.dart';
import 'package:hajicare/features/money/services/money_currency_helper.dart';
import 'package:hajicare/features/money/services/money_tts_service.dart';
import 'package:hajicare/features/money/services/smart_multi_pass_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MoneyDetection makeDetection({
    required String className,
    required double confidence,
    required Rect normalizedBox,
  }) {
    final info = MoneyClassParser.parse(className)!;
    return MoneyDetection(
      className: className,
      currency: info.currency,
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

  group('HajiCare Multi-Currency Recognition Test Suite', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // -------------------------------------------------------------------------
    // TEST 0: All 32 Labels in labels.txt mapped accurately
    // -------------------------------------------------------------------------
    test('Labels.txt — all 32 labels correctly parsed without exception', () {
      expect(MoneyClassParser.allLabels.length, equals(32));

      // Check USD
      expect(
        MoneyClassParser.parse('one dollar')?.currency,
        equals(CurrencyCode.usd),
      );
      expect(MoneyClassParser.parse('one dollar')?.amount, equals(1.0));
      expect(MoneyClassParser.parse('twenty dollar')?.amount, equals(20.0));
      expect(
        MoneyClassParser.parse('one hundred dollar')?.amount,
        equals(100.0),
      );

      // Check SAR
      expect(
        MoneyClassParser.parse('five riyal')?.currency,
        equals(CurrencyCode.sar),
      );
      expect(MoneyClassParser.parse('five riyal')?.amount, equals(5.0));
      expect(MoneyClassParser.parse('fifty halalas')?.isCoin, isTrue);
      expect(MoneyClassParser.parse('fifty halalas')?.amount, equals(0.50));

      // Check IDR
      expect(
        MoneyClassParser.parse('one hundred thousand rupiah')?.currency,
        equals(CurrencyCode.idr),
      );
      expect(
        MoneyClassParser.parse('one hundred thousand rupiah')?.amount,
        equals(100000.0),
      );
      expect(
        MoneyClassParser.parse('five hundred coin rupiah')?.isCoin,
        isTrue,
      );
      expect(
        MoneyClassParser.parse('five hundred coin rupiah')?.amount,
        equals(500.0),
      );
    });

    // -------------------------------------------------------------------------
    // TEST A: SAR Same Currency (10 SAR + 5 SAR)
    // -------------------------------------------------------------------------
    test('Test A: SAR Same Currency => 2 detections, Total SAR = 15', () {
      final detections = [
        makeDetection(
          className: 'ten riyal',
          confidence: 0.94,
          normalizedBox: const Rect.fromLTWH(0.1, 0.1, 0.3, 0.3),
        ),
        makeDetection(
          className: 'five riyal',
          confidence: 0.91,
          normalizedBox: const Rect.fromLTWH(0.5, 0.1, 0.3, 0.3),
        ),
      ];

      final totals = MoneyAggregator.totalsByCurrency(detections);

      expect(detections.length, equals(2));
      expect(totals[CurrencyCode.sar], equals(15.0));
      expect(totals[CurrencyCode.idr], isNull);
      expect(totals[CurrencyCode.usd], isNull);
      expect(MoneyAggregator.hasMixedCurrencies(detections), isFalse);
      expect(
        MoneyAggregator.singleCurrencyOrNull(detections),
        equals(CurrencyCode.sar),
      );
      expect(
        CurrencyFormatter.format(totals[CurrencyCode.sar]!, CurrencyCode.sar),
        equals('15 SAR'),
      );
    });

    // -------------------------------------------------------------------------
    // TEST B: IDR Same Currency (100k + 50k + 20k IDR)
    // -------------------------------------------------------------------------
    test('Test B: IDR Same Currency => 3 detections, Total IDR = 170.000', () {
      final detections = [
        makeDetection(
          className: 'one hundred thousand rupiah',
          confidence: 0.96,
          normalizedBox: const Rect.fromLTWH(0.05, 0.1, 0.25, 0.3),
        ),
        makeDetection(
          className: 'fifty thousand rupiah',
          confidence: 0.92,
          normalizedBox: const Rect.fromLTWH(0.35, 0.1, 0.25, 0.3),
        ),
        makeDetection(
          className: 'twenty thousand rupiah',
          confidence: 0.89,
          normalizedBox: const Rect.fromLTWH(0.65, 0.1, 0.25, 0.3),
        ),
      ];

      final totals = MoneyAggregator.totalsByCurrency(detections);

      expect(detections.length, equals(3));
      expect(totals[CurrencyCode.idr], equals(170000.0));
      expect(
        CurrencyFormatter.format(totals[CurrencyCode.idr]!, CurrencyCode.idr),
        equals('Rp 170.000'),
      );
    });

    // -------------------------------------------------------------------------
    // TEST C: USD Same Currency ($20 + $10 + $5 USD)
    // -------------------------------------------------------------------------
    test('Test C: USD Same Currency => 3 detections, Total USD = 35', () {
      final detections = [
        makeDetection(
          className: 'twenty dollar',
          confidence: 0.95,
          normalizedBox: const Rect.fromLTWH(0.1, 0.1, 0.25, 0.3),
        ),
        makeDetection(
          className: 'ten dollar',
          confidence: 0.93,
          normalizedBox: const Rect.fromLTWH(0.4, 0.1, 0.25, 0.3),
        ),
        makeDetection(
          className: 'five dollar',
          confidence: 0.88,
          normalizedBox: const Rect.fromLTWH(0.7, 0.1, 0.25, 0.3),
        ),
      ];

      final totals = MoneyAggregator.totalsByCurrency(detections);

      expect(detections.length, equals(3));
      expect(totals[CurrencyCode.usd], equals(35.0));
      expect(
        CurrencyFormatter.format(totals[CurrencyCode.usd]!, CurrencyCode.usd),
        equals('\$35.00'),
      );
    });

    // -------------------------------------------------------------------------
    // TEST D: Duplicate denomination, different physical objects (5 SAR + 5 SAR)
    // -------------------------------------------------------------------------
    test(
      'Test D: 2 separate 5 SAR objects at different locations are NOT merged',
      () {
        final pass1 = [
          makeDetection(
            className: 'five riyal',
            confidence: 0.89,
            normalizedBox: const Rect.fromLTWH(0.10, 0.20, 0.30, 0.25),
          ),
          makeDetection(
            className: 'five riyal',
            confidence: 0.92,
            normalizedBox: const Rect.fromLTWH(0.60, 0.20, 0.30, 0.25),
          ),
        ];

        final merged = SmartMultiPassDetector.mergeCrossPassDetections([pass1]);
        final totals = MoneyAggregator.totalsByCurrency(merged);

        expect(merged.length, equals(2));
        expect(totals[CurrencyCode.sar], equals(10.0));
      },
    );

    // -------------------------------------------------------------------------
    // TEST E: Same physical object across passes merged into 1
    // -------------------------------------------------------------------------
    test(
      'Test E: Same physical object across 3 passes merged into 1 with highest confidence',
      () {
        const box1 = Rect.fromLTWH(0.20, 0.30, 0.30, 0.25);
        const box2 = Rect.fromLTWH(0.21, 0.30, 0.29, 0.25);
        const box3 = Rect.fromLTWH(0.20, 0.31, 0.30, 0.24);

        final pass1 = [
          makeDetection(
            className: 'ten riyal',
            confidence: 0.82,
            normalizedBox: box1,
          ),
        ];
        final pass2 = [
          makeDetection(
            className: 'ten riyal',
            confidence: 0.95,
            normalizedBox: box2,
          ),
        ];
        final pass3 = [
          makeDetection(
            className: 'ten riyal',
            confidence: 0.88,
            normalizedBox: box3,
          ),
        ];

        final merged = SmartMultiPassDetector.mergeCrossPassDetections([
          pass1,
          pass2,
          pass3,
        ]);
        final totals = MoneyAggregator.totalsByCurrency(merged);

        expect(merged.length, equals(1));
        expect(totals[CurrencyCode.sar], equals(10.0));
        expect(merged.first.confidence, equals(0.95));
      },
    );

    // -------------------------------------------------------------------------
    // TEST F: Mixed Currency (10 SAR + 5 SAR + 20 USD + 100k IDR)
    // -------------------------------------------------------------------------
    test(
      'Test F: Mixed Currency photo produces currency-separated totals without raw sum',
      () {
        final detections = [
          makeDetection(
            className: 'ten riyal',
            confidence: 0.95,
            normalizedBox: const Rect.fromLTWH(0.05, 0.05, 0.2, 0.2),
          ),
          makeDetection(
            className: 'five riyal',
            confidence: 0.92,
            normalizedBox: const Rect.fromLTWH(0.30, 0.05, 0.2, 0.2),
          ),
          makeDetection(
            className: 'twenty dollar',
            confidence: 0.94,
            normalizedBox: const Rect.fromLTWH(0.55, 0.05, 0.2, 0.2),
          ),
          makeDetection(
            className: 'one hundred thousand rupiah',
            confidence: 0.96,
            normalizedBox: const Rect.fromLTWH(0.05, 0.50, 0.3, 0.3),
          ),
        ];

        final totals = MoneyAggregator.totalsByCurrency(detections);

        expect(detections.length, equals(4));
        expect(MoneyAggregator.hasMixedCurrencies(detections), isTrue);
        expect(MoneyAggregator.singleCurrencyOrNull(detections), isNull);

        // Separate totals
        expect(totals[CurrencyCode.sar], equals(15.0));
        expect(totals[CurrencyCode.usd], equals(20.0));
        expect(totals[CurrencyCode.idr], equals(100000.0));

        // Grand total calculation in IDR target
        final fx = CurrencyRateService.instance;
        final grandTotalIdr = MoneyAggregator.grandTotalIn(
          totals: totals,
          targetCurrency: CurrencyCode.idr,
          conversionService: fx,
        );

        final expectedIdr =
            100000.0 +
            fx.convert(
              amount: 15.0,
              from: CurrencyCode.sar,
              to: CurrencyCode.idr,
            ) +
            fx.convert(
              amount: 20.0,
              from: CurrencyCode.usd,
              to: CurrencyCode.idr,
            );

        expect(grandTotalIdr, closeTo(expectedIdr, 0.01));
      },
    );

    // -------------------------------------------------------------------------
    // TEST G: Generic Cross-Rate Conversions
    // -------------------------------------------------------------------------
    test('Test G: Full conversion matrix between SAR, IDR, and USD', () {
      final fx = CurrencyRateService.instance;

      // SAR <-> IDR
      final sarToIdr = fx.convert(
        amount: 10.0,
        from: CurrencyCode.sar,
        to: CurrencyCode.idr,
      );
      expect(sarToIdr, greaterThan(30000));
      final idrToSar = fx.convert(
        amount: sarToIdr,
        from: CurrencyCode.idr,
        to: CurrencyCode.sar,
      );
      expect(idrToSar, closeTo(10.0, 0.01));

      // SAR <-> USD
      final sarToUsd = fx.convert(
        amount: 37.5,
        from: CurrencyCode.sar,
        to: CurrencyCode.usd,
      );
      expect(sarToUsd, closeTo(10.0, 0.01));
      final usdToSar = fx.convert(
        amount: 10.0,
        from: CurrencyCode.usd,
        to: CurrencyCode.sar,
      );
      expect(usdToSar, closeTo(37.5, 0.01));

      // USD <-> IDR
      final usdToIdr = fx.convert(
        amount: 10.0,
        from: CurrencyCode.usd,
        to: CurrencyCode.idr,
      );
      expect(usdToIdr, greaterThan(100000));
      final idrToUsd = fx.convert(
        amount: usdToIdr,
        from: CurrencyCode.idr,
        to: CurrencyCode.usd,
      );
      expect(idrToUsd, closeTo(10.0, 0.01));
    });

    // -------------------------------------------------------------------------
    // TEST H: Same Currency Conversion
    // -------------------------------------------------------------------------
    test(
      'Test H: Same Currency conversion immediately returns exact amount',
      () {
        final fx = CurrencyRateService.instance;
        expect(
          fx.convert(
            amount: 100000.0,
            from: CurrencyCode.idr,
            to: CurrencyCode.idr,
          ),
          equals(100000.0),
        );
        expect(
          fx.convert(
            amount: 25.5,
            from: CurrencyCode.sar,
            to: CurrencyCode.sar,
          ),
          equals(25.5),
        );
        expect(
          fx.convert(
            amount: 50.0,
            from: CurrencyCode.usd,
            to: CurrencyCode.usd,
          ),
          equals(50.0),
        );
      },
    );

    // -------------------------------------------------------------------------
    // TEST I & J: TTS and Fallback Boundaries
    // -------------------------------------------------------------------------
    test(
      'Test I & J: Natural Indonesian TTS sentence building handles single and mixed currency gracefully',
      () {
        final tts = MoneyTtsService();

        // Single SAR
        final sarDetections = [
          makeDetection(
            className: 'ten riyal',
            confidence: 0.9,
            normalizedBox: Rect.zero,
          ),
          makeDetection(
            className: 'five riyal',
            confidence: 0.9,
            normalizedBox: Rect.zero,
          ),
        ];
        final sarSentence = tts.buildSpeechSentence(
          detections: sarDetections,
          totalsByCurrency: {CurrencyCode.sar: 15.0},
          targetCurrency: CurrencyCode.idr,
        );
        expect(sarSentence, contains('Terdeteksi dua uang'));
        expect(sarSentence, contains('lima belas Riyal Saudi'));
        expect(sarSentence, contains('Setara sekitar'));

        // Mixed currency
        final mixedDetections = [
          makeDetection(
            className: 'ten riyal',
            confidence: 0.9,
            normalizedBox: Rect.zero,
          ),
          makeDetection(
            className: 'twenty dollar',
            confidence: 0.9,
            normalizedBox: Rect.zero,
          ),
        ];
        final mixedSentence = tts.buildSpeechSentence(
          detections: mixedDetections,
          totalsByCurrency: {CurrencyCode.sar: 10.0, CurrencyCode.usd: 20.0},
          targetCurrency: CurrencyCode.idr,
        );
        expect(mixedSentence, contains('Terdeteksi dua uang'));
        expect(mixedSentence, contains('Total per mata uang'));
        expect(mixedSentence, contains('Jika seluruhnya dikonversikan'));

        // Offline / conversion unavailable
        final offlineSentence = tts.buildSpeechSentence(
          detections: mixedDetections,
          totalsByCurrency: {CurrencyCode.sar: 10.0, CurrencyCode.usd: 20.0},
          targetCurrency: CurrencyCode.idr,
          isConversionAvailable: false,
        );
        expect(
          offlineSentence,
          contains('Konversi mata uang sedang tidak tersedia'),
        );
      },
    );
  });
}
