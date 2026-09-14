import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/money/models/money_detection.dart';
import 'package:hajicare/features/money/services/riyal_currency_helper.dart';

void main() {
  group('Money Recognition Photo-Based Logic & Acceptance Tests', () {
    // Helper function that mirrors the detection extraction logic in MoneyRecognitionScreen
    List<MoneyDetection> processDetections({
      required List<Map<String, dynamic>> rawResults,
      double confidenceThreshold = 0.65,
    }) {
      final List<MoneyDetection> validList = [];
      for (final res in rawResults) {
        final double confidence = (res['confidence'] as num).toDouble();
        if (confidence < confidenceThreshold) continue;

        final String className = res['className'] as String;
        final info = RiyalCurrencyHelper.getInfo(className);
        if (info == null) continue;

        validList.add(MoneyDetection(
          className: className,
          displayName: info.displayName,
          spokenName: info.spokenName,
          amount: info.amount,
          confidence: confidence,
          box: res['box'] as Rect? ?? Rect.zero,
          normalizedBox: res['normalizedBox'] as Rect? ?? Rect.zero,
          isCoin: info.isCoin,
        ));
      }
      return validList;
    }

    double calculateTotal(List<MoneyDetection> detections) {
      return detections.fold(0.0, (sum, item) => sum + item.amount);
    }

    test('Test 1: 5 + 10 + 5 + 100 + 5 => 5 detections, Total = 125 Riyal', () {
      final raw = [
        {'className': 'five riyal', 'confidence': 0.92},
        {'className': 'ten riyal', 'confidence': 0.88},
        {'className': 'five riyal', 'confidence': 0.90},
        {'className': 'one hundred riyal', 'confidence': 0.95},
        {'className': 'five riyal', 'confidence': 0.85},
      ];

      final detections = processDetections(rawResults: raw);
      final total = calculateTotal(detections);

      expect(detections.length, equals(5));
      expect(total, equals(125.0));
      expect(RiyalCurrencyHelper.formatAmount(total), equals('125 Riyal'));
      expect(
        RiyalCurrencyHelper.totalToSpokenIndonesian(total),
        equals('seratus dua puluh lima Riyal'),
      );
    });

    test('Test 2: 5 + 5 + 5 => 3 detections, Total = 15 Riyal', () {
      final raw = [
        {'className': 'five riyal', 'confidence': 0.91},
        {'className': 'five riyal', 'confidence': 0.89},
        {'className': 'five riyal', 'confidence': 0.94},
      ];

      final detections = processDetections(rawResults: raw);
      final total = calculateTotal(detections);

      expect(detections.length, equals(3));
      expect(total, equals(15.0));
      expect(RiyalCurrencyHelper.formatAmount(total), equals('15 Riyal'));
      expect(
        RiyalCurrencyHelper.totalToSpokenIndonesian(total),
        equals('lima belas Riyal'),
      );
    });

    test('Test 3: 100 => 1 detection, Total = 100 Riyal', () {
      final raw = [
        {'className': 'one hundred riyal', 'confidence': 0.96},
      ];

      final detections = processDetections(rawResults: raw);
      final total = calculateTotal(detections);

      expect(detections.length, equals(1));
      expect(total, equals(100.0));
      expect(RiyalCurrencyHelper.formatAmount(total), equals('100 Riyal'));
      expect(
        RiyalCurrencyHelper.totalToSpokenIndonesian(total),
        equals('seratus Riyal'),
      );
    });

    test('Test 4: Foto tanpa uang => 0 detections, Total = 0 Riyal', () {
      final raw = <Map<String, dynamic>>[];

      final detections = processDetections(rawResults: raw);
      final total = calculateTotal(detections);

      expect(detections.length, equals(0));
      expect(total, equals(0.0));
      expect(RiyalCurrencyHelper.formatAmount(total), equals('0 Riyal'));
      expect(
        RiyalCurrencyHelper.totalToSpokenIndonesian(total),
        equals('nol Riyal'),
      );
    });

    test('Test 5: Confidence threshold filtering (< 0.65)', () {
      final raw = [
        {'className': 'fifty riyal', 'confidence': 0.80}, // Valid
        {'className': 'ten riyal', 'confidence': 0.64}, // Ignored (< 0.65)
        {'className': 'five riyal', 'confidence': 0.40}, // Ignored (< 0.65)
        {'className': 'five hundred riyal', 'confidence': 0.75}, // Valid
      ];

      final detections = processDetections(
        rawResults: raw,
        confidenceThreshold: 0.65,
      );
      final total = calculateTotal(detections);

      expect(detections.length, equals(2));
      expect(total, equals(550.0));
      expect(
        detections.map((d) => d.displayName).toList(),
        containsAll(['50 Riyal', '500 Riyal']),
      );
    });

    test('Test 6: 5 + 5 + 5 + 10 => 4 detections, Total = 25 Riyal (Duplicates preserved)', () {
      final raw = [
        {'className': 'five riyal', 'confidence': 0.82},
        {'className': 'five riyal', 'confidence': 0.86},
        {'className': 'five riyal', 'confidence': 0.88},
        {'className': 'ten riyal', 'confidence': 0.90},
      ];

      final detections = processDetections(rawResults: raw);
      final total = calculateTotal(detections);

      expect(detections.length, equals(4));
      expect(total, equals(25.0));
      // Verify duplicate 5 Riyal items are maintained as 3 distinct physical objects
      final fiveRiyalDetections =
          detections.where((d) => d.amount == 5.0).toList();
      expect(fiveRiyalDetections.length, equals(3));
    });

    test('Coin Denominations handling (Halalas)', () {
      final raw = [
        {'className': 'fifty halalas', 'confidence': 0.90}, // 0.50
        {'className': 'twenty five halalas', 'confidence': 0.85}, // 0.25
        {'className': 'ten riyal', 'confidence': 0.95}, // 10.0
      ];

      final detections = processDetections(rawResults: raw);
      final total = calculateTotal(detections);

      expect(detections.length, equals(3));
      expect(total, equals(10.75));
      expect(RiyalCurrencyHelper.formatAmount(total), equals('10.75 Riyal'));
      expect(
        RiyalCurrencyHelper.totalToSpokenIndonesian(total),
        equals('sepuluh Riyal dan tujuh puluh lima halala'),
      );
    });
  });
}
