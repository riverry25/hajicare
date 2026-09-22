import 'dart:math' as math;
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
/// - When mode is UNIFIED, seamlessly recognizes both alphabet and words without manual switching.
///   Static hand postures are directed to Alphabet; dynamic motion signs are evaluated for Words.
/// - When mode is ALPHABET, only Alphabet interpreter runs. Word model NEVER runs.
/// - When mode is WORD, only Word interpreter runs. Alphabet model NEVER runs.
class BisindoInferenceService implements BisindoPredictor {
  final BisindoAlphabetInferenceService alphabetService;
  final BisindoWordInferenceService wordService;

  BisindoMode currentMode = BisindoMode.unified;

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

  /// Calculates average hand/wrist displacement between consecutive frames.
  /// Dynamic word signs have active trajectories (> 0.015), while fingerspelling
  /// alphabet signs are held steadily (< 0.015).
  static double _calculateHandMotion(List<List<List<double>>> sequence) {
    if (sequence.length < 2) return 0.0;
    double displacement = 0.0;
    int count = 0;
    for (int i = 1; i < sequence.length; i++) {
      final prev = sequence[i - 1];
      final curr = sequence[i];
      for (final idx in [15, 16, 501, 522]) {
        if (idx < prev.length && idx < curr.length) {
          final p = prev[idx];
          final c = curr[idx];
          if (p.length >= 2 && c.length >= 2) {
            final dx = c[0] - p[0];
            final dy = c[1] - p[1];
            displacement += math.sqrt(dx * dx + dy * dy);
            count++;
          }
        }
      }
    }
    return count > 0 ? (displacement / count) : 0.0;
  }

  /// Unified prediction intelligently combining Alphabet and Word models.
  Future<BisindoPrediction> _predictUnified(
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

    // 1. Evaluate alphabet on the latest frame
    final alphaPred = alphabetService.predict(landmarks.last);

    // 2. If buffer does not have enough frames for word sequence, return alphabet
    if (landmarks.length < 15) {
      return alphaPred;
    }

    // 3. Compute dynamic hand motion across the sequence
    final motion = _calculateHandMotion(landmarks);

    // If hands are static / holding a hand posture, the sign is fingerspelling (alphabet).
    // Word model must NOT trigger when hands are static, preventing "U -> MAAF" false positives.
    if (motion < 0.015) {
      return alphaPred;
    }

    // 4. Dynamic motion detected: evaluate word sequence
    final wordPred = wordService.predict(landmarks);

    // 5. Arbitration:
    // If the word model is strongly confident with dynamic motion, it is a word gesture!
    if (wordPred.isRecognized && wordPred.confidence >= 0.75) {
      return wordPred;
    }

    // Otherwise, if alphabet is recognized, prefer alphabet
    if (alphaPred.isRecognized) {
      return alphaPred;
    }

    // Fall back to word prediction if recognized with moderate confidence
    if (wordPred.isRecognized) {
      return wordPred;
    }

    return alphaPred;
  }

  /// Mode routing:
  /// - UNIFIED mode: Seamlessly detects both alphabet letters and dynamic words.
  /// - ALPHABET mode: ONLY runs alphabetService. Never produces a word label.
  /// - WORD mode: ONLY runs wordService. Never produces an alphabet label.
  @override
  Future<BisindoPrediction> predictFromLandmarks(
    List<List<List<double>>> landmarks,
  ) async {
    if (currentMode == BisindoMode.unified) {
      return _predictUnified(landmarks);
    } else if (currentMode == BisindoMode.alphabet) {
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
