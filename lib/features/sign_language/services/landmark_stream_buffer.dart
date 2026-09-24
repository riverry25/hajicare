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

  final int windowSize;
  final int? minimumFrames;
  final int inferenceStride;
  final Duration throttleDuration;

  final ValueChanged<BisindoPrediction>? onPrediction;
  final ValueChanged<int>? onBufferLengthChanged;
  final ValueChanged<Object>? onError;

  final List<List<List<double>>> _frameBuffer = [];
  bool _isInferring = false;
  DateTime _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _generation = 0;
  int _framesSinceLastInference = 0;

  LandmarkStreamBuffer({
    required this.inferenceService,
    this.windowSize = 48,
    this.minimumFrames,
    this.inferenceStride = 2,
    this.throttleDuration = const Duration(milliseconds: 70),
    this.onPrediction,
    this.onBufferLengthChanged,
    this.onError,
  }) : assert(windowSize > 0),
       assert(
         minimumFrames == null ||
             (minimumFrames > 0 && minimumFrames <= windowSize),
       ),
       assert(inferenceStride > 0),
       assert(throttleDuration >= Duration.zero);

  int get bufferLength => _frameBuffer.length;
  bool get isInferring => _isInferring;
  int get effectiveMinFrames => minimumFrames ?? windowSize;
  bool get isReady => _frameBuffer.length >= effectiveMinFrames;

  /// Adds a frame of 543 holistic landmarks from the camera stream.
  void addFrame(List<List<double>> frameLandmarks) {
    _frameBuffer.add(frameLandmarks);

    if (_frameBuffer.length > windowSize) {
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
    if (_isInferring) return;

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
