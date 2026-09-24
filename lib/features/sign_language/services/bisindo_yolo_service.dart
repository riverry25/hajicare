import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/bisindo_prediction.dart';

/// Dedicated service for YOLO26 BISINDO Alphabet recognition.
///
/// Wraps detections from `assets/models/fix_model/best.tflite` and labels from
/// `assets/models/fix_model/label.txt` into standard [BisindoPrediction] objects,
/// ensuring full compatibility with HajiCare's existing stabilization, holding,
/// confirmation, HUD overlay, and Indonesian TTS pipelines.
class BisindoYoloService {
  static const String kModelPath = 'assets/models/fix_model/best.tflite';
  static const String kLabelPath = 'assets/models/fix_model/label.txt';

  /// Minimum detection confidence threshold to consider a gesture candidate.
  static const double kDefaultConfidenceThreshold = 0.40;

  List<String> _labels = const [];
  bool _isLabelsLoaded = false;

  List<String> get labels => _labels;
  bool get isLabelsLoaded => _isLabelsLoaded;

  /// Loads class labels from assets if not already loaded.
  Future<List<String>> loadLabels() async {
    if (_isLabelsLoaded && _labels.isNotEmpty) {
      return _labels;
    }

    try {
      final raw = await rootBundle.loadString(kLabelPath);
      _labels = raw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      _isLabelsLoaded = true;

      if (kDebugMode) {
        debugPrint(
          '[BISINDO][YOLO] Loaded ${_labels.length} alphabet labels from $kLabelPath (A..Z)',
        );
      }
      return _labels;
    } catch (e) {
      debugPrint('[BISINDO][YOLO] Error loading labels from $kLabelPath: $e');
      // Fallback to standard 26 alphabet labels
      _labels = List.generate(
        26,
        (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
      );
      _isLabelsLoaded = true;
      return _labels;
    }
  }

  /// Converts a raw list of [YOLOResult] detections into a [BisindoPrediction].
  BisindoPrediction processDetections(
    List<YOLOResult> detections, {
    double confidenceThreshold = kDefaultConfidenceThreshold,
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

    final top = sorted.first;
    final isRecognized = top.confidence >= confidenceThreshold;

    // Resolve class name safely
    String resolvedLabel = top.className;
    if (resolvedLabel.isEmpty &&
        top.classIndex >= 0 &&
        top.classIndex < _labels.length) {
      resolvedLabel = _labels[top.classIndex];
    } else if (resolvedLabel.isEmpty &&
        top.classIndex >= 0 &&
        top.classIndex < 26) {
      resolvedLabel = String.fromCharCode('A'.codeUnitAt(0) + top.classIndex);
    }

    final candidates = sorted.map((r) {
      String name = r.className;
      if (name.isEmpty && r.classIndex >= 0 && r.classIndex < _labels.length) {
        name = _labels[r.classIndex];
      } else if (name.isEmpty && r.classIndex >= 0 && r.classIndex < 26) {
        name = String.fromCharCode('A'.codeUnitAt(0) + r.classIndex);
      }

      return BisindoCandidate(
        classId: r.classIndex,
        label: name,
        distance: (1.0 - r.confidence).clamp(0.0, 1.0),
        confidence: r.confidence,
      );
    }).toList();

    if (kDebugMode && isRecognized) {
      final summary = candidates
          .take(3)
          .map((c) => '${c.label}: ${(c.confidence * 100).toStringAsFixed(1)}%')
          .join(', ');
      debugPrint('[BISINDO][YOLO] Detected: $resolvedLabel ($summary)');
    }

    return BisindoPrediction(
      classId: top.classIndex,
      label: resolvedLabel,
      confidence: top.confidence,
      distance: (1.0 - top.confidence).clamp(0.0, 1.0),
      candidates: candidates,
      isRecognized: isRecognized,
    );
  }
}
