import 'package:flutter/foundation.dart';

import '../models/bisindo_mode.dart';
import '../models/bisindo_prediction.dart';
import 'bisindo_inference_service.dart';

/// Rolling temporal buffer and throttling coordinator for realtime BISINDO inference.
///
/// Features:
/// - In Word mode: accumulates 30 frames before inference.
/// - In Alphabet mode: processes single frames with throttling (~100ms / 10 FPS).
/// - Concurrency guard (`_isInferring`) prevents overlapping inference runs.
class LandmarkStreamBuffer {
  final BisindoPredictor inferenceService;

  final int windowSize;
  final Duration throttleDuration;
  final int minimumWordFrames;

  final ValueChanged<BisindoPrediction>? onPrediction;
  final ValueChanged<Object>? onError;

  BisindoMode _mode = BisindoMode.alphabet;
  final List<List<List<double>>> _frameBuffer = [];
  bool _isInferring = false;
  DateTime _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _generation = 0;
  int _receivedFrameCount = 0;

  LandmarkStreamBuffer({
    required this.inferenceService,
    this.windowSize = 30,
    BisindoMode initialMode = BisindoMode.unified,
    this.throttleDuration = const Duration(milliseconds: 100),
    int? minimumFrames,
    int? minimumWordFrames,
    this.onPrediction,
    this.onError,
  }) : _mode = initialMode,
       minimumWordFrames = minimumWordFrames ?? minimumFrames ?? 30,
       assert((minimumWordFrames ?? minimumFrames ?? 30) > 0),
       assert(throttleDuration >= Duration.zero);

  BisindoMode get mode => _mode;
  int get bufferLength => _frameBuffer.length;
  bool get isInferring => _isInferring;

  void setMode(BisindoMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    if (inferenceService is BisindoInferenceService) {
      (inferenceService as BisindoInferenceService).currentMode = newMode;
    }
    clear();
  }

  void addFrame(List<List<double>> frameLandmarks) {
    _receivedFrameCount++;
    _frameBuffer.add(frameLandmarks);

    final maxBuffer = windowSize;
    if (_frameBuffer.length > maxBuffer) {
      _frameBuffer.removeAt(0);
    }

    if (kDebugMode && _receivedFrameCount % 30 == 0) {
      debugPrint(
        '[BISINDO_BUFFER] mode=${_mode.label} len=${_frameBuffer.length}/$maxBuffer',
      );
    }

    _checkAndTriggerInference();
  }

  void clear() {
    _frameBuffer.clear();
    _receivedFrameCount = 0;
    _generation++;
  }

  void _checkAndTriggerInference() {
    if (_isInferring) return;

    final requiredMin = _mode == BisindoMode.word ? minimumWordFrames : 1;
    if (_frameBuffer.length < requiredMin) return;

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

    final sequenceSnapshot = List<List<List<double>>>.of(_frameBuffer);

    try {
      final prediction = await inferenceService.predictFromLandmarks(
        sequenceSnapshot,
      );
      if (inferenceGeneration != _generation) return;

      if (kDebugMode && prediction.isRecognized) {
        debugPrint(
          '[BISINDO_INFERENCE] mode=${_mode.label} prediction=${prediction.label} confidence=${(prediction.confidence * 100).toStringAsFixed(1)}%',
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
