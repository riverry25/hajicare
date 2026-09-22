import 'package:flutter/foundation.dart';

import '../models/bisindo_mode.dart';
import '../models/bisindo_prediction.dart';
import 'bisindo_alphabet_inference_service.dart';
import 'bisindo_preprocessor.dart';
import 'bisindo_word_inference_service.dart';

abstract interface class BisindoPredictor {
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  );
}

/// Coordinator service managing independent BISINDO TFLite model services.
///
/// Features:
/// 1. Alphabet Service (`BisindoAlphabetInferenceService`):
///    - Dedicated Interpreter & separate labels (`assets/models/bisindo_alphabet_labels.json`)
///    - Shape: [1, 86] -> [1, 27]
///
/// 2. Word Service (`BisindoWordInferenceService`):
///    - Dedicated Interpreter & separate labels (`assets/models/bisindo_wl_labels.json`)
///    - Shape: [1, 30, 300] -> [1, 8]
///
/// Complete isolation:
/// - When mode is ALPHABET, only Alphabet interpreter runs. Word model NEVER runs.
/// - When mode is WORD, only Word interpreter runs. Alphabet model NEVER runs.
class BisindoInferenceService implements BisindoPredictor {
  final BisindoAlphabetInferenceService alphabetService;
  final BisindoWordInferenceService wordService;

  BisindoMode currentMode = BisindoMode.alphabet;

  BisindoInferenceService({
    BisindoAlphabetInferenceService? alphabetService,
    BisindoWordInferenceService? wordService,
  }) : alphabetService = alphabetService ?? BisindoAlphabetInferenceService(),
       wordService = wordService ?? BisindoWordInferenceService();

  bool get isInitialized =>
      alphabetService.isInitialized && wordService.isInitialized;

  List<String> get alphabetLabels => alphabetService.labels;
  List<String> get wordLabels => wordService.labels;

  /// Initializes both models independently with clear status logging.
  Future<void> initialize() async {
    Object? alphabetError;
    Object? wordError;

    try {
      await alphabetService.initialize();
    } catch (e) {
      alphabetError = e;
      debugPrint('[BISINDO][INIT] Alphabet service initialization failed: $e');
    }

    try {
      await wordService.initialize();
    } catch (e) {
      wordError = e;
      debugPrint('[BISINDO][INIT] Word service initialization failed: $e');
    }

    if (alphabetError != null && wordError != null) {
      throw StateError(
        'Both BISINDO models failed to initialize:\n'
        'Alphabet: $alphabetError\nWord: $wordError',
      );
    } else if (alphabetError != null) {
      debugPrint(
        '[BISINDO][INIT] Warning: Alphabet failed, but Word model is ready.',
      );
    } else if (wordError != null) {
      debugPrint(
        '[BISINDO][INIT] Warning: Word failed, but Alphabet model is ready.',
      );
    }
  }

  /// Strict mode routing:
  /// - In ALPHABET mode: ONLY runs alphabetService. Never produces a word label.
  /// - In WORD mode: ONLY runs wordService. Never produces an alphabet label.
  @override
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  ) async {
    if (currentMode == BisindoMode.alphabet) {
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
      final pred = alphabetService.predict(landmarks.last);

      // Section 13 Safety Check: An alphabet prediction must NEVER produce a word label
      if (wordLabels.isNotEmpty &&
          wordLabels.contains(pred.label.toLowerCase())) {
        debugPrint(
          '[BISINDO][ROUTING_ERROR] Alphabet mode produced word label "${pred.label}"! Rejecting.',
        );
        throw StateError(
          'Pipeline routing error: Alphabet mode produced word label "${pred.label}"',
        );
      }

      return pred;
    } else {
      // WORD mode
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
      final pred = wordService.predict(landmarks);

      // Safety check: A word prediction must NEVER produce a single alphabet letter
      if (pred.label.length == 1 &&
          alphabetLabels.contains(pred.label.toUpperCase())) {
        debugPrint(
          '[BISINDO][ROUTING_ERROR] Word mode produced alphabet label "${pred.label}"! Rejecting.',
        );
        throw StateError(
          'Pipeline routing error: Word mode produced alphabet label "${pred.label}"',
        );
      }

      return pred;
    }
  }

  /// Self-test helper for unit tests without camera hardware.
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
    await alphabetService.dispose();
    await wordService.dispose();
  }
}
