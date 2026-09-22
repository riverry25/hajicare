import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../models/bisindo_mode.dart';
import '../models/bisindo_prediction.dart';
import 'bisindo_preprocessor.dart';

abstract interface class BisindoPredictor {
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  );
}

/// Service managing BISINDO sign language TFLite neural network inference.
///
/// Features:
/// 1. Word Recognition (`bisindo_wl_model.tflite`):
///    - Input: [1, 30, 300] Float32 (30 frames x 300 features)
///    - Output: [1, 8] Float32 softmax probabilities
///    - Labels: 8 classes from `bisindo_wl_labels.json` (air, belajar, hari, maaf, makan, saya, terima_kasih, tuli)
///
/// 2. Alphabet Recognition (`bisindo_alphabet_model_f32.tflite`):
///    - Input: [1, 86] Float32 (left hand 42 + right hand 42 + 2 presence flags)
///    - Output: [1, 27] Float32 softmax probabilities
///    - Labels: 27 classes from `bisindo_alphabet_labels.json` (A..Z + NOTHING at index 14)
class BisindoInferenceService implements BisindoPredictor {
  static const String kWordModelAssetPath =
      'assets/models/bisindo_wl_model.tflite';
  static const String kWordLabelsAssetPath =
      'assets/models/bisindo_wl_labels.json';

  static const String kAlphabetModelAssetPath =
      'assets/models/bisindo_alphabet_model_f32.tflite';
  static const String kAlphabetLabelsAssetPath =
      'assets/models/bisindo_alphabet_labels.json';

  tfl.Interpreter? _wordInterpreter;
  tfl.Interpreter? _alphabetInterpreter;

  List<String> _wordLabels = [];
  List<String> _alphabetLabels = [];

  bool _isInitialized = false;
  BisindoMode currentMode = BisindoMode.unified;

  bool get isInitialized => _isInitialized;
  List<String> get wordLabels => List.unmodifiable(_wordLabels);
  List<String> get alphabetLabels => List.unmodifiable(_alphabetLabels);

