import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'landmark_stream_buffer.dart';

/// Bridges the native Android CameraX + MediaPipe Holistic landmark stream
/// to the Flutter BISINDO prediction pipeline.
class BisindoCameraLandmarkService {
  static const String kMethodChannelName =
      'com.hajicare.bisindo/camera_control';
  static const String kEventChannelName = 'com.hajicare.bisindo/landmarks';

  final MethodChannel _methodChannel = const MethodChannel(kMethodChannelName);
  final EventChannel _eventChannel = const EventChannel(kEventChannelName);

  final LandmarkStreamBuffer streamBuffer;

  StreamSubscription<dynamic>? _eventSubscription;
  bool _isCameraActive = false;
  String? _lastError;
  int _receivedFramesCount = 0;

  final ValueNotifier<bool> isStreamingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<int> framesCountNotifier = ValueNotifier<int>(0);

  BisindoCameraLandmarkService({required this.streamBuffer});

  bool get isCameraActive => _isCameraActive;
  String? get lastError => _lastError;
  int get receivedFramesCount => _receivedFramesCount;

  /// Checks the current camera permission status ("granted", "denied").
  Future<String> checkPermission() async {
    try {
      final String? result = await _methodChannel.invokeMethod<String>(
        'checkPermission',
      );
      return result ?? 'denied';
    } catch (e) {
      debugPrint('[BISINDO_CAMERA] checkPermission error: $e');
      return 'denied';
    }
  }

  /// Requests runtime camera permission from Android OS.
  Future<String> requestPermission() async {
    try {
      final String? result = await _methodChannel.invokeMethod<String>(
        'requestPermission',
      );
      return result ?? 'denied';
    } catch (e) {
      debugPrint('[BISINDO_CAMERA] requestPermission error: $e');
      return 'denied';
    }
  }

  /// Starts the native Android camera stream and subscribes to MediaPipe landmark events.
  Future<bool> startCamera() async {
    if (_isCameraActive) return true;

    try {
      _lastError = null;
      errorNotifier.value = null;
      streamBuffer.clear();
      _receivedFramesCount = 0;
      framesCountNotifier.value = 0;

      // 1. Subscribe to landmark stream
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _onLandmarkEvent,
        onError: _onStreamError,
        cancelOnError: false,
      );

      // 2. Invoke native CameraX start
      final bool? success = await _methodChannel.invokeMethod<bool>(
        'startCamera',
      );
      _isCameraActive = success == true;
      isStreamingNotifier.value = _isCameraActive;

      if (!_isCameraActive) {
        await _eventSubscription?.cancel();
        _eventSubscription = null;
        _lastError = 'Kamera belum dapat digunakan. Silakan coba lagi.';
        errorNotifier.value = _lastError;
      }

      debugPrint('[BISINDO_CAMERA] started');
      return _isCameraActive;
    } catch (e) {
      _isCameraActive = false;
      isStreamingNotifier.value = false;
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      _lastError = 'Kamera belum dapat digunakan. Silakan coba lagi.';
      errorNotifier.value = _lastError;
      debugPrint('[BISINDO_CAMERA] startCamera error: $e');
      return false;
    }
  }

  /// Stops the native camera stream and unbinds CameraX.
  Future<void> stopCamera() async {
    try {
      await _eventSubscription?.cancel();
      _eventSubscription = null;

      if (_isCameraActive) {
        await _methodChannel.invokeMethod<bool>('stopCamera');
      }
      _isCameraActive = false;
      isStreamingNotifier.value = false;
      streamBuffer.clear();
      _receivedFramesCount = 0;
      framesCountNotifier.value = 0;
      debugPrint('[BISINDO_CAMERA] camera stopped');
    } catch (e) {
      debugPrint('[BISINDO_CAMERA] stopCamera error: $e');
    }
  }

  /// Handles incoming landmark frames from native Android MediaPipe.
  void _onLandmarkEvent(dynamic event) {
    if (event is! Map) return;

    final rawLandmarks = event['landmarks'];
    if (rawLandmarks is! List) return;

    // Strict validation: must have exactly 543 landmarks
    if (rawLandmarks.length != 543) {
      debugPrint(
        '[BISINDO_CAMERA] Invalid landmark count: ${rawLandmarks.length} (expected 543)',
      );
      return;
    }

    final List<List<double>> frame = [];
    bool hasInvalidValue = false;

    for (int i = 0; i < 543; i++) {
      final pt = rawLandmarks[i];
      if (pt is! List || pt.length < 3) {
        hasInvalidValue = true;
        break;
      }

      final double x = (pt[0] as num).toDouble();
      final double y = (pt[1] as num).toDouble();
      final double z = (pt[2] as num).toDouble();

      // Validate against NaN or Infinity
      if (x.isNaN ||
          x.isInfinite ||
          y.isNaN ||
          y.isInfinite ||
          z.isNaN ||
          z.isInfinite) {
        hasInvalidValue = true;
        break;
      }

      frame.add([x, y, z]);
    }

    if (hasInvalidValue || frame.length != 543) {
      return; // Discard corrupt frame
    }

    _receivedFramesCount++;
    framesCountNotifier.value = _receivedFramesCount;

    // Send valid frame to temporal inference buffer
    streamBuffer.addFrame(frame);

    if (_receivedFramesCount == 1 || _receivedFramesCount % 20 == 0) {
      debugPrint('[BISINDO_CAMERA] landmarks=543');
    }
  }

  void _onStreamError(dynamic error) {
    _lastError = error.toString();
    errorNotifier.value = _lastError;
    debugPrint('[BISINDO_CAMERA] Stream error: $error');
  }

  void dispose() {
    stopCamera();
    isStreamingNotifier.dispose();
    errorNotifier.dispose();
    framesCountNotifier.dispose();
  }
}
