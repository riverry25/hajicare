import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../services/cams_canonical_frames.dart';
import '../../../services/cams_location_resolver.dart';
import '../../../services/cams_nlp_engine.dart';
import '../models/sign_token.dart';
import 'bisindo_recognition_controller.dart';

/// Downstream CAMS NLP v3 controller watching the shared BISINDO/SIBI token buffer
/// in [BisindoRecognitionController].
/// Never alters camera detection or model switching; translates the accumulated
/// gloss sequence into polite Indonesian, English, and Arabic MSA after a 1.5s
/// silent idle pause or an explicit [translateNow] tap.
class CamsTranslationController extends GetxController {
  final BisindoRecognitionController recognitionController;
  final CamsNlpEngine nlpEngine;
  final CamsLocationResolver locationResolver;
  final Duration autoTranslateDelay;
  final bool autoDetectGpsOnInit;

  CamsTranslationController({
    required this.recognitionController,
    CamsNlpEngine? nlpEngine,
    CamsLocationResolver? locationResolver,
    this.autoTranslateDelay = const Duration(milliseconds: 1500),
    this.autoDetectGpsOnInit = true,
  }) : nlpEngine = nlpEngine ?? CamsNlpEngine.instance,
       locationResolver = locationResolver ?? const CamsLocationResolver();

  final selectedLocation = CamsLocation.unknown.obs;
  final isAutoGpsDetected = false.obs;
  final selectedRole = CamsInterlocutorRole.unknown.obs;
  final isEngineReady = false.obs;
  final isAutoTranslatePending = false.obs;
  final latestResult = Rxn<CamsResult>();
  final speakingLanguageCode = RxnString();

