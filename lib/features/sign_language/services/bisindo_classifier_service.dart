import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../models/bisindo_prediction.dart';
import '../models/sign_language_model.dart';

/// Production TFLite classifier service for MotionGRU float16 models (SIBI & BISINDO).
///
/// Input: [1, 48, 706] float32
/// Output: [1, num_classes] float32 (softmax probabilities)
class BisindoClassifierService {
  static const double kDefaultConfidenceThreshold = 0.70;
  static const int kExpectedSequenceLen = 48;
  static const int kExpectedBaseFeatureDim = 353;
  static const int kExpectedInputFeatureDim = 706;
  static const int kExpectedNumClasses = 47;

  SignLanguageModelConfig _currentConfig = SignLanguageModelConfig.bisindo;
  SignLanguageModel get currentModel => _currentConfig.model;
  SignLanguageModelConfig get currentConfig => _currentConfig;

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
  Future<void> initialize({
    SignLanguageModel model = SignLanguageModel.bisindo,
  }) async {
    await loadModel(SignLanguageModelConfig.forModel(model));
  }

  /// Hot-swaps the active model (SIBI or BISINDO) cleanly and smoothly.
  Future<void> loadModel(SignLanguageModelConfig config) async {
    if (_isDisposed) return;

    // Safely close existing interpreter
    try {
      _interpreter?.close();
    } catch (_) {}
    _interpreter = null;
    _isInitialized = false;
    _currentConfig = config;

    try {
      debugPrint(
        '[SIGN_CLASSIFIER] Initializing ${config.model.displayName} MotionGRU service...',
      );

      // 1. Load and validate metadata if available
      if (config.configAsset != null) {
        try {
          final metadataStr = await rootBundle.loadString(config.configAsset!);
          _metadata = json.decode(metadataStr) as Map<String, dynamic>;

          if (_metadata.containsKey(
            'recommended_confidence_threshold_initial',
          )) {
            _confidenceThreshold =
                (_metadata['recommended_confidence_threshold_initial'] as num)
                    .toDouble();
          } else {
            _confidenceThreshold = config.defaultConfidenceThreshold;
          }
        } catch (e) {
          debugPrint(
            '[SIGN_CLASSIFIER] Metadata load warning ($e), using default threshold: ${config.defaultConfidenceThreshold}',
          );
          _confidenceThreshold = config.defaultConfidenceThreshold;
        }
      } else {
        _confidenceThreshold = config.defaultConfidenceThreshold;
      }

      // 2. Load labels dynamically
      final labelsStr = await rootBundle.loadString(config.labelAsset);
      _labels = labelsStr
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      debugPrint(
        '[SIGN_CLASSIFIER] Loaded ${_labels.length} classes for ${config.model.displayName}: ${_labels.take(5).join(', ')} ... ${_labels.last}',
      );

      // 3. Load TFLite interpreter
      final options = tfl.InterpreterOptions()..threads = 2;
      try {
        final byteData = await rootBundle.load(config.modelAsset);
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        _interpreter = tfl.Interpreter.fromBuffer(bytes, options: options);
      } catch (e) {
        debugPrint(
          '[SIGN_CLASSIFIER] fromBuffer load failed ($e), falling back to fromAsset...',
        );
        _interpreter = await tfl.Interpreter.fromAsset(
          config.modelAsset,
          options: options,
        );
      }

      // 4. Validate input & output tensor shapes
      final inTensors = _interpreter!.getInputTensors();
      final outTensors = _interpreter!.getOutputTensors();

      if (inTensors.isEmpty || outTensors.isEmpty) {
        throw StateError('[SIGN_CLASSIFIER] Interpreter has missing tensors');
      }

      final inShape = inTensors[0].shape;
      final outShape = outTensors[0].shape;

      debugPrint(
        '[SIGN_CLASSIFIER] ${config.model.displayName} Input: $inShape, type: ${inTensors[0].type}; Output: $outShape, type: ${outTensors[0].type}',
      );

      // Validate input shape: [1, 48, 706]
      if (inShape.length != 3 ||
          inShape[1] != kExpectedSequenceLen ||
          inShape[2] != kExpectedInputFeatureDim) {
        final err =
            'Input tensor shape $inShape does not match expected [1, $kExpectedSequenceLen, $kExpectedInputFeatureDim] for ${config.model.displayName}';
        if (kDebugMode) throw StateError(err);
      }

      // Validate output shape: [1, num_classes]
      if (outShape.length != 2 || outShape[1] != _labels.length) {
        final err =
            'Output tensor shape $outShape does not match label count ${_labels.length} for ${config.model.displayName}';
        if (kDebugMode) throw StateError(err);
      }

      _isInitialized = true;
      debugPrint(
        '[SIGN_CLASSIFIER] ${config.model.displayName} initialized successfully ✅',
      );
    } catch (e, st) {
      _isInitialized = false;
      debugPrint(
        '[SIGN_CLASSIFIER] Initialization error for ${config.model.displayName}: $e\n$st',
      );
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
