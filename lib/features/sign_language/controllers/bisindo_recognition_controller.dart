import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/bisindo_prediction.dart';
import '../models/sign_token.dart';
import '../services/bisindo_tts_service.dart';
import '../services/sign_transcript_store.dart';

enum SignRecognitionState { idle, reading, analyzing, recognized }

class BisindoRecognitionConfig {
  final double confidenceThreshold;
  final int stablePredictionsRequired;
  final Duration duplicateCooldown;
  final Duration handPresenceTimeout;

  /// Spelled letters and full words/sentences are spoken as a coherent utterance
  /// after this idle period (when the jamaah has stopped demonstrating for a few seconds).
  final Duration speechIdleDelay;

  const BisindoRecognitionConfig({
    this.confidenceThreshold = 0.58,
    this.stablePredictionsRequired = 3,
    this.duplicateCooldown = const Duration(milliseconds: 1400),
    this.handPresenceTimeout = const Duration(milliseconds: 1200),
    this.speechIdleDelay = const Duration(milliseconds: 2600), // ~2.6s calm pause
  }) : assert(stablePredictionsRequired > 0),
       assert(confidenceThreshold >= 0.0 && confidenceThreshold <= 1.0);

  /// Backward-compatible alias
  Duration get letterSpeechIdle => speechIdleDelay;
}

/// Owns the single shared "Transkripsi AI" used by both SIBI and BISINDO.
/// Responsibilities: hold-to-confirm stability gate (SIBI frame stream
/// anti-duplicate cooldown, token composition, persistence, and a serialized
/// Indonesian Text-to-Speech queue.
/// The transcript is only cleared by [resetTranscript]; model switches and
/// camera stops must use [resetRecognitionState].
class BisindoRecognitionController extends GetxController {
  final BisindoRecognitionConfig config;
  final SignLabelParser labelParser;
  final SignTokenComposer tokenComposer;
  final BisindoTtsService ttsService;
  final SignTranscriptStore transcriptStore;
  final bool autoTick;

  BisindoRecognitionController({
    this.config = const BisindoRecognitionConfig(),
    this.labelParser = const SignLabelParser(),
    this.tokenComposer = const SignTokenComposer(),
    BisindoTtsService? ttsService,
    SignTranscriptStore? transcriptStore,
    this.autoTick = true,
  }) : ttsService = ttsService ?? BisindoTtsService(),
       transcriptStore =
           transcriptStore ?? const SharedPrefsSignTranscriptStore();

  // Camera & Detection States
  final isCameraActive = false.obs;
  final isCameraReady = false.obs;
  final isDetecting = false.obs;
  final isHandDetected = false.obs;
  final bufferCount = 0.obs;

  // Recognition States
  final recognitionState = SignRecognitionState.idle.obs;
  final currentCandidate = RxnString();
  final detectedLabel = ''.obs;
  final candidateConfidence = 0.0.obs;
  final confidence = 0.0.obs;
  final stabilityStreak = 0.obs;
  final holdProgress = 0.0.obs;

  // Output Sentence Tokens & Transcript
  final tokens = <SignToken>[].obs;
  final rawTranscript = ''.obs;
  final isSpeaking = false.obs;

  final List<String> _consecutivePredictions = [];
  Timer? _ticker;
  DateTime? _lastHandSeenAt;
  DateTime? _lastCommittedAt;
  String? _lastCommittedLabel;
  bool _isClosed = false;

  // Persistence
  bool _transcriptTouched = false;
  Future<void>? _restoreFuture;

  // Speech
  Future<void> _speechChain = Future<void>.value();
  int _pendingSpeechCount = 0;
  DateTime? _lastGestureCommitAt;
  int _lastSpokenTokenIndex = 0;
  int _lastSpokenLetterRunEnd = -1;

  /// Completes once the persisted transcript has been restored (if any).
  Future<void> get restored => _restoreFuture ?? Future<void>.value();

