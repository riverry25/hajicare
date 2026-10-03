import 'package:flutter/material.dart';

import 'currency_code.dart';

/// Represents a single physical currency item (banknote or coin) detected by YOLO.
class MoneyDetection {
  final String className;
  final CurrencyCode currency;
  final String displayName;
  final String spokenName;
  final double amount;
  final double confidence;
  final Rect box;
  final Rect normalizedBox;
  final bool isCoin;

  const MoneyDetection({
    required this.className,
    required this.currency,
    required this.displayName,
    required this.spokenName,
    required this.amount,
    required this.confidence,
    required this.box,
    required this.normalizedBox,
    this.isCoin = false,
  });

  /// Confidence expressed as an integer percentage from 0 to 100.
  int get confidencePercentage => (confidence * 100).clamp(0, 100).round();

  MoneyDetection copyWith({
    String? className,
    CurrencyCode? currency,
    String? displayName,
    String? spokenName,
    double? amount,
    double? confidence,
    Rect? box,
    Rect? normalizedBox,
    bool? isCoin,
  }) {
    return MoneyDetection(
      className: className ?? this.className,
      currency: currency ?? this.currency,
      displayName: displayName ?? this.displayName,
      spokenName: spokenName ?? this.spokenName,
      amount: amount ?? this.amount,
      confidence: confidence ?? this.confidence,
      box: box ?? this.box,
      normalizedBox: normalizedBox ?? this.normalizedBox,
      isCoin: isCoin ?? this.isCoin,
    );
  }

  @override
  String toString() =>
      'MoneyDetection($displayName, $amount ${currency.code}, conf: ${(confidence * 100).toStringAsFixed(1)}%)';
}
