import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/landmark_frame.dart';
import '../models/sign_capture_quality.dart';
import '../models/bisindo_prediction.dart';
import '../services/bisindo_classifier_service.dart';
import '../services/bisindo_feature_extractor.dart';
import '../services/bisindo_sequence_buffer.dart';
import '../services/bisindo_tts_service.dart';

enum IsolatedSignState {
  initializing,
  ready,
  countdown,
  capturing,
  processing,
  result,
  error,
}

/// Controller managing the isolated BISINDO gesture recognition lifecycle:
/// READY -> COUNTDOWN -> CAPTURING (2.8s) -> PROCESSING -> RESULT / ERROR.
class SignLanguageController extends GetxController {
  final BisindoClassifierService classifierService;
  final BisindoTtsService ttsService;
  void Function(BisindoPrediction prediction)? onPredictionAccepted;

  SignLanguageController({
    BisindoClassifierService? classifierService,
    BisindoTtsService? ttsService,
    this.onPredictionAccepted,
  }) : classifierService = classifierService ?? BisindoClassifierService(),
       ttsService = ttsService ?? BisindoTtsService();

  // Reactive UI States
  final state = IsolatedSignState.initializing.obs;
  final countdownSeconds = 3.obs;
  final captureProgress = 0.0.obs;
  final framesCollected = 0.obs;
  final isMuted = false.obs;

  // Prediction & Guidance
  final detectedLabel = ''.obs;
  final confidenceScore = 0.0.obs;
  final guidanceMessage = ''.obs;
  final topCandidates = <BisindoCandidate>[].obs;
  final lastQuality = Rxn<SignCaptureQuality>();

  // Internal temporal buffers & guards
  final BisindoSequenceBuffer _sequenceBuffer = BisindoSequenceBuffer();
  final List<LandmarkFrame> _capturedFrames = [];
  Timer? _countdownTimer;
  Timer? _captureTimer;
  Timer? _progressTicker;
  DateTime? _captureStartTime;
  static const Duration kCaptureDuration = Duration(milliseconds: 2800);

  bool _isDisposed = false;

  String get stateStatusText {
    switch (state.value) {
      case IsolatedSignState.initializing:
        return 'Menyiapkan modul BISINDO...';
      case IsolatedSignState.ready:
        return 'Posisikan tubuh bagian atas dan tangan di dalam kamera.';
      case IsolatedSignState.countdown:
        return 'Bersiap dalam ${countdownSeconds.value}...';
      case IsolatedSignState.capturing:
        return 'Lakukan satu gerakan BISINDO';
      case IsolatedSignState.processing:
        return 'Memproses gerakan...';
      case IsolatedSignState.result:
        return 'Terdeteksi: ${detectedLabel.value.toUpperCase()}';
      case IsolatedSignState.error:
        return guidanceMessage.value.isNotEmpty
            ? guidanceMessage.value
            : 'Gerakan belum dikenali. Silakan ulangi.';
    }
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(initializeServices());
  }

  Future<void> initializeServices() async {
    state.value = IsolatedSignState.initializing;
    try {
      await Future.wait([
        classifierService.initialize(),
        ttsService.initialize(),
      ]);
      if (!_isDisposed) {
        state.value = IsolatedSignState.ready;
      }
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Initialization failed: $e');
      if (!_isDisposed) {
        guidanceMessage.value =
            'Gagal memuat model BISINDO. Silakan mulai ulang.';
        state.value = IsolatedSignState.error;
      }
    }
  }

  /// Ingests incoming camera landmark frames.
  /// Only buffers frames during active [IsolatedSignState.capturing] window.
  void onIncomingLandmarkFrame(LandmarkFrame frame) {
    if (_isDisposed || state.value != IsolatedSignState.capturing) return;

    try {
      final baseFeature = BisindoFeatureExtractor.extractBaseFeature(frame);
      _sequenceBuffer.addBaseFeature(baseFeature);
      _capturedFrames.add(frame);
      framesCollected.value = _sequenceBuffer.length;
    } catch (e) {
      debugPrint(
        '[SIGN_LANGUAGE_CONTROLLER] Error extracting base feature: $e',
      );
    }
  }

