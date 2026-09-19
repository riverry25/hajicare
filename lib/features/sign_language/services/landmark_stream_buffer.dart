import 'dart:async';
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
  final BisindoInferenceService inferenceService;

  /// Window size for temporal inference (default 100 frames).
  final int windowSize;

  /// Minimum duration between consecutive inferences to prevent CPU overload (default 300 ms).
  final Duration throttleDuration;

  /// Callback triggered when a new prediction is produced.
  final ValueChanged<BisindoPrediction>? onPrediction;

  /// Callback triggered when an error occurs during inference.
  final ValueChanged<Object>? onError;

  final List<List<List<double>>> _frameBuffer = [];
  bool _isInferring = false;
  DateTime _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);

  LandmarkStreamBuffer({
    required this.inferenceService,
    this.windowSize = 100,
    this.throttleDuration = const Duration(milliseconds: 300),
    this.onPrediction,
    this.onError,
  });

  /// Current number of frames accumulated in the rolling buffer.
  int get bufferLength => _frameBuffer.length;

  /// Whether an inference call is currently in-flight.
  bool get isInferring => _isInferring;

  /// Feeds a single frame of 543 landmarks into the buffer and checks if
  /// an inference should be triggered.
  void addFrame(List<List<double>> frameLandmarks) {
    _frameBuffer.add(frameLandmarks);

    // Keep buffer within the desired window size
    if (_frameBuffer.length > windowSize) {
      _frameBuffer.removeAt(0);
    }

    _checkAndTriggerInference();
  }

  /// Clears the temporal frame buffer.
  void clear() {
    _frameBuffer.clear();
  }

  void _checkAndTriggerInference() {
    if (_isInferring) return;

    // Wait until at least 30 frames are collected to have meaningful motion
    if (_frameBuffer.length < 30) return;

    final now = DateTime.now();
    if (now.difference(_lastInferenceTime) < throttleDuration) {
      return;
    }

    _triggerInference();
  }

  Future<void> _triggerInference() async {
    _isInferring = true;
    _lastInferenceTime = DateTime.now();

    // Snapshot buffer to prevent concurrent mutation
    final sequenceSnapshot = List<List<List<double>>>.from(
      _frameBuffer.map(
        (f) => List<List<double>>.from(f.map((pt) => List<double>.from(pt))),
      ),
    );

    try {
      final prediction = await inferenceService.predictFromLandmarks(
        sequenceSnapshot,
      );
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
