import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/money_detection.dart';
import 'riyal_currency_helper.dart';

/// Configuration for Smart Multi-Pass Money Detection.
class MultiPassConfig {
  /// Final confidence threshold for UI display and total calculation.
  final double finalConfidenceThreshold;

  /// Candidate confidence threshold used during intermediate passes.
  final double candidateConfidenceThreshold;

  /// Intersection-over-Union threshold to identify the same physical object across passes.
  final double crossPassIoUThreshold;

  /// Maximum number of additional passes (Pass 2 enhanced + Pass 3 tiled).
  final int maxAdditionalPasses;

  const MultiPassConfig({
    this.finalConfidenceThreshold = 0.65,
    this.candidateConfidenceThreshold = 0.50,
    this.crossPassIoUThreshold = 0.50,
    this.maxAdditionalPasses = 2,
  });
}

/// Result of a single inference pass.
class PassResult {
  final int passIndex;
  final String passName;
  final List<MoneyDetection> detections;
  final int executionTimeMs;

  const PassResult({
    required this.passIndex,
    required this.passName,
    required this.detections,
    required this.executionTimeMs,
  });
}

/// Overall result of the Smart Multi-Pass detection pipeline.
class MultiPassDetectionResult {
  final List<MoneyDetection> finalDetections;
  final double totalAmount;
  final List<PassResult> passResults;
  final int totalExecutionTimeMs;

  const MultiPassDetectionResult({
    required this.finalDetections,
    required this.totalAmount,
    required this.passResults,
    required this.totalExecutionTimeMs,
  });
}

/// Engine that performs smart multi-pass detection, enhancement,
/// adaptive tiling, and cross-pass deduplication.
class SmartMultiPassDetector {
  final YOLO yolo;
  final MultiPassConfig config;

  const SmartMultiPassDetector({
    required this.yolo,
    this.config = const MultiPassConfig(),
  });

  /// Executes the Smart Multi-Pass pipeline on [originalImageBytes].
  ///
  /// [onStatusUpdate] provides user-friendly status updates for the UI.
  Future<MultiPassDetectionResult> processImage(
    Uint8List originalImageBytes, {
    void Function(String status)? onStatusUpdate,
  }) async {
    final overallStopwatch = Stopwatch()..start();
    final List<PassResult> passResults = [];

    // -------------------------------------------------------------------------
    // PASS 1: Baseline inference on original image
    // -------------------------------------------------------------------------
    onStatusUpdate?.call('Memeriksa foto...');
    final pass1Stopwatch = Stopwatch()..start();
    final pass1Detections = await _runInference(
      imageBytes: originalImageBytes,
      confidenceThreshold: config.candidateConfidenceThreshold,
    );
    pass1Stopwatch.stop();

    passResults.add(
      PassResult(
        passIndex: 1,
        passName: 'Original Image',
        detections: pass1Detections,
        executionTimeMs: pass1Stopwatch.elapsedMilliseconds,
      ),
    );

    debugPrint(
      '[MoneyAI] Pass 1 (Original): ${pass1Detections.length} candidate detections (${pass1Stopwatch.elapsedMilliseconds}ms)',
    );

    // -------------------------------------------------------------------------
    // ADAPTIVE EVALUATION: Decide whether additional passes are required
    // -------------------------------------------------------------------------
    final bool shouldRunEnhancedPass = _shouldRunEnhancedPass(pass1Detections);
    final bool shouldRunTiledPass = _shouldRunTiledPass(
      pass1Detections,
      originalImageBytes,
    );

    // -------------------------------------------------------------------------
    // PASS 2: Enhanced image inference (if adaptive condition met)
    // -------------------------------------------------------------------------
    if (shouldRunEnhancedPass && config.maxAdditionalPasses >= 1) {
      onStatusUpdate?.call('Meningkatkan kejernihan foto...');
      final pass2Stopwatch = Stopwatch()..start();

      final enhancedBytes = await _enhanceImage(originalImageBytes);
      if (enhancedBytes != null) {
        final pass2Detections = await _runInference(
          imageBytes: enhancedBytes,
          confidenceThreshold: config.candidateConfidenceThreshold,
        );
        pass2Stopwatch.stop();

        passResults.add(
          PassResult(
            passIndex: 2,
            passName: 'Enhanced Image',
            detections: pass2Detections,
            executionTimeMs: pass2Stopwatch.elapsedMilliseconds,
          ),
        );

        debugPrint(
          '[MoneyAI] Pass 2 (Enhanced): ${pass2Detections.length} candidate detections (${pass2Stopwatch.elapsedMilliseconds}ms)',
        );
      }
    } else {
      debugPrint(
        '[MoneyAI] Pass 2 skipped adaptively (Pass 1 result is already confident)',
      );
    }

    // -------------------------------------------------------------------------
    // PASS 3: Tiled / Cropped inference (if adaptive condition met)
    // -------------------------------------------------------------------------
    if (shouldRunTiledPass && config.maxAdditionalPasses >= 2) {
      onStatusUpdate?.call('Mencari semua lembar uang...');
      final pass3Stopwatch = Stopwatch()..start();

      final tiledDetections = await _runTiledInference(
        originalImageBytes,
        config.candidateConfidenceThreshold,
      );
      pass3Stopwatch.stop();

      passResults.add(
        PassResult(
          passIndex: 3,
          passName: 'Tiled Inference',
          detections: tiledDetections,
          executionTimeMs: pass3Stopwatch.elapsedMilliseconds,
        ),
      );

      debugPrint(
        '[MoneyAI] Pass 3 (Tiled): ${tiledDetections.length} candidate detections (${pass3Stopwatch.elapsedMilliseconds}ms)',
      );
    } else {
      debugPrint(
        '[MoneyAI] Pass 3 skipped adaptively (Scene is not crowded/small-object)',
      );
    }

    // -------------------------------------------------------------------------
    // MERGE & CROSS-PASS DEDUPLICATION
    // -------------------------------------------------------------------------
    onStatusUpdate?.call('Memastikan hasil deteksi...');
    final List<MoneyDetection> finalDetections = mergeCrossPassDetections(
      passResults.map((p) => p.detections).toList(),
      finalThreshold: config.finalConfidenceThreshold,
      candidateThreshold: config.candidateConfidenceThreshold,
      iouThreshold: config.crossPassIoUThreshold,
    );

    final double totalAmount = finalDetections.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    overallStopwatch.stop();

    debugPrint(
      '[MoneyAI] Merged: ${finalDetections.length} unique objects. Total: ${totalAmount.toStringAsFixed(2)} SAR (${overallStopwatch.elapsedMilliseconds}ms total)',
    );

    return MultiPassDetectionResult(
      finalDetections: finalDetections,
      totalAmount: totalAmount,
      passResults: passResults,
      totalExecutionTimeMs: overallStopwatch.elapsedMilliseconds,
    );
  }