  String get statusText {
    if (!isCameraActive.value) return 'Mulai kamera untuk mendeteksi isyarat';
    if (!isHandDetected.value) return 'Posisikan tangan ke kamera';
    if (bufferCount.value < 20) {
      return 'Menyiapkan deteksi... (${bufferCount.value}/48)';
    }
    switch (recognitionState.value) {
      case SignRecognitionState.idle:
        return 'Posisikan tangan ke kamera';
      case SignRecognitionState.reading:
        return 'Membaca gerakan...';
      case SignRecognitionState.analyzing:
        final candidate = currentCandidate.value;
        if (candidate != null &&
            candidate.isNotEmpty &&
            stabilityStreak.value > 0) {
          final pct = (holdProgress.value * 100).round();
          return 'Tahan gerakan: ${candidate.toUpperCase()} ($pct%)';
        }
        return 'Menganalisis gerakan...';
      case SignRecognitionState.recognized:
        return '✓ ${detectedLabel.value.toUpperCase()} terkonfirmasi!';
    }
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(ttsService.initialize());
    _restoreFuture = _restoreTranscript();
    if (autoTick) {
      _ticker = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => tick(),
      );
    }
  }

  Future<void> _restoreTranscript() async {
    final saved = await transcriptStore.load();
    // Never overwrite anything the user produced while loading.
    if (_isClosed || _transcriptTouched || saved.isEmpty) return;
    tokens.assignAll(saved);
    rawTranscript.value = tokenComposer.compose(tokens);
    // Restored letters are considered already spoken.
    _lastSpokenTokenIndex = tokens.length;
    _lastSpokenLetterRunEnd = tokens.length;
  }

  void setCameraActive(bool active, {DateTime? now}) {
    if (_isClosed) return;
    isCameraActive.value = active;
    isCameraReady.value = active;
    if (!active) {
      isDetecting.value = false;
      _resetRecognition(clearAll: true);
      isHandDetected.value = false;
      _lastHandSeenAt = null;
    } else {
      isDetecting.value = true;
      _lastHandSeenAt = now ?? DateTime.now();
    }
  }

  void updateBufferCount(int count) {
    if (_isClosed) return;
    bufferCount.value = count;
    if (count < 48 && isHandDetected.value) {
      recognitionState.value = SignRecognitionState.reading;
    }
  }

  void registerHandFrame({DateTime? now}) {
    if (_isClosed || !isCameraActive.value) return;
    isHandDetected.value = true;
    _lastHandSeenAt = now ?? DateTime.now();
  }

  double? _customConfidenceThreshold;
  int? _customStablePredictionsRequired;

  /// Sets model-specific threshold overrides (e.g. for YOLO SIBI vs BISINDO GRU).
  void setModelThresholds({
    double? confidenceThreshold,
    int? stablePredictionsRequired,
  }) {
    _customConfidenceThreshold = confidenceThreshold;
    _customStablePredictionsRequired = stablePredictionsRequired;
  }

  /// Processes inference result through confidence check and stability gate.
  void handlePrediction(BisindoPrediction prediction, {DateTime? now}) {
    if (_isClosed || !isCameraActive.value) return;
    final timestamp = now ?? DateTime.now();
    registerHandFrame(now: timestamp);

    final conf = prediction.confidence.clamp(0.0, 1.0);
    candidateConfidence.value = conf;
    confidence.value = conf;

    final double threshold =
        _customConfidenceThreshold ?? config.confidenceThreshold;
    final int requiredStreak =
        _customStablePredictionsRequired ?? config.stablePredictionsRequired;

    // Check confidence threshold
    if (!prediction.isRecognized ||
        prediction.label.isEmpty ||
        prediction.confidence < threshold) {
      // Confidence rejected
      _consecutivePredictions.clear();
      stabilityStreak.value = 0;
      holdProgress.value = 0.0;
      recognitionState.value = SignRecognitionState.analyzing;
      currentCandidate.value = null;
      return;
    }

    currentCandidate.value = prediction.label;
    recognitionState.value = SignRecognitionState.analyzing;

    // Stability Filter: requires stablePredictionsRequired consecutive identical labels
    if (_consecutivePredictions.isNotEmpty &&
        _consecutivePredictions.last != prediction.label) {
      _consecutivePredictions.clear();
    }

    _consecutivePredictions.add(prediction.label);
    final streak = _consecutivePredictions.length;
    stabilityStreak.value = streak;
    holdProgress.value = (streak / requiredStreak).clamp(0.0, 1.0);

    if (kDebugMode && (streak == 1 || streak >= requiredStreak)) {
      debugPrint(
        '[SIGN_LANGUAGE] candidate=${prediction.label} conf=${(conf * 100).toStringAsFixed(1)}% streak=$streak/$requiredStreak hold=${(holdProgress.value * 100).round()}%',
      );
    }

    if (streak >= requiredStreak) {
      _commitLabel(prediction.label, timestamp);
    }
  }

  /// Returns the committed token, or null if suppressed/invalid.
  SignToken? _commitLabel(
    String label,
    DateTime now, {
    bool shouldSpeak = true,
  }) {
    // Anti Duplicate Cooldown Check
    if (_lastCommittedLabel == label && _lastCommittedAt != null) {
      final elapsed = now.difference(_lastCommittedAt!);
      if (elapsed < config.duplicateCooldown) {
        return null; // Suppress duplicate commit within cooldown
      }
    }

    final SignToken token;
    try {
      token = labelParser.parse(label).toToken();
    } on FormatException catch (e) {
      debugPrint('[BISINDO] FormatException parsing label $label: $e');
      return null;
    }

    tokens.add(token);
    _onTranscriptChanged();
    _lastCommittedLabel = label;
    _lastCommittedAt = now;
    detectedLabel.value = label;
    recognitionState.value = SignRecognitionState.recognized;
    _consecutivePredictions.clear();
    stabilityStreak.value = 0;
    holdProgress.value = 1.0;

    if (shouldSpeak) {
      _lastGestureCommitAt = now;
    }

    if (kDebugMode) {
      debugPrint(
        '[BISINDO] Committed label: "$label" -> Transcript: "${rawTranscript.value}"',
      );
    }
    return token;
  }

  /// Commits an externally recognized label (e.g. BISINDO segment classifier)
  /// directly to the shared transcript. Utterance is debounced until the jamaah
  /// stops gesturing for a few seconds.
  bool commitWord(String label, {bool speak = false, DateTime? now}) {
    if (_isClosed) return false;
    final token = _commitLabel(label, now ?? DateTime.now(), shouldSpeak: speak);
    return token != null;
  }

  /// Handles absence of hands.
  void handleNoHand({DateTime? now}) {
    if (_isClosed) return;
    isHandDetected.value = false;
    _consecutivePredictions.clear();
    stabilityStreak.value = 0;
    holdProgress.value = 0.0;
    currentCandidate.value = null;
    recognitionState.value = SignRecognitionState.idle;
  }

  void tick({DateTime? now}) {
    if (_isClosed) return;
    final timestamp = now ?? DateTime.now();
    _maybeSpeakIdleTranscript(timestamp);

    if (!isCameraActive.value) return;
    final lastHand = _lastHandSeenAt;
    if (lastHand == null ||
        timestamp.difference(lastHand) >= config.handPresenceTimeout) {
      handleNoHand(now: timestamp);
    }
  }

  void insertSpace() {
    if (tokens.isEmpty || tokens.last.type == SignTokenType.space) return;
    _speakPendingTokens(force: true);
    tokens.add(const SignToken.space());
    _onTranscriptChanged();
  }

  void insertWord(String word) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return;
    tokens.add(SignToken.word(trimmed));
    _onTranscriptChanged();
  }

  void insertLetter(String letter) {
    final trimmed = letter.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    tokens.add(SignToken.letter(trimmed));
    _onTranscriptChanged();
  }

  void deleteLast() {
    if (tokens.isEmpty) return;
    tokens.removeLast();
    if (_lastSpokenTokenIndex > tokens.length) {
      _lastSpokenTokenIndex = tokens.length;
    }
    if (_lastSpokenLetterRunEnd > tokens.length) {
      _lastSpokenLetterRunEnd = tokens.length;
    }
    _onTranscriptChanged();
  }

  /// Clears the shared transcript. Only the user's RESET action should call this.
  void resetTranscript() {
    tokens.clear();
    rawTranscript.value = '';
    _lastCommittedAt = null;
    _lastCommittedLabel = null;
    _lastGestureCommitAt = null;
    _lastSpokenTokenIndex = 0;
    _lastSpokenLetterRunEnd = -1;
    _resetRecognition(clearAll: true);
    _transcriptTouched = true;
    unawaited(transcriptStore.save(const []));
  }

  /// Clears transient recognition state (streak, candidate, buffers) while
  /// keeping the transcript intact. Use for model switches / camera stop.
  void resetRecognitionState() {
    if (_isClosed) return;
    _resetRecognition(clearAll: true);
  }

  Future<void> speakTranscript() async {
    final text = rawTranscript.value.trim();
    if (text.isEmpty) return;
    _lastGestureCommitAt = null;
    _lastSpokenTokenIndex = tokens.length;
    _lastSpokenLetterRunEnd = tokens.length;
    await _enqueueSpeech(text);
  }

  // Speech helpers

  /// Serializes TTS so consecutive words never cut each other off.
  Future<void> _enqueueSpeech(String text) {
    final clean = text.trim();
    if (clean.isEmpty || _isClosed) return Future<void>.value();
    _pendingSpeechCount++;
    isSpeaking.value = true;
    _speechChain = _speechChain.then((_) async {
      try {
        if (!_isClosed) await ttsService.speak(clean);
      } catch (e) {
        debugPrint('[SIGN_TTS] speak error: $e');
      } finally {
        _pendingSpeechCount--;
        if (!_isClosed && _pendingSpeechCount <= 0) {
          _pendingSpeechCount = 0;
          isSpeaking.value = false;
        }
      }
    });
    return _speechChain;
  }

  /// Speaks accumulated words and spelled letters after the jamaah pauses signing
  /// for [BisindoRecognitionConfig.speechIdleDelay].
  void _maybeSpeakIdleTranscript(DateTime now) {
    final lastCommit = _lastGestureCommitAt;
    if (lastCommit == null) return;
    if (now.difference(lastCommit) < config.speechIdleDelay) return;
    // Still holding an active candidate: wait for user to finish gesture
    if (stabilityStreak.value > 0 ||
        recognitionState.value == SignRecognitionState.reading) {
      return;
    }
    _speakPendingTokens();
  }

  void _speakPendingTokens({bool force = false}) {
    _lastGestureCommitAt = null;

    if (tokens.isEmpty) return;
    if (_lastSpokenTokenIndex >= tokens.length && !force) return;

    final startIndex = _lastSpokenTokenIndex.clamp(0, tokens.length);
    final pendingTokens = tokens.sublist(startIndex);
    if (pendingTokens.isEmpty) return;

    final text = tokenComposer.compose(pendingTokens).trim();
    _lastSpokenTokenIndex = tokens.length;
    _lastSpokenLetterRunEnd = tokens.length;

    if (text.isNotEmpty) {
      _enqueueSpeech(text);
    }
  }


  void _resetRecognition({required bool clearAll}) {
    _consecutivePredictions.clear();
    stabilityStreak.value = 0;
    holdProgress.value = 0.0;
    candidateConfidence.value = 0;
    confidence.value = 0;
    currentCandidate.value = null;
    detectedLabel.value = '';
    recognitionState.value = SignRecognitionState.idle;
    if (clearAll) {
      bufferCount.value = 0;
    }
  }

  void _onTranscriptChanged() {
    _transcriptTouched = true;
    rawTranscript.value = tokenComposer.compose(tokens);
    unawaited(transcriptStore.save(List<SignToken>.of(tokens)));
  }

  @override
  void onClose() {
    _isClosed = true;
    _ticker?.cancel();
    _ticker = null;
    ttsService.dispose();
    super.onClose();
  }
}
