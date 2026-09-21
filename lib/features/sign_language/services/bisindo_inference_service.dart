import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import '../models/bisindo_prediction.dart';
import 'bisindo_preprocessor.dart';

abstract interface class BisindoPredictor {
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  );
}

/// Service managing BISINDO sign language neural network inference on Android / Flutter.
///
/// Pipeline:
/// Raw Landmarks [T, 543, 3]
///       ↓
/// Preprocessing [1, 2, 100, 27] Float32List
///       ↓
/// ONNX Runtime (`hajicare_encoder.onnx`)
///       ↓
/// 256-d Embedding
///       ↓
/// Prototype Matching (`hajicare_prototypes.json`) via Euclidean (L2) distance
///       ↓
/// BisindoPrediction
class BisindoInferenceService implements BisindoPredictor {
  static const String kModelAssetPath = 'assets/models/hajicare_encoder.onnx';
  static const String kPrototypesAssetPath =
      'assets/models/hajicare_prototypes.json';

  static const String kInputTensorName = 'input';
  static const String kOutputTensorName = 'embedding';
  static const int kEmbeddingDimension = 256;

  /// Conservative open-set policy. These values are geometry based so an
  /// obviously distant embedding is not forced into one of the known classes.
  static const double kMaxRelativePrototypeDistance = 1.60;
  static const double kMinCandidateMargin = 0.04;
  static const double kMinPossibleCandidateMargin = 0.02;

  final OnnxRuntime _onnxRuntime = OnnxRuntime();
  OrtSession? _session;

  /// Runtime prototypes loaded dynamically from the asset file.
  final List<List<double>> _prototypes = [];
  final List<String> _labels = [];
  bool _isInitialized = false;
  int _lifecycleGeneration = 0;

  bool get isInitialized => _isInitialized;

  /// Loads the ONNX model session and prototype database from Flutter assets.
  Future<void> initialize() async {
    if (_isInitialized) return;
    final generation = _lifecycleGeneration;

    try {
      debugPrint(
        '[BisindoInferenceService] Initializing model and prototypes...',
      );

      // 1. Load and parse prototypes JSON
      final jsonString = await rootBundle.loadString(kPrototypesAssetPath);
      final Map<String, dynamic> data =
          json.decode(jsonString) as Map<String, dynamic>;
      final classesMap = data['classes'] as Map<String, dynamic>;

      _prototypes.clear();
      _labels.clear();

      final classEntries = classesMap.entries.toList()
        ..sort((a, b) {
          final aId = int.tryParse(a.key);
          final bId = int.tryParse(b.key);
          if (aId != null && bId != null) return aId.compareTo(bId);
          return a.key.compareTo(b.key);
        });
      if (classEntries.length < 2) {
        throw StateError('At least two BISINDO prototypes are required');
      }

      for (final entry in classEntries) {
        final key = entry.key;
        final classData = entry.value as Map<String, dynamic>;
        final label = classData['name'] as String?;
        if (label == null || label.trim().isEmpty) {
          throw StateError('Missing prototype label for class: $key');
        }
        final rawProto = classData['prototype'] as List<dynamic>;
        final List<double> protoVec = rawProto
            .map((e) => (e as num).toDouble())
            .toList();

        if (protoVec.length != kEmbeddingDimension) {
          throw StateError(
            'Expected prototype dimension $kEmbeddingDimension but got ${protoVec.length} for class $label ($key)',
          );
        }

        _prototypes.add(protoVec);
        _labels.add(label);
      }

      // 2. Create ONNX Runtime session from asset
      final session = await _onnxRuntime.createSessionFromAsset(
        kModelAssetPath,
      );
      if (generation != _lifecycleGeneration) {
        await session.close();
        return;
      }
      _session = session;

      _isInitialized = true;
      debugPrint(
        '[BisindoInferenceService] Initialized successfully with ${_prototypes.length} classes: ${_labels.join(", ")}',
      );
    } catch (e, stack) {
      debugPrint('[BisindoInferenceService] Initialization failed: $e\n$stack');
      _isInitialized = false;
      await dispose();
      rethrow;
    }
  }