  // ---------------------------------------------------------------------------
  // INFERENCE RUNNER
  // ---------------------------------------------------------------------------

  Future<List<MoneyDetection>> _runInference({
    required Uint8List imageBytes,
    required double confidenceThreshold,
  }) async {
    final Map<String, dynamic> result = await yolo.predict(
      imageBytes,
      confidenceThreshold: confidenceThreshold,
    );

    final rawList =
        (result['detections'] as List?)
            ?.map((d) => YOLOResult.fromMap(d as Map))
            .toList() ??
        [];

    final List<MoneyDetection> list = [];
    for (final res in rawList) {
      if (res.confidence < confidenceThreshold) continue;
      final info = RiyalCurrencyHelper.getInfo(res.className);
      if (info == null) continue;

      list.add(
        MoneyDetection(
          className: res.className,
          displayName: info.displayName,
          spokenName: info.spokenName,
          amount: info.amount,
          confidence: res.confidence,
          box: res.boundingBox,
          normalizedBox: res.normalizedBox,
          isCoin: info.isCoin,
        ),
      );
    }
    return list;
  }

  // ---------------------------------------------------------------------------
  // ADAPTIVE LOGIC
  // ---------------------------------------------------------------------------

  /// Determines whether the enhanced image pass should be executed.
  bool _shouldRunEnhancedPass(List<MoneyDetection> pass1Detections) {
    // Condition 1: No detections found in Pass 1 (possible poor lighting/contrast)
    if (pass1Detections.isEmpty) return true;

    // Condition 2: Any detection has borderline confidence (< 0.80)
    final hasBorderlineConfidence = pass1Detections.any(
      (d) => d.confidence < 0.80,
    );
    if (hasBorderlineConfidence) return true;

    // Condition 3: If single detection has very high confidence (>= 0.90), skip pass 2
    if (pass1Detections.length == 1 &&
        pass1Detections.first.confidence >= 0.90) {
      return false;
    }

    // Condition 4: Multiple detections, run enhancement to catch crowded details
    return pass1Detections.length >= 2;
  }

