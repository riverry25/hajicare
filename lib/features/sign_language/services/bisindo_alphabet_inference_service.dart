import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../models/bisindo_prediction.dart';
import 'bisindo_preprocessor.dart';

/// Independent inference service for BISINDO Alphabet recognition.
///
/// Model: `assets/models/bisindo_alphabet_model_f32.tflite`
/// Input shape: [1, 86] Float32
/// Output shape: [1, 27] Float32
/// Labels: 27 classes from `assets/models/bisindo_alphabet_labels.json`
class BisindoAlphabetInferenceService {
  static const String kModelAssetPath =
      'assets/models/bisindo_alphabet_model_f32.tflite';
  static const String kLabelsAssetPath =
      'assets/models/bisindo_alphabet_labels.json';

  static const double kConfidenceThreshold = 0.55;

  tfl.Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<String> get labels => List.unmodifiable(_labels);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(
        '[BISINDO][ALPHABET] Initializing Alphabet TFLite interpreter and labels...',
      );

      // 1. Load labels
      final jsonStr = await rootBundle.loadString(kLabelsAssetPath);
      final dynamic decoded = json.decode(jsonStr);
      if (decoded is List) {
        _labels = decoded.cast<String>();
      } else if (decoded is Map && decoded.containsKey('labels')) {
        _labels = (decoded['labels'] as List).cast<String>();
      } else {
        throw StateError('Invalid alphabet labels format in $kLabelsAssetPath');
      }

      // 2. Load model with plain CPU InterpreterOptions (threads = 2)
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
          '[BISINDO][ALPHABET] fromBuffer failed ($e), falling back to fromAsset',
        );
        _interpreter = await tfl.Interpreter.fromAsset(
          kModelAssetPath,
          options: options,
        );
      }

      // 3. Inspect real tensors
      final inTensors = _interpreter!.getInputTensors();
      final outTensors = _interpreter!.getOutputTensors();

      final inShape = inTensors.isNotEmpty ? inTensors[0].shape : [];
      final inType = inTensors.isNotEmpty ? inTensors[0].type : null;
      final outShape = outTensors.isNotEmpty ? outTensors[0].shape : [];
      final outType = outTensors.isNotEmpty ? outTensors[0].type : null;

      debugPrint('[BISINDO][ALPHABET] input = $inShape, input type = $inType');
      debugPrint(
        '[BISINDO][ALPHABET] output = $outShape, output type = $outType',
      );
      debugPrint('[BISINDO][ALPHABET] labels = ${_labels.length}');

      // Validate output shape matches label count
      final outputCount = outShape.isNotEmpty ? outShape.last : 0;
      if (outputCount != _labels.length) {
        throw StateError(
          '[BISINDO][ALPHABET] Output dimension ($outputCount) does not match label count (${_labels.length})',
        );
      }

      _isInitialized = true;
      debugPrint('[BISINDO][ALPHABET] BISINDO alphabet ready ✅');
    } catch (e, stack) {
      debugPrint('[BISINDO][ALPHABET] Initialization failed: $e\n$stack');
      _isInitialized = false;
      await dispose();
      rethrow;
    }
  }

  /// Runs inference strictly on a single 543-landmark frame.
  ///
  /// Output is strictly mapped against [_labels] (A..Z, NOTHING).
  /// Any word label like 'maaf' or 'belajar' is strictly impossible here.
  BisindoPrediction predict(List<List<double>> frame) {
    final interpreter = _interpreter;
    if (!_isInitialized || interpreter == null) {
      throw StateError('[BISINDO][ALPHABET] Interpreter is not initialized');
    }

    if (frame.isEmpty) {
      return const BisindoPrediction(
        classId: -1,
        label: '',
        confidence: 0.0,
        distance: 1.0,
        candidates: [],
        isRecognized: false,
      );
    }

    // 1. Preprocess frame into [1, 86] Float32List
    final Float32List inputTensor = BisindoPreprocessor.processAlphabetFrame(
      frame,
    );

    // 2. Prepare input and output buffers
    final List<List<double>> input = [inputTensor];
    final List<List<double>> output = [
      List<double>.filled(_labels.length, 0.0),
    ];

    // 3. Run inference
    interpreter.run(input, output);

    final List<double> probs = output[0];

    // 4. Compute Top 5 probabilities for diagnostic logging
    final List<MapEntry<int, double>> indexedProbs = [];
    for (int i = 0; i < probs.length; i++) {
      indexedProbs.add(MapEntry(i, probs[i]));
    }
    indexedProbs.sort((a, b) => b.value.compareTo(a.value));

    final top5 = indexedProbs.take(5).toList();
    final top5Log = top5
        .map((e) => '${_labels[e.key]}: ${(e.value * 100).toStringAsFixed(1)}%')
        .join(', ');

    final topIdx = top5.first.key;
    final topConfidence = top5.first.value;
    final predictedLabel = _labels[topIdx];

    // Development assertion: label MUST belong to alphabet labels
    assert(
      _labels.contains(predictedLabel),
      'Predicted label $predictedLabel not in alphabetLabels!',
    );

    // Filter out NOTHING class or low confidence
    final isNothing = predictedLabel.toUpperCase() == 'NOTHING';
    final isRecognized = !isNothing && topConfidence >= kConfidenceThreshold;

    if (kDebugMode && isRecognized) {
      debugPrint('[BISINDO][ALPHABET] Recognized: $predictedLabel ($top5Log)');
    }

    final candidates = top5
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
      classId: isNothing ? -1 : topIdx,
      label: isNothing ? '' : predictedLabel,
      confidence: topConfidence,
      distance: (1.0 - topConfidence).clamp(0.0, 1.0),
      candidates: candidates,
      isRecognized: isRecognized,
    );
  }

  Future<void> dispose() async {
    try {
      _interpreter?.close();
    } catch (e) {
      debugPrint('[BISINDO][ALPHABET] Error closing interpreter: $e');
    }
    _interpreter = null;
    _isInitialized = false;
  }
}
