import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/bisindo_prediction.dart';
import '../models/landmark_frame.dart';
import '../models/sign_capture_quality.dart';
import '../services/bisindo_classifier_service.dart';
import '../services/bisindo_feature_extractor.dart';
import '../services/bisindo_segmenter.dart';
import '../services/bisindo_sequence_buffer.dart';

/// Lifecycle of the BISINDO recognizer.
///
/// Continuous mode (default):
/// `stopped → listening ⇄ signing → classifying → recognized/rejected → listening`
///
/// Manual fallback (temporary):
/// `manualCountdown → manualCapturing → classifying → recognized/rejected`
enum BisindoLiveState {
  initializing,
  stopped,
  listening,
  signing,
  classifying,
  recognized,
  rejected,
  manualCountdown,
  manualCapturing,
  error,
}

/// Continuous BISINDO recognition: frames are auto-segmented into single
/// gestures ([BisindoSegmenter]) and each segment is classified with the
/// MotionGRU model using the exact training preprocessing
/// (base features → resample to 48 → motion delta → [1, 48, 706]).
///
/// Accepted results are forwarded via [onPredictionAccepted]; the shared
/// transcript and TTS live in `BisindoRecognitionController`.
class SignLanguageController extends GetxController {
  final BisindoClassifierService classifierService;
  final BisindoSegmenter segmenter;
  void Function(BisindoPrediction prediction)? onPredictionAccepted;

  /// Minimum top1-top2 probability gap for auto-committing in continuous mode.
  final double minContinuousMargin;

  SignLanguageController({
    BisindoClassifierService? classifierService,
    BisindoSegmenter? segmenter,
    this.onPredictionAccepted,
    this.minContinuousMargin = 0.15,
  }) : classifierService = classifierService ?? BisindoClassifierService(),
       segmenter = segmenter ?? BisindoSegmenter();

  static const Duration kManualCaptureDuration = Duration(milliseconds: 2800);
  static const Duration kRecognizedHold = Duration(milliseconds: 900);
  static const Duration kRejectedHold = Duration(milliseconds: 1600);

  // Reactive UI States
  final state = BisindoLiveState.initializing.obs;
  final isContinuousRunning = false.obs;
  final countdownSeconds = 3.obs;
  final captureProgress = 0.0.obs;
  final framesCollected = 0.obs;

  // Prediction & Guidance
  final detectedLabel = ''.obs;
  final confidenceScore = 0.0.obs;
  final guidanceMessage = ''.obs;
  final topCandidates = <BisindoCandidate>[].obs;
  final lastQuality = Rxn<SignCaptureQuality>();

  // Continuous pipeline
  bool _isClassifying = false;
  BisindoSegment? _pendingSegment;
  Timer? _transientTimer;

  // Manual pipeline
  final List<LandmarkFrame> _manualFrames = [];
  Timer? _countdownTimer;
  Timer? _captureTimer;
  Timer? _progressTicker;
  DateTime? _captureStartTime;

  bool _isDisposed = false;

  bool get isReadyForInput =>
      state.value != BisindoLiveState.initializing &&
      state.value != BisindoLiveState.error;

  bool get isManualActive =>
      state.value == BisindoLiveState.manualCountdown ||
      state.value == BisindoLiveState.manualCapturing;

  String get stateStatusText {
    switch (state.value) {
      case BisindoLiveState.initializing:
        return 'Menyiapkan modul BISINDO...';
      case BisindoLiveState.stopped:
        return 'Tekan MULAI untuk mendeteksi BISINDO';
      case BisindoLiveState.listening:
        return 'Siap — lakukan isyarat BISINDO';
      case BisindoLiveState.signing:
        return 'Membaca gerakan...';
      case BisindoLiveState.classifying:
        return 'Memproses gerakan...';
      case BisindoLiveState.recognized:
        return 'Terdeteksi: ${detectedLabel.value.toUpperCase()}';
      case BisindoLiveState.rejected:
        return guidanceMessage.value.isNotEmpty
            ? guidanceMessage.value
            : 'Gerakan belum dikenali. Silakan ulangi.';
      case BisindoLiveState.manualCountdown:
        return 'Bersiap dalam ${countdownSeconds.value}...';
      case BisindoLiveState.manualCapturing:
        return 'Lakukan satu gerakan BISINDO';
      case BisindoLiveState.error:
        return guidanceMessage.value.isNotEmpty
            ? guidanceMessage.value
            : 'Modul BISINDO bermasalah. Silakan coba lagi.';
    }
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(initializeServices());
  }