  /// Determines whether tiled/crop inference should be executed.
  bool _shouldRunTiledPass(
    List<MoneyDetection> pass1Detections,
    Uint8List imageBytes,
  ) {
    // If Pass 1 found a single large banknote with high confidence (>= 0.90),
    // tiling is completely unnecessary and would waste processing time.
    if (pass1Detections.length == 1 &&
        pass1Detections.first.confidence >= 0.90 &&
        (pass1Detections.first.normalizedBox.width > 0.40 ||
            pass1Detections.first.normalizedBox.height > 0.40)) {
      return false;
    }

    // Condition 1: Multi-money scene with 3+ objects (likely crowded)
    if (pass1Detections.length >= 3) return true;

    // Condition 2: Any detected object is small relative to frame (< 0.25 normalized size)
    final hasSmallObjects = pass1Detections.any(
      (d) => d.normalizedBox.width < 0.25 && d.normalizedBox.height < 0.25,
    );
    if (hasSmallObjects) return true;

    // Condition 3: No detections found in Pass 1, check if bills are small in distance
    if (pass1Detections.isEmpty) return true;

    return false;
  }

  // ---------------------------------------------------------------------------
  // IMAGE ENHANCEMENT (PASS 2)
  // ---------------------------------------------------------------------------

  /// Performs light contrast enhancement and normalization in pure Dart.
  Future<Uint8List?> _enhanceImage(Uint8List imageBytes) async {
    return compute(_enhanceImageWorker, imageBytes);
  }

