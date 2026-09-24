import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../models/bisindo_prediction.dart';
import 'bisindo_preprocessor.dart';

abstract interface class BisindoPredictor {
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  );
}

/// Service managing the final deploy-ready BISINDO Tiny GRU TFLite model:
/// - Model: `assets/models/bisindo/hajicare_bisindo_gru_float32.tflite`
/// - Input shape: [1, 48, 135] Float32
/// - Output shape: [1, 23] Float32
/// - Labels: 23 classes loaded from `assets/models/bisindo/labels.json`
/// - Config: loaded dynamically from `assets/models/bisindo/model_config.json`
class BisindoInferenceService implements BisindoPredictor {
  static const String kModelAssetPath =
      'assets/models/bisindo/hajicare_bisindo_gru_float32.tflite';
  static const String kLabelsAssetPath = 'assets/models/bisindo/labels.json';
  static const String kConfigAssetPath =
      'assets/models/bisindo/model_config.json';

  // Fallback defaults if config fails to load
  static const double kDefaultConfidenceThreshold = 0.78;
  static const int kExpectedSequenceLen = 48;
  static const int kExpectedFeatureDim = 135;
  static const int kExpectedNumClasses = 23;

  tfl.Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, dynamic> _config = {};
  double _confidenceThreshold = kDefaultConfidenceThreshold;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<String> get labels => List.unmodifiable(_labels);
  double get confidenceThreshold => _confidenceThreshold;
  Map<String, dynamic> get config => Map.unmodifiable(_config);

  /// Loads configuration, labels, and the TFLite interpreter.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[BISINDO][INIT] Loading model configuration...');
      // 1. Load model_config.json
      try {
        final configStr = await rootBundle.loadString(kConfigAssetPath);
        _config = json.decode(configStr) as Map<String, dynamic>;
        if (_config.containsKey('confidence_threshold')) {
          _confidenceThreshold = (_config['confidence_threshold'] as num)
              .toDouble();
        }
        debugPrint(
          '[BISINDO][INIT] Config loaded: confidence_threshold=$_confidenceThreshold, seqLen=${_config['sequence_length']}, featureDim=${_config['feature_dim']}',
        );
      } catch (e) {
        debugPrint(
          '[BISINDO][INIT] Warning: Failed to load config ($e), using default threshold: $kDefaultConfidenceThreshold',
        );
        _confidenceThreshold = kDefaultConfidenceThreshold;
      }

      // 2. Load labels.json as source of truth
      debugPrint('[BISINDO][INIT] Loading labels from $kLabelsAssetPath...');
      final labelsStr = await rootBundle.loadString(kLabelsAssetPath);
      final Map<String, dynamic> labelsDecoded =
          json.decode(labelsStr) as Map<String, dynamic>;

      if (labelsDecoded.containsKey('labels')) {
        final rawLabels = labelsDecoded['labels'] as List;
        _labels = rawLabels.map((item) {
          if (item is Map && item.containsKey('name')) {
            return item['name'].toString();
          }
          return item.toString();
        }).toList();
      } else if (labelsDecoded.containsKey('class_names')) {
        _labels = (labelsDecoded['class_names'] as List).cast<String>();
      } else {
        throw StateError('Invalid labels format in $kLabelsAssetPath');
      }

      debugPrint(
        '[BISINDO][INIT] Loaded ${_labels.length} classes: ${_labels.join(', ')}',
      );

      if (_labels.length != kExpectedNumClasses) {
        debugPrint(
          '[BISINDO][INIT] Warning: Loaded ${_labels.length} classes, expected $kExpectedNumClasses',
        );
      }

      // 3. Load TFLite interpreter
      debugPrint(
        '[BISINDO][INIT] Loading TFLite model from $kModelAssetPath...',
      );
      final options = tfl.InterpreterOptions()..threads = 2;

      try {
        final byteData = await rootBundle.load(kModelAssetPath);
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        _interpreter = tfl.Interpreter.fromBuffer(bytes, options: options);
      } catch (e) {
        debugPrint(
          '[BISINDO][INIT] fromBuffer failed ($e), falling back to fromAsset...',
        );
        _interpreter = await tfl.Interpreter.fromAsset(
          kModelAssetPath,
          options: options,
        );
      }

      // 4. Validate tensor shapes & types
      final inTensors = _interpreter!.getInputTensors();
      final outTensors = _interpreter!.getOutputTensors();

      final inShape = inTensors.isNotEmpty ? inTensors[0].shape : [];
      final inType = inTensors.isNotEmpty ? inTensors[0].type : null;
      final outShape = outTensors.isNotEmpty ? outTensors[0].shape : [];
      final outType = outTensors.isNotEmpty ? outTensors[0].type : null;

      debugPrint(
        '[BISINDO][INIT] Input Tensor: shape=$inShape, type=$inType (Expected: [1, 48, 135] Float32)',
      );
      debugPrint(
        '[BISINDO][INIT] Output Tensor: shape=$outShape, type=$outType (Expected: [1, ${_labels.length}] Float32)',
      );

      // Verify shape constraints
      if (inShape.length != 3 ||
          inShape[0] != 1 ||
          inShape[1] != kExpectedSequenceLen ||
          inShape[2] != kExpectedFeatureDim) {
        throw StateError(
          'Tensor shape mismatch: Model input $inShape does not match expected [1, 48, 135]',
        );
      }