  Future<void> initializeServices() async {
    state.value = BisindoLiveState.initializing;
    try {
      await classifierService.initialize();
      if (_isDisposed) return;
      state.value = isContinuousRunning.value
          ? BisindoLiveState.listening
          : BisindoLiveState.stopped;
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Initialization failed: $e');
      if (!_isDisposed) {
        guidanceMessage.value =
            'Gagal memuat model BISINDO. Silakan mulai ulang.';
        state.value = BisindoLiveState.error;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Continuous mode
  // ---------------------------------------------------------------------------

  /// Starts hands-free detection. Safe to call repeatedly.
  void startContinuous() {
    if (_isDisposed) return;
    isContinuousRunning.value = true;
    segmenter.reset();
    _pendingSegment = null;
    guidanceMessage.value = '';
    if (state.value == BisindoLiveState.initializing ||
        state.value == BisindoLiveState.error ||
        isManualActive) {
      return; // Will move to listening when ready / manual finishes.
    }
    _transientTimer?.cancel();
    state.value = BisindoLiveState.listening;
  }

  /// Stops detection (camera stop / model switch). Transcript is untouched.
  void stopContinuous() {
    if (_isDisposed) return;
    isContinuousRunning.value = false;
    _cancelManualTimers();
    _manualFrames.clear();
    _transientTimer?.cancel();
    segmenter.reset();
    _pendingSegment = null;
    framesCollected.value = 0;
    captureProgress.value = 0.0;
    if (state.value != BisindoLiveState.initializing &&
        state.value != BisindoLiveState.error) {
      state.value = BisindoLiveState.stopped;
    }
  }

  /// Ingests a camera landmark frame. [nowMs] is injectable for tests.
  void onIncomingLandmarkFrame(LandmarkFrame frame, {int? nowMs}) {
    if (_isDisposed) return;

    if (state.value == BisindoLiveState.manualCapturing) {
      _manualFrames.add(frame);
      framesCollected.value = _manualFrames.length;
      return;
    }

    if (!isContinuousRunning.value || !isReadyForInput || isManualActive) {
      return;
    }

    final timestamp = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final segment = segmenter.add(frame, nowMs: timestamp);
    framesCollected.value = segmenter.activeFrameCount;
    captureProgress.value = segmenter.isActive
        ? (segmenter.activeFrameCount / BisindoSequenceBuffer.kSequenceLength)
              .clamp(0.0, 1.0)
        : 0.0;

    if (segmenter.isActive) {
      if (state.value == BisindoLiveState.listening ||
          state.value == BisindoLiveState.recognized ||
          state.value == BisindoLiveState.rejected) {
        _transientTimer?.cancel();
        state.value = BisindoLiveState.signing;
      }
    } else if (state.value == BisindoLiveState.signing) {
      state.value = BisindoLiveState.listening;
    }

    if (segment != null) {
      _enqueueSegment(segment);
    }
  }

  void _enqueueSegment(BisindoSegment segment) {
    if (_isClassifying) {
      // Keep only the most recent gesture; never stack inference calls.
      _pendingSegment = segment;
      return;
    }
    unawaited(_classifySegment(segment));
  }

  Future<void> _classifySegment(BisindoSegment segment) async {
    _isClassifying = true;
    state.value = BisindoLiveState.classifying;
    try {
      await _classifyFrames(
        segment.frames,
        minMargin: minContinuousMargin,
        source: 'auto/${segment.reason.name}',
      );
    } finally {
      _isClassifying = false;
      final next = _pendingSegment;
      _pendingSegment = null;
      if (next != null && !_isDisposed && isContinuousRunning.value) {
        unawaited(_classifySegment(next));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Manual fallback (temporary): 3s countdown → 2.8s capture → classify
  // ---------------------------------------------------------------------------

  void startCaptureSession({bool skipCountdown = false}) {
    if (_isDisposed ||
        !isReadyForInput ||
        isManualActive ||
        state.value == BisindoLiveState.classifying) {
      return;
    }

    _cancelManualTimers();
    _transientTimer?.cancel();
    segmenter.reset();
    _pendingSegment = null;
    _manualFrames.clear();
    framesCollected.value = 0;
    captureProgress.value = 0.0;
    guidanceMessage.value = '';

    if (skipCountdown) {
      _beginManualRecording();
      return;
    }
    state.value = BisindoLiveState.manualCountdown;
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
        _beginManualRecording();
      }
    });
  }

  void _beginManualRecording() {
    if (_isDisposed) return;
    state.value = BisindoLiveState.manualCapturing;
    _captureStartTime = DateTime.now();

    _progressTicker = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isDisposed || state.value != BisindoLiveState.manualCapturing) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now()
          .difference(_captureStartTime!)
          .inMilliseconds;
      captureProgress.value = (elapsed / kManualCaptureDuration.inMilliseconds)
          .clamp(0.0, 1.0);
    });

    _captureTimer = Timer(kManualCaptureDuration, () {
      _progressTicker?.cancel();
      unawaited(_finishManualRecording());
    });
  }

