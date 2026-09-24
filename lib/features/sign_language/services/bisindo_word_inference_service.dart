import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../models/bisindo_prediction.dart';
import 'bisindo_preprocessor.dart';

/// Independent inference service for BISINDO Word recognition.
///
/// Model: `assets/models/bisindo_wl_model.tflite`
/// Input shape: [1, 30, 300] Float32 (30 frames x 300 features)
/// Output shape: [1, 8] Float32
/// Labels: 8 classes from `assets/models/bisindo_wl_labels.json`
class BisindoWordInferenceService {
  static const String kModelAssetPath = 'assets/models/bisindo_wl_model.tflite';
  static const String kLabelsAssetPath = 'assets/models/bisindo_wl_labels.json';

  static const double kConfidenceThreshold = 0.65;

  tfl.Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<String> get labels => List.unmodifiable(_labels);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(
        '[BISINDO][WORD] Initializing Word TFLite interpreter and labels...',
      );

      // 1. Load labels
      final jsonStr = await rootBundle.loadString(kLabelsAssetPath);
      final Map<String, dynamic> decoded =
          json.decode(jsonStr) as Map<String, dynamic>;
      if (decoded.containsKey('labels')) {
        _labels = (decoded['labels'] as List).cast<String>();
      } else if (decoded.containsKey('index_to_label')) {
        final map = decoded['index_to_label'] as Map<String, dynamic>;
        _labels = List.generate(map.length, (i) => map['$i'] as String);
      } else {
        throw StateError('Invalid word labels format in $kLabelsAssetPath');
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
          '[BISINDO][WORD] fromBuffer failed ($e), falling back to fromAsset',
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

      debugPrint('[BISINDO][WORD] input = $inShape, input type = $inType');
      debugPrint('[BISINDO][WORD] output = $outShape, output type = $outType');
      debugPrint('[BISINDO][WORD] labels = ${_labels.length}');

      // Validate output shape matches label count
      final outputCount = outShape.isNotEmpty ? outShape.last : 0;
      if (outputCount != _labels.length) {
        throw StateError(
          '[BISINDO][WORD] Output dimension ($outputCount) does not match label count (${_labels.length})',
        );
      }

      _isInitialized = true;
      debugPrint('[BISINDO][WORD] BISINDO word ready ✅');
    } catch (e, stack) {
      debugPrint('[BISINDO][WORD] Initialization failed: $e\n$stack');
      _isInitialized = false;
      await dispose();
      rethrow;
    }
  }

  /// Runs inference strictly on a 30-frame sequence.
  ///
  /// Output is strictly mapped against [_labels] (air, belajar, hari, maaf, makan, saya, terima_kasih, tuli).
  /// Any alphabet label is strictly impossible here.
  BisindoPrediction predict(List<List<List<double>>> sequence) {
    final interpreter = _interpreter;
    if (!_isInitialized || interpreter == null) {
      throw StateError('[BISINDO][WORD] Interpreter is not initialized');
    }

    if (sequence.isEmpty) {
      return const BisindoPrediction(
        classId: -1,
        label: '',
        confidence: 0.0,
        distance: 1.0,
        candidates: [],
        isRecognized: false,
      );
    }

    // 1. Preprocess sequence into [1, 30, 300] Float32List
    final Float32List inputTensor = BisindoPreprocessor.processWordSequence(
      sequence,
    );

    // 2. Format nested input [1, 30, 300]
    final List<List<List<double>>> input = [
      List.generate(
        BisindoPreprocessor.kWordSequenceLen,
        (t) => List.generate(
          BisindoPreprocessor.kWordTemporalDim,
          (f) => inputTensor[t * BisindoPreprocessor.kWordTemporalDim + f],
        ),
      ),
    ];

    // 3. Prepare output buffer [1, num_classes]
    final List<List<double>> output = [
      List<double>.filled(_labels.length, 0.0),
    ];

    // 4. Run inference
    interpreter.run(input, output);

    final List<double> probs = output[0];

    // 5. Compute top probabilities for diagnostic logging
    final List<MapEntry<int, double>> indexedProbs = [];
    for (int i = 0; i < probs.length; i++) {
      indexedProbs.add(MapEntry(i, probs[i]));
    }
    indexedProbs.sort((a, b) => b.value.compareTo(a.value));

    final topLog = indexedProbs
        .take(3)
        .map((e) => '${_labels[e.key]}: ${(e.value * 100).toStringAsFixed(1)}%')
        .join(', ');

    final topIdx = indexedProbs.first.key;
    final topConfidence = indexedProbs.first.value;
    final predictedLabel = _labels[topIdx];

    // Development assertion: label MUST belong to word labels
    assert(
      _labels.contains(predictedLabel),
      'Predicted label $predictedLabel not in wordLabels!',
    );

    final isRecognized = topConfidence >= kConfidenceThreshold;

    if (kDebugMode && isRecognized) {
      debugPrint('[BISINDO][WORD] Recognized: $predictedLabel ($topLog)');
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

  Future<void> dispose() async {
    try {
      _interpreter?.close();
    } catch (e) {
      debugPrint('[BISINDO][WORD] Error closing interpreter: $e');
    }
    _interpreter = null;
    _isInitialized = false;
  }
}
