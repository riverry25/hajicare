import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'cams_canonical_frames.dart';

class CamsResult {
  final CamsDecision decision;
  final String intent;
  final double confidence;
  final List<String> normalizedTokens;
  final List<String> oovTokens;
  final String idC0;
  final String idC3;
  final String enText;
  final String arText;
  final List<CamsClarificationOption> clarificationOptions;
  final String reason;
  final CamsLocation location;
  final CamsInterlocutorRole role;

  const CamsResult({
    required this.decision,
    required this.intent,
    required this.confidence,
    required this.normalizedTokens,
    this.oovTokens = const [],
    this.idC0 = '',
    this.idC3 = '',
    this.enText = '',
    this.arText = '',
    this.clarificationOptions = const [],
    this.reason = '',
    this.location = CamsLocation.unknown,
    this.role = CamsInterlocutorRole.unknown,
  });

  bool get isSuccess => decision == CamsDecision.proceedTranslate;
  bool get needsClarification => decision == CamsDecision.requestClarification;
  bool get isOov => decision == CamsDecision.rejectOov;
}

/// 100% Offline CAMS NLP v3 Engine (TF-IDF (1,2) + Context C3 + 11-Class Logistic Regression).
class CamsNlpEngine {
  static final CamsNlpEngine instance = CamsNlpEngine._internal();

  factory CamsNlpEngine() => instance;

  CamsNlpEngine._internal();

  static const String kDefaultAssetPath =
      'assets/cams/cams_v3_offline_weights.json';

  static const Set<String> _ambiguousOnlyVocabulary = {
    'BANTU',
    'APA',
    'SAYA',
    'AKU',
    'YA',
    'TIDAK',
    'DI',
    'KE',
    'KAN',
    'MANA',
    'DIMANA',
  };

  bool _isLoaded = false;
  Map<String, int> _vocabulary = const {};
  List<double> _idf = const [];
  List<String> _classes = const [];
  List<List<double>> _coef = const [];
  List<double> _intercept = const [];
  Set<String> _mgru86Concepts = const {};
  double _safetyGateThreshold = 0.45;

  bool get isLoaded => _isLoaded;
  Set<String> get mgru86Concepts => _mgru86Concepts;
  List<String> get classes => _classes;
  double get safetyGateThreshold => _safetyGateThreshold;

  /// Loads offline model weights from Flutter asset bundle once.
  Future<void> ensureLoaded({String assetPath = kDefaultAssetPath}) async {
    if (_isLoaded) return;
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    loadFromJsonMap(decoded);
  }

  /// Directly loads weights from a decoded JSON map (used in unit tests & asset init).
  @visibleForTesting
  void loadFromJsonMap(Map<String, dynamic> data) {
    final rawVocab = data['vocabulary'] as Map<String, dynamic>? ?? const {};
    _vocabulary = rawVocab.map(
      (key, value) => MapEntry(key.toUpperCase(), (value as num).toInt()),
    );

    final rawIdf = data['idf'] as List<dynamic>? ?? const [];
    _idf = rawIdf
        .map((e) => (e as num).toDouble())
        .toList(growable: false);

    final rawClasses = data['classes'] as List<dynamic>? ?? const [];
    _classes = rawClasses
        .map((e) => e.toString())
        .toList(growable: false);

    final rawCoef = data['coef'] as List<dynamic>? ?? const [];
    _coef = rawCoef
        .map(
          (row) => (row as List<dynamic>)
              .map((v) => (v as num).toDouble())
              .toList(growable: false),
        )
        .toList(growable: false);

    final rawIntercept = data['intercept'] as List<dynamic>? ?? const [];
    _intercept = rawIntercept
        .map((e) => (e as num).toDouble())
        .toList(growable: false);

    final rawConcepts = data['mgru_86_concepts'] as List<dynamic>? ?? const [];
    _mgru86Concepts = rawConcepts
        .map((e) => e.toString().trim().toUpperCase())
        .toSet();

    _safetyGateThreshold =
        (data['safety_gate_threshold'] as num?)?.toDouble() ?? 0.45;
    _isLoaded = true;
  }