  Future<void> _finishManualRecording() async {
    if (_isDisposed) return;
    captureProgress.value = 1.0;
    final frames = List<LandmarkFrame>.of(_manualFrames);
    _manualFrames.clear();
    _isClassifying = true;
    state.value = BisindoLiveState.classifying;
    try {
      await _classifyFrames(frames, minMargin: 0.0, source: 'manual');
    } finally {
      _isClassifying = false;
      segmenter.reset();
    }
  }

  // ---------------------------------------------------------------------------
  // Shared classification
  // ---------------------------------------------------------------------------

  Future<void> _classifyFrames(
    List<LandmarkFrame> frames, {
    required double minMargin,
    required String source,
  }) async {
    if (_isDisposed) return;
    try {
      final quality = SignCaptureQuality.fromFrames(frames);
      lastQuality.value = quality;
      final qualityCheck = quality.validate();
      if (!qualityCheck.isValid) {
        _reject(
          qualityCheck.userErrorMessage ??
              'Gerakan belum cukup terdeteksi. Silakan coba lagi.',
        );
        return;
      }

      final buffer = BisindoSequenceBuffer();
      for (final frame in frames) {
        buffer.addBaseFeature(
          BisindoFeatureExtractor.extractBaseFeature(frame),
        );
      }
      final inputTensor = buffer.prepareModelInput();
      final prediction = await classifierService.classify(inputTensor);
      if (_isDisposed) return;

      confidenceScore.value = prediction.confidence;
      topCandidates.assignAll(prediction.candidates);

      final accepted =
          prediction.isRecognized &&
          prediction.label.isNotEmpty &&
          prediction.margin >= minMargin;

      if (kDebugMode) {
        debugPrint(
          '[BISINDO_LIVE] $source frames=${frames.length} -> ${prediction.label} '
          'conf=${(prediction.confidence * 100).toStringAsFixed(1)}% '
          'margin=${(prediction.margin * 100).toStringAsFixed(1)}% accepted=$accepted',
        );
      }

      if (!accepted) {
        _reject('Gerakan belum dikenali. Silakan ulangi.');
        return;
      }

      detectedLabel.value = prediction.label;
      guidanceMessage.value = '';
      _showTransient(BisindoLiveState.recognized, kRecognizedHold);
      onPredictionAccepted?.call(prediction);
    } catch (e, st) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Processing error: $e\n$st');
      _reject('Terjadi kesalahan pemrosesan gerakan. Silakan coba lagi.');
    }
  }

  void _reject(String message) {
    guidanceMessage.value = message;
    _showTransient(BisindoLiveState.rejected, kRejectedHold);
  }

  /// Shows a short-lived result state, then returns to listening/stopped.
  void _showTransient(BisindoLiveState transient, Duration hold) {
    if (_isDisposed) return;
    _transientTimer?.cancel();
    state.value = transient;
    _transientTimer = Timer(hold, () {
      if (_isDisposed || state.value != transient) return;
      _settleIdleState();
    });
  }

  void _settleIdleState() {
    if (!isContinuousRunning.value) {
      state.value = BisindoLiveState.stopped;
    } else {
      state.value = segmenter.isActive
          ? BisindoLiveState.signing
          : BisindoLiveState.listening;
    }
  }

  void _cancelManualTimers() {
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
    _cancelManualTimers();
    _transientTimer?.cancel();
    _manualFrames.clear();
    segmenter.reset();
    _pendingSegment = null;
    unawaited(classifierService.dispose());
    super.onClose();
  }
}
