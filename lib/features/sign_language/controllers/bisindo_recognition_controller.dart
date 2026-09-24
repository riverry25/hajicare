import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/bisindo_mode.dart';
import '../models/bisindo_prediction.dart';
import '../models/sign_token.dart';
import '../services/bisindo_tts_service.dart';

enum SignRecognitionState {
  idle,
  candidate,
  holding,
  confirmed,
  waitingForRelease,
}

class BisindoRecognitionConfig {
  final double minimumConfidenceWord;
  final double minimumConfidenceAlphabet;
  final Duration confirmationDuration;
  final Duration predictionInterval;
  final int predictionWindowSize;
  final double minimumStableRatio;
  final double releaseConfidence;
  final Duration releaseDuration;
  final Duration duplicateCooldown;
  final Duration handPresenceTimeout;
  final Duration predictionFreshness;
  final Duration confirmedDisplayDuration;

  const BisindoRecognitionConfig({
    double? minimumConfidence,
    double? minimumConfidenceWord,
    double? minimumConfidenceAlphabet,
    this.confirmationDuration = const Duration(milliseconds: 950),
    this.predictionInterval = const Duration(milliseconds: 100),
    this.predictionWindowSize = 5,
    this.minimumStableRatio = 0.75,
    this.releaseConfidence = 0.45,
    this.releaseDuration = const Duration(milliseconds: 300),
    this.duplicateCooldown = const Duration(milliseconds: 900),
    this.handPresenceTimeout = const Duration(milliseconds: 450),
    this.predictionFreshness = const Duration(milliseconds: 350),
    this.confirmedDisplayDuration = const Duration(milliseconds: 300),
  }) : minimumConfidenceWord =
           minimumConfidenceWord ?? minimumConfidence ?? 0.70,
       minimumConfidenceAlphabet =
           minimumConfidenceAlphabet ?? minimumConfidence ?? 0.65,
       assert(predictionWindowSize > 0),
       assert(minimumStableRatio > 0 && minimumStableRatio <= 1);

  double get minimumConfidence => minimumConfidenceWord;
}

typedef BisindoAiProcessor = Future<String> Function(String rawTranscript);

/// Manages reactive state, mode switching (Word vs. Alphabet), gesture hold
/// stabilization, duplicate prevention, and Indonesian Text-to-Speech.
class BisindoRecognitionController extends GetxController {
  final BisindoRecognitionConfig config;
  final SignLabelParser labelParser;
  final SignTokenComposer tokenComposer;
  final BisindoAiProcessor? aiProcessor;
  final BisindoTtsService ttsService;
  final bool autoTick;

  BisindoRecognitionController({
    this.config = const BisindoRecognitionConfig(),
    this.labelParser = const SignLabelParser(),
    this.tokenComposer = const SignTokenComposer(),
    this.aiProcessor,
    BisindoTtsService? ttsService,
    this.autoTick = true,
  }) : ttsService = ttsService ?? BisindoTtsService();

  // Mode Selection: UNIFIED (gabungan huruf & kata), HURUF, atau KATA
  final selectedMode = BisindoMode.unified.obs;

  // Camera & Detection States
  final isCameraActive = false.obs;
  final isCameraReady = false.obs;
  final isDetecting = false.obs;
  final isHandDetected = false.obs;

  // Recognition States
  final recognitionState = SignRecognitionState.idle.obs;
  final currentCandidate = RxnString();
  final detectedLabel = ''.obs;
  final candidateConfidence = 0.0.obs;
  final confidence = 0.0.obs;
  final confirmationProgress = 0.0.obs;
  final holdProgress = 0.0.obs;

  // Tokens & Output Text
  final tokens = <SignToken>[].obs;
  final rawTranscript = ''.obs;
  final aiTranscript = ''.obs;
  final isSendingToAi = false.obs;
  final isSpeaking = false.obs;

  final List<String?> _predictionWindow = <String?>[];
  Timer? _ticker;
  DateTime? _lastHandSeenAt;
  DateTime? _lastStrongPredictionAt;
  DateTime? _holdStartedAt;
  DateTime? _releaseStartedAt;
  DateTime? _confirmedAt;
  DateTime? _lastCommittedAt;
  String? _holdingLabel;
  String? _lockedLabel;
  bool _isClosed = false;

  int get _requiredStableSamples => math.max(
    1,
    (config.predictionWindowSize * config.minimumStableRatio).ceil(),
  );

  String get statusText {
    if (!isCameraActive.value) return 'Mulai kamera untuk mendeteksi isyarat';
    if (!isHandDetected.value) {
      return 'Arahkan tangan ke kamera untuk mendeteksi';
    }
    switch (recognitionState.value) {
      case SignRecognitionState.idle:
        return 'Lakukan isyarat kata atau bentuk huruf';
      case SignRecognitionState.candidate:
        return 'Mendeteksi isyarat...';
      case SignRecognitionState.holding:
        return 'Tahan sebentar: ${currentCandidate.value?.toUpperCase() ?? ''}';
      case SignRecognitionState.confirmed:
        return '✓ ${currentCandidate.value?.toUpperCase() ?? ''} terkonfirmasi';
      case SignRecognitionState.waitingForRelease:
        return 'Lepaskan tangan atau ubah isyarat';
    }
  }