  /// Starts the isolated sign recognition session:
  /// 3s countdown -> 2.8s recording -> processing -> result
  void startCaptureSession({bool skipCountdown = false}) {
    if (_isDisposed ||
        state.value == IsolatedSignState.countdown ||
        state.value == IsolatedSignState.capturing ||
        state.value == IsolatedSignState.processing) {
      return;
    }

    _cancelTimers();
    _sequenceBuffer.clear();
    _capturedFrames.clear();
    framesCollected.value = 0;
    captureProgress.value = 0.0;
    guidanceMessage.value = '';

    if (skipCountdown) {
      _beginRecording();
    } else {
      state.value = IsolatedSignState.countdown;
      countdownSeconds.value = 3;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }
        if (countdownSeconds.value > 1) {
          countdownSeconds.value--;
        } else {
          timer.cancel();
          _beginRecording();
        }
      });
    }
  }

  void _beginRecording() {
    if (_isDisposed) return;
    state.value = IsolatedSignState.capturing;
    _captureStartTime = DateTime.now();

    // Progress update ticker
    _progressTicker = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isDisposed || state.value != IsolatedSignState.capturing) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now()
          .difference(_captureStartTime!)
          .inMilliseconds;
      final progress = (elapsed / kCaptureDuration.inMilliseconds).clamp(
        0.0,
        1.0,
      );
      captureProgress.value = progress;
    });

    // Capture duration timer
    _captureTimer = Timer(kCaptureDuration, () {
      _progressTicker?.cancel();
      _finishRecordingAndProcess();
    });
  }

  Future<void> _finishRecordingAndProcess() async {
    if (_isDisposed) return;
    state.value = IsolatedSignState.processing;
    captureProgress.value = 1.0;

    try {
      // 1. Session Quality Gating
      final quality = SignCaptureQuality.fromFrames(_capturedFrames);
      lastQuality.value = quality;
      final qualityCheck = quality.validate();

      if (!qualityCheck.isValid) {
        guidanceMessage.value =
            qualityCheck.userErrorMessage ??
            'Gerakan belum cukup terdeteksi. Silakan coba lagi.';
        state.value = IsolatedSignState.error;
        return;
      }

      // 2. Temporal Resampling to 48 & Motion Delta Calculation -> [1, 48, 706]
      final inputTensor = _sequenceBuffer.prepareModelInput();

      // 3. TFLite MotionGRU Classification
      final prediction = await classifierService.classify(inputTensor);

      detectedLabel.value = prediction.label;
      confidenceScore.value = prediction.confidence;
      topCandidates.assignAll(prediction.candidates);

      // 4. Confidence Policy Check
      if (prediction.isRecognized) {
        state.value = IsolatedSignState.result;
        onPredictionAccepted?.call(prediction);
        // Trigger Indonesian TTS once for accepted result
        if (!isMuted.value) {
          unawaited(ttsService.speak(prediction.label));
        }
      } else {
        guidanceMessage.value = 'Gerakan belum dikenali. Silakan ulangi.';
        state.value = IsolatedSignState.error;
      }
    } catch (e, st) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Processing error: $e\n$st');
      guidanceMessage.value =
          'Terjadi kesalahan pemrosesan gerakan. Silakan coba lagi.';
      state.value = IsolatedSignState.error;
    }
  }

  /// Retries capture from ready state.
  void resetToReady() {
    _cancelTimers();
    _sequenceBuffer.clear();
    _capturedFrames.clear();
    framesCollected.value = 0;
    captureProgress.value = 0.0;
    guidanceMessage.value = '';
    state.value = IsolatedSignState.ready;
  }

  /// Toggles speech mute state.
  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (isMuted.value) {
      unawaited(ttsService.stop());
    }
  }

  /// Re-speaks current recognized label.
  Future<void> speakCurrentResult() async {
    if (detectedLabel.value.isNotEmpty && !isMuted.value) {
      await ttsService.speak(detectedLabel.value);
    }
  }

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _captureTimer?.cancel();
    _captureTimer = null;
    _progressTicker?.cancel();
    _progressTicker = null;
  }

  @override
  void onClose() {
    _isDisposed = true;
    _cancelTimers();
    _sequenceBuffer.clear();
    _capturedFrames.clear();
    super.onClose();
  }
}