  static Uint8List? _enhanceImageWorker(Uint8List imageBytes) {
    try {
      final img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      // 1. Moderate contrast enhancement (contrast: 1.25)
      final enhanced = img.contrast(decoded, contrast: 120);

      // 2. Encode to high-quality JPEG
      return Uint8List.fromList(img.encodeJpg(enhanced, quality: 88));
    } catch (e) {
      debugPrint('[MoneyAI] Image enhancement worker error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // TILED / CROP INFERENCE (PASS 3)
  // ---------------------------------------------------------------------------

  /// Runs inference on 4 overlapping quadrants and maps detection coordinates
  /// back into the original image normalized coordinate space.
  Future<List<MoneyDetection>> _runTiledInference(
    Uint8List originalBytes,
    double candidateThreshold,
  ) async {
    final List<MoneyDetection> tiledResults = [];

    // Define 4 quadrants with 15% overlap to prevent cutting bills at boundaries
    // [left_norm, top_norm, width_norm, height_norm]
    const tiles = [
      Rect.fromLTWH(0.0, 0.0, 0.58, 0.58), // Top-Left
      Rect.fromLTWH(0.42, 0.0, 0.58, 0.58), // Top-Right
      Rect.fromLTWH(0.0, 0.42, 0.58, 0.58), // Bottom-Left
      Rect.fromLTWH(0.42, 0.42, 0.58, 0.58), // Bottom-Right
    ];

    try {
      final img.Image? decoded = img.decodeImage(originalBytes);
      if (decoded == null) return tiledResults;

      final int imageW = decoded.width;
      final int imageH = decoded.height;

      for (int i = 0; i < tiles.length; i++) {
        final tileNorm = tiles[i];
        final int cropX = (tileNorm.left * imageW).round().clamp(0, imageW - 1);
        final int cropY = (tileNorm.top * imageH).round().clamp(0, imageH - 1);
        final int cropW = (tileNorm.width * imageW).round().clamp(
          1,
          imageW - cropX,
        );
        final int cropH = (tileNorm.height * imageH).round().clamp(
          1,
          imageH - cropY,
        );

        final cropped = img.copyCrop(
          decoded,
          x: cropX,
          y: cropY,
          width: cropW,
          height: cropH,
        );

        final tileBytes = Uint8List.fromList(
          img.encodeJpg(cropped, quality: 85),
        );

        // Inference on tile
        final Map<String, dynamic> result = await yolo.predict(
          tileBytes,
          confidenceThreshold: candidateThreshold,
        );

        final rawList =
            (result['detections'] as List?)
                ?.map((d) => YOLOResult.fromMap(d as Map))
                .toList() ??
            [];

        for (final res in rawList) {
          if (res.confidence < candidateThreshold) continue;
          final info = RiyalCurrencyHelper.getInfo(res.className);
          if (info == null) continue;

          // Map normalized box from tile coordinates back to original image space
          final tNorm = res.normalizedBox;
          final double origLeft = (tileNorm.left + tNorm.left * tileNorm.width)
              .clamp(0.0, 1.0);
          final double origTop = (tileNorm.top + tNorm.top * tileNorm.height)
              .clamp(0.0, 1.0);
          final double origRight =
              (tileNorm.left + tNorm.right * tileNorm.width).clamp(0.0, 1.0);
          final double origBottom =
              (tileNorm.top + tNorm.bottom * tileNorm.height).clamp(0.0, 1.0);

          if (origRight <= origLeft || origBottom <= origTop) continue;

          final mappedNormalizedBox = Rect.fromLTRB(
            origLeft,
            origTop,
            origRight,
            origBottom,
          );

          tiledResults.add(
            MoneyDetection(
              className: res.className,
              displayName: info.displayName,
              spokenName: info.spokenName,
              amount: info.amount,
              confidence: res.confidence,
              box: Rect.fromLTRB(
                origLeft * imageW,
                origTop * imageH,
                origRight * imageW,
                origBottom * imageH,
              ),
              normalizedBox: mappedNormalizedBox,
              isCoin: info.isCoin,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[MoneyAI] Tiled inference error: $e');
    }

    return tiledResults;
  }

  // ---------------------------------------------------------------------------
  // MERGE & CROSS-PASS DEDUPLICATION
  // ---------------------------------------------------------------------------

  /// Merges detections from multiple passes:
  /// - Identifies detections of the SAME physical object (same class + IoU >= [iouThreshold]).
  /// - Preserves the best confidence score and box for that physical object.
  /// - Real physical duplicate objects (e.g. two separate 5 Riyal bills at different positions)
  ///   have IoU < [iouThreshold] and are NEVER merged.
  /// - Candidates with confidence >= [finalThreshold] are included directly.
  /// - Intermediate candidates with confidence >= [candidateThreshold] that were confirmed
  ///   by at least 2 independent passes receive a confidence boost.
  static List<MoneyDetection> mergeCrossPassDetections(
    List<List<MoneyDetection>> passResults, {
    double finalThreshold = 0.65,
    double candidateThreshold = 0.50,
    double iouThreshold = 0.50,
  }) {
    // 1. Flatten all candidate detections across all passes
    final List<MoneyDetection> allCandidates = [];
    for (final list in passResults) {
      allCandidates.addAll(list);
    }

    if (allCandidates.isEmpty) return [];

    // 2. Sort by confidence descending so highest confidence detections lead clusters
    allCandidates.sort((a, b) => b.confidence.compareTo(a.confidence));

    // 3. Cluster detections representing the same physical object
    final List<MoneyDetection> clusters = [];
    final List<int> clusterMatchCounts = [];

    for (final candidate in allCandidates) {
      int matchedClusterIndex = -1;

      for (int i = 0; i < clusters.length; i++) {
        final existing = clusters[i];

        // Must be the same denomination/class
        if (existing.className.toLowerCase() !=
            candidate.className.toLowerCase()) {
          continue;
        }

        // Must have high overlap to be considered the same physical object
        final double iou = calculateIoU(
          existing.normalizedBox,
          candidate.normalizedBox,
        );

        if (iou >= iouThreshold) {
          matchedClusterIndex = i;
          break;
        }
      }

      if (matchedClusterIndex >= 0) {
        // Increment confirmation count across passes
        clusterMatchCounts[matchedClusterIndex]++;

        // Keep the detection with the higher confidence
        if (candidate.confidence > clusters[matchedClusterIndex].confidence) {
          clusters[matchedClusterIndex] = candidate;
        }
      } else {
        // New physical object
        clusters.add(candidate);
        clusterMatchCounts.add(1);
      }
    }

    // 4. Final Thresholding and Cross-Pass Confirmation
    final List<MoneyDetection> finalValidList = [];

    for (int i = 0; i < clusters.length; i++) {
      final item = clusters[i];
      final matchCount = clusterMatchCounts[i];

      if (item.confidence >= finalThreshold) {
        // Directly qualifies with high confidence
        finalValidList.add(item);
      } else if (item.confidence >= candidateThreshold && matchCount >= 2) {
        // Confirmed across multiple passes: boost confidence
        final boostedConfidence = math.min(1.0, item.confidence + 0.10);
        if (boostedConfidence >= finalThreshold) {
          finalValidList.add(
            MoneyDetection(
              className: item.className,
              displayName: item.displayName,
              spokenName: item.spokenName,
              amount: item.amount,
              confidence: boostedConfidence,
              box: item.box,
              normalizedBox: item.normalizedBox,
              isCoin: item.isCoin,
            ),
          );
        }
      }
    }

    return finalValidList;
  }

  /// Calculates Intersection-over-Union (IoU) between two bounding boxes.
  static double calculateIoU(Rect a, Rect b) {
    final double left = math.max(a.left, b.left);
    final double top = math.max(a.top, b.top);
    final double right = math.min(a.right, b.right);
    final double bottom = math.min(a.bottom, b.bottom);

    if (right <= left || bottom <= top) return 0.0;

    final double intersectionArea = (right - left) * (bottom - top);
    final double areaA = a.width * a.height;
    final double areaB = b.width * b.height;
    final double unionArea = areaA + areaB - intersectionArea;

    if (unionArea <= 0) return 0.0;
    return (intersectionArea / unionArea).clamp(0.0, 1.0);
  }
}