  Timer? _debounceTimer;
  Worker? _tokensWorker;
  bool _isClosed = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initEngineAndGps());
    _tokensWorker = ever<List<SignToken>>(
      recognitionController.tokens,
      _onTokensChanged,
    );
    if (recognitionController.tokens.isNotEmpty) {
      _scheduleAutoTranslate();
    }
  }

  Future<void> _initEngineAndGps() async {
    try {
      await nlpEngine.ensureLoaded();
    } catch (e) {
      debugPrint('[CamsTranslationController] weights load note: $e');
    }
    if (_isClosed) return;
    isEngineReady.value = nlpEngine.isLoaded;

    if (autoDetectGpsOnInit) {
      final gpsLoc = await locationResolver.detectCurrentHajjLocation();
      if (!_isClosed &&
          gpsLoc != CamsLocation.unknown &&
          selectedLocation.value == CamsLocation.unknown) {
        selectedLocation.value = gpsLoc;
        isAutoGpsDetected.value = true;
        if (recognitionController.tokens.isNotEmpty) {
          translateNow();
        }
      }
    }
  }

  void _onTokensChanged(List<SignToken> currentTokens) {
    if (_isClosed) return;
    final glosses = extractGlossTokens(currentTokens);
    if (glosses.isEmpty) {
      _debounceTimer?.cancel();
      isAutoTranslatePending.value = false;
      latestResult.value = null;
      return;
    }
    _scheduleAutoTranslate();
  }

  void _scheduleAutoTranslate() {
    _debounceTimer?.cancel();
    isAutoTranslatePending.value = true;
    _debounceTimer = Timer(autoTranslateDelay, () {
      if (_isClosed) return;
      isAutoTranslatePending.value = false;
      translateNow();
    });
  }

  void setLocation(CamsLocation location, {bool fromGps = false}) {
    selectedLocation.value = location;
    isAutoGpsDetected.value = fromGps;
    if (recognitionController.tokens.isNotEmpty) {
      translateNow();
    }
  }

  void setRole(CamsInterlocutorRole role) {
    selectedRole.value = role;
    if (recognitionController.tokens.isNotEmpty) {
      translateNow();
    }
  }

  /// Extracts normalized gloss tokens from the shared [SignToken] buffer,
  /// merging adjacent fingerspelled letters when they form a known concept.
  List<String> extractGlossTokens(List<SignToken> tokens) {
    final result = <String>[];
    final letterRun = <String>[];

    void flushLetterRun() {
      if (letterRun.isEmpty) return;
      final joined = letterRun.join().toUpperCase();
      if (letterRun.length > 1 &&
          (nlpEngine.mgru86Concepts.isEmpty ||
              nlpEngine.mgru86Concepts.contains(joined))) {
        result.add(joined);
      } else {
        result.addAll(letterRun);
      }
      letterRun.clear();
    }

    for (final token in tokens) {
      switch (token.type) {
        case SignTokenType.letter:
          final letter = token.value.trim().toUpperCase();
          if (letter.isNotEmpty) letterRun.add(letter);
        case SignTokenType.word:
          flushLetterRun();
          final word = token.value.trim();
          if (word.isNotEmpty) result.add(word);
        case SignTokenType.space:
          flushLetterRun();
      }
    }
    flushLetterRun();
    return result;
  }

  /// Computes the minimum camera confidence across current word/letter tokens
  /// (defaults to 0.85 if tokens have no recorded camera confidence).
  double computeMinCameraConfidence(List<SignToken> tokens) {
    double? minConf;
    for (final token in tokens) {
      if (token.type == SignTokenType.space) continue;
      final c = token.confidence;
      if (c != null) {
        minConf = (minConf == null || c < minConf) ? c : minConf;
      }
    }
    return minConf ?? 0.85;
  }

  /// Immediately executes CAMS NLP v3 offline translation on the current buffer.
  CamsResult? translateNow() {
    _debounceTimer?.cancel();
    isAutoTranslatePending.value = false;

    final currentTokens = List<SignToken>.of(recognitionController.tokens);
    final glossTokens = extractGlossTokens(currentTokens);
    if (glossTokens.isEmpty) {
      latestResult.value = null;
      return null;
    }

    final minConf = computeMinCameraConfidence(currentTokens);
    final result = nlpEngine.translate(
      glossTokens: glossTokens,
      location: selectedLocation.value.tokenKey,
      interlocutorRole: selectedRole.value.tokenKey,
      minCameraConf: minConf,
    );
    latestResult.value = result;
    return result;
  }

  /// Resolves a `REQUEST_CLARIFICATION` state in 1 tap by replacing the buffer
  /// with the chosen option's canonical gloss tokens and translating immediately.
  CamsResult applyClarification(CamsClarificationOption option) {
    _debounceTimer?.cancel();
    isAutoTranslatePending.value = false;

    final currentModel = recognitionController.tokens.isNotEmpty
        ? recognitionController.tokens.last.sourceModel
        : null;

    recognitionController.replaceTokensFromClarification(
      option.glossTokens,
      sourceModel: currentModel,
    );

    final result = nlpEngine.translate(
      glossTokens: option.glossTokens,
      location: selectedLocation.value.tokenKey,
      interlocutorRole: selectedRole.value.tokenKey,
      minCameraConf: 0.92,
    );
    latestResult.value = result;
    return result;
  }

  /// Speaks the translated sentence for `'id'`, `'en'`, or `'ar'`.
  Future<void> speakLanguage(String languageCode) async {
    final res = latestResult.value;
    if (res == null || !res.isSuccess) return;

    final code = languageCode.trim().toLowerCase();
    final String textToSpeak;
    if (code == 'ar') {
      textToSpeak = res.arText;
    } else if (code == 'en') {
      textToSpeak = res.enText;
    } else {
      textToSpeak = res.idC3.isNotEmpty ? res.idC3 : res.idC0;
    }

    if (textToSpeak.trim().isEmpty) return;
    speakingLanguageCode.value = code;
    try {
      await recognitionController.speakTextInLanguage(
        textToSpeak,
        languageCode: code,
      );
    } finally {
      if (!_isClosed && speakingLanguageCode.value == code) {
        speakingLanguageCode.value = null;
      }
    }
  }

  void clearResult() {
    _debounceTimer?.cancel();
    isAutoTranslatePending.value = false;
    latestResult.value = null;
  }

  @override
  void onClose() {
    _isClosed = true;
    _debounceTimer?.cancel();
    _tokensWorker?.dispose();
    super.onClose();
  }
}
