import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/currency_code.dart';
import '../models/money_detection.dart';
import 'money_aggregator.dart';
import 'money_class_parser.dart';

/// Configuration for Smart Multi-Pass Money Detection.
class MultiPassConfig {
  /// Final confidence threshold for UI display and total calculation.
  final double finalConfidenceThreshold;

  /// Candidate confidence threshold used during intermediate passes.
  final double candidateConfidenceThreshold;

  /// Intersection-over-Union threshold to identify the same physical object across passes.
  final double crossPassIoUThreshold;

  /// Intersection-over-Union threshold to suppress conflicting denominations on the same physical object.
  final double conflictIoUThreshold;

  /// Maximum number of additional passes (Pass 2 enhanced + Pass 3 tiled).
  final int maxAdditionalPasses;

  /// Maximum image dimension for inference downscaling (default 1280px).
  final int maxInferenceDimension;

  const MultiPassConfig({
    this.finalConfidenceThreshold = 0.58,
    this.candidateConfidenceThreshold = 0.42,
    this.crossPassIoUThreshold = 0.45,
    this.conflictIoUThreshold = 0.48,
    this.maxAdditionalPasses = 2,
    this.maxInferenceDimension = 1280,
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

/// Overall result of the Smart Multi-Pass multi-currency detection pipeline.
class MultiPassDetectionResult {
  final List<MoneyDetection> finalDetections;
  final Map<CurrencyCode, double> totalsByCurrency;
  final List<PassResult> passResults;
  final int totalExecutionTimeMs;
  final int imageWidth;
  final int imageHeight;

  const MultiPassDetectionResult({
    required this.finalDetections,
    required this.totalsByCurrency,
    required this.passResults,
    required this.totalExecutionTimeMs,
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  /// Total amount for a given currency code.
  double totalFor(CurrencyCode currency) => totalsByCurrency[currency] ?? 0.0;

  /// Convenience getter for SAR total (preserved for backward compatibility).
  double get totalAmount => totalFor(CurrencyCode.sar);
}

/// Engine that performs smart multi-pass detection, enhancement,
/// adaptive tiling, and cross-pass deduplication across multiple currencies.
class SmartMultiPassDetector {
  final YOLO yolo;
  final MultiPassConfig config;

  const SmartMultiPassDetector({
    required this.yolo,
    this.config = const MultiPassConfig(),
  });

  /// Executes the Smart Multi-Pass pipeline on [originalImageBytes].
  /// [onStatusUpdate] provides user-friendly status updates for the UI.
  Future<MultiPassDetectionResult> processImage(
    Uint8List originalImageBytes, {
    void Function(String status)? onStatusUpdate,
  }) async {
    final overallStopwatch = Stopwatch()..start();
    final List<PassResult> passResults = [];

    // Step 0: Optimize and normalize image size in background isolate
    onStatusUpdate?.call('Memeriksa foto...');
    final optimizedPayload = await optimizeImageForInference(
      originalImageBytes,
      maxDimension: config.maxInferenceDimension,
    );
    final Uint8List inferenceBytes = optimizedPayload.bytes;
    final int origW = optimizedPayload.width;
    final int origH = optimizedPayload.height;

    // PASS 1: Baseline inference on optimized image
    final pass1Stopwatch = Stopwatch()..start();
    final pass1Detections = await _runInference(
      imageBytes: inferenceBytes,
      confidenceThreshold: config.candidateConfidenceThreshold,
      imageW: origW,
      imageH: origH,
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

    // ADAPTIVE EVALUATION: Decide whether additional passes are required
    final bool shouldRunEnhancedPass = _shouldRunEnhancedPass(pass1Detections);
    final bool shouldRunTiledPass = _shouldRunTiledPass(pass1Detections);

    // PASS 2: Enhanced image inference (if adaptive condition met)
    if (shouldRunEnhancedPass && config.maxAdditionalPasses >= 1) {
      onStatusUpdate?.call('Meningkatkan kejernihan foto...');
      final pass2Stopwatch = Stopwatch()..start();

      final enhancedBytes = await _enhanceImage(inferenceBytes);
      if (enhancedBytes != null) {
        final pass2Detections = await _runInference(
          imageBytes: enhancedBytes,
          confidenceThreshold: config.candidateConfidenceThreshold,
          imageW: origW,
          imageH: origH,
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

    // PASS 3: Tiled / Cropped inference (if adaptive condition met)
    if (shouldRunTiledPass && config.maxAdditionalPasses >= 2) {
      onStatusUpdate?.call('Mencari semua lembar uang...');
      final pass3Stopwatch = Stopwatch()..start();

      final tiledDetections = await _runTiledInference(
        inferenceBytes,
        config.candidateConfidenceThreshold,
        imageW: origW,
        imageH: origH,
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

    // MERGE & CROSS-PASS DEDUPLICATION WITH CONFLICT SUPPRESSION
    onStatusUpdate?.call('Memastikan hasil deteksi...');
    final List<MoneyDetection> finalDetections = mergeCrossPassDetections(
      passResults.map((p) => p.detections).toList(),
      finalThreshold: config.finalConfidenceThreshold,
      candidateThreshold: config.candidateConfidenceThreshold,
      iouThreshold: config.crossPassIoUThreshold,
      conflictIoUThreshold: config.conflictIoUThreshold,
    );

    // Multi-currency totals calculation
    final Map<CurrencyCode, double> totalsByCurrency =
        MoneyAggregator.totalsByCurrency(finalDetections);

    overallStopwatch.stop();

    debugPrint(
      '[MoneyAI] Merged: ${finalDetections.length} unique objects. Totals: $totalsByCurrency (${overallStopwatch.elapsedMilliseconds}ms total)',
    );

    return MultiPassDetectionResult(
      finalDetections: finalDetections,
      totalsByCurrency: totalsByCurrency,
      passResults: passResults,
      totalExecutionTimeMs: overallStopwatch.elapsedMilliseconds,
      imageWidth: origW,
      imageHeight: origH,
    );
  }

  // INFERENCE RUNNER

  Future<List<MoneyDetection>> _runInference({
    required Uint8List imageBytes,
    required double confidenceThreshold,
    int? imageW,
    int? imageH,
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
    final int w = (imageW != null && imageW > 0) ? imageW : 1;
    final int h = (imageH != null && imageH > 0) ? imageH : 1;

    for (final res in rawList) {
      if (res.confidence < confidenceThreshold) continue;
      final info = MoneyClassParser.parse(res.className);
      if (info == null) continue;

      list.add(
        MoneyDetection(
          className: res.className,
          currency: info.currency,
          displayName: info.displayName,
          spokenName: info.spokenName,
          amount: info.amount,
          confidence: res.confidence,
          box: Rect.fromLTWH(
            res.normalizedBox.left * w,
            res.normalizedBox.top * h,
            res.normalizedBox.width * w,
            res.normalizedBox.height * h,
          ),
          normalizedBox: res.normalizedBox,
          isCoin: info.isCoin,
        ),
      );
    }
    return list;
  }

  // ADAPTIVE LOGIC

  /// Determines whether the enhanced image pass should be executed.
  bool _shouldRunEnhancedPass(List<MoneyDetection> pass1Detections) {
    // Condition 1: No detections found in Pass 1 (possible poor lighting/contrast)
    if (pass1Detections.isEmpty) return true;

    // Condition 2: Any detection has borderline/low confidence (< 0.70)
    final hasLowConfidence = pass1Detections.any(
      (d) => d.confidence < 0.70,
    );
    if (hasLowConfidence) return true;

    // Condition 3: All detections are already confident (>= 0.70) -> Skip enhancement!
    return false;
  }

  /// Determines whether tiled/crop inference should be executed.
  bool _shouldRunTiledPass(List<MoneyDetection> pass1Detections) {
    // If Pass 1 found objects with high confidence (>= 0.72) and normal size, skip tiling
    if (pass1Detections.isNotEmpty &&
        pass1Detections.every((d) => d.confidence >= 0.72) &&
        pass1Detections.every(
          (d) =>
              d.normalizedBox.width >= 0.20 || d.normalizedBox.height >= 0.20,
        )) {
      return false;
    }

    // Condition 1: Scene has small banknote candidates (< 0.20 normalized size)
    final hasSmallObjects = pass1Detections.any(
      (d) => d.normalizedBox.width < 0.20 && d.normalizedBox.height < 0.20,
    );
    if (hasSmallObjects) return true;

    // Condition 2: Still 0 detections found (might be distant money)
    if (pass1Detections.isEmpty) return true;

    return false;
  }

  // IMAGE ENHANCEMENT (PASS 2)

  /// Performs light contrast enhancement and normalization in background isolate.
  Future<Uint8List?> _enhanceImage(Uint8List imageBytes) async {
    return compute(_enhanceImageWorker, imageBytes);
  }

  static Uint8List? _enhanceImageWorker(Uint8List imageBytes) {
    try {
      final img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      // Moderate contrast enhancement (contrast: 118)
      final enhanced = img.contrast(decoded, contrast: 118);

      // Encode to JPEG (quality: 85 for speed and low memory)
      return Uint8List.fromList(img.encodeJpg(enhanced, quality: 85));
    } catch (e) {
      debugPrint('[MoneyAI] Image enhancement worker error: $e');
      return null;
    }
  }

  // TILED / CROP INFERENCE (PASS 3)

  /// Runs inference on 4 overlapping quadrants and maps detection coordinates
  /// back into the original image normalized coordinate space.
  Future<List<MoneyDetection>> _runTiledInference(
    Uint8List baseBytes,
    double candidateThreshold, {
    required int imageW,
    required int imageH,
  }) async {
    final List<MoneyDetection> tiledResults = [];

    // Define 4 quadrants with 16% overlap to avoid cutting bills at borders
    const tiles = [
      Rect.fromLTWH(0.0, 0.0, 0.58, 0.58), // Top-Left
      Rect.fromLTWH(0.42, 0.0, 0.58, 0.58), // Top-Right
      Rect.fromLTWH(0.0, 0.42, 0.58, 0.58), // Bottom-Left
      Rect.fromLTWH(0.42, 0.42, 0.58, 0.58), // Bottom-Right
    ];

    try {
      final payload = await compute(_generateTileBytesWorker, baseBytes);
      if (payload == null || payload.tileBytes.length != tiles.length) {
        return tiledResults;
      }

      for (int i = 0; i < tiles.length; i++) {
        final tileNorm = tiles[i];
        final tileBytes = payload.tileBytes[i];

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
          final info = MoneyClassParser.parse(res.className);
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
              currency: info.currency,
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

  static _TiledCropPayload? _generateTileBytesWorker(Uint8List originalBytes) {
    try {
      final img.Image? decoded = img.decodeImage(originalBytes);
      if (decoded == null) return null;

      final int imageW = decoded.width;
      final int imageH = decoded.height;

      const tiles = [
        Rect.fromLTWH(0.0, 0.0, 0.58, 0.58),
        Rect.fromLTWH(0.42, 0.0, 0.58, 0.58),
        Rect.fromLTWH(0.0, 0.42, 0.58, 0.58),
        Rect.fromLTWH(0.42, 0.42, 0.58, 0.58),
      ];

      final List<Uint8List> tileBytes = [];
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

        tileBytes.add(Uint8List.fromList(img.encodeJpg(cropped, quality: 82)));
      }
      return _TiledCropPayload(imageW, imageH, tileBytes);
    } catch (e) {
      debugPrint('[MoneyAI] Tile generation worker error: $e');
      return null;
    }
  }

  // MERGE, CROSS-PASS DEDUPLICATION & CONFLICT RESOLUTION

  /// Merges detections from multiple passes.
  /// 1. Clustered matches of the SAME class receive confirmation boost (+0.12).
  /// 2. Conflicting denominations on the SAME physical banknote (high IoU >= [conflictIoUThreshold])
  ///    are suppressed, keeping strictly the higher-confidence detection to eliminate double-counting.
  /// 3. Size and geometry sanity filtering rejects background noise artifacts.
  static List<MoneyDetection> mergeCrossPassDetections(
    List<List<MoneyDetection>> passResults, {
    double finalThreshold = 0.58,
    double candidateThreshold = 0.42,
    double iouThreshold = 0.45,
    double conflictIoUThreshold = 0.48,
  }) {
    final List<MoneyDetection> allCandidates = [];
    for (final list in passResults) {
      allCandidates.addAll(list);
    }

    if (allCandidates.isEmpty) return [];

    // Sort descending by confidence so highest-confidence detections lead clustering
    allCandidates.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<MoneyDetection> clusters = [];
    final List<int> clusterMatchCounts = [];

    for (final candidate in allCandidates) {
      // Noise rejection: tiny boxes that are not coins
      final normArea =
          candidate.normalizedBox.width * candidate.normalizedBox.height;
      if (!candidate.isCoin && normArea < 0.005) {
        continue;
      }

      // Aspect ratio sanity check: real banknotes are elongated rectangles
      if (!candidate.isCoin) {
        final aspect =
            candidate.normalizedBox.width / candidate.normalizedBox.height;
        if (aspect < 0.22 || aspect > 4.5) {
          continue;
        }
      }

      int matchedSameClassIndex = -1;

      for (int i = 0; i < clusters.length; i++) {
        final existing = clusters[i];

        final double iou = calculateIoU(
          existing.normalizedBox,
          candidate.normalizedBox,
        );

        // Check A: Same physical bill of the SAME class/currency
        if (existing.currency == candidate.currency &&
            existing.className.toLowerCase() ==
                candidate.className.toLowerCase()) {
          if (iou >= iouThreshold) {
            matchedSameClassIndex = i;
            break;
          }
        }
      }

      if (matchedSameClassIndex >= 0) {
        // Increment confirmation count across passes
        clusterMatchCounts[matchedSameClassIndex]++;

        // Keep the detection with the higher confidence or better bounding box
        if (candidate.confidence >
            clusters[matchedSameClassIndex].confidence) {
          clusters[matchedSameClassIndex] = candidate;
        }
      } else {
        // Check B: Conflict check with existing clusters!
        // If candidate overlaps heavily with an already accepted cluster of a DIFFERENT class/currency,
        // it is a competing hypothesis on the SAME physical banknote.
        // Because allCandidates is sorted descending, the existing cluster has higher confidence.
        // We suppress the lower-confidence candidate to prevent double-counting.
        bool isConflicting = false;
        for (int i = 0; i < clusters.length; i++) {
          final existing = clusters[i];
          final double iou = calculateIoU(
            existing.normalizedBox,
            candidate.normalizedBox,
          );
          if (iou >= conflictIoUThreshold) {
            isConflicting = true;
            break;
          }
        }

        if (!isConflicting) {
          // New genuine physical object
          clusters.add(candidate);
          clusterMatchCounts.add(1);
        }
      }
    }

    // Final Thresholding & Multi-pass Confidence Boost
    final List<MoneyDetection> finalValidList = [];

    for (int i = 0; i < clusters.length; i++) {
      final item = clusters[i];
      final matchCount = clusterMatchCounts[i];

      if (item.confidence >= finalThreshold) {
        finalValidList.add(item);
      } else if (item.confidence >= candidateThreshold && matchCount >= 2) {
        // Confirmed across multiple passes: boost confidence
        final boostedConfidence = math.min(1.0, item.confidence + 0.12);
        if (boostedConfidence >= finalThreshold) {
          finalValidList.add(item.copyWith(confidence: boostedConfidence));
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

class _TiledCropPayload {
  final int imageW;
  final int imageH;
  final List<Uint8List> tileBytes;

  const _TiledCropPayload(this.imageW, this.imageH, this.tileBytes);
}

/// Payload returned by [optimizeImageForInference].
class OptimizedImagePayload {
  final Uint8List bytes;
  final int width;
  final int height;

  const OptimizedImagePayload({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

class _OptimizationParams {
  final Uint8List bytes;
  final int maxDimension;

  const _OptimizationParams(this.bytes, this.maxDimension);
}

/// Optimizes raw camera/gallery image bytes before running multi-pass inference.
/// Downscales large photos (e.g. 12MP-48MP) to [maxDimension] in an isolate to save memory and CPU.
Future<OptimizedImagePayload> optimizeImageForInference(
  Uint8List rawBytes, {
  int maxDimension = 1280,
}) {
  return compute(_optimizeImageWorker, _OptimizationParams(rawBytes, maxDimension));
}

OptimizedImagePayload _optimizeImageWorker(_OptimizationParams params) {
  try {
    final img.Image? decoded = img.decodeImage(params.bytes);
    if (decoded == null) {
      return OptimizedImagePayload(
        bytes: params.bytes,
        width: 1080,
        height: 1920,
      );
    }

    final int origW = decoded.width;
    final int origH = decoded.height;
    final int maxDim = math.max(origW, origH);

    if (maxDim <= params.maxDimension) {
      return OptimizedImagePayload(
        bytes: params.bytes,
        width: origW,
        height: origH,
      );
    }

    // Downscale preserving aspect ratio
    final double scale = params.maxDimension / maxDim;
    final int targetW = (origW * scale).round();
    final int targetH = (origH * scale).round();

    final resized = img.copyResize(
      decoded,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.linear,
    );

    final optimizedBytes = Uint8List.fromList(
      img.encodeJpg(resized, quality: 85),
    );
    return OptimizedImagePayload(
      bytes: optimizedBytes,
      width: origW,
      height: origH,
    );
  } catch (e) {
    debugPrint('[MoneyAI] optimizeImageWorker error: $e');
    return OptimizedImagePayload(
      bytes: params.bytes,
      width: 1080,
      height: 1920,
    );
  }
}
