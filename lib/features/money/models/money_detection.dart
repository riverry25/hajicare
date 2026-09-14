import 'package:flutter/material.dart';

/// Represents a single physical currency item detected by YOLO in a frame.
class MoneyDetection {
  final String className;
  final String displayName;
  final String spokenName;
  final double amount;
  final double confidence;
  final Rect box;
  final Rect normalizedBox;
  final bool isCoin;

  const MoneyDetection({
    required this.className,
    required this.displayName,
    required this.spokenName,
    required this.amount,
    required this.confidence,
    required this.box,
    required this.normalizedBox,
    this.isCoin = false,
  });

  int get confidencePercentage => (confidence * 100).clamp(0, 100).round();

  @override
  String toString() =>
      'MoneyDetection($displayName, $amount Riyal, conf: ${(confidence * 100).toStringAsFixed(1)}%)';
}
