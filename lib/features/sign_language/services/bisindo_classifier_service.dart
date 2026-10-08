import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../models/bisindo_prediction.dart';

/// Production TFLite classifier service for BISINDO MotionGRU float16 model.
///
/// Input: [1, 48, 706] float32
/// Output: [1, 47] float32 (softmax probabilities)
class BisindoClassifierService {
  static const String kModelAssetPath =
      'assets/models/bisindo/bisindo_motion_gru_float16.tflite';
  static const String kLabelsAssetPath = 'assets/models/bisindo/labels.txt';
  static const String kMetadataAssetPath =
      'assets/models/bisindo/model_metadata.json';

  static const double kDefaultConfidenceThreshold = 0.70;
  static const int kExpectedSequenceLen = 48;
  static const int kExpectedBaseFeatureDim = 353;
  static const int kExpectedInputFeatureDim = 706;
  static const int kExpectedNumClasses = 47;

  tfl.Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, dynamic> _metadata = {};
  double _confidenceThreshold = kDefaultConfidenceThreshold;
  bool _isInitialized = false;
  bool _isRunningInference = false;
  bool _isDisposed = false;

  bool get isInitialized => _isInitialized;
  bool get isRunningInference => _isRunningInference;
  List<String> get labels => List.unmodifiable(_labels);
  double get confidenceThreshold => _confidenceThreshold;
  Map<String, dynamic> get metadata => Map.unmodifiable(_metadata);

  /// Initializes the classifier by loading metadata, labels, and the TFLite model.
  Future<void> initialize() async {
    if (_isDisposed) return;
    if (_isInitialized) return;

    try {
      debugPrint('[BISINDO_CLASSIFIER] Initializing MotionGRU service...');

      // 1. Load and validate metadata
      final metadataStr = await rootBundle.loadString(kMetadataAssetPath);
      _metadata = json.decode(metadataStr) as Map<String, dynamic>;

      final seqLen = _metadata['sequence_length'] as int? ?? 48;
      final baseDim = _metadata['base_feature_dim'] as int? ?? 353;
      final inDim = _metadata['model_input_feature_dim'] as int? ?? 706;
      final numClasses = _metadata['num_classes'] as int? ?? 47;

      if (seqLen != kExpectedSequenceLen ||
          baseDim != kExpectedBaseFeatureDim ||
          inDim != kExpectedInputFeatureDim ||
          numClasses != kExpectedNumClasses) {
        final err =
            'Model metadata mismatch: seq=$seqLen (exp $kExpectedSequenceLen), base=$baseDim (exp $kExpectedBaseFeatureDim), in=$inDim (exp $kExpectedInputFeatureDim), classes=$numClasses (exp $kExpectedNumClasses)';
        if (kDebugMode) {
          throw StateError(err);
        } else {
          debugPrint('[BISINDO_CLASSIFIER] Warning: $err');
        }
      }

      if (_metadata.containsKey('recommended_confidence_threshold_initial')) {
        _confidenceThreshold =
            (_metadata['recommended_confidence_threshold_initial'] as num)
                .toDouble();
      } else {
        _confidenceThreshold = kDefaultConfidenceThreshold;
      }

      // 2. Load labels dynamically
      final labelsStr = await rootBundle.loadString(kLabelsAssetPath);
      _labels = labelsStr
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (_labels.length != kExpectedNumClasses) {
        final err =
            'Labels count (${_labels.length}) does not match expected $kExpectedNumClasses';
        if (kDebugMode) {
          throw StateError(err);
        } else {
          debugPrint('[BISINDO_CLASSIFIER] Warning: $err');
        }
      }

      debugPrint(
        '[BISINDO_CLASSIFIER] Loaded ${_labels.length} classes: ${_labels.take(5).join(', ')} ... ${_labels.last}',
      );

      // 3. Load TFLite interpreter
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
          '[BISINDO_CLASSIFIER] fromBuffer load failed ($e), falling back to fromAsset...',
        );
        _interpreter = await tfl.Interpreter.fromAsset(
          kModelAssetPath,
          options: options,
        );
      }

      // 4. Validate input & output tensor shapes
      final inTensors = _interpreter!.getInputTensors();
      final outTensors = _interpreter!.getOutputTensors();

      if (inTensors.isEmpty || outTensors.isEmpty) {
        throw StateError(
          '[BISINDO_CLASSIFIER] Interpreter has missing tensors',
        );
      }

      final inShape = inTensors[0].shape;
      final outShape = outTensors[0].shape;