  /// Runs inference on a raw sequence of MediaPipe Holistic landmarks [T, 543, 3].
  @override
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  ) async {
    if (!_isInitialized || _session == null) {
      await initialize();
    }

    final session = _session;
    if (session == null) {
      throw StateError('ONNX session is not available');
    }

    // 1. Preprocess raw landmarks to Float32List with shape [1, 2, 100, 27]
    final Float32List inputTensorData = BisindoPreprocessor.processRawLandmarks(
      landmarks,
    );

    // 2. Create native OrtValue input tensor
    final OrtValue inputOrtValue = await OrtValue.fromList(inputTensorData, [
      1,
      2,
      BisindoPreprocessor.kTargetFrames,
      BisindoPreprocessor.kNumSelectedKeypoints,
    ]);

    OrtValue? outputOrtValue;
    try {
      // 3. Run ONNX Inference
      final Map<String, OrtValue> outputs = await session.run({
        kInputTensorName: inputOrtValue,
      });

      outputOrtValue = outputs[kOutputTensorName];
      if (outputOrtValue == null) {
        throw StateError(
          'Output tensor "$kOutputTensorName" not returned by model. Available: ${outputs.keys.toList()}',
        );
      }

      // 4. Extract 256 embedding
      final List<dynamic> rawEmbedding = await outputOrtValue.asFlattenedList();
      final List<double> embedding = rawEmbedding
          .map((e) => (e as num).toDouble())
          .toList();

      if (embedding.length != kEmbeddingDimension) {
        throw StateError(
          'Expected embedding size $kEmbeddingDimension, but got ${embedding.length}',
        );
      }

      // Validate no NaN or Inf in embedding
      for (int i = 0; i < embedding.length; i++) {
        if (embedding[i].isNaN || embedding[i].isInfinite) {
          throw StateError('Embedding contains NaN or Infinity at index $i');
        }
      }

      // 5. Compare against prototypes via Euclidean (L2) distance
      return _classifyEmbedding(embedding);
    } finally {
      // 6. Dispose native OrtValue memory immediately
      try {
        await inputOrtValue.dispose();
      } catch (e) {
        debugPrint(
          '[BisindoInferenceService] Error disposing inputOrtValue: $e',
        );
      }
      if (outputOrtValue != null) {
        try {
          await outputOrtValue.dispose();
        } catch (e) {
          debugPrint(
            '[BisindoInferenceService] Error disposing outputOrtValue: $e',
          );
        }
      }
    }
  }

  /// Calculates Euclidean / L2 distances against the 8 prototype vectors,
  /// computes softmax confidence scores, and returns the top prediction.
  BisindoPrediction _classifyEmbedding(List<double> embedding) {
    final List<double> distances = [];

    for (int p = 0; p < _prototypes.length; p++) {
      final proto = _prototypes[p];
      double sumSq = 0.0;
      for (int d = 0; d < kEmbeddingDimension; d++) {
        final diff = embedding[d] - proto[d];
        sumSq += diff * diff;
      }
      final dist = math.sqrt(sumSq);
      distances.add(dist);
    }

    // Numerically stable softmax with temperature for smooth probabilities
    // Lower distance => higher logit
    const double temperature = 2.0;
    double minDistance = distances.reduce(math.min);

    double sumExp = 0.0;
    final List<double> expScores = [];
    for (int i = 0; i < distances.length; i++) {
      // (minDistance - d) is <= 0; 0 for the closest distance
      final expVal = math.exp((minDistance - distances[i]) / temperature);
      expScores.add(expVal);
      sumExp += expVal;
    }

    final List<BisindoCandidate> candidates = [];
    for (int i = 0; i < distances.length; i++) {
      final double confidence = sumExp > 0 ? (expScores[i] / sumExp) : 0.0;
      candidates.add(
        BisindoCandidate(
          classId: i,
          label: _labels[i],
          distance: distances[i],
          confidence: confidence,
        ),
      );
    }

    // Sort candidates by lowest distance first
    candidates.sort((a, b) => a.distance.compareTo(b.distance));

    final top = candidates.first;
    final runnerUp = candidates.length > 1 ? candidates[1] : top;
    final nearestPrototypeDistance = _nearestOtherPrototypeDistance(
      top.classId,
    );
    final margin = runnerUp.distance > 1e-9
        ? (runnerUp.distance - top.distance) / runnerUp.distance
        : 0.0;
    final isStrongMatch = isReliableMatch(
      winnerDistance: top.distance,
      runnerUpDistance: runnerUp.distance,
      nearestPrototypeDistance: nearestPrototypeDistance,
    );
    final isPossibleMatch =
        !isStrongMatch && margin >= kMinPossibleCandidateMargin;
    final matchQuality = isStrongMatch
        ? BisindoMatchQuality.strong
        : isPossibleMatch
        ? BisindoMatchQuality.possible
        : BisindoMatchQuality.unknown;
    final isRecognized = matchQuality != BisindoMatchQuality.unknown;

    return BisindoPrediction(
      classId: top.classId,
      label: top.label,
      confidence: top.confidence,
      distance: top.distance,
      candidates: candidates,
      isRecognized: isRecognized,
      guidance: isRecognized
          ? null
          : margin < kMinCandidateMargin
          ? 'Gerakan belum cukup jelas. Ulangi perlahan dan tahan posisi akhir.'
          : 'Isyarat belum dikenali. Pastikan tangan dan bahu terlihat penuh.',
      margin: margin,
      matchQuality: matchQuality,
    );
  }

  double _nearestOtherPrototypeDistance(int classId) {
    final source = _prototypes[classId];
    double nearest = double.infinity;

    for (int i = 0; i < _prototypes.length; i++) {
      if (i == classId) continue;
      double sumSq = 0;
      for (int d = 0; d < kEmbeddingDimension; d++) {
        final diff = source[d] - _prototypes[i][d];
        sumSq += diff * diff;
      }
      nearest = math.min(nearest, math.sqrt(sumSq));
    }

    return nearest;
  }

  @visibleForTesting
  static bool isReliableMatch({
    required double winnerDistance,
    required double runnerUpDistance,
    required double nearestPrototypeDistance,
  }) {
    if (!winnerDistance.isFinite ||
        !runnerUpDistance.isFinite ||
        !nearestPrototypeDistance.isFinite ||
        nearestPrototypeDistance <= 1e-9 ||
        runnerUpDistance <= 1e-9) {
      return false;
    }

    final relativeDistance = winnerDistance / nearestPrototypeDistance;
    final margin = (runnerUpDistance - winnerDistance) / runnerUpDistance;
    return relativeDistance <= kMaxRelativePrototypeDistance &&
        margin >= kMinCandidateMargin;
  }

  /// Runs an internal self-test using a synthetic landmark sequence to verify
  /// the full end-to-end inference pipeline without camera hardware.
  Future<BisindoPrediction> runSelfTest() async {
    final syntheticSeq = BisindoPreprocessor.generateSyntheticSequence(
      frames: 75,
    );
    return await predictFromLandmarks(syntheticSeq);
  }

  /// Release native ONNX session resources.
  Future<void> dispose() async {
    _lifecycleGeneration++;
    if (_session != null) {
      try {
        await _session!.close();
      } catch (e) {
        debugPrint('[BisindoInferenceService] Error closing session: $e');
      }
      _session = null;
    }
    _isInitialized = false;
  }
}
