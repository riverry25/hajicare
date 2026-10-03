import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart bridge connecting Flutter with native Android Foreground Service for Adhan.
/// Enables reliable Adhan playback in background and when app is closed.
class AdhanNativeBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.hajicare/adhan_native_service',
  );

  /// Checks if running on Android where native foreground service is supported.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Schedules an exact native alarm that launches the AdhanPlaybackService
  /// when [scheduledTime] arrives, even if the device is locked or app is closed.
  static Future<bool> scheduleNativeAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required bool isSubuh,
  }) async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('scheduleNativeAdhan', {
        'id': id,
        'prayerName': prayerName,
        'isSubuh': isSubuh,
        'triggerTimestampMs': scheduledTime.millisecondsSinceEpoch,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('[AdhanNativeBridge] scheduleNativeAdhan error: $e');
      return false;
    }
  }

  /// Cancels a previously scheduled native alarm by [id].
  static Future<bool> cancelNativeAdhan({required int id}) async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('cancelNativeAdhan', {
        'id': id,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('[AdhanNativeBridge] cancelNativeAdhan error: $e');
      return false;
    }
  }

  /// Immediately starts the native Foreground Service to play the adhan.
  static Future<bool> startAdhanService({
    required String prayerName,
    required bool isSubuh,
  }) async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('startAdhanService', {
        'prayerName': prayerName,
        'isSubuh': isSubuh,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('[AdhanNativeBridge] startAdhanService error: $e');
      return false;
    }
  }

  /// Immediately stops the native Foreground Service and halts audio playback.
  static Future<bool> stopAdhanService() async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('stopAdhanService');
      return res ?? false;
    } catch (e) {
      debugPrint('[AdhanNativeBridge] stopAdhanService error: $e');
      return false;
    }
  }

  /// Checks if the native AdhanPlaybackService is currently playing audio.
  static Future<bool> isServiceRunning() async {
    if (!isSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isServiceRunning');
      return res ?? false;
    } catch (e) {
      debugPrint('[AdhanNativeBridge] isServiceRunning error: $e');
      return false;
    }
  }
}
