import 'package:flutter/foundation.dart';

import '../models/bisindo_prediction.dart';
import 'bisindo_inference_service.dart';

/// Temporal buffer and throttling coordinator for realtime BISINDO inference.
///
/// Designed to receive live landmark frames from a MediaPipe Holistic camera stream
/// without blocking the UI thread or flooding ONNX runtime.
///
/// Expected input:
/// Sequence of 543 landmarks `[543, 3]` (x, y, z) per camera tick.
class LandmarkStreamBuffer {
  final BisindoPredictor inferenceService;

  /// Window size for temporal inference (default 100 frames).
  final int windowSize;

  /// Minimum duration between consecutive inferences to prevent CPU overload.
  final Duration throttleDuration;

  /// Minimum useful sequence length before inference is attempted.
  final int minimumFrames;

  /// Callback triggered when a new prediction is produced.
  final ValueChanged<BisindoPrediction>? onPrediction;

  /// Callback triggered when an error occurs during inference.
  final ValueChanged<Object>? onError;

  final List<List<List<double>>> _frameBuffer = [];
  bool _isInferring = false;
  DateTime _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _generation = 0;
  int _receivedFrameCount = 0;

  LandmarkStreamBuffer({
    required this.inferenceService,
    this.windowSize = 100,
    this.throttleDuration = const Duration(milliseconds: 100),
    this.minimumFrames = 30,
    this.onPrediction,
    this.onError,
  }) : assert(minimumFrames > 0 && minimumFrames <= windowSize),
       assert(throttleDuration >= Duration.zero);

  /// Current number of frames accumulated in the rolling buffer.
  int get bufferLength => _frameBuffer.length;

  /// Whether an inference call is currently in-flight.
  bool get isInferring => _isInferring;

  /// Feeds a single frame of 543 landmarks into the buffer and checks if
  /// an inference should be triggered.
  void addFrame(List<List<double>> frameLandmarks) {
    _receivedFrameCount++;
    _frameBuffer.add(frameLandmarks);

    // Keep buffer within the desired window size
    if (_frameBuffer.length > windowSize) {
      _frameBuffer.removeAt(0);
    }

    if (kDebugMode && _receivedFrameCount % 30 == 0) {
      debugPrint('[BISINDO_BUFFER] ${_frameBuffer.length}/$windowSize');
    }

    _checkAndTriggerInference();
  }

  /// Clears the temporal frame buffer.
  void clear() {
    _frameBuffer.clear();
    _receivedFrameCount = 0;
    _generation++;
  }

  void _checkAndTriggerInference() {
    if (_isInferring) return;

    if (_frameBuffer.length < minimumFrames) return;

    final now = DateTime.now();
    if (now.difference(_lastInferenceTime) < throttleDuration) {
      return;
    }

    _triggerInference();
  }

  Future<void> _triggerInference() async {
    _isInferring = true;
    _lastInferenceTime = DateTime.now();
    final inferenceGeneration = _generation;

    // Frames are never mutated after insertion. A shallow sequence snapshot
    // prevents concurrent list mutation without copying ~160k doubles/run.
    final sequenceSnapshot = List<List<List<double>>>.of(_frameBuffer);

    try {
      final prediction = await inferenceService.predictFromLandmarks(
        sequenceSnapshot,
      );
      if (inferenceGeneration != _generation) return;

      if (kDebugMode) {
        debugPrint(
          '[BISINDO_INFERENCE] prediction=${prediction.label} confidence=${prediction.confidence.toStringAsFixed(2)}',
        );
      }
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
