import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/bisindo_prediction.dart';

/// Dedicated service for YOLO SIBI & BISINDO Alphabet recognition.
///
/// Wraps detections from `assets/models/sibi/sibi.tflite` and labels from
/// `assets/models/sibi/labels_sibi.txt` into standard [BisindoPrediction] objects,
/// ensuring full compatibility with HajiCare's stabilization, holding,
/// confirmation, HUD overlay, and Indonesian TTS pipelines.
class BisindoYoloService {
  static const String kSibiModelPath = 'assets/models/sibi/sibi.tflite';
  static const String kSibiLabelPath = 'assets/models/sibi/labels_sibi.txt';

  static const String kModelPath = kSibiModelPath;
  static const String kLabelPath = kSibiLabelPath;

  /// Minimum detection confidence threshold to consider a gesture candidate.
  static const double kDefaultConfidenceThreshold = 0.35;

  final String modelPath;
  final String labelPath;
  final double defaultConfidence;

  BisindoYoloService({
    this.modelPath = kSibiModelPath,
    this.labelPath = kSibiLabelPath,
    this.defaultConfidence = kDefaultConfidenceThreshold,
  });

  List<String> _labels = const [];
  bool _isLabelsLoaded = false;
  DateTime _lastLogTime = DateTime.fromMillisecondsSinceEpoch(0);

  List<String> get labels => _labels;
  bool get isLabelsLoaded => _isLabelsLoaded;

  /// Loads class labels from assets if not already loaded.
  Future<List<String>> loadLabels([String? customPath]) async {
    final targetPath = customPath ?? labelPath;
    if (_isLabelsLoaded && _labels.isNotEmpty && customPath == null) {
      return _labels;
    }

    try {
      final raw = await rootBundle.loadString(targetPath);
      _labels = raw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      _isLabelsLoaded = true;

      if (kDebugMode) {
        debugPrint(
          '[SIGN_LANGUAGE][YOLO] Loaded ${_labels.length} labels from $targetPath: ${_labels.take(6).join(', ')}...',
        );
      }
      return _labels;
    } catch (e) {
      debugPrint(
        '[SIGN_LANGUAGE][YOLO] Error loading labels from $targetPath: $e',
      );
      // Fallback to standard 26 alphabet labels
      _labels = List.generate(
        26,
        (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
      );
      _isLabelsLoaded = true;
      return _labels;
    }
  }

  String _resolveLabelName(int classIndex, String className) {
    final trimmedClass = className.trim();
    final parsed = int.tryParse(trimmedClass);
    if (parsed != null && parsed >= 0 && parsed < _labels.length) {
      return _labels[parsed];
    }
    if (trimmedClass.isNotEmpty && parsed == null) {
      return trimmedClass;
    }
    if (classIndex >= 0 && classIndex < _labels.length) {
      return _labels[classIndex];
    }
    if (classIndex >= 0 && classIndex < 26) {
      return String.fromCharCode('A'.codeUnitAt(0) + classIndex);
    }
    return trimmedClass;
  }

  /// Converts a raw list of [YOLOResult] detections into a [BisindoPrediction].
  BisindoPrediction processDetections(
    List<YOLOResult> detections, {
    double confidenceThreshold = kDefaultConfidenceThreshold,
    bool alphabetOnly = false,
  }) {
    if (detections.isEmpty) {
      return const BisindoPrediction(
        classId: -1,
        label: '',
        confidence: 0.0,
        distance: 1.0,
        candidates: [],
        isRecognized: false,
      );
    }

    // Sort detections by confidence descending
    final sorted = List<YOLOResult>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    YOLOResult target = sorted.first;
    if (alphabetOnly) {
      // Prioritize single letter A-Z if available above threshold
      for (final r in sorted) {
        final name = _resolveLabelName(r.classIndex, r.className);
        final isLetter =
            name.length == 1 && RegExp(r'^[A-Za-z]$').hasMatch(name);
        if (isLetter && r.confidence >= confidenceThreshold) {
          target = r;
          break;
        }
      }
    }

    final isRecognized = target.confidence >= confidenceThreshold;
    String resolvedLabel = _resolveLabelName(
      target.classIndex,
      target.className,
    );
    if (resolvedLabel.length == 1) {
      resolvedLabel = resolvedLabel.toUpperCase();
    }

    final candidates = sorted.map((r) {
      String name = _resolveLabelName(r.classIndex, r.className);
      if (name.length == 1) {
        name = name.toUpperCase();
      }

      return BisindoCandidate(
        classId: r.classIndex,
        label: name,
        distance: (1.0 - r.confidence).clamp(0.0, 1.0),
        confidence: r.confidence,
      );
    }).toList();

    if (kDebugMode && isRecognized) {
      final now = DateTime.now();
      if (now.difference(_lastLogTime).inMilliseconds > 1500) {
        _lastLogTime = now;
        final summary = candidates
            .take(3)
            .map(
              (c) => '${c.label}: ${(c.confidence * 100).toStringAsFixed(1)}%',
            )
            .join(', ');
        debugPrint('[SIGN_LANGUAGE][YOLO] Detected: $resolvedLabel ($summary)');
      }
    }

    return BisindoPrediction(
      classId: target.classIndex,
      label: resolvedLabel,
      confidence: target.confidence,
      distance: (1.0 - target.confidence).clamp(0.0, 1.0),
      candidates: candidates,
      isRecognized: isRecognized,
    );
  }
}