  Future<tfl.Interpreter> _loadInterpreter(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      return tfl.Interpreter.fromBuffer(
        bytes,
        options: tfl.InterpreterOptions()..threads = 2,
      );
    } catch (e) {
      debugPrint(
        '[BISINDO][MODEL] fromBuffer failed for $assetPath ($e), fallback to fromAsset',
      );
      return await tfl.Interpreter.fromAsset(
        assetPath,
        options: tfl.InterpreterOptions()..threads = 2,
      );
    }
  }

  /// Initializes both TFLite models and loads label definitions from assets.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(
        '[BISINDO][MODEL] Initializing TFLite interpreters and labels...',
      );

      // 1. Load Word Labels from JSON
      final wordJsonStr = await rootBundle.loadString(kWordLabelsAssetPath);
      final Map<String, dynamic> wordData =
          json.decode(wordJsonStr) as Map<String, dynamic>;
      if (wordData.containsKey('labels')) {
        _wordLabels = (wordData['labels'] as List).cast<String>();
      } else if (wordData.containsKey('index_to_label')) {
        final map = wordData['index_to_label'] as Map<String, dynamic>;
        _wordLabels = List.generate(map.length, (i) => map['$i'] as String);
      } else {
        throw StateError('Invalid structure in $kWordLabelsAssetPath');
      }

      // 2. Load Alphabet Labels from JSON
      final alphaJsonStr = await rootBundle.loadString(
        kAlphabetLabelsAssetPath,
      );
      final List<dynamic> alphaList =
          json.decode(alphaJsonStr) as List<dynamic>;
      _alphabetLabels = alphaList.cast<String>();

      // 3. Load Word Model TFLite Interpreter (fromBuffer with fromAsset fallback)
      _wordInterpreter = await _loadInterpreter(kWordModelAssetPath);
      _logTensorInfo('Word Model', _wordInterpreter!);

      // 4. Load Alphabet Model TFLite Interpreter (fromBuffer with fromAsset fallback)
      _alphabetInterpreter = await _loadInterpreter(kAlphabetModelAssetPath);
      _logTensorInfo('Alphabet Model', _alphabetInterpreter!);

      _isInitialized = true;
      debugPrint(
        '[BISINDO][MODEL] Successfully loaded Word model (${_wordLabels.length} labels) '
        'and Alphabet model (${_alphabetLabels.length} labels)',
      );
    } catch (e, stack) {
      debugPrint('[BISINDO][MODEL] Initialization failed: $e\n$stack');
      _isInitialized = false;
      await dispose();
      rethrow;
    }
  }

  void _logTensorInfo(String name, tfl.Interpreter interpreter) {
    try {
      final inTensors = interpreter.getInputTensors();
      final outTensors = interpreter.getOutputTensors();
      for (final t in inTensors) {
        debugPrint(
          '[BISINDO][MODEL] $name input: ${t.name} shape=${t.shape} type=${t.type}',
        );
      }
      for (final t in outTensors) {
        debugPrint(
          '[BISINDO][MODEL] $name output: ${t.name} shape=${t.shape} type=${t.type}',
        );
      }
    } catch (e) {
      debugPrint('[BISINDO][MODEL] Error reading tensor info: $e');
    }
  }

  /// Predicts sign language token based on currently active recognition mode.
  @override
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (currentMode == BisindoMode.alphabet) {
      if (landmarks.isEmpty) {
        return _createEmptyAlphabetPrediction();
      }
      return predictAlphabet(landmarks.last);
    } else if (currentMode == BisindoMode.word) {
      return predictWord(landmarks);
    } else {
      return predictUnified(landmarks);
    }
  }

  /// Unified multi-modal prediction running both Alphabet and Word models
  /// on the input stream to eliminate manual switching.
  Future<BisindoPrediction> predictUnified(
    List<List<List<double>>> sequence,
  ) async {
    if (sequence.isEmpty) {
      return _createEmptyAlphabetPrediction();
    }

    // 1. Evaluate alphabet on the latest frame
    final alphaPred = await predictAlphabet(sequence.last);

    // 2. If buffer has fewer than 15 frames, return alphabet result if detected
    if (sequence.length < 15) {
      return alphaPred.isRecognized
          ? alphaPred
          : _createEmptyAlphabetPrediction();
    }

    // 3. Evaluate word model on temporal sequence
    final wordPred = await predictWord(sequence);

    // 4. Arbitration between Word and Alphabet:
    if (!alphaPred.isRecognized && !wordPred.isRecognized) {
      return wordPred.confidence > alphaPred.confidence ? wordPred : alphaPred;
    }
    if (alphaPred.isRecognized && !wordPred.isRecognized) {
      return alphaPred;
    }
    if (!alphaPred.isRecognized && wordPred.isRecognized) {
      return wordPred;
    }

    // Both detected: compare confidences
    if (wordPred.confidence >= alphaPred.confidence) {
      return wordPred;
    } else {
      return alphaPred;
    }
  }

  /// Runs inference on a 30-frame sequence using `bisindo_wl_model.tflite` [1, 30, 300].
  Future<BisindoPrediction> predictWord(
    List<List<List<double>>> sequence,
  ) async {
    final interpreter = _wordInterpreter;
    if (!_isInitialized || interpreter == null) {
      throw StateError('Word model interpreter is not initialized');
    }

    try {
      // 1. Preprocess sequence into [1, 30, 300] Float32List
      final Float32List inputTensor = BisindoPreprocessor.processWordSequence(
        sequence,
      );

      // 2. Format input as nested List [1, 30, 300]
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
      final int numClasses = _wordLabels.isNotEmpty ? _wordLabels.length : 8;
      final List<List<double>> output = [List<double>.filled(numClasses, 0.0)];

      // 4. Run TFLite inference
      interpreter.run(input, output);

      // 5. Build prediction from softmax probabilities
      final List<double> probs = output[0];
      return _buildWordPrediction(probs);
    } catch (e, stack) {
      debugPrint('[BISINDO][INFERENCE] Word inference error: $e\n$stack');
      rethrow;
    }
  }

  /// Runs inference on a single frame using `bisindo_alphabet_model_f32.tflite` [1, 86].
  Future<BisindoPrediction> predictAlphabet(List<List<double>> frame) async {
    final interpreter = _alphabetInterpreter;
    if (!_isInitialized || interpreter == null) {
      throw StateError('Alphabet model interpreter is not initialized');
    }

    try {
      // 1. Preprocess frame into [1, 86] Float32List
      final Float32List inputTensor = BisindoPreprocessor.processAlphabetFrame(
        frame,
      );

      // 2. Format input as nested List [1, 86]
      final List<List<double>> input = [
        List.generate(
          BisindoPreprocessor.kAlphabetFeatureDim,
          (i) => inputTensor[i],
        ),
      ];

      // 3. Prepare output buffer [1, num_classes] (27)
      final int numClasses = _alphabetLabels.isNotEmpty
          ? _alphabetLabels.length
          : 27;
      final List<List<double>> output = [List<double>.filled(numClasses, 0.0)];

      // 4. Run TFLite inference
      interpreter.run(input, output);

      // 5. Build prediction from softmax probabilities
      final List<double> probs = output[0];
      return _buildAlphabetPrediction(probs);
    } catch (e, stack) {
      debugPrint('[BISINDO][INFERENCE] Alphabet inference error: $e\n$stack');
      rethrow;
    }
  }

  BisindoPrediction _buildWordPrediction(List<double> probs) {
    final List<BisindoCandidate> candidates = [];
    for (int i = 0; i < probs.length; i++) {
      final label = i < _wordLabels.length ? _wordLabels[i] : 'class_$i';
      candidates.add(
        BisindoCandidate(
          classId: i,
          label: label,
          distance: 1.0 - probs[i],
          confidence: probs[i],
        ),
      );
    }

    // Sort by highest confidence first
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    final top = candidates.first;
    final runnerUp = candidates.length > 1 ? candidates[1] : top;
    final margin = top.confidence - runnerUp.confidence;

    final isStrong = top.confidence >= 0.75 && margin >= 0.15;
    final isPossible = top.confidence >= 0.60;
    final quality = isStrong
        ? BisindoMatchQuality.strong
        : isPossible
        ? BisindoMatchQuality.possible
        : BisindoMatchQuality.unknown;

    return BisindoPrediction(
      classId: top.classId,
      label: top.label,
      confidence: top.confidence,
      distance: top.distance,
      candidates: candidates,
      isRecognized: quality != BisindoMatchQuality.unknown,
      margin: margin,
      matchQuality: quality,
      guidance: quality == BisindoMatchQuality.unknown
          ? 'Gerakan belum cukup jelas. Lakukan gestur dengan mantap.'
          : null,
    );
  }

  BisindoPrediction _buildAlphabetPrediction(List<double> probs) {
    final List<BisindoCandidate> candidates = [];
    for (int i = 0; i < probs.length; i++) {
      final label = i < _alphabetLabels.length
          ? _alphabetLabels[i]
          : 'class_$i';
      candidates.add(
        BisindoCandidate(
          classId: i,
          label: label,
          distance: 1.0 - probs[i],
          confidence: probs[i],
        ),
      );
    }

    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    final top = candidates.first;

    // Index 14 in bisindo_alphabet_labels.json is "NOTHING"
    final bool isNothing =
        top.label.toUpperCase() == 'NOTHING' || top.classId == 14;
    final bool isRecognized = !isNothing && top.confidence >= 0.65;

    return BisindoPrediction(
      classId: top.classId,
      label: isNothing ? '' : top.label,
      confidence: top.confidence,
      distance: top.distance,
      candidates: candidates,
      isRecognized: isRecognized,
      margin: candidates.length > 1
          ? (top.confidence - candidates[1].confidence)
          : 0.0,
      matchQuality: isRecognized
          ? BisindoMatchQuality.strong
          : BisindoMatchQuality.unknown,
      guidance: isNothing ? 'Tunjukkan tangan untuk mengeja huruf' : null,
    );
  }

  BisindoPrediction _createEmptyAlphabetPrediction() {
    return const BisindoPrediction(
      classId: 14,
      label: '',
      confidence: 0.0,
      distance: 1.0,
      candidates: [],
      isRecognized: false,
      matchQuality: BisindoMatchQuality.unknown,
      guidance: 'Tunjukkan tangan ke kamera',
    );
  }

  /// Self-test helper for tests without camera hardware.
  Future<BisindoPrediction> runSelfTest() async {
    final syntheticSeq = BisindoPreprocessor.generateSyntheticSequence(
      frames: 30,
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
      _wordInterpreter?.close();
      _alphabetInterpreter?.close();
    } catch (e) {
      debugPrint('[BISINDO][MODEL] Error closing interpreters: $e');
    }
    _wordInterpreter = null;
    _alphabetInterpreter = null;
    _isInitialized = false;
  }
}