  /// Normalizes a single raw gesture token to UPPER_SNAKE_CASE and maps MINUM_OLD -> MINUM.
  static String normalizeToken(String rawToken) {
    final cleaned = rawToken
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (cleaned == 'MINUM_OLD') return 'MINUM';
    return cleaned;
  }

  /// Translates a sequence of sign language gloss tokens into polite 3-language sentences
  /// (Indonesian C0/C3, English, Arabic MSA) conditioned on location and interlocutor role.
  CamsResult translate({
    required List<String> glossTokens,
    required String location,
    required String interlocutorRole,
    double minCameraConf = 0.85,
  }) {
    final resolvedLoc = CamsLocation.fromString(location);
    final resolvedRole = CamsInterlocutorRole.fromString(interlocutorRole);

    // 1. Normalization (UPPER_SNAKE_CASE + MINUM_OLD -> MINUM)
    final normalized = glossTokens
        .map(normalizeToken)
        .where((t) => t.isNotEmpty)
        .toList(growable: false);

    if (normalized.isEmpty) {
      return CamsResult(
        decision: CamsDecision.requestClarification,
        intent: 'AMBIGUOUS',
        confidence: 0.0,
        normalizedTokens: const [],
        clarificationOptions: CamsCanonicalFrameResolver.buildClarifications(
          normalizedTokens: const [],
          location: resolvedLoc,
          role: resolvedRole,
        ),
        reason: 'EMPTY_BUFFER',
        location: resolvedLoc,
        role: resolvedRole,
      );
    }

    // 2. Safety Gate 1: Out-of-Vocabulary check against mgru_86_concepts
    if (_mgru86Concepts.isNotEmpty) {
      final oov = normalized
          .where((token) => !_mgru86Concepts.contains(token))
          .toList(growable: false);
      if (oov.isNotEmpty) {
        return CamsResult(
          decision: CamsDecision.rejectOov,
          intent: 'OOV_REJECTED',
          confidence: 0.0,
          normalizedTokens: normalized,
          oovTokens: oov,
          reason: 'OUT_OF_VOCABULARY',
          location: resolvedLoc,
          role: resolvedRole,
        );
      }
    }

    // 3. Safety Gate 2: Camera confidence < 0.50 or all tokens are vague/ambiguous
    final allAmbiguous = normalized.every(_ambiguousOnlyVocabulary.contains);
    if (minCameraConf < 0.50 || allAmbiguous) {
      return CamsResult(
        decision: CamsDecision.requestClarification,
        intent: 'CLARIFICATION_REQUIRED',
        confidence: minCameraConf < 0.50 ? minCameraConf : 0.0,
        normalizedTokens: normalized,
        clarificationOptions: CamsCanonicalFrameResolver.buildClarifications(
          normalizedTokens: normalized,
          location: resolvedLoc,
          role: resolvedRole,
        ),
        reason: minCameraConf < 0.50
            ? 'LOW_CAMERA_CONFIDENCE'
            : 'AMBIGUOUS_GLOSS_ONLY',
        location: resolvedLoc,
        role: resolvedRole,
      );
    }

    // If weights are not yet loaded, fallback safely to canonical rule matching
    if (!_isLoaded || _classes.isEmpty) {
      final fallbackFrame = CamsCanonicalFrameResolver.resolve(
        intent: 'GENERAL_SOCIAL_AND_DAILY',
        normalizedTokens: normalized,
        location: resolvedLoc,
        role: resolvedRole,
      );
      return CamsResult(
        decision: CamsDecision.proceedTranslate,
        intent: 'GENERAL_SOCIAL_AND_DAILY',
        confidence: minCameraConf,
        normalizedTokens: normalized,
        idC0: fallbackFrame.idC0,
        idC3: fallbackFrame.idC3,
        enText: fallbackFrame.enText,
        arText: fallbackFrame.arText,
        reason: 'FALLBACK_UNLOADED',
        location: resolvedLoc,
        role: resolvedRole,
      );
    }

    // 4. TF-IDF (1,2) + Context C3 sequence construction
    final sequence = <String>[...normalized];
    if (resolvedLoc != CamsLocation.unknown) {
      sequence.add('LOC_${resolvedLoc.tokenKey}');
    }
    if (resolvedRole != CamsInterlocutorRole.unknown) {
      sequence.add('ROLE_${resolvedRole.tokenKey}');
    }

    final ngrams = <String>[
      ...sequence,
      for (int i = 0; i < sequence.length - 1; i++)
        '${sequence[i]} ${sequence[i + 1]}',
    ];

    final termCounts = <int, double>{};
    for (final gram in ngrams) {
      final idx = _vocabulary[gram];
      if (idx != null && idx >= 0 && idx < _idf.length) {
        termCounts[idx] = (termCounts[idx] ?? 0.0) + 1.0;
      }
    }

    final tfidfVec = <int, double>{};
    double sumSquares = 0.0;
    termCounts.forEach((idx, tf) {
      final val = tf * _idf[idx];
      tfidfVec[idx] = val;
      sumSquares += val * val;
    });

    if (sumSquares > 0.0) {
      final l2Norm = math.sqrt(sumSquares);
      for (final idx in tfidfVec.keys.toList(growable: false)) {
        tfidfVec[idx] = tfidfVec[idx]! / l2Norm;
      }
    }

    // 5. Linear Logits (W · x + b) & Softmax over 11 classes
    final numClasses = _classes.length;
    final logits = List<double>.filled(numClasses, 0.0);
    double maxLogit = double.negativeInfinity;

    for (int c = 0; c < numClasses; c++) {
      double z = c < _intercept.length ? _intercept[c] : 0.0;
      final row = _coef[c];
      tfidfVec.forEach((idx, xVal) {
        if (idx < row.length) {
          z += row[idx] * xVal;
        }
      });
      logits[c] = z;
      if (z > maxLogit) maxLogit = z;
    }

    final probs = List<double>.filled(numClasses, 0.0);
    double expSum = 0.0;
    for (int c = 0; c < numClasses; c++) {
      final e = math.exp(logits[c] - maxLogit);
      probs[c] = e;
      expSum += e;
    }

    int bestClassIdx = 0;
    double maxProb = 0.0;
    for (int c = 0; c < numClasses; c++) {
      final p = expSum > 0.0 ? probs[c] / expSum : (1.0 / numClasses);
      probs[c] = p;
      if (p > maxProb) {
        maxProb = p;
        bestClassIdx = c;
      }
    }

    final predictedIntent = _classes[bestClassIdx];

    // 6. Safety Gate 3: Probability threshold check (0.45)
    if (maxProb < _safetyGateThreshold) {
      return CamsResult(
        decision: CamsDecision.requestClarification,
        intent: predictedIntent,
        confidence: maxProb,
        normalizedTokens: normalized,
        clarificationOptions: CamsCanonicalFrameResolver.buildClarifications(
          normalizedTokens: normalized,
          location: resolvedLoc,
          role: resolvedRole,
          topIntent: predictedIntent,
        ),
        reason: 'BELOW_SAFETY_THRESHOLD',
        location: resolvedLoc,
        role: resolvedRole,
      );
    }

    final frame = CamsCanonicalFrameResolver.resolve(
      intent: predictedIntent,
      normalizedTokens: normalized,
      location: resolvedLoc,
      role: resolvedRole,
    );

    return CamsResult(
      decision: CamsDecision.proceedTranslate,
      intent: predictedIntent,
      confidence: maxProb,
      normalizedTokens: normalized,
      idC0: frame.idC0,
      idC3: frame.idC3,
      enText: frame.enText,
      arText: frame.arText,
      reason: 'OK',
      location: resolvedLoc,
      role: resolvedRole,
    );
  }
}
