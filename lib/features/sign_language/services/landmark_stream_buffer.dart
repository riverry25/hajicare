import 'package:flutter/foundation.dart';

import '../models/bisindo_prediction.dart';
import 'bisindo_inference_service.dart';

/// Rolling temporal buffer and coordinator for realtime BISINDO GRU inference.
///
/// Pipeline:
/// - Accumulates 48 frames (15 FPS, ~3.2s window).
/// - When buffer length < 48: does NOT run inference.
/// - When buffer reaches 48 frames: triggers inference every [inferenceStride] frames (default: 4 frames).
/// - Threading: concurrency guard prevents overlapping inference calls.
class LandmarkStreamBuffer {
  final BisindoPredictor inferenceService;

  int _windowSize;
  int? _minimumFrames;
  int _inferenceStride;
  Duration _throttleDuration;

  int get windowSize => _windowSize;
  int? get minimumFrames => _minimumFrames;
  int get inferenceStride => _inferenceStride;
  Duration get throttleDuration => _throttleDuration;

  final ValueChanged<BisindoPrediction>? onPrediction;
  final ValueChanged<int>? onBufferLengthChanged;
  final ValueChanged<Object>? onError;

  final List<List<List<double>>> _frameBuffer = [];
  bool _isInferring = false;
  bool _isPaused = false;
  DateTime _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _generation = 0;
  int _framesSinceLastInference = 0;

  LandmarkStreamBuffer({
    required this.inferenceService,
    int windowSize = 48,
    int? minimumFrames,
    int inferenceStride = 2,
    Duration throttleDuration = const Duration(milliseconds: 70),
    this.onPrediction,
    this.onBufferLengthChanged,
    this.onError,
  }) : _windowSize = windowSize,
       _minimumFrames = minimumFrames,
       _inferenceStride = inferenceStride,
       _throttleDuration = throttleDuration,
       assert(windowSize > 0),
       assert(
         minimumFrames == null ||
             (minimumFrames > 0 && minimumFrames <= windowSize),
       ),
       assert(inferenceStride > 0),
       assert(throttleDuration >= Duration.zero);

  int get bufferLength => _frameBuffer.length;
  bool get isInferring => _isInferring;
  bool get isPaused => _isPaused;
  int get effectiveMinFrames => _minimumFrames ?? _windowSize;
  bool get isReady => _frameBuffer.length >= effectiveMinFrames;

  /// Pauses landmark buffer processing and inference (e.g. during model switching).
  void pause() {
    _isPaused = true;
  }

  /// Resumes landmark buffer processing and inference.
  void resume() {
    _isPaused = false;
  }

  /// Updates buffer and stride parameters when switching models (e.g. SIBI vs BISINDO).
  void updateConfig({
    int? windowSize,
    int? minimumFrames,
    int? inferenceStride,
    Duration? throttleDuration,
  }) {
    if (windowSize != null && windowSize > 0) {
      _windowSize = windowSize;
    }
    if (minimumFrames != null) {
      _minimumFrames = minimumFrames;
    }
    if (inferenceStride != null && inferenceStride > 0) {
      _inferenceStride = inferenceStride;
    }
    if (throttleDuration != null) {
      _throttleDuration = throttleDuration;
    }
    while (_frameBuffer.length > _windowSize) {
      _frameBuffer.removeAt(0);
    }
    onBufferLengthChanged?.call(_frameBuffer.length);
  }

  /// Adds a frame of 543 holistic landmarks from the camera stream.
  void addFrame(List<List<double>> frameLandmarks) {
    if (_isPaused) return;

    _frameBuffer.add(frameLandmarks);

    if (_frameBuffer.length > _windowSize) {
      _frameBuffer.removeAt(0);
    }

    _framesSinceLastInference++;
    onBufferLengthChanged?.call(_frameBuffer.length);

    _checkAndTriggerInference();
  }

  void clear() {
    _frameBuffer.clear();
    _framesSinceLastInference = 0;
    _generation++;
    onBufferLengthChanged?.call(0);
  }

  void _checkAndTriggerInference() {
    if (_isPaused || _isInferring) return;

    // Do NOT infer if buffer has not reached the required minimum sequence length
    if (_frameBuffer.length < effectiveMinFrames) return;

    // Run inference every `inferenceStride` frames (default: 2 frames)
    if (_framesSinceLastInference < inferenceStride) return;

    final now = DateTime.now();
    if (now.difference(_lastInferenceTime) < throttleDuration) {
      return;
    }

    _triggerInference();
  }

  Future<void> _triggerInference() async {
    _isInferring = true;
    _lastInferenceTime = DateTime.now();
    _framesSinceLastInference = 0;
    final inferenceGeneration = _generation;

    final sequenceSnapshot = List<List<List<double>>>.of(_frameBuffer);

    try {
      final prediction = await inferenceService.predictFromLandmarks(
        sequenceSnapshot,
      );
      if (inferenceGeneration != _generation) return;

      onPrediction?.call(prediction);
    } catch (e, stack) {
      debugPrint('[LandmarkStreamBuffer] Inference error: $e\n$stack');
      onError?.call(e);
    } finally {
      _isInferring = false;
    }
  }

  void dispose() {
    clear();
  }
}