  @override
  void onInit() {
    super.onInit();
    ttsService.initialize();
    if (autoTick) {
      _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => tick());
    }
  }

  void setMode(BisindoMode newMode) {
    if (_isClosed || selectedMode.value == newMode) return;
    selectedMode.value = newMode;
    _resetRecognition(clearLock: true);
    debugPrint('[BISINDO] Mode changed to: ${newMode.label}');
  }

  void setCameraActive(bool active, {DateTime? now}) {
    if (_isClosed) return;
    isCameraActive.value = active;
    isCameraReady.value = active;
    if (!active) {
      isDetecting.value = false;
      _resetRecognition(clearLock: true);
      isHandDetected.value = false;
      _lastHandSeenAt = null;
      _lastStrongPredictionAt = null;
    } else {
      isDetecting.value = true;
      _lastHandSeenAt = now ?? DateTime.now();
    }
  }

  void registerHandFrame({DateTime? now}) {
    if (_isClosed || !isCameraActive.value) return;
    isHandDetected.value = true;
    _lastHandSeenAt = now ?? DateTime.now();
  }

  void handlePrediction(BisindoPrediction prediction, {DateTime? now}) {
    if (_isClosed || !isCameraActive.value) return;
    final timestamp = now ?? DateTime.now();
    registerHandFrame(now: timestamp);

    final conf = prediction.confidence.clamp(0.0, 1.0);
    candidateConfidence.value = conf;
    confidence.value = conf;

    final double minConf = selectedMode.value.isWord
        ? config.minimumConfidenceWord
        : config.minimumConfidenceAlphabet;

    final passesFilter =
        prediction.isRecognized &&
        prediction.label.isNotEmpty &&
        prediction.confidence >= minConf;

    if (!passesFilter) {
      _addWindowSample(null);
      if (_lockedLabel != null &&
          (!prediction.isRecognized ||
              prediction.confidence < config.releaseConfidence)) {
        _advanceRelease(timestamp);
      } else if (_lockedLabel == null) {
        _predictionWindow.clear();
        _cancelHold(keepCandidate: false);
      }
      return;
    }

    currentCandidate.value = prediction.label;
    detectedLabel.value = prediction.label;
    _lastStrongPredictionAt = timestamp;
    _addWindowSample(prediction.label);
    final stableLabel = _stableLabel();

    if (kDebugMode) {
      debugPrint(
        '[BISINDO] candidate=${prediction.label} '
        'conf=${(prediction.confidence * 100).toStringAsFixed(1)}% '
        'stable=${stableLabel ?? '-'}',
      );
    }

    // Handle locked label (duplicate prevention)
    if (_lockedLabel != null) {
      if (stableLabel != null && stableLabel != _lockedLabel) {
        if (_advanceRelease(timestamp, clearPredictionWindow: false)) {
          _startHolding(stableLabel, timestamp);
        }
      } else {
        _releaseStartedAt = null;
        if (recognitionState.value != SignRecognitionState.confirmed) {
          recognitionState.value = SignRecognitionState.waitingForRelease;
        }
      }
      return;
    }

    if (stableLabel == null) {
      _cancelHold(keepCandidate: true);
      recognitionState.value = SignRecognitionState.candidate;
      return;
    }

    if (_holdingLabel != stableLabel || _holdStartedAt == null) {
      _startHolding(stableLabel, timestamp);
    } else {
      _updateHold(timestamp);
    }
  }

  void handleNoHand({DateTime? now}) {
    if (_isClosed) return;
    final timestamp = now ?? DateTime.now();
    isHandDetected.value = false;
    _addWindowSample(null);
    _cancelHold(keepCandidate: false);
    if (_lockedLabel != null) {
      _advanceRelease(timestamp);
    } else {
      recognitionState.value = SignRecognitionState.idle;
    }
  }

  void tick({DateTime? now}) {
    if (_isClosed || !isCameraActive.value) return;
    final timestamp = now ?? DateTime.now();
    final lastHand = _lastHandSeenAt;
    if (lastHand == null ||
        timestamp.difference(lastHand) >= config.handPresenceTimeout) {
      handleNoHand(now: timestamp);
    }

    if (_lockedLabel != null) {
      final confirmedAt = _confirmedAt;
      if (recognitionState.value == SignRecognitionState.confirmed &&
          confirmedAt != null &&
          timestamp.difference(confirmedAt) >=
              config.confirmedDisplayDuration) {
        recognitionState.value = SignRecognitionState.waitingForRelease;
      }
      if (!isHandDetected.value) _advanceRelease(timestamp);
      return;
    }

    final lastPrediction = _lastStrongPredictionAt;
    if (_holdStartedAt != null &&
        (lastPrediction == null ||
            timestamp.difference(lastPrediction) >
                config.predictionFreshness)) {
      _cancelHold(keepCandidate: false);
      return;
    }
    _updateHold(timestamp);
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
    aiTranscript.value = '';
    _lastCommittedAt = null;
    _resetRecognition(clearLock: true);
    isHandDetected.value = false;
    _lastHandSeenAt = null;
    _lastStrongPredictionAt = null;
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

  Future<bool> sendToAi() async {
    final input = rawTranscript.value.trim();
    if (input.isEmpty || aiProcessor == null || isSendingToAi.value) {
      return false;
    }
    isSendingToAi.value = true;
    try {
      final result = (await aiProcessor!(input)).trim();
      if (!_isClosed) aiTranscript.value = result;
      return result.isNotEmpty;
    } finally {
      if (!_isClosed) isSendingToAi.value = false;
    }
  }

  void _addWindowSample(String? label) {
    _predictionWindow.add(label);
    if (_predictionWindow.length > config.predictionWindowSize) {
      _predictionWindow.removeAt(0);
    }
  }

  String? _stableLabel() {
    if (_predictionWindow.length < _requiredStableSamples) return null;
    final counts = <String, int>{};
    for (final label in _predictionWindow) {
      if (label != null) counts[label] = (counts[label] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.value >= _requiredStableSamples ? best.key : null;
  }

  void _startHolding(String label, DateTime now) {
    _holdingLabel = label;
    _holdStartedAt = now;
    currentCandidate.value = label;
    detectedLabel.value = label;
    confirmationProgress.value = 0;
    holdProgress.value = 0;
    recognitionState.value = SignRecognitionState.holding;
    if (kDebugMode) debugPrint('[BISINDO] holding=$label progress=0.00');
  }

  void _updateHold(DateTime now) {
    final started = _holdStartedAt;
    final label = _holdingLabel;
    if (started == null || label == null || _lockedLabel != null) return;
    final durationMs = math.max(1, config.confirmationDuration.inMilliseconds);
    final progress = now.difference(started).inMilliseconds / durationMs;
    final clamped = progress.clamp(0.0, 1.0);
    confirmationProgress.value = clamped;
    holdProgress.value = clamped;
    if (progress >= 1) _commit(label, now);
  }

  void _commit(String label, DateTime now) {
    final lastCommit = _lastCommittedAt;
    if (lastCommit != null &&
        now.difference(lastCommit) < config.duplicateCooldown) {
      return;
    }
    try {
      tokens.add(labelParser.parse(label).toToken());
    } on FormatException catch (error) {
      if (kDebugMode) debugPrint('[BISINDO] ignored label: $error');
      _cancelHold(keepCandidate: false);
      return;
    }
    _refreshTranscript();
    _lockedLabel = label;
    _lastCommittedAt = now;
    _confirmedAt = now;
    _holdingLabel = null;
    _holdStartedAt = null;
    confirmationProgress.value = 1;
    holdProgress.value = 1;
    recognitionState.value = SignRecognitionState.confirmed;
    if (kDebugMode) debugPrint('[BISINDO] confirmed=$label -> committed');
  }

  bool _advanceRelease(DateTime now, {bool clearPredictionWindow = true}) {
    _releaseStartedAt ??= now;
    if (now.difference(_releaseStartedAt!) < config.releaseDuration) {
      return false;
    }
    if (kDebugMode) debugPrint('[BISINDO] released=$_lockedLabel');
    _lockedLabel = null;
    _releaseStartedAt = null;
    _confirmedAt = null;
    if (clearPredictionWindow) _predictionWindow.clear();
    confirmationProgress.value = 0;
    holdProgress.value = 0;
    recognitionState.value = SignRecognitionState.idle;
    return true;
  }

  void _cancelHold({required bool keepCandidate}) {
    _holdingLabel = null;
    _holdStartedAt = null;
    confirmationProgress.value = 0;
    holdProgress.value = 0;
    if (!keepCandidate) {
      currentCandidate.value = null;
      detectedLabel.value = '';
    }
    if (_lockedLabel == null) {
      recognitionState.value = SignRecognitionState.idle;
    }
  }

  void _resetRecognition({required bool clearLock}) {
    _predictionWindow.clear();
    _cancelHold(keepCandidate: false);
    candidateConfidence.value = 0;
    confidence.value = 0;
    _releaseStartedAt = null;
    _confirmedAt = null;
    if (clearLock) _lockedLabel = null;
    recognitionState.value = SignRecognitionState.idle;
  }

  void _refreshTranscript() {
    rawTranscript.value = tokenComposer.compose(tokens);
    aiTranscript.value = '';
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
