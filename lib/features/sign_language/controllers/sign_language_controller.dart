import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/bisindo_prediction.dart';
import '../models/landmark_frame.dart';
import '../models/sign_capture_quality.dart';
import '../models/sign_language_model.dart';
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
  final currentModel = SignLanguageModel.bisindo.obs;
  final state = BisindoLiveState.initializing.obs;
  final isContinuousRunning = false.obs;
  final countdownSeconds = 3.obs;
  final captureProgress = 0.0.obs;
  final framesCollected = 0.obs;

  // Streaming Gesture Suggestion & Clockwise Hold-to-Confirm
  final streamingCandidate = ''.obs;
  final suggestionProgress = 0.0.obs;
  final isCandidateConfirmed = false.obs;

  // Prediction & Guidance
  final detectedLabel = ''.obs;
  final confidenceScore = 0.0.obs;
  final guidanceMessage = ''.obs;
  final topCandidates = <BisindoCandidate>[].obs;
  final lastQuality = Rxn<SignCaptureQuality>();

  // Continuous pipeline
  bool _isClassifying = false;
  bool _isPreviewing = false;
  DateTime _lastPreviewTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _candidateStreak = 0;
  String _lastCandidateLabel = '';
  double _lastCandidateConfidence = 0.0;
  String _pendingCandidateLabel = '';
  int _pendingCandidateCount = 0;
  DateTime? _segmentStartDateTime;
  int _lastInferenceDurationMs = 0;
  bool _isCommittedForCurrentSegment = false;
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
    final modelName = currentModel.value.displayName;
    switch (state.value) {
      case BisindoLiveState.initializing:
        return 'Menyiapkan modul $modelName...';
      case BisindoLiveState.stopped:
        return 'Tekan MULAI untuk mendeteksi $modelName';
      case BisindoLiveState.listening:
        return 'Siap — lakukan isyarat $modelName';
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
        return 'Lakukan satu gerakan $modelName';
      case BisindoLiveState.error:
        return guidanceMessage.value.isNotEmpty
            ? guidanceMessage.value
            : 'Modul $modelName bermasalah. Silakan coba lagi.';
    }
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(initializeServices());
  }

  Future<void> initializeServices({SignLanguageModel? model}) async {
    state.value = BisindoLiveState.initializing;
    try {
      final target = model ?? currentModel.value;
      await classifierService.initialize(model: target);
      currentModel.value = target;
      if (_isDisposed) return;
      state.value = isContinuousRunning.value
          ? BisindoLiveState.listening
          : BisindoLiveState.stopped;
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Initialization failed: $e');
      if (!_isDisposed) {
        guidanceMessage.value =
            'Gagal memuat model ${currentModel.value.displayName}. Silakan mulai ulang.';
        state.value = BisindoLiveState.error;
      }
    }
  }

  /// Seamlessly switches between SIBI and BISINDO models in memory.
  Future<void> switchModel(SignLanguageModel targetModel) async {
    if (currentModel.value == targetModel && classifierService.isInitialized) {
      return;
    }
    try {
      final config = SignLanguageModelConfig.forModel(targetModel);
      await classifierService.loadModel(config);
      currentModel.value = targetModel;
      segmenter.reset();
      detectedLabel.value = '';
      confidenceScore.value = 0.0;
      topCandidates.clear();
      guidanceMessage.value = '';
      _isCommittedForCurrentSegment = false;
      isCandidateConfirmed.value = false;
      _resetStreamingPreviewState();
      debugPrint(
        '[SIGN_LANGUAGE_CONTROLLER] Switched to ${targetModel.displayName} smoothly ✅',
      );
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Switch model error: $e');
      rethrow;
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
    _isCommittedForCurrentSegment = false;
    isCandidateConfirmed.value = false;
    _resetStreamingPreviewState();
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
    _isCommittedForCurrentSegment = false;
    isCandidateConfirmed.value = false;
    _resetStreamingPreviewState();
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
        _isCommittedForCurrentSegment = false;
        isCandidateConfirmed.value = false;
        _segmentStartDateTime = DateTime.now();
      } else {
        _segmentStartDateTime ??= DateTime.now();
      }
      _maybeRunStreamingPreview();
    } else {
      _segmentStartDateTime = null;
      if (state.value == BisindoLiveState.signing) {
        state.value = BisindoLiveState.listening;
      }
      if (!isCandidateConfirmed.value) {
        _resetStreamingPreviewState();
      }
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
    if (_isCommittedForCurrentSegment) {
      segmenter.reset();
      return;
    }
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
  // Streaming Preview Inference (Live Suggestions & Hold-to-Confirm)
  // ---------------------------------------------------------------------------

  void _maybeRunStreamingPreview() {
    if (_isDisposed ||
        _isClassifying ||
        _isPreviewing ||
        _isCommittedForCurrentSegment ||
        !classifierService.isInitialized) {
      return;
    }

    final activeFrames = segmenter.activeFrames;
    // Lower threshold from 8 to 5 so low-spec (15-20 FPS) phones respond immediately (~250-300ms)
    if (activeFrames.length < 5) return;

    final now = DateTime.now();
    // Adaptive throttle: on fast phones, 130ms; on slower phones, adapts to prevent UI lag
    final minInterval = _lastInferenceDurationMs > 75
        ? math.min(220, _lastInferenceDurationMs + 45)
        : 130;
    if (now.difference(_lastPreviewTime).inMilliseconds < minInterval) return;
    _lastPreviewTime = now;

    unawaited(_runPreviewInference(List<LandmarkFrame>.of(activeFrames)));
  }

  Future<void> _runPreviewInference(List<LandmarkFrame> frames) async {
    _isPreviewing = true;
    final stopwatch = Stopwatch()..start();
    try {
      final buffer = BisindoSequenceBuffer();
      for (final frame in frames) {
        buffer.addBaseFeature(
          BisindoFeatureExtractor.extractBaseFeature(frame),
        );
      }
      final inputTensor = buffer.prepareModelInput();
      final prediction = await classifierService.classify(inputTensor);
      stopwatch.stop();
      _lastInferenceDurationMs = stopwatch.elapsedMilliseconds;

      if (_isDisposed || !segmenter.isActive || _isCommittedForCurrentSegment) {
        return;
      }

      final candidateThreshold = (classifierService.confidenceThreshold * 0.58)
          .clamp(0.32, 0.52);

      if (prediction.isRecognized &&
          prediction.label.isNotEmpty &&
          prediction.confidence >= candidateThreshold) {
        confidenceScore.value = prediction.confidence;
        topCandidates.assignAll(prediction.candidates);

        final newCandidate = prediction.label;
        final newConfidence = prediction.confidence;

        // Anti-jitter hysteresis & candidate stabilization for low-spec camera noise:
        if (_lastCandidateLabel.isEmpty) {
          _lastCandidateLabel = newCandidate;
          _lastCandidateConfidence = newConfidence;
          _candidateStreak = 1;
          _pendingCandidateLabel = '';
          _pendingCandidateCount = 0;
        } else if (newCandidate == _lastCandidateLabel) {
          _candidateStreak++;
          _lastCandidateConfidence =
              0.65 * _lastCandidateConfidence + 0.35 * newConfidence;
          _pendingCandidateLabel = '';
          _pendingCandidateCount = 0;
        } else {
          // Switch candidate immediately if confident enough or previous streak was minimal
          if (newConfidence > _lastCandidateConfidence + 0.18 ||
              _candidateStreak <= 1) {
            _lastCandidateLabel = newCandidate;
            _lastCandidateConfidence = newConfidence;
            _candidateStreak = 1;
            _pendingCandidateLabel = '';
            _pendingCandidateCount = 0;
          } else {
            // Require 2 consecutive preview frames before switching candidate to filter out 1-frame noise
            if (_pendingCandidateLabel == newCandidate) {
              _pendingCandidateCount++;
              if (_pendingCandidateCount >= 2) {
                _lastCandidateLabel = newCandidate;
                _lastCandidateConfidence = newConfidence;
                _candidateStreak = 2;
                _pendingCandidateLabel = '';
                _pendingCandidateCount = 0;
              }
            } else {
              _pendingCandidateLabel = newCandidate;
              _pendingCandidateCount = 1;
            }
          }
        }

        streamingCandidate.value = _lastCandidateLabel;

        // Smooth FPS-independent progress:
        final elapsedMs = _segmentStartDateTime != null
            ? DateTime.now().difference(_segmentStartDateTime!).inMilliseconds
            : (frames.length * 50);

        final streakFactor = (_candidateStreak / 4.0).clamp(0.0, 1.0);
        final timeFactor = (elapsedMs / 700.0).clamp(0.0, 1.0);
        final combinedProgress = math
            .max(streakFactor * 0.55 + timeFactor * 0.45, streakFactor * 0.75)
            .clamp(0.0, 1.0);

        suggestionProgress.value = combinedProgress;

        if (combinedProgress >= 0.92 &&
            prediction.confidence >= classifierService.confidenceThreshold &&
            !_isCommittedForCurrentSegment) {
          _confirmAndCommitCandidate(prediction);
        }
      } else {
        // Soft decay on low-confidence frames (e.g. slight motion blur on low-spec camera)
        if (_candidateStreak > 0) {
          _candidateStreak = math.max(0, _candidateStreak - 1);
          suggestionProgress.value = (_candidateStreak / 4.0).clamp(0.0, 1.0);
        }
      }
    } catch (e) {
      debugPrint('[STREAMING_PREVIEW] error: $e');
    } finally {
      _isPreviewing = false;
    }
  }

  void _confirmAndCommitCandidate(BisindoPrediction prediction) {
    if (_isCommittedForCurrentSegment || _isDisposed) return;
    _isCommittedForCurrentSegment = true;
    isCandidateConfirmed.value = true;
    suggestionProgress.value = 1.0;
    detectedLabel.value = prediction.label;
    confidenceScore.value = prediction.confidence;

    HapticFeedback.mediumImpact();
    onPredictionAccepted?.call(prediction);

    _transientTimer?.cancel();
    state.value = BisindoLiveState.recognized;
    _transientTimer = Timer(kRecognizedHold, () {
      if (_isDisposed) return;
      isCandidateConfirmed.value = false;
      _resetStreamingPreviewState();
      if (segmenter.isActive) {
        state.value = BisindoLiveState.signing;
      } else {
        state.value = isContinuousRunning.value
            ? BisindoLiveState.listening
            : BisindoLiveState.stopped;
      }
    });
  }

  void _resetStreamingPreviewState() {
    streamingCandidate.value = '';
    suggestionProgress.value = 0.0;
    _candidateStreak = 0;
    _lastCandidateLabel = '';
    _lastCandidateConfidence = 0.0;
    _pendingCandidateLabel = '';
    _pendingCandidateCount = 0;
    _segmentStartDateTime = null;
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
    if (_isDisposed || _isCommittedForCurrentSegment) return;
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
      if (_isDisposed || _isCommittedForCurrentSegment) return;

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

      guidanceMessage.value = '';
      _confirmAndCommitCandidate(prediction);
    } catch (e, st) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Processing error: $e\n$st');
      _reject('Terjadi kesalahan pemrosesan gerakan. Silakan coba lagi.');
    }
  }

  void _reject(String message) {
    _resetStreamingPreviewState();
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