      debugPrint(
        '[BISINDO_CLASSIFIER] Input shape: $inShape, type: ${inTensors[0].type}; Output shape: $outShape, type: ${outTensors[0].type}',
      );

      // Validate input shape: [1, 48, 706]
      if (inShape.length != 3 ||
          inShape[1] != kExpectedSequenceLen ||
          inShape[2] != kExpectedInputFeatureDim) {
        final err =
            'Input tensor shape $inShape does not match expected [1, $kExpectedSequenceLen, $kExpectedInputFeatureDim]';
        if (kDebugMode) throw StateError(err);
      }

      // Validate output shape: [1, 47]
      if (outShape.length != 2 || outShape[1] != _labels.length) {
        final err =
            'Output tensor shape $outShape does not match label count ${_labels.length}';
        if (kDebugMode) throw StateError(err);
      }

      _isInitialized = true;
      debugPrint('[BISINDO_CLASSIFIER] Initialized successfully ✅');
    } catch (e, st) {
      _isInitialized = false;
      debugPrint('[BISINDO_CLASSIFIER] Initialization error: $e\n$st');
      await dispose();
      rethrow;
    }
  }

  /// Runs isolated sign recognition on the provided [1, 48, 706] input tensor.
  Future<BisindoPrediction> classify(
    List<List<List<double>>> inputTensor,
  ) async {
    final interpreter = _interpreter;
    if (!_isInitialized || interpreter == null || _isDisposed) {
      throw StateError(
        '[BISINDO_CLASSIFIER] Classifier is not initialized or disposed',
      );
    }

    if (_isRunningInference) {
      debugPrint(
        '[BISINDO_CLASSIFIER] Inference already in progress, skipping duplicate call',
      );
      return const BisindoPrediction(
        classId: -1,
        label: '',
        confidence: 0.0,
        distance: 1.0,
        candidates: [],
        isRecognized: false,
        guidance: 'Pemrosesan sedang berlangsung',
      );
    }

    _isRunningInference = true;
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Prepare output tensor [1, 47]
      final List<List<double>> output = [
        List<double>.filled(_labels.length, 0.0),
      ];

      // 2. Run TFLite inference
      interpreter.run(inputTensor, output);
      stopwatch.stop();

      final List<double> probs = output[0];

      // 3. Build indexed probabilities
      final List<MapEntry<int, double>> indexed = [];
      for (int i = 0; i < probs.length; i++) {
        indexed.add(MapEntry(i, probs[i]));
      }
      indexed.sort((a, b) => b.value.compareTo(a.value));

      final topIdx = indexed.first.key;
      final topConfidence = indexed.first.value;
      final topLabel = _labels[topIdx];
      final isRecognized = topConfidence >= _confidenceThreshold;

      // 4. Debug Top-5 logging
      if (kDebugMode) {
        final top5Str = indexed
            .take(5)
            .map(
              (e) =>
                  '${_labels[e.key]}: ${(e.value * 100).toStringAsFixed(1)}%',
            )
            .join(' | ');
        debugPrint(
          '[BISINDO_CLASSIFIER] Prediction: $topLabel ($topConfidence) in ${stopwatch.elapsedMilliseconds}ms | Top-5: $top5Str',
        );
      }

      final candidates = indexed
          .take(5)
          .map(
            (e) => BisindoCandidate(
              classId: e.key,
              label: _labels[e.key],
              distance: (1.0 - e.value).clamp(0.0, 1.0),
              confidence: e.value,
            ),
          )
          .toList();

      final margin = indexed.length > 1
          ? (topConfidence - indexed[1].value).clamp(0.0, 1.0)
          : topConfidence;

      return BisindoPrediction(
        classId: topIdx,
        label: topLabel,
        confidence: topConfidence,
        distance: (1.0 - topConfidence).clamp(0.0, 1.0),
        candidates: candidates,
        isRecognized: isRecognized,
        guidance: isRecognized
            ? null
            : 'Gerakan belum dikenali. Silakan ulangi.',
        margin: margin,
        matchQuality: isRecognized
            ? BisindoMatchQuality.strong
            : BisindoMatchQuality.unknown,
      );
    } finally {
      _isRunningInference = false;
    }
  }

  /// Disposes interpreter and resources cleanly.
  Future<void> dispose() async {
    _isDisposed = true;
    _isInitialized = false;
    try {
      _interpreter?.close();
    } catch (e) {
      debugPrint('[BISINDO_CLASSIFIER] Error closing interpreter: $e');
    }
    _interpreter = null;
  }
}
