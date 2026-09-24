import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/bisindo_prediction.dart';
import '../models/sign_token.dart';
import '../services/bisindo_tts_service.dart';

enum SignRecognitionState { idle, reading, analyzing, recognized }

class BisindoRecognitionConfig {
  final double confidenceThreshold;
  final int stablePredictionsRequired;
  final Duration duplicateCooldown;
  final Duration handPresenceTimeout;

  const BisindoRecognitionConfig({
    this.confidenceThreshold = 0.58,
    this.stablePredictionsRequired = 3,
    this.duplicateCooldown = const Duration(milliseconds: 1200),
    this.handPresenceTimeout = const Duration(milliseconds: 1000),
  }) : assert(stablePredictionsRequired > 0),
       assert(confidenceThreshold >= 0.0 && confidenceThreshold <= 1.0);
}

/// Manages reactive state, hold-to-confirm stability gate, anti-duplicate cooldown,
/// token composition, and Indonesian Text-to-Speech.
class BisindoRecognitionController extends GetxController {
  final BisindoRecognitionConfig config;
  final SignLabelParser labelParser;
  final SignTokenComposer tokenComposer;
  final BisindoTtsService ttsService;
  final bool autoTick;

  BisindoRecognitionController({
    this.config = const BisindoRecognitionConfig(),
    this.labelParser = const SignLabelParser(),
    this.tokenComposer = const SignTokenComposer(),
    BisindoTtsService? ttsService,
    this.autoTick = true,
  }) : ttsService = ttsService ?? BisindoTtsService();

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
    ttsService.initialize();
    if (autoTick) {
      _ticker = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => tick(),
      );
    }
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

  /// Processes inference result through confidence check and stability gate.
  void handlePrediction(BisindoPrediction prediction, {DateTime? now}) {
    if (_isClosed || !isCameraActive.value) return;
    final timestamp = now ?? DateTime.now();
    registerHandFrame(now: timestamp);

    final conf = prediction.confidence.clamp(0.0, 1.0);
    candidateConfidence.value = conf;
    confidence.value = conf;

    final double threshold = config.confidenceThreshold;

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
    holdProgress.value = (streak / config.stablePredictionsRequired).clamp(
      0.0,
      1.0,
    );

    if (kDebugMode) {
      debugPrint(
        '[BISINDO] candidate=${prediction.label} conf=${(conf * 100).toStringAsFixed(1)}% streak=$streak/${config.stablePredictionsRequired} hold=${(holdProgress.value * 100).round()}%',
      );
    }

    if (streak >= config.stablePredictionsRequired) {
      _commitLabel(prediction.label, timestamp);
    }
  }

  void _commitLabel(String label, DateTime now) {
    // Anti Duplicate Cooldown Check
    if (_lastCommittedLabel == label && _lastCommittedAt != null) {
      final elapsed = now.difference(_lastCommittedAt!);
      if (elapsed < config.duplicateCooldown) {
        return; // Suppress duplicate commit within cooldown
      }
    }

    try {
      tokens.add(labelParser.parse(label).toToken());
    } on FormatException catch (e) {
      debugPrint('[BISINDO] FormatException parsing label $label: $e');
      return;
    }

    _refreshTranscript();
    _lastCommittedLabel = label;
    _lastCommittedAt = now;
    detectedLabel.value = label;
    recognitionState.value = SignRecognitionState.recognized;
    _consecutivePredictions.clear();
    stabilityStreak.value = 0;
    holdProgress.value = 1.0;

    if (kDebugMode) {
      debugPrint(
        '[BISINDO] Committed label: "$label" -> Transcript: "${rawTranscript.value}"',
      );
    }
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
    if (_isClosed || !isCameraActive.value) return;
    final timestamp = now ?? DateTime.now();
    final lastHand = _lastHandSeenAt;
    if (lastHand == null ||
        timestamp.difference(lastHand) >= config.handPresenceTimeout) {
      handleNoHand(now: timestamp);
    }
  }

  void insertSpace() {
    if (tokens.isEmpty || tokens.last.type == SignTokenType.space) return;
    tokens.add(const SignToken.space());
    _refreshTranscript();
  }

  void deleteLast() {
    if (tokens.isEmpty) return;
    tokens.removeLast();
    _refreshTranscript();
  }

  void resetTranscript() {
    tokens.clear();
    rawTranscript.value = '';
    _lastCommittedAt = null;
    _lastCommittedLabel = null;
    _resetRecognition(clearAll: true);
  }

  Future<void> speakTranscript() async {
    final text = rawTranscript.value.trim();
    if (text.isEmpty) return;
    isSpeaking.value = true;
    try {
      await ttsService.speak(text);
    } finally {
      if (!_isClosed) isSpeaking.value = false;
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

  void _refreshTranscript() {
    rawTranscript.value = tokenComposer.compose(tokens);
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