      final int outClasses = outShape.isNotEmpty ? outShape.last : 0;
      if (outClasses != _labels.length) {
        throw StateError(
          'Output tensor classes ($outClasses) != label count (${_labels.length})',
        );
      }

      _isInitialized = true;
      debugPrint(
        '[BISINDO][INIT] BISINDO GRU model initialized successfully ✅',
      );
    } catch (e, stack) {
      debugPrint('[BISINDO][INIT] Initialization failed: $e\n$stack');
      _isInitialized = false;
      await dispose();
      rethrow;
    }
  }

  /// Predicts gesture label from a sequence of 48 frames, each frame containing 135 features.
  BisindoPrediction predict(List<Float32List> sequence48) {
    final interpreter = _interpreter;
    if (!_isInitialized || interpreter == null) {
      throw StateError('[BISINDO] Interpreter is not initialized');
    }

    if (sequence48.length < kExpectedSequenceLen) {
      return const BisindoPrediction(
        classId: -1,
        label: '',
        confidence: 0.0,
        distance: 1.0,
        candidates: [],
        isRecognized: false,
      );
    }

    final stopwatch = Stopwatch()..start();

    // 1. Prepare input tensor [1, 48, 135]
    final List<List<List<double>>> input = [
      List.generate(kExpectedSequenceLen, (t) {
        final frameFeatures = sequence48[t];
        return List<double>.generate(kExpectedFeatureDim, (f) {
          return f < frameFeatures.length ? frameFeatures[f].toDouble() : 0.0;
        });
      }),
    ];

    // 2. Prepare output tensor [1, 23]
    final List<List<double>> output = [
      List<double>.filled(_labels.length, 0.0),
    ];

    // 3. Run inference
    interpreter.run(input, output);
    stopwatch.stop();

    final List<double> probs = output[0];

    // 4. Find best prediction and candidate ranking
    final List<MapEntry<int, double>> indexedProbs = [];
    for (int i = 0; i < probs.length; i++) {
      indexedProbs.add(MapEntry(i, probs[i]));
    }
    indexedProbs.sort((a, b) => b.value.compareTo(a.value));

    final topIdx = indexedProbs.first.key;
    final topConfidence = indexedProbs.first.value;
    final predictedLabel = _labels[topIdx];

    // Live recognition flag: marks as recognized if confidence >= 0.48 so controller
    // can evaluate hold-and-confirm stability.
    final isRecognized = topConfidence >= 0.48;

    if (kDebugMode) {
      final top3Log = indexedProbs
          .take(3)
          .map(
            (e) => '${_labels[e.key]}: ${(e.value * 100).toStringAsFixed(1)}%',
          )
          .join(', ');
      debugPrint(
        '[BISINDO] buffer=48/48 prediction=$predictedLabel confidence=${(topConfidence * 100).toStringAsFixed(1)}% (th=${(_confidenceThreshold * 100).round()}%) inference=${stopwatch.elapsedMilliseconds}ms top3=[$top3Log]',
      );
    }

    final candidates = indexedProbs
        .map(
          (e) => BisindoCandidate(
            classId: e.key,
            label: _labels[e.key],
            distance: (1.0 - e.value).clamp(0.0, 1.0),
            confidence: e.value,
          ),
        )
        .toList();

    return BisindoPrediction(
      classId: topIdx,
      label: predictedLabel,
      confidence: topConfidence,
      distance: (1.0 - topConfidence).clamp(0.0, 1.0),
      candidates: candidates,
      isRecognized: isRecognized,
    );
  }

  /// Predicts directly from a sequence of 543-landmark frames (e.g. from camera landmark stream).
  @override
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  ) async {
    if (landmarks.isEmpty) {
      return const BisindoPrediction(
        classId: -1,
        label: '',
        confidence: 0.0,
        distance: 1.0,
        candidates: [],
        isRecognized: false,
      );
    }

    // Take the most recent 48 frames or pad initial frames if buffer is filling up
    final List<List<List<double>>> sourceFrames;
    if (landmarks.length >= kExpectedSequenceLen) {
      sourceFrames = landmarks.sublist(landmarks.length - kExpectedSequenceLen);
    } else {
      final deficit = kExpectedSequenceLen - landmarks.length;
      final firstFrame = landmarks.first;
      sourceFrames = [
        for (int i = 0; i < deficit; i++) firstFrame,
        ...landmarks,
      ];
    }

    final List<Float32List> sequence135 = [];
    for (final frame in sourceFrames) {
      sequence135.add(BisindoPreprocessor.processRaw543Frame(frame));
    }

    return predict(sequence135);
  }

  /// Self-test helper generating a synthetic 48-frame sequence for diagnostic validation.
  Future<BisindoPrediction> runSelfTest() async {
    final syntheticSeq = BisindoPreprocessor.generateSyntheticSequence(
      frames: kExpectedSequenceLen,
    );
    return await predictFromLandmarks(syntheticSeq);
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
    return relativeDistance <= 1.60 && margin >= 0.04;
  }

  Future<void> dispose() async {
    try {
      _interpreter?.close();
    } catch (e) {
      debugPrint('[BISINDO] Error closing interpreter: $e');
    }
    _interpreter = null;
    _isInitialized = false;
  }
}
